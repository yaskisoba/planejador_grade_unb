module Main exposing (main)

{-| Tela de entrada e ciclo de vida da aplicação.

A interface carrega o catálogo curricular pela API.
-}

import Browser
import Codec exposing (Grade)
import GradeView
import Html exposing (Html, button, div, h1, h2, h3, input, label, node, p, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (attribute, checked, class, disabled, href, rel, style, type_, value)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import Types exposing (Catalogo, Disciplina, Request)


type alias Model =
    { requisicao : Request
    , estado : Estado
    , opcaoSelecionada : Int
    , catalogo : EstadoCatalogo
    , buscaCursadas : String
    , buscaDesejadas : String
    }


type Estado
    = Pronto
    | Carregando
    | Falhou String
    | Carregado (List Grade)


type EstadoCatalogo
    = CarregandoCatalogo
    | FalhouCatalogo String
    | CatalogoCarregado Catalogo


type Msg
    = GerarGrades
    | AlternarCursada String
    | AlternarDesejada String
    | AlternarBloqueio String
    | SelecionouOpcao Int
    | BuscouCursadas String
    | BuscouDesejadas String
    | CarregarCatalogo
    | RecebeuCatalogo (Result Http.Error Catalogo)
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
    ( { requisicao = requisicaoInicial
      , estado = Pronto
      , opcaoSelecionada = 0
      , catalogo = CarregandoCatalogo
      , buscaCursadas = ""
      , buscaDesejadas = ""
      }
    , pedirCatalogo
    )


requisicaoInicial : Request
requisicaoInicial =
    { cursadas = []
    , desejadas = []
    , bloqueados = []
    , pesoJanelas = 3
    , pesoDias = 2
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GerarGrades ->
            if podeGerarGrades model then
                ( { model | estado = Carregando }
                , pedirGrades model.requisicao
                )

            else
                ( model, Cmd.none )

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

        BuscouCursadas busca ->
            ( { model | buscaCursadas = busca }, Cmd.none )

        BuscouDesejadas busca ->
            ( { model | buscaDesejadas = busca }, Cmd.none )

        CarregarCatalogo ->
            ( { model | catalogo = CarregandoCatalogo }, pedirCatalogo )

        RecebeuCatalogo (Ok catalogo) ->
            ( { model | catalogo = CatalogoCarregado catalogo }, Cmd.none )

        RecebeuCatalogo (Err erro) ->
            ( { model | catalogo = FalhouCatalogo (mensagemErro erro) }, Cmd.none )


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


pedirCatalogo : Cmd Msg
pedirCatalogo =
    Http.get
        { url = "/api/disciplinas"
        , expect = Http.expectJson RecebeuCatalogo Types.decodeCatalogo
        }


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


desejadasSemTurma : Model -> List Disciplina
desejadasSemTurma model =
    case model.catalogo of
        CatalogoCarregado catalogo ->
            List.filter
                (\disciplina -> not disciplina.temTurmas && List.member disciplina.codigo model.requisicao.desejadas)
                catalogo.disciplinas

        _ ->
            []


podeGerarGrades : Model -> Bool
podeGerarGrades model =
    case model.catalogo of
        CatalogoCarregado _ ->
            model.estado /= Carregando
                && not (List.isEmpty model.requisicao.desejadas)
                && List.isEmpty (desejadasSemTurma model)

        _ ->
            False


view : Model -> Html Msg
view model =
    let
        ocupado =
            model.estado == Carregando

        semTurma =
            desejadasSemTurma model
    in
    div [ class "app" ]
        [ node "link" [ rel "stylesheet", href "/grade.css" ] []
        , h1 [] [ text "Planejador de grade da UnB" ]
        , p [] [ text "Escolha as disciplinas e os períodos em que você não pode ter aula. O planejador buscará combinações sem conflitos." ]
        , h2 [] [ text "1. Disciplinas" ]
        , p [] [ text "Marque o que já cursou e o que deseja cursar. Uma disciplina não pode ficar nos dois grupos." ]
        , viewCatalogo model ocupado
        , h2 [] [ text "2. Horários bloqueados" ]
        , p [] [ text "Clique nas células para marcar os períodos em que você não pode estudar. M = manhã, T = tarde, N = noite." ]
        , viewGradeSemanal model.requisicao.bloqueados ocupado
        , p [] [ text (String.fromInt (List.length model.requisicao.bloqueados) ++ " períodos bloqueados") ]
        , button
            [ type_ "button"
            , disabled (not (podeGerarGrades model))
            , onClick GerarGrades
            ]
            [ text
                (if ocupado then
                    "Buscando grades..."

                 else
                    "Gerar grades"
                )
            ]
        , if List.isEmpty model.requisicao.desejadas then
            p [] [ text "Selecione ao menos uma disciplina desejada para continuar." ]

          else if not (List.isEmpty semTurma) then
            p [ attribute "role" "status" ]
                [ text
                    ("Sem turma cadastrada: "
                        ++ String.join ", " (List.map .codigo semTurma)
                        ++ ". Desmarque essas disciplinas para gerar a grade."
                    )
                ]

          else
            text ""
        , viewEstado model
        ]


viewCatalogo : Model -> Bool -> Html Msg
viewCatalogo model ocupado =
    case model.catalogo of
        CarregandoCatalogo ->
            p [] [ text "Carregando disciplinas..." ]

        FalhouCatalogo detalhe ->
            div []
                [ p [] [ text ("Não foi possível carregar as disciplinas. " ++ detalhe) ]
                , button [ type_ "button", onClick CarregarCatalogo ] [ text "Tentar novamente" ]
                ]

        CatalogoCarregado catalogo ->
            viewDisciplinas model ocupado catalogo


viewDisciplinas : Model -> Bool -> Catalogo -> Html Msg
viewDisciplinas model ocupado catalogo =
    div [ class "disciplinas" ]
        [ p [] [ text ("Engenharia de Software · matriz " ++ catalogo.matriz) ]
        , div []
            [ h3 [] [ text "Já cursei" ]
            , p [] [ text "Essas matérias contam como pré-requisitos já cumpridos." ]
            , viewListaDisciplinas "Buscar cursadas por código ou nome"
                model.buscaCursadas
                BuscouCursadas
                (viewOpcao AlternarCursada model.requisicao.cursadas ocupado)
                catalogo.disciplinas
            ]
        , div []
            [ h3 [] [ text "Quero cursar" ]
            , p [] [ text ("Turmas do Campus Gama · SIGAA " ++ catalogo.periodoTurmas) ]
            , viewListaDisciplinas "Buscar desejadas por código ou nome"
                model.buscaDesejadas
                BuscouDesejadas
                (viewOpcao AlternarDesejada model.requisicao.desejadas ocupado)
                (List.filter .temTurmas catalogo.disciplinas)
            ]
        ]


viewListaDisciplinas : String -> String -> (String -> Msg) -> (Disciplina -> Html Msg) -> List Disciplina -> Html Msg
viewListaDisciplinas rotulo busca aoBuscar exibirOpcao disciplinas =
    let
        consulta =
            busca |> String.trim |> String.toLower

        corresponde disciplina =
            String.contains consulta (String.toLower (disciplina.codigo ++ " " ++ disciplina.nome))

        encontradas =
            List.filter corresponde disciplinas
    in
    div []
        [ label []
            [ text (rotulo ++ " ")
            , input [ type_ "search", value busca, onInput aoBuscar ] []
            ]
        , if List.isEmpty encontradas then
            p [] [ text "Nenhuma disciplina encontrada." ]

          else
            div
                [ style "width" "fit-content"
                , style "max-width" "100%"
                , style "box-sizing" "border-box"
                , style "padding-inline-end" "0.5rem"
                , style "max-height" "18rem"
                , style "overflow-y" "auto"
                ]
                (List.map exibirOpcao encontradas)
        ]


viewOpcao : (String -> Msg) -> List String -> Bool -> Disciplina -> Html Msg
viewOpcao fazerMsg selecionadas ocupado disciplina =
    let
        codigo =
            disciplina.codigo
    in
    label [ class "disciplina", style "display" "block" ]
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
