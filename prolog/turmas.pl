:- module(turmas, [disciplina/3, turma/5, prerequisito/2, grupo_prerequisitos/2, carregar_oferta/3]).

:- use_module(library(apply)).
:- dynamic disciplina/3, turma/5, prerequisito/2, requisitos_oferta/2.

disciplina('FGA0158', "Orientação a Objetos", 4).
disciplina('FGA0210', "Paradigmas de Programação", 4).
disciplina('FGA0244', "Projeto de Algoritmos", 4).
disciplina('FGA0124', "Engenharia de Requisitos", 4).

turma('FGA0158', 'A', "Professor 1", ['24M34'], 40).
turma('FGA0158', 'B', "Professor 2", ['35T12'], 40).
turma('FGA0210', 'A', "Professor 3", ['24M34'], 40).
turma('FGA0210', 'B', "Professor 4", ['35M12'], 40).
turma('FGA0244', 'A', "Professor 5", ['35M12'], 40).
turma('FGA0244', 'B', "Professor 6", ['46T34'], 40).
turma('FGA0124', 'A', "Professor 7", ['6M12'], 0).
turma('FGA0124', 'B', "Professor 8", ['6T12'], 30).

prerequisito('FGA0210', 'FGA0158').

grupo_prerequisitos(Codigo, [Requisito]) :-
    prerequisito(Codigo, Requisito).
grupo_prerequisitos(Codigo, Alternativas) :-
    requisitos_oferta(Codigo, Alternativas).

carregar_oferta(Disciplinas, Turmas, Requisitos) :-
    transaction((
        retractall(disciplina(_, _, _)),
        retractall(turma(_, _, _, _, _)),
        retractall(prerequisito(_, _)),
        retractall(requisitos_oferta(_, _)),
        maplist(adicionar_disciplina, Disciplinas),
        maplist(adicionar_turma, Turmas),
        maplist(adicionar_requisitos, Requisitos)
    )).

adicionar_disciplina([Codigo, Nome, Creditos]) :-
    atom_string(Disciplina, Codigo),
    assertz(disciplina(Disciplina, Nome, Creditos)).

adicionar_turma([Codigo, Identificador, Horarios, Vagas]) :-
    atom_string(Disciplina, Codigo),
    atom_string(Id, Identificador),
    maplist(atom_string, HorariosAtomos, Horarios),
    assertz(turma(Disciplina, Id, "", HorariosAtomos, Vagas)).

adicionar_requisitos([Codigo, Requisitos]) :-
    atom_string(Disciplina, Codigo),
    maplist(atom_string, Alternativas, Requisitos),
    assertz(requisitos_oferta(Disciplina, Alternativas)).
