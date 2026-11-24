module HorarioTest exposing (suite)

import Expect
import Horario exposing (Dia(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Horario"
        [ describe "deTexto"
            [ test "combina dias e períodos" <|
                \_ ->
                    Expect.equal (Just [ "2M3", "2M4", "4M3", "4M4" ]) (codigos "24M34")
            , test "remove repetições e ordena, como o motor Prolog" <|
                \_ ->
                    Expect.equal (codigos "24M34") (codigos "442M433")
            , test "lê o primeiro e o último período de cada turno" <|
                \_ ->
                    [ "2M1", "2M5", "2T1", "2T6", "7N1", "7N4" ]
                        |> List.map codigos
                        |> Expect.equal
                            [ Just [ "2M1" ]
                            , Just [ "2M5" ]
                            , Just [ "2T1" ]
                            , Just [ "2T6" ]
                            , Just [ "7N1" ]
                            , Just [ "7N4" ]
                            ]
            , describe "rejeita"
                ([ "", "M12", "24", "24M", "1M1", "8M12", "2M0", "2M6", "2T7", "2N5", "2X1", "2m1", "24M34 ", " 24M34", "2M3T4" ]
                    |> List.map
                        (\texto ->
                            test ("\"" ++ texto ++ "\"") <|
                                \_ -> Expect.equal Nothing (codigos texto)
                        )
                )
            , test "preserva o texto original" <|
                \_ ->
                    Horario.deTexto "442M433"
                        |> Maybe.map Horario.paraTexto
                        |> Expect.equal (Just "442M433")
            ]
        , describe "períodos"
            [ test "são quinze, numerados em sequência" <|
                \_ ->
                    List.map Horario.ordem Horario.periodos
                        |> Expect.equal (List.range 1 15)
            , test "começam e terminam em ordem cronológica" <|
                \_ ->
                    Horario.periodos
                        |> List.concatMap (\periodo -> [ Horario.inicio periodo, Horario.fim periodo ])
                        |> (\horas -> Expect.equal (List.sort horas) horas)
            , test "todo código de slot é lido de volta como o mesmo slot" <|
                \_ ->
                    let
                        todos =
                            Horario.dias
                                |> List.concatMap
                                    (\dia -> List.map (Horario.Slot dia) Horario.periodos)
                    in
                    todos
                        |> List.map
                            (Horario.codigoSlot
                                >> Horario.deTexto
                                >> Maybe.map Horario.slots
                            )
                        |> Expect.equal (List.map (\slot -> Just [ slot ]) todos)
            ]
        , describe "descricao"
            [ test "junta períodos consecutivos" <|
                \_ -> Expect.equal (Just "Seg e Qua, 10:00–11:50") (descricao "24M34")
            , test "separa períodos não consecutivos" <|
                \_ -> Expect.equal (Just "Ter, 08:00–08:55 e 10:00–10:55") (descricao "3M13")
            , test "enumera três dias" <|
                \_ -> Expect.equal (Just "Seg, Qua e Sex, 14:00–15:50") (descricao "246T23")
            , test "abrevia os dias com acento" <|
                \_ -> Expect.equal "Sáb" (Horario.abreviacaoDia Sabado)
            ]
        ]


codigos : String -> Maybe (List String)
codigos texto =
    Horario.deTexto texto
        |> Maybe.map (Horario.slots >> List.map Horario.codigoSlot)


descricao : String -> Maybe String
descricao texto =
    Maybe.map Horario.descricao (Horario.deTexto texto)
