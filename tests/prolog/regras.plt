:- use_module('../../prolog/regras').

:- begin_tests(horarios).

test(slots) :-
    horario_slots('24M34', [35, 36, 67, 68]).

test(noite) :-
    horario_slots("6N12", [108, 109]).

test(horarios_repetidos_e_fora_de_ordem, [true(Slots == [35, 36, 67, 68])]) :-
    horario_slots('442M433', Slots).

test(dia_invalido, [fail]) :-
    horario_slots('8M12', _).

test(indice_invalido, [fail]) :-
    horario_slots('2M6', _).

test(formato_invalido, [fail]) :-
    horario_slots('M12', _).

test(choque) :-
    choque(['24M34'], ['4M45']).

test(sem_choque, [fail]) :-
    choque(['24M34'], ['24M12', '35M34']).

:- end_tests(horarios).

:- begin_tests(prerequisitos).

test(sem_requisito, [fail]) :-
    apto([], 'FGA0210').

test(com_requisito) :-
    apto(["FGA0158"], "FGA0210").

test(ja_cursada, [fail]) :-
    apto(['FGA0158'], 'FGA0158').

test(aptas) :-
    disciplinas_aptas([], ['FGA0210', 'FGA0244'], ['FGA0244']).

:- end_tests(prerequisitos).

:- begin_tests(creditos).

test(soma_creditos_com_atomo_e_string, [true(Total == 8)]) :-
    total_creditos(['FGA0210', "FGA0244"], Total).

:- end_tests(creditos).

:- begin_tests(grade).

test(combinacoes, [Total == 3]) :-
    aggregate_all(count, grade(['FGA0158'], ['FGA0210', 'FGA0244'], [], _), Total).

test(bloqueio, [Grade == [turma('FGA0210', 'B', "Professor 4", ['35M12'], 40),
                          turma('FGA0244', 'B', "Professor 6", ['46T34'], 40)]]) :-
    grade(['FGA0158'], ['FGA0210', 'FGA0244'], ['2M3'], Grade).

test(turma_lotada, [Grade == [turma('FGA0124', 'B', "Professor 8", ['6T12'], 30)]]) :-
    grade([], ['FGA0124'], [], Grade).

test(json_strings, [nondet]) :-
    grade(["FGA0158"], ["FGA0210", "FGA0244"], ["6T34"], _).

test(sem_prerequisito, [fail]) :-
    grade([], ['FGA0210'], [], _).

test(sem_prerequisito_em_uma_das_desejadas, [fail]) :-
    grade([], ['FGA0210', 'FGA0244'], [], _).

test(limite_creditos, [fail]) :-
    grade([], ['FGA0158', 'FGA0244'], [], 0, 4, _).

test(disciplina_repetida_conta_uma_vez, [true(Ids == ['B'])]) :-
    findall(Id,
            grade([], ['FGA0124', "FGA0124"], [], 4, 4,
                  [turma('FGA0124', Id, _, _, _)]),
            Ids).

test(tudo_bloqueado, [fail]) :-
    grade([], ['FGA0124'], ['6T1'], _).

:- end_tests(grade).
