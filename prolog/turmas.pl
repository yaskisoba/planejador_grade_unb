:- module(turmas, [disciplina/3, turma/5, prerequisito/2]).

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
