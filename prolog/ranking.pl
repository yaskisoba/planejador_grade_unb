:- module(ranking, [
    metricas_grade/3,
    pontuacao_grade/2,
    top_5_grades/4,
    top_5_grades/6,
    top_5_grades_pesos/6
]).

:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(regras, [horarios_slots/2, grade/4, grade/6]).

:- meta_predicate melhores_cinco(1, -).

%! metricas_grade(+Grade, -Janelas, -DiasCampus) is det.
%
%  Grade deve estar instanciada, no formato produzido por regras:grade/4.
%  Janelas conta slots livres entre a primeira e a ultima aula de cada dia,
%  inclusive entre turnos. Nao conta intervalos entre dias nem tempo fora
%  desse intervalo diario. Usa a mesma escala de slots das restricoes.
metricas_grade(Grade, Janelas, DiasCampus) :-
    maplist(horarios_turma, Grade, PorTurma),
    append(PorTurma, Horarios),
    horarios_slots(Horarios, Slots),
    maplist(slot_dia, Slots, Pares),
    group_pairs_by_key(Pares, PorDia),
    pairs_values(PorDia, SlotsPorDia),
    length(SlotsPorDia, DiasCampus),
    maplist(janelas_dia, SlotsPorDia, JanelasPorDia),
    sum_list(JanelasPorDia, Janelas).

horarios_turma(turma(_, _, _, Horarios, _), Horarios).

slot_dia(Slot, Dia-Slot) :-
    Dia is Slot // 16.

janelas_dia([Primeiro|Restantes], Janelas) :-
    last([Primeiro|Restantes], Ultimo),
    length([Primeiro|Restantes], Ocupados),
    Janelas is Ultimo - Primeiro + 1 - Ocupados.

%! pontuacao_grade(+Grade, -Pontuacao) is det.
%
%  Menor e melhor. Como ha no maximo seis dias (2..7), peso 7 prioriza
%  menos janelas; em igualdade de janelas, prefere menos dias no campus.
pontuacao_grade(Grade, Pontuacao) :-
    metricas_grade(Grade, Janelas, DiasCampus),
    pontuacao(Janelas, DiasCampus, Pontuacao).

pontuacao(Janelas, DiasCampus, Pontuacao) :-
    pontuacao(Janelas, DiasCampus, 7, 1, Pontuacao).

pontuacao(Janelas, DiasCampus, PesoJanelas, PesoDias, Pontuacao) :-
    Pontuacao is PesoJanelas * Janelas + PesoDias * DiasCampus.

%! top_5_grades(+Cursadas, +Desejadas, +Bloqueados, -Top5) is det.
%
%  Retorna ate cinco termos resultado(Pontuacao, Janelas, DiasCampus, Grade).
%  Mantem os limites padrao de regras:grade/4. Sem solucao, retorna [].
top_5_grades(Cursadas, Desejadas, Bloqueados, Top5) :-
    melhores_cinco(grade(Cursadas, Desejadas, Bloqueados), Top5).

%! top_5_grades(+Cursadas, +Desejadas, +Bloqueados, +Min, +Max, -Top5) is det.
%
%  Mesma classificacao, com limites de creditos explicitos.
top_5_grades(Cursadas, Desejadas, Bloqueados, Min, Max, Top5) :-
    melhores_cinco(grade(Cursadas, Desejadas, Bloqueados, Min, Max), Top5).

%! top_5_grades_pesos(+Cursadas, +Desejadas, +Bloqueados, +PesoJanelas, +PesoDias, -Top5) is det.
%
%  Igual a top_5_grades/4, mas usa os pesos informados para ordenar e pontuar.
top_5_grades_pesos(Cursadas, Desejadas, Bloqueados, PesoJanelas, PesoDias, Top5) :-
    melhores_cinco(grade(Cursadas, Desejadas, Bloqueados), PesoJanelas, PesoDias, Top5).

melhores_cinco(GerarGrade, Top5) :-
    melhores_cinco(GerarGrade, 7, 1, Top5).

melhores_cinco(GerarGrade, PesoJanelas, PesoDias, Top5) :-
    findall(resultado(Pontuacao, Janelas, DiasCampus, Grade),
            ( call(GerarGrade, Grade),
              metricas_grade(Grade, Janelas, DiasCampus),
              pontuacao(Janelas, DiasCampus, PesoJanelas, PesoDias, Pontuacao) ),
            Resultados),
    % Ordenar antes de limitar garante o Top 5 global. sort/2 remove apenas
    % resultados identicos; grades distintas empatadas continuam na lista.
    % O proprio termo Grade desempata de forma deterministica.
    sort(Resultados, Ordenados),
    primeiros_cinco(Ordenados, Top5).

primeiros_cinco(Ordenados, Top5) :-
    length(Ordenados, Quantidade),
    Limite is min(5, Quantidade),
    length(Top5, Limite),
    append(Top5, _, Ordenados).
