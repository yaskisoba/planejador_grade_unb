:- module(regras, [
    slot/4,
    horario_slots/2,
    horarios_slots/2,
    choque/2,
    apto/2,
    disciplinas_aptas/3,
    total_creditos/2,
    grade/4,
    grade/6
]).

:- use_module(library(clpfd)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(library(ordsets)).
:- use_module(turmas).

limite_creditos(2, 32).

turno('M', 0, 5).
turno('T', 5, 6).
turno('N', 11, 4).

slot(Dia, Turno, Indice, Slot) :-
    turno(Turno, Deslocamento, Maximo),
    Dia in 2..7,
    Indice in 1..Maximo,
    Slot #= Dia * 16 + Deslocamento + Indice.

horario_slots(Horario, Slots) :-
    atom_codes(Horario, Codigos),
    phrase(horario(Dias, Turno, Indices), Codigos),
    maplist(slots_dia(Turno, Indices), Dias, PorDia),
    append(PorDia, Todos),
    sort(Todos, Slots).

slots_dia(Turno, Indices, Dia, Slots) :-
    maplist(slot(Dia, Turno), Indices, Slots).

horario([D|Ds], Turno, [I|Is]) -->
    digito(D), digitos(Ds),
    [C], { char_code(Turno, C), turno(Turno, _, _) },
    digito(I), digitos(Is).

digitos([D|Ds]) --> digito(D), !, digitos(Ds).
digitos([]) --> [].

digito(D) --> [C], { code_type(C, digit(D)) }.

horarios_slots(Horarios, Slots) :-
    maplist(horario_slots, Horarios, PorHorario),
    append(PorHorario, Todos),
    sort(Todos, Slots).

choque(HorariosA, HorariosB) :-
    horarios_slots(HorariosA, SlotsA),
    horarios_slots(HorariosB, SlotsB),
    \+ ord_disjoint(SlotsA, SlotsB).

texto_atomo(Texto, Atomo) :-
    atom_string(Atomo, Texto).

apto(Cursadas, Codigo) :-
    maplist(texto_atomo, Cursadas, Feitas),
    texto_atomo(Codigo, C),
    \+ memberchk(C, Feitas),
    forall(grupo_prerequisitos(C, Alternativas),
           (member(Requisito, Alternativas), memberchk(Requisito, Feitas))).

disciplinas_aptas(Cursadas, Desejadas, Aptas) :-
    maplist(texto_atomo, Desejadas, Codigos),
    include(apto(Cursadas), Codigos, Aptas).

total_creditos(Codigos, Total) :-
    maplist(creditos, Codigos, Creditos),
    sum(Creditos, #=, Total).

creditos(Codigo, Creditos) :-
    texto_atomo(Codigo, C),
    disciplina(C, _, Creditos).

grade(Cursadas, Desejadas, Bloqueados, Grade) :-
    limite_creditos(Minimo, Maximo),
    grade(Cursadas, Desejadas, Bloqueados, Minimo, Maximo, Grade).

grade(Cursadas, Desejadas, Bloqueados, Minimo, Maximo, Grade) :-
    maplist(texto_atomo, Desejadas, Atomos),
    sort(Atomos, Codigos),
    maplist(apto(Cursadas), Codigos),
    total_creditos(Codigos, Total),
    Total #>= Minimo,
    Total #=< Maximo,
    horarios_slots(Bloqueados, SlotsBloqueados),
    maplist(opcoes(SlotsBloqueados), Codigos, Opcoes),
    maplist(escolha, Opcoes, Escolhas),
    sem_choques(Opcoes, Escolhas),
    label(Escolhas),
    maplist(nth1, Escolhas, Opcoes, Pares),
    pairs_keys(Pares, Grade).

opcoes(Bloqueados, Codigo, Opcoes) :-
    findall(Turma-Slots, turma_disponivel(Bloqueados, Codigo, Turma, Slots), Opcoes).

turma_disponivel(Bloqueados, Codigo, turma(Codigo, Id, Professor, Horarios, Vagas), Slots) :-
    turma(Codigo, Id, Professor, Horarios, Vagas),
    Vagas > 0,
    horarios_slots(Horarios, Slots),
    ord_disjoint(Slots, Bloqueados).

escolha(Opcoes, Escolha) :-
    length(Opcoes, Quantidade),
    Quantidade > 0,
    Escolha in 1..Quantidade.

sem_choques([], []).
sem_choques([Opcoes|Resto], [Escolha|Escolhas]) :-
    maplist(compativeis(Opcoes, Escolha), Resto, Escolhas),
    sem_choques(Resto, Escolhas).

compativeis(OpcoesA, EscolhaA, OpcoesB, EscolhaB) :-
    findall([IA, IB],
            ( nth1(IA, OpcoesA, _-SlotsA),
              nth1(IB, OpcoesB, _-SlotsB),
              ord_disjoint(SlotsA, SlotsB) ),
            Permitidos),
    tuples_in([[EscolhaA, EscolhaB]], Permitidos).
