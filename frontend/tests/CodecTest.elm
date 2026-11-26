module CodecTest exposing (suite)

import Codec exposing (Grade)
import Expect
import Horario
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Codec"
        [ describe "requisicaoParaJson"
            [ test "produz exatamente o contrato" <|
                \_ ->
                    Codec.requisicaoParaJson
                        { cursadas = [ "FGA0158" ]
                        , desejadas = [ "FGA0244", "FGA0210" ]
                        , bloqueados = slots [ "2M12", "6T34" ]
                        , pesoJanelas = 5
                        , pesoDias = 0
                        }
                        |> Encode.encode 0
                        |> Expect.equal
                            """{"cursadas":["FGA0158"],"desejadas":["FGA0244","FGA0210"],"bloqueados":["2M1","2M2","6T3","6T4"],"peso_janelas":5,"peso_dias":0}"""
            , test "mantém as listas vazias" <|
                \_ ->
                    Codec.requisicaoParaJson
                        { cursadas = [], desejadas = [], bloqueados = [], pesoJanelas = 7, pesoDias = 1 }
                        |> Encode.encode 0
                        |> Expect.equal
                            """{"cursadas":[],"desejadas":[],"bloqueados":[],"peso_janelas":7,"peso_dias":1}"""
            ]
        , describe "respostaDecoder"
            [ test "lê o exemplo do contrato" <|
                \_ ->
                    decodificar exemploContrato
                        |> Result.map (List.map resumo)
                        |> Expect.equal
                            (Ok
                                [ { numeros = [ 1, 95, 0, 3 ]
                                  , turmas = [ ( "FGA0244", "A", [ "35M34" ] ) ]
                                  }
                                ]
                            )
            , test "aceita turma sem nome e sem professor" <|
                \_ ->
                    extras (turmaCom "")
                        |> Expect.equal (Ok [ ( Nothing, Nothing ) ])
            , test "lê nome e professor quando presentes" <|
                \_ ->
                    extras (turmaCom """, "nome": "Paradigmas", "professor": "Professor 3" """)
                        |> Expect.equal (Ok [ ( Just "Paradigmas", Just "Professor 3" ) ])
            , test "trata null como ausente" <|
                \_ ->
                    extras (turmaCom """, "nome": null, "professor": null""")
                        |> Expect.equal (Ok [ ( Nothing, Nothing ) ])
            , test "rejeita campo opcional de outro tipo" <|
                \_ ->
                    Expect.err (extras (turmaCom """, "nome": 10"""))
            , test "ignora campos desconhecidos" <|
                \_ ->
                    Expect.ok (decodificar (turmaCom """, "vagas": 40"""))
            , test "lista vazia não é erro" <|
                \_ ->
                    Expect.equal (Ok []) (decodificar """{"grades": []}""")
            , test "mantém a ordem recebida" <|
                \_ ->
                    decodificar """{"grades": [
                        {"rank": 2, "score": 9, "janelas": 1, "dias_campus": 2, "turmas": []},
                        {"rank": 1, "score": 4, "janelas": 0, "dias_campus": 4, "turmas": []}
                    ]}"""
                        |> Result.map (List.map .rank)
                        |> Expect.equal (Ok [ 2, 1 ])
            , test "informa qual horário é inválido" <|
                \_ ->
                    case decodificar (String.replace "35M34" "8M12" exemploContrato) of
                        Err mensagem ->
                            Expect.equal True (String.contains "Horário inválido: \"8M12\"" mensagem)

                        Ok _ ->
                            Expect.fail "O horário 8M12 deveria ser rejeitado."
            , describe "exige o campo"
                ([ "grades", "rank", "score", "janelas", "dias_campus", "turmas", "codigo", "turma", "horarios" ]
                    |> List.map
                        (\campo ->
                            test campo <|
                                \_ ->
                                    exemploContrato
                                        |> String.replace ("\"" ++ campo ++ "\":") "\"outro\":"
                                        |> decodificar
                                        |> Expect.err
                        )
                )
            , test "rejeita a resposta de erro da API" <|
                \_ ->
                    Expect.err (decodificar """{"detail": "erro"}""")
            ]
        ]


exemploContrato : String
exemploContrato =
    """{"grades": [{"rank": 1, "score": 95, "janelas": 0, "dias_campus": 3, "turmas": [{"codigo": "FGA0244", "turma": "A", "horarios": ["35M34"]}]}]}"""


turmaCom : String -> String
turmaCom campos =
    String.replace """["35M34"]""" ("""["35M34"]""" ++ campos) exemploContrato


decodificar : String -> Result String (List Grade)
decodificar =
    Decode.decodeString Codec.respostaDecoder >> Result.mapError Decode.errorToString


resumo : Grade -> { numeros : List Int, turmas : List ( String, String, List String ) }
resumo grade =
    { numeros = [ grade.rank, grade.score, grade.janelas, grade.diasCampus ]
    , turmas =
        List.map
            (\turma -> ( turma.codigo, turma.turma, List.map Horario.paraTexto turma.horarios ))
            grade.turmas
    }


extras : String -> Result String (List ( Maybe String, Maybe String ))
extras =
    decodificar
        >> Result.map
            (List.concatMap .turmas >> List.map (\turma -> ( turma.nome, turma.professor )))


slots : List String -> List Horario.Slot
slots =
    List.filterMap Horario.deTexto >> List.concatMap Horario.slots
