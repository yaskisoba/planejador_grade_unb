module Semana exposing
    ( Celula, Conteudo(..)
    , celulas, choques, diasVisiveis, turnosVisiveis
    )

{-| Distribui as turmas de uma grade pelos dias e períodos da semana.

@docs Celula, Conteudo
@docs celulas, choques, diasVisiveis, turnosVisiveis

-}

import Codec exposing (Turma)
import Horario exposing (Dia(..), Periodo, Slot, Turno(..))


{-| Trecho de um dia que começa em `inicio` e ocupa `duracao` períodos seguidos
do mesmo turno.
-}
type alias Celula =
    { inicio : Periodo
    , fim : Periodo
    , duracao : Int
    , conteudo : Conteudo
    }


{-| `Janela` é um período livre entre a primeira e a última aula do dia, a mesma
definição usada por `prolog/ranking.pl`. O motor nunca gera `Choque`, mas a
tela o mostra em vez de esconder uma das turmas.
-}
type Conteudo
    = Livre
    | Janela
    | Aula Turma
    | Choque (List Turma)


{-| Células de um dia dentro de um turno, em ordem. Períodos seguidos da mesma
aula formam uma única célula. Períodos livres e janelas ficam separados, para
que cada janela contada apareça na tela.
-}
celulas : List Turma -> Dia -> Turno -> List Celula
celulas turmas dia turno =
    let
        limites =
            extremos (List.filter (\slot -> slot.dia == dia) (todosSlots turmas))
    in
    Horario.periodosDoTurno turno
        |> List.map
            (\periodo ->
                { inicio = periodo
                , fim = periodo
                , duracao = 1
                , conteudo = conteudoDe limites turmas (Slot dia periodo)
                }
            )
        |> List.foldr unir []


{-| Códigos dos slots em que duas ou mais turmas se sobrepõem.
-}
choques : List Turma -> List String
choques turmas =
    Horario.dias
        |> List.concatMap (\dia -> List.map (Slot dia) Horario.periodos)
        |> List.filter (\slot -> List.length (ocupantes turmas slot) > 1)
        |> List.map Horario.codigoSlot


{-| Segunda a sexta sempre aparecem. Sábado, só se houver aula.
-}
diasVisiveis : List Turma -> List Dia
diasVisiveis turmas =
    List.filter
        (\dia -> dia /= Sabado || List.any (\slot -> slot.dia == dia) (todosSlots turmas))
        Horario.dias


{-| Manhã e tarde sempre aparecem. Noite, só se houver aula.
-}
turnosVisiveis : List Turma -> List Turno
turnosVisiveis turmas =
    List.filter
        (\turno ->
            (turno /= Noite)
                || List.any (\slot -> Horario.turno slot.periodo == turno) (todosSlots turmas)
        )
        Horario.turnos



-- AUXILIARES


todosSlots : List Turma -> List Slot
todosSlots turmas =
    List.concatMap slotsDaTurma turmas


slotsDaTurma : Turma -> List Slot
slotsDaTurma turma =
    List.concatMap Horario.slots turma.horarios


ocupantes : List Turma -> Slot -> List Turma
ocupantes turmas slot =
    List.filter (\turma -> List.member slot (slotsDaTurma turma)) turmas


extremos : List Slot -> Maybe ( Int, Int )
extremos slots =
    let
        ordens =
            List.map (\slot -> Horario.ordem slot.periodo) slots
    in
    Maybe.map2 Tuple.pair (List.minimum ordens) (List.maximum ordens)


conteudoDe : Maybe ( Int, Int ) -> List Turma -> Slot -> Conteudo
conteudoDe limites turmas slot =
    case ocupantes turmas slot of
        [] ->
            if entre limites (Horario.ordem slot.periodo) then
                Janela

            else
                Livre

        [ turma ] ->
            Aula turma

        varias ->
            Choque varias


entre : Maybe ( Int, Int ) -> Int -> Bool
entre limites ordem =
    case limites of
        Just ( primeiro, ultimo ) ->
            primeiro < ordem && ordem < ultimo

        Nothing ->
            False


unir : Celula -> List Celula -> List Celula
unir celula seguintes =
    case seguintes of
        proxima :: resto ->
            if continua celula.conteudo proxima.conteudo then
                { celula | fim = proxima.fim, duracao = celula.duracao + proxima.duracao } :: resto

            else
                celula :: seguintes

        [] ->
            [ celula ]


continua : Conteudo -> Conteudo -> Bool
continua atual proximo =
    case ( atual, proximo ) of
        ( Aula _, Aula _ ) ->
            atual == proximo

        ( Choque _, Choque _ ) ->
            atual == proximo

        _ ->
            False
