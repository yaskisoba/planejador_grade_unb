:- use_module('../../prolog/ranking').
:- use_module('../../prolog/regras').

:- begin_tests(ranking).

% Casos isolados medem slots, sem depender da pequena base demonstrativa.
grade_horarios(Horarios, [turma(teste, 'A', "Teste", Horarios, 1)]).

test(grade_vazia) :-
    metricas_grade([], 0, 0),
    pontuacao_grade([], 0).

test(aulas_contiguas) :-
    grade_horarios(['2M1234'], Grade),
    metricas_grade(Grade, 0, 1).

test(janela_interna) :-
    grade_horarios(['2M14'], Grade),
    metricas_grade(Grade, 2, 1),
    pontuacao_grade(Grade, 15).

test(soma_janelas_de_dias_distintos) :-
    grade_horarios(['24M14'], Grade),
    metricas_grade(Grade, 4, 2).

test(intervalo_entre_dias_nao_e_janela) :-
    grade_horarios(['2M1', '7N4'], Grade),
    metricas_grade(Grade, 0, 2).

test(transicao_de_turnos_contigua) :-
    grade_horarios(['2M5', '2T1', '3T6', '3N1'], Grade),
    metricas_grade(Grade, 0, 2).

test(janelas_entre_turnos) :-
    grade_horarios(['2M5', '2N1'], Grade),
    metricas_grade(Grade, 6, 1).

test(horarios_repetidos_e_fora_de_ordem) :-
    grade_horarios(['4T2', '2M13', '2M1', '4T12'], Grade),
    metricas_grade(Grade, 1, 2).

test(uniao_das_aulas_de_todas_as_turmas) :-
    Grade = [turma(a, 'A', "Teste", ['2M13'], 1),
             turma(b, 'A', "Teste", ['2M2'], 1)],
    metricas_grade(Grade, 0, 1).

test(horarios_com_strings) :-
    grade_horarios(["24M13"], Grade),
    metricas_grade(Grade, 2, 2).

test(horario_invalido, [fail]) :-
    grade_horarios(['8M1'], Grade),
    metricas_grade(Grade, _, _).

test(menos_janelas_tem_prioridade_sobre_dias) :-
    grade_horarios(['234567M1'], Compacta),
    grade_horarios(['2M13'], ComJanela),
    pontuacao_grade(Compacta, Melhor),
    pontuacao_grade(ComJanela, Pior),
    assertion(Melhor < Pior).

test(menos_dias_desempata_janelas) :-
    grade_horarios(['2M12'], Concentrada),
    grade_horarios(['24M1'], Dispersa),
    pontuacao_grade(Concentrada, Melhor),
    pontuacao_grade(Dispersa, Pior),
    assertion(Melhor < Pior).

% O gerador sintetico exercita mais de cinco candidatos e duplicatas sem
% alterar os fatos de producao. Os testes seguintes integram a API publica.
grade_sintetica([turma(teste, Id, "Teste", [Horario], 1)]) :-
    member(Id-Horario,
           [h-'2M15', g-'2M14', f-'234567M1', e-'23456M1',
            d-'2345M1', c-'234M1', b-'23M1', a-'2M1']).

grade_sintetica_repetida(Grade) :-
    member(_, [primeira, segunda]),
    grade_sintetica(Grade).

grade_empatada([turma(teste, Id, "Teste", ['2M1'], 1)]) :-
    member(Id, [b, a, a]).

resumo(Resultados, Resumo) :-
    findall(Pontuacao-Janelas-Dias-Ids,
            ( member(resultado(Pontuacao, Janelas, Dias, Grade), Resultados),
              findall(Codigo-Id, member(turma(Codigo, Id, _, _, _), Grade), Ids) ),
            Resumo).

test(top_cinco_global_ordenado) :-
    ranking:melhores_cinco(plunit_ranking:grade_sintetica, Top5),
    resumo(Top5, Resumo),
    assertion(Resumo == [1-0-1-[teste-a], 2-0-2-[teste-b],
                         3-0-3-[teste-c], 4-0-4-[teste-d], 5-0-5-[teste-e]]).

test(duplicatas_nao_ocupam_o_top_cinco) :-
    ranking:melhores_cinco(plunit_ranking:grade_sintetica_repetida, Top5),
    resumo(Top5, Resumo),
    assertion(Resumo == [1-0-1-[teste-a], 2-0-2-[teste-b],
                         3-0-3-[teste-c], 4-0-4-[teste-d], 5-0-5-[teste-e]]).

test(empate_preserva_grades_distintas_em_ordem_estavel) :-
    ranking:melhores_cinco(plunit_ranking:grade_empatada, Top5),
    resumo(Top5, Resumo),
    assertion(Resumo == [1-0-1-[teste-a], 1-0-1-[teste-b]]).

test(integracao_com_regras_e_menos_de_cinco_resultados) :-
    top_5_grades(['FGA0158'], ['FGA0210', 'FGA0244'], [], Top5),
    resumo(Top5, Resumo),
    assertion(Resumo == [4-0-4-['FGA0210'-'A', 'FGA0244'-'A'],
                         4-0-4-['FGA0210'-'B', 'FGA0244'-'B'],
                         24-3-3-['FGA0210'-'A', 'FGA0244'-'B']]),
    forall(member(resultado(_, _, _, Grade), Top5),
           once(grade(['FGA0158'], ['FGA0210', 'FGA0244'], [], Grade))).

test(bloqueios_filtram_sem_adicionar_dias_ao_ranking) :-
    top_5_grades(['FGA0158'], ['FGA0210', 'FGA0244'], ['2M3'], Top5),
    resumo(Top5, Resumo),
    assertion(Resumo == [4-0-4-['FGA0210'-'B', 'FGA0244'-'B']]).

test(turma_sem_vagas_nao_aparece) :-
    top_5_grades([], ['FGA0124'], [], Top5),
    resumo(Top5, Resumo),
    assertion(Resumo == [1-0-1-['FGA0124'-'B']]).

test(entradas_json_e_desejadas_repetidas) :-
    top_5_grades(["FGA0158"], ["FGA0244", "FGA0210", "FGA0244"], [], Strings),
    top_5_grades(['FGA0158'], ['FGA0210', 'FGA0244'], [], Atomos),
    assertion(Strings == Atomos).

test(sem_prerequisito, [true(Top5 == [])]) :-
    top_5_grades([], ['FGA0210'], [], Top5).

test(disciplina_ja_cursada, [true(Top5 == [])]) :-
    top_5_grades(['FGA0158'], ['FGA0158'], [], Top5).

test(disciplina_inexistente, [true(Top5 == [])]) :-
    top_5_grades([], [inexistente], [], Top5).

test(todas_as_turmas_bloqueadas, [true(Top5 == [])]) :-
    top_5_grades([], ['FGA0124'], ['6T1'], Top5).

test(limite_maximo_de_creditos, [true(Top5 == [])]) :-
    top_5_grades(['FGA0158'], ['FGA0210', 'FGA0244'], [], 0, 4, Top5).

test(limite_minimo_de_creditos, [true(Top5 == [])]) :-
    top_5_grades([], ['FGA0124'], [], 8, 32, Top5).

test(limites_inclusivos) :-
    top_5_grades(['FGA0158'], ['FGA0210', 'FGA0244'], [], 8, 8, Top5),
    top_5_grades(['FGA0158'], ['FGA0210', 'FGA0244'], [], Padrao),
    assertion(Top5 == Padrao).

test(sem_desejadas_no_limite_padrao, [true(Top5 == [])]) :-
    top_5_grades([], [], [], Top5).

test(grade_vazia_com_minimo_zero, [true(Top5 == [resultado(0, 0, 0, [])])]) :-
    top_5_grades([], [], [], 0, 32, Top5).

:- end_tests(ranking).
