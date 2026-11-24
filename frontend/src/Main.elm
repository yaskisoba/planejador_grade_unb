module Main exposing (main)

{-| Shell da aplicação: modelo, mensagens, atualizações e integração HTTP.

As telas de entrada e de visualização podem evoluir separadamente usando os
tipos compartilhados de `Types`.
-}

import Browser
import Html exposing (Html, button, div, h1, h2, p, text)
import Html.Attributes exposing (disabled, type_)
import Html.Events exposing (onClick)
import Http
import Types exposing (Grade, Request)


type alias Model =
    { requisicao : Request
    , estado : Estado
    }


type Estado
    = Pronto
    | Carregando
    | Falhou String
    | Carregado (List Grade)


type Msg
    = GerarGrades
    | RecebeuResposta (Result Http.Error (List Grade))


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { requisicao = requisicaoInicial, estado = Pronto }
    , Cmd.none
    )


requisicaoInicial : Request
requisicaoInicial =
    { cursadas = [ "FGA0158" ]
    , desejadas = [ "FGA0244", "FGA0210" ]
    , bloqueados = []
    , pesoJanelas = 3
    , pesoDias = 2
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GerarGrades ->
            ( { model | estado = Carregando }
            , pedirGrades model.requisicao
            )

        RecebeuResposta (Ok grades) ->
            ( { model | estado = Carregado grades }, Cmd.none )

        RecebeuResposta (Err erro) ->
            ( { model | estado = Falhou (mensagemErro erro) }, Cmd.none )


pedirGrades : Request -> Cmd Msg
pedirGrades requisicao =
    Http.post
        { url = "/api/gerar-grades"
        , body = Http.jsonBody (Types.encodeRequest requisicao)
        , expect = Http.expectJson RecebeuResposta Types.decodeGrades
        }


mensagemErro : Http.Error -> String
mensagemErro erro =
    case erro of
        Http.BadUrl _ ->
            "O endereço da API está inválido."

        Http.Timeout ->
            "A API demorou demais para responder."

        Http.NetworkError ->
            "Não foi possível conectar à API. Confira se o backend está rodando."

        Http.BadStatus status ->
            "A API respondeu com erro HTTP " ++ String.fromInt status ++ "."

        Http.BadBody detalhe ->
            "A resposta da API não segue o contrato JSON esperado: " ++ detalhe


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Planejador de grade da UnB" ]
        , p [] [ text "A interface Elm envia uma requisição ao backend Python, que consulta o planejador em Prolog." ]
        , button
            [ type_ "button"
            , disabled (model.estado == Carregando)
            , onClick GerarGrades
            ]
            [ text
                (if model.estado == Carregando then
                    "Buscando grades..."

                 else
                    "Gerar grades"
                )
            ]
        , viewEstado model.estado
        ]


viewEstado : Estado -> Html Msg
viewEstado estado =
    case estado of
        Pronto ->
            p [] [ text "Pronto para solicitar sugestões." ]

        Carregando ->
            p [] [ text "Consultando o planejador..." ]

        Falhou detalhe ->
            div [] [ h2 [] [ text "Não foi possível gerar as grades" ], p [] [ text detalhe ] ]

        Carregado grades ->
            div []
                [ h2 [] [ text (String.fromInt (List.length grades) ++ " grades recebidas") ]
                , if List.isEmpty grades then
                    p [] [ text "Nenhuma grade atende a esses critérios." ]

                  else
                    div [] (List.map viewResumoGrade grades)
                ]


viewResumoGrade : Grade -> Html Msg
viewResumoGrade grade =
    p []
        [ text
            ("Opção "
                ++ String.fromInt grade.rank
                ++ " — pontuação "
                ++ String.fromInt grade.score
                ++ ", "
                ++ String.fromInt grade.janelas
                ++ " janelas, "
                ++ String.fromInt grade.diasCampus
                ++ " dias no campus"
            )
        ]
