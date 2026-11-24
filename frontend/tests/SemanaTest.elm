module SemanaTest exposing (suite)

import Codec exposing (Turma)
import Expect
import Horario exposing (Dia(..), Turno(..))
import Semana exposing (Conteudo(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Semana"
        [ describe "celulas"
            [ test "une períodos seguidos da mesma turma" <|
                \_ ->
                    resumo [ turma "A" [ "2M34" ] ] Segunda Manha
                        |> Expect.equal [ "M1 livre", "M2 livre", "M3-M4 A", "M5 livre" ]
            , test "não une turmas diferentes" <|
                \_ ->
                    resumo [ turma "A" [ "2M12" ], turma "B" [ "2M34" ] ] Segunda Manha
                        |> Expect.equal [ "M1-M2 A", "M3-M4 B", "M5 livre" ]
            , test "marca como janela o período livre entre aulas" <|
                \_ ->
                    resumo [ turma "A" [ "2M14" ] ] Segunda Manha
                        |> Expect.equal [ "M1 A", "M2 janela", "M3 janela", "M4 A", "M5 livre" ]
            , test "conta janelas entre turnos" <|
                \_ ->
                    let
                        turmas =
                            [ turma "A" [ "2M5" ], turma "B" [ "2N1" ] ]
                    in
                    Horario.turnos
                        |> List.concatMap (Semana.celulas turmas Segunda)
                        |> List.filter (\celula -> celula.conteudo == Janela)
                        |> List.length
                        |> Expect.equal 6
            , test "não há janela entre M5 e T1" <|
                \_ ->
                    resumo [ turma "A" [ "2M5", "2T1" ] ] Segunda Manha
                        |> Expect.equal [ "M1 livre", "M2 livre", "M3 livre", "M4 livre", "M5 A" ]
            , test "aulas de outro dia não criam janelas" <|
                \_ ->
                    resumo [ turma "A" [ "2M1" ], turma "B" [ "3M5" ] ] Segunda Manha
                        |> Expect.equal [ "M1 A", "M2 livre", "M3 livre", "M4 livre", "M5 livre" ]
            , test "mostra todas as turmas em choque" <|
                \_ ->
                    resumo [ turma "A" [ "2M12" ], turma "B" [ "2M23" ] ] Segunda Manha
                        |> Expect.equal [ "M1 A", "M2 A+B", "M3 B", "M4 livre", "M5 livre" ]
            , test "as durações sempre cobrem o turno inteiro" <|
                \_ ->
                    let
                        turmas =
                            [ turma "A" [ "24M34", "6N12" ], turma "B" [ "2M45", "357T135" ] ]
                    in
                    Horario.dias
                        |> List.concatMap (\dia -> List.map (duracaoTotal turmas dia) Horario.turnos)
                        |> Expect.equal (List.concatMap (\_ -> [ 5, 6, 4 ]) Horario.dias)
            ]
        , describe "choques"
            [ test "lista os slots sobrepostos" <|
                \_ ->
                    Semana.choques [ turma "A" [ "24M34" ], turma "B" [ "4M45" ] ]
                        |> Expect.equal [ "4M4" ]
            , test "horário repetido na mesma turma não é choque" <|
                \_ ->
                    Expect.equal [] (Semana.choques [ turma "A" [ "2M12", "2M1" ] ])
            ]
        , describe "dias e turnos visíveis"
            [ test "sem turmas, mostra a semana útil de dia" <|
                \_ ->
                    ( Semana.diasVisiveis [], Semana.turnosVisiveis [] )
                        |> Expect.equal
                            ( [ Segunda, Terca, Quarta, Quinta, Sexta ], [ Manha, Tarde ] )
            , test "inclui sábado e noite quando há aula" <|
                \_ ->
                    let
                        turmas =
                            [ turma "A" [ "7M1", "2N1" ] ]
                    in
                    ( Semana.diasVisiveis turmas, Semana.turnosVisiveis turmas )
                        |> Expect.equal ( Horario.dias, Horario.turnos )
            ]
        ]


turma : String -> List String -> Turma
turma codigo horarios =
    { codigo = codigo
    , turma = "A"
    , horarios = List.filterMap Horario.deTexto horarios
    , nome = Nothing
    , professor = Nothing
    }


resumo : List Turma -> Dia -> Turno -> List String
resumo turmas dia turno =
    Semana.celulas turmas dia turno
        |> List.map
            (\celula ->
                (if celula.duracao == 1 then
                    Horario.codigoPeriodo celula.inicio

                 else
                    Horario.codigoPeriodo celula.inicio ++ "-" ++ Horario.codigoPeriodo celula.fim
                )
                    ++ " "
                    ++ nomeConteudo celula.conteudo
            )


nomeConteudo : Conteudo -> String
nomeConteudo conteudo =
    case conteudo of
        Livre ->
            "livre"

        Janela ->
            "janela"

        Aula aula ->
            aula.codigo

        Choque turmas ->
            String.join "+" (List.map .codigo turmas)


duracaoTotal : List Turma -> Dia -> Turno -> Int
duracaoTotal turmas dia turno =
    Semana.celulas turmas dia turno
        |> List.map .duracao
        |> List.sum
