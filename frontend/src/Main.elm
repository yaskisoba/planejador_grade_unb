module Main exposing (main)

{-| Tela de entrada e ciclo de vida da aplicação.

As opções de disciplinas refletem a pequena base demonstrativa atual em
`prolog/turmas.pl`. Quando a API fornecer catálogo, esta lista poderá vir dela.
-}

import Browser
import Codec exposing (Grade)
import GradeView
import Html exposing (Html, button, div, h1, h2, h3, input, label, node, p, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (checked, class, disabled, href, rel, type_)
import Html.Events exposing (onCheck, onClick)
import Http
import Types exposing (Request)


type alias Model =
    { requisicao : Request
    , estado : Estado
    , opcaoSelecionada : Int
    }


type Estado
    = Pronto
    | Carregando
    | Falhou String
    | Carregado (List Grade)


type Msg
    = GerarGrades
    | AlternarCursada String
    | AlternarDesejada String
    | AlternarBloqueio String
    | SelecionouOpcao Int
    | RecebeuResposta (Result Http.Error (List Grade))


type alias Disciplina =
    { codigo : String
    , nome : String
    , creditos : Int
    }


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
    ( { requisicao = requisicaoInicial, estado = Pronto, opcaoSelecionada = 0 }
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


disciplinas : List Disciplina
disciplinas =
    [ { codigo = "FGA0158", nome = "Orientação a Objetos", creditos = 4 }
    , { codigo = "FGA0210", nome = "Paradigmas de Programação", creditos = 4 }
    , { codigo = "FGA0244", nome = "Projeto de Algoritmos", creditos = 4 }
    , { codigo = "FGA0124", nome = "Engenharia de Requisitos", creditos = 4 }
    ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GerarGrades ->
            ( { model | estado = Carregando }
            , pedirGrades model.requisicao
            )

        AlternarCursada codigo ->
            alterarSelecao codigo True model

        AlternarDesejada codigo ->
            alterarSelecao codigo False model

        AlternarBloqueio horario ->
            let
                pedido =
                    model.requisicao
            in
            ( { model
                | requisicao =
                    { pedido | bloqueados = alternar horario pedido.bloqueados }
                , estado = Pronto
              }
            , Cmd.none
            )

        RecebeuResposta (Ok grades) ->
            ( { model | estado = Carregado grades, opcaoSelecionada = 0 }, Cmd.none )

        RecebeuResposta (Err erro) ->
            ( { model | estado = Falhou (mensagemErro erro) }, Cmd.none )

        SelecionouOpcao opcao ->
            ( { model | opcaoSelecionada = opcao }, Cmd.none )


alterarSelecao : String -> Bool -> Model -> ( Model, Cmd Msg )
alterarSelecao codigo ehCursada model =
    let
        pedido =
            model.requisicao

        cursadasNovas =
            if ehCursada then
                alternar codigo pedido.cursadas

            else
                List.filter ((/=) codigo) pedido.cursadas

        desejadasNovas =
            if ehCursada then
                List.filter ((/=) codigo) pedido.desejadas

            else
                alternar codigo pedido.desejadas
    in
    ( { model
        | requisicao =
            { pedido | cursadas = cursadasNovas, desejadas = desejadasNovas }
        , estado = Pronto
      }
    , Cmd.none
    )


alternar : a -> List a -> List a
alternar item itens =
    if List.member item itens then
        List.filter ((/=) item) itens

    else
        itens ++ [ item ]


pedirGrades : Request -> Cmd Msg
pedirGrades requisicao =
    Http.post
        { url = "/api/gerar-grades"
        , body = Http.jsonBody (Types.encodeRequest requisicao)
        , expect = Http.expectJson RecebeuResposta Codec.respostaDecoder
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
    let
        ocupado =
            model.estado == Carregando

        pedidoValido =
            not (List.isEmpty model.requisicao.desejadas)
    in
    div [ class "app" ]
        [ node "link" [ rel "stylesheet", href "/grade.css" ] []
        , h1 [] [ text "Planejador de grade da UnB" ]
        , p [] [ text "Escolha as disciplinas e os períodos em que você não pode ter aula. O planejador buscará combinações sem conflitos." ]
        , h2 [] [ text "1. Disciplinas" ]
        , p [] [ text "Marque o que já cursou e o que deseja cursar. Uma disciplina não pode ficar nos dois grupos." ]
        , viewDisciplinas model.requisicao ocupado
        , h2 [] [ text "2. Horários bloqueados" ]
        , p [] [ text "Clique nas células para marcar os períodos em que você não pode estudar. M = manhã, T = tarde, N = noite." ]
        , viewGradeSemanal model.requisicao.bloqueados ocupado
        , p [] [ text (String.fromInt (List.length model.requisicao.bloqueados) ++ " períodos bloqueados") ]
        , button
            [ type_ "button"
            , disabled (ocupado || not pedidoValido)
            , onClick GerarGrades
            ]
            [ text
                (if ocupado then
                    "Buscando grades..."

                 else
                    "Gerar grades"
                )
            ]
        , if not pedidoValido then
            p [] [ text "Selecione ao menos uma disciplina desejada para continuar." ]

          else
            text ""
        , viewEstado model
        ]


viewDisciplinas : Request -> Bool -> Html Msg
viewDisciplinas requisicao ocupado =
    div [ class "disciplinas" ]
        [ div []
            [ h3 [] [ text "Já cursei" ]
            , p [] [ text "Essas matérias contam como pré-requisitos já cumpridos." ]
            , div [] (List.map (viewOpcao AlternarCursada requisicao.cursadas ocupado) disciplinas)
            ]
        , div []
            [ h3 [] [ text "Quero cursar" ]
            , p [] [ text "Essas matérias serão enviadas ao planejador para montar a grade." ]
            , div [] (List.map (viewOpcao AlternarDesejada requisicao.desejadas ocupado) disciplinas)
            ]
        ]


viewOpcao : (String -> Msg) -> List String -> Bool -> Disciplina -> Html Msg
viewOpcao fazerMsg selecionadas ocupado disciplina =
    let
        codigo =
            disciplina.codigo
    in
    label [ class "disciplina" ]
        [ input
            [ type_ "checkbox"
            , checked (List.member codigo selecionadas)
            , disabled ocupado
            , onCheck (\_ -> fazerMsg codigo)
            ]
            []
        , text
            (" "
                ++ disciplina.codigo
                ++ " — "
                ++ disciplina.nome
                ++ " ("
                ++ String.fromInt disciplina.creditos
                ++ " créditos)"
            )
        ]


viewGradeSemanal : List String -> Bool -> Html Msg
viewGradeSemanal bloqueados ocupado =
    let
        dias =
            [ ( 2, "Seg" ), ( 3, "Ter" ), ( 4, "Qua" ), ( 5, "Qui" ), ( 6, "Sex" ), ( 7, "Sáb" ) ]

        turnos =
            [ ( "M", "Manhã", List.range 1 5 )
            , ( "T", "Tarde", List.range 1 6 )
            , ( "N", "Noite", List.range 1 4 )
            ]

        linhas =
            List.concatMap (viewLinhasTurno dias bloqueados ocupado) turnos
    in
    table [ class "grade-semanal" ]
        [ thead []
            [ tr []
                (th [] [ text "Período" ]
                    :: List.map (\( _, nome ) -> th [] [ text nome ]) dias
                )
            ]
        , tbody [] linhas
        ]


viewLinhasTurno : List ( Int, String ) -> List String -> Bool -> ( String, String, List Int ) -> List (Html Msg)
viewLinhasTurno dias bloqueados ocupado ( turno, nomeTurno, indices ) =
    List.map
        (\indice ->
            tr []
                (th [] [ text (nomeTurno ++ " " ++ String.fromInt indice) ]
                    :: List.map (viewCelula turno indice bloqueados ocupado) dias
                )
        )
        indices


viewCelula : String -> Int -> List String -> Bool -> ( Int, String ) -> Html Msg
viewCelula turno indice bloqueados ocupado ( dia, _ ) =
    let
        codigo =
            String.fromInt dia ++ turno ++ String.fromInt indice

        bloqueado =
            List.member codigo bloqueados
    in
    td []
        [ button
            [ type_ "button"
            , class (if bloqueado then "horario bloqueado" else "horario livre")
            , disabled ocupado
            , onClick (AlternarBloqueio codigo)
            ]
            [ text (if bloqueado then "Bloq." else "Livre") ]
        ]


viewEstado : Model -> Html Msg
viewEstado model =
    case model.estado of
        Pronto ->
            p [] [ text "Ajuste os filtros e gere suas grades." ]

        Carregando ->
            p [] [ text "Consultando o planejador..." ]

        Falhou detalhe ->
            div [] [ h2 [] [ text "Não foi possível gerar as grades" ], p [] [ text detalhe ] ]

        Carregado grades ->
            GradeView.view
                { selecionada = model.opcaoSelecionada
                , aoSelecionar = SelecionouOpcao
                }
                grades
