:- use_module('../regras').
:- use_module('../turmas').

:- begin_tests(oferta).

% snapshot/1 descarta as alterações dos fatos mesmo quando um teste falha.
% Assim, carregar_oferta/3 pode ser exercitado sem substituir a base dos
% outros testes, independentemente da ordem de execução das suítes.
carregar_cenario(Grupos) :-
    findall(["TEST0004", Grupo], member(Grupo, Grupos), Requisitos),
    carregar_oferta(
        [["TEST0001", "Requisito A", 4],
         ["TEST0002", "Requisito B", 4],
         ["TEST0003", "Requisito C", 4],
         ["TEST0004", "Disciplina desejada", 4]],
        [["TEST0004", "01", ["24M34"], 10]],
        Requisitos).

test(conjuncao_aceita_todos_os_requisitos) :-
    snapshot((
        carregar_cenario([["TEST0001"], ["TEST0002"]]),
        assertion(apto(["TEST0001", "TEST0002"], "TEST0004"))
    )).

test(conjuncao_rejeita_cada_requisito_ausente) :-
    snapshot((
        carregar_cenario([["TEST0001"], ["TEST0002"]]),
        forall(member(Cursadas, [[], ["TEST0001"], ["TEST0002"]]),
               assertion(\+ apto(Cursadas, "TEST0004")))
    )).

test(disjuncao_aceita_cada_alternativa) :-
    snapshot((
        carregar_cenario([["TEST0001", "TEST0002"]]),
        forall(member(Cursadas, [["TEST0001"], ["TEST0002"],
                                ["TEST0001", "TEST0002"]]),
               assertion(apto(Cursadas, "TEST0004")))
    )).

test(disjuncao_rejeita_ausencia_de_alternativas) :-
    snapshot((
        carregar_cenario([["TEST0001", "TEST0002"]]),
        forall(member(Cursadas, [[], ["TEST0003"]]),
               assertion(\+ apto(Cursadas, "TEST0004")))
    )).

test(grupos_mistos_geram_grade_com_cada_alternativa) :-
    snapshot((
        carregar_cenario([["TEST0001", "TEST0002"], ["TEST0003"]]),
        forall(member(Cursadas, [["TEST0001", "TEST0003"],
                                ["TEST0002", "TEST0003"]]),
               assertion(grade(Cursadas, ["TEST0004"], [],
                               [turma('TEST0004', '01', "", ['24M34'], 10)])))
    )).

test(grupos_mistos_nao_geram_grade_com_grupo_incompleto) :-
    snapshot((
        carregar_cenario([["TEST0001", "TEST0002"], ["TEST0003"]]),
        forall(member(Cursadas, [["TEST0001", "TEST0002"], ["TEST0003"], []]),
               assertion(\+ grade(Cursadas, ["TEST0004"], [], _)))
    )).

test(carregamento_converte_codigos_e_horarios_preservando_dados) :-
    snapshot((
        carregar_oferta([["TEST0004", "Disciplina desejada", 6]],
                        [["TEST0004", "02", ["24M34", "6T12"], 7]],
                        [["TEST0004", ["TEST0001", "TEST0002"]]]),
        assertion(disciplina('TEST0004', "Disciplina desejada", 6)),
        assertion(turma('TEST0004', '02', "", ['24M34', '6T12'], 7)),
        assertion(grupo_prerequisitos('TEST0004', ['TEST0001', 'TEST0002']))
    )).

test(nova_oferta_substitui_disciplinas_turmas_e_requisitos) :-
    snapshot((
        carregar_cenario([["TEST0001"]]),
        % Também cobre os requisitos da antiga base demonstrativa.
        assertz(turmas:prerequisito('TEST0004', 'TEST0002')),
        carregar_oferta([["TEST0004", "Nome atualizado", 6]],
                        [["TEST0004", "02", ["6T12"], 3]], []),
        findall(C-N-Cr, disciplina(C, N, Cr), Disciplinas),
        findall(C-I-P-H-V, turma(C, I, P, H, V), Turmas),
        findall(C-R, grupo_prerequisitos(C, R), Requisitos),
        assertion(Disciplinas == ['TEST0004'-"Nome atualizado"-6]),
        assertion(Turmas == ['TEST0004'-'02'-""-['6T12']-3]),
        assertion(Requisitos == []),
        assertion(apto([], 'TEST0004'))
    )).

test(recarregar_mesma_oferta_nao_duplica_fatos_nem_grades) :-
    snapshot((
        carregar_cenario([["TEST0001", "TEST0002"]]),
        carregar_cenario([["TEST0001", "TEST0002"]]),
        aggregate_all(count, disciplina(_, _, _), TotalDisciplinas),
        aggregate_all(count, turma(_, _, _, _, _), TotalTurmas),
        findall(C-R, grupo_prerequisitos(C, R), Requisitos),
        findall(G, grade(["TEST0001"], ["TEST0004"], [], G), Grades),
        assertion(TotalDisciplinas == 4),
        assertion(TotalTurmas == 1),
        assertion(Requisitos == ['TEST0004'-['TEST0001', 'TEST0002']]),
        assertion(Grades == [[turma('TEST0004', '01', "", ['24M34'], 10)]])
    )).

test(carga_incompleta_preserva_oferta_anterior) :-
    snapshot((
        carregar_cenario([["TEST0001"]]),
        % A segunda turma malformada faz a carga falhar após inserir a primeira.
        assertion(\+ carregar_oferta([["NOVA0001", "Nova", 2]],
                                     [["NOVA0001", "A", ["2M1"], 5], []], [])),
        assertion(\+ disciplina('NOVA0001', _, _)),
        assertion(\+ turma('NOVA0001', _, _, _, _)),
        assertion(grupo_prerequisitos('TEST0004', ['TEST0001'])),
        assertion(grade(["TEST0001"], ["TEST0004"], [],
                        [turma('TEST0004', '01', "", ['24M34'], 10)]))
    )).

:- end_tests(oferta).
