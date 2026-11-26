module Main exposing (main)

{-| Tela de entrada e ciclo de vida da aplicação.

A interface carrega o catálogo curricular pela API.

-}

import Browser
import Codec exposing (Grade)
import GradeView
import Horario
import Html exposing (Html, button, caption, div, h1, h2, h3, input, label, node, p, span, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (attribute, checked, class, colspan, disabled, href, placeholder, rel, scope, tabindex, type_, value)
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
    , pesoJanelasTexto : String
    , pesoDiasTexto : String
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
    | AlterouPesoJanelas String
    | AlterouPesoDias String
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
      , pesoJanelasTexto = "3"
      , pesoDiasTexto = "2"
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

        AlterouPesoJanelas valor ->
            let
                atualizado =
                    aplicarPeso (\requisicao peso -> { requisicao | pesoJanelas = peso }) valor model
            in
            ( { atualizado | pesoJanelasTexto = valor }, Cmd.none )

        AlterouPesoDias valor ->
            let
                atualizado =
                    aplicarPeso (\requisicao peso -> { requisicao | pesoDias = peso }) valor model
            in
            ( { atualizado | pesoDiasTexto = valor }, Cmd.none )

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


aplicarPeso : (Request -> Int -> Request) -> String -> Model -> Model
aplicarPeso atualizar valor model =
    let
        requisicao =
            case String.toInt valor of
                Just peso ->
                    if peso >= 0 then
                        atualizar model.requisicao peso

                    else
                        model.requisicao

                Nothing ->
                    model.requisicao
    in
    { model | requisicao = requisicao, estado = Pronto }


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
            model.estado
                /= Carregando
                && not (List.isEmpty model.requisicao.desejadas)
                && List.isEmpty (desejadasSemTurma model)
                && pesosValidos model

        _ ->
            False


pesosValidos : Model -> Bool
pesosValidos model =
    pesoValido model.pesoJanelasTexto && pesoValido model.pesoDiasTexto


pesoValido : String -> Bool
pesoValido texto =
    case String.toInt texto of
        Just peso ->
            peso >= 0

        Nothing ->
            False


view : Model -> Html Msg
view model =
    let
        ocupado =
            model.estado == Carregando

        semTurma =
            desejadasSemTurma model
    in
    node "main"
        [ class "app", attribute "lang" "pt-BR" ]
        [ node "link" [ rel "stylesheet", href "/grade.css" ] []
        , node "header"
            [ class "app-cabecalho" ]
            [ div [ class "app-marca" ]
                [ span [ class "app-simbolo", attribute "aria-hidden" "true" ] [ text "▦" ]
                , text "UnB / Planejamento acadêmico"
                ]
            
            , p [ class "app-introducao" ] [ text "Escolha suas disciplinas, reserve seus horários e encontre uma grade que combine com a sua rotina." ]
            ]
        , node "section"
            [ class "app-painel", attribute "aria-labelledby" "titulo-disciplinas" ]
            [ viewTitulo "01" "titulo-disciplinas" "Disciplinas" "Marque o que já cursou e o que deseja cursar no próximo semestre."
            , viewCatalogo model ocupado
            ]
        , node "section"
            [ class "app-painel", attribute "aria-labelledby" "titulo-horarios" ]
            [ viewTitulo "02" "titulo-horarios" "Sua disponibilidade" "Marque os períodos em que você não pode ter aula. Clique novamente para liberar."
            , div [ class "app-linha-apoio" ]
                [ div [ class "horarios-legenda" ]
                    [ span [ class "legenda-livre" ] [ text "Disponível" ]
                    , span [ class "legenda-bloqueado" ] [ text "Bloqueado" ]
                    ]
                , span [ class "app-contador", attribute "role" "status" ]
                    [ text (String.fromInt (List.length model.requisicao.bloqueados) ++ " períodos bloqueados") ]
                ]
            , viewGradeSemanal model.requisicao.bloqueados ocupado
            , viewPesos model ocupado
            , div [ class "app-acao" ]
                [ div []
                    [ p [ class "app-acao-titulo" ] [ text "Tudo pronto para montar sua grade?" ]
                    , p [ class "app-ajuda", attribute "role" "status" ]
                        [ text
                            (if List.isEmpty model.requisicao.desejadas then
                                "Selecione ao menos uma disciplina em “Quero cursar”."

                             else if not (List.isEmpty semTurma) then
                                "Sem turma cadastrada: " ++ String.join ", " (List.map .codigo semTurma) ++ ". Desmarque essas disciplinas para continuar."

                             else if not (pesosValidos model) then
                                 "Informe pesos inteiros maiores ou iguais a zero."

                             else
                                String.fromInt (List.length model.requisicao.desejadas) ++ " disciplina(s) desejada(s). Vamos buscar combinações sem conflitos."
                            )
                        ]
                    ]
                , button
                    [ type_ "button"
                    , class "app-botao app-botao-principal"
                    , disabled (not (podeGerarGrades model))
                    , onClick GerarGrades
                    ]
                    [ text
                        (if ocupado then
                            "Buscando grades…"

                         else
                            "Gerar grades"
                        )
                    , span [ attribute "aria-hidden" "true" ] [ text "→" ]
                    ]
                ]
            ]
        , node "section"
            [ class "app-painel app-resultados"
            , attribute "aria-label" "Grades sugeridas"
            , attribute "aria-busy"
                (if ocupado then
                    "true"

                 else
                    "false"
                )
            ]
            [ viewEstado model ]
        ]


viewPesos : Model -> Bool -> Html Msg
viewPesos model ocupado =
    div [ class "pesos", attribute "aria-labelledby" "pesos-titulo" ]
        [ h3 [ attribute "id" "pesos-titulo" ] [ text "Preferências de ranking" ]
        , p [ class "app-ajuda" ]
            [ text "Aumente o peso de um critério para que ele influencie mais a pontuação; use 0 para ignorá-lo." ]
        , div [ class "pesos-campos" ]
            [ label [ class "peso-campo" ]
                [ text "Peso das janelas entre aulas"
                , input
                    [ type_ "number"
                    , attribute "min" "0"
                    , attribute "step" "1"
                    , value model.pesoJanelasTexto
                    , disabled ocupado
                    , onInput AlterouPesoJanelas
                    ]
                    []
                ]
            , label [ class "peso-campo" ]
                [ text "Peso dos dias no campus"
                , input
                    [ type_ "number"
                    , attribute "min" "0"
                    , attribute "step" "1"
                    , value model.pesoDiasTexto
                    , disabled ocupado
                    , onInput AlterouPesoDias
                    ]
                    []
                ]
            ]
        ]


viewTitulo : String -> String -> String -> String -> Html Msg
viewTitulo numero id titulo descricao =
    div [ class "app-titulo-secao" ]
        [ span [ class "app-etapa", attribute "aria-hidden" "true" ] [ text numero ]
        , div []
            [ h2 [ attribute "id" id ] [ text titulo ]
            , p [ class "app-ajuda" ] [ text descricao ]
            ]
        ]


viewCatalogo : Model -> Bool -> Html Msg
viewCatalogo model ocupado =
    case model.catalogo of
        CarregandoCatalogo ->
            p [ class "app-mensagem", attribute "role" "status" ] [ text "Carregando disciplinas…" ]

        FalhouCatalogo detalhe ->
            div [ class "app-mensagem app-erro", attribute "role" "alert" ]
                [ p [] [ text ("Não foi possível carregar as disciplinas. " ++ detalhe) ]
                , button [ class "app-botao", type_ "button", onClick CarregarCatalogo ] [ text "Tentar novamente" ]
                ]

        CatalogoCarregado catalogo ->
            viewDisciplinas model ocupado catalogo


viewDisciplinas : Model -> Bool -> Catalogo -> Html Msg
viewDisciplinas model ocupado catalogo =
    div []
        [ p [ class "app-contexto" ] [ text ("Engenharia de Software · matriz " ++ catalogo.matriz ++ " · Campus Gama · " ++ catalogo.periodoTurmas) ]
        , div [ class "disciplinas" ]
            [ div [ class "disciplinas-grupo" ]
                [ div [ class "disciplinas-cabecalho" ]
                    [ h3 [] [ text "Já cursei" ]
                    , viewContador model.requisicao.cursadas
                    ]
                , p [ class "app-ajuda" ] [ text "Seu histórico conta para os pré-requisitos." ]
                , viewListaDisciplinas "Buscar cursadas por código ou nome"
                    model.buscaCursadas
                    BuscouCursadas
                    (viewOpcao AlternarCursada model.requisicao.cursadas ocupado)
                    catalogo.disciplinas
                ]
            , div [ class "disciplinas-grupo" ]
                [ div [ class "disciplinas-cabecalho" ]
                    [ h3 [] [ text "Quero cursar" ]
                    , viewContador model.requisicao.desejadas
                    ]
                , p [ class "app-ajuda" ] [ text "Disciplinas com turmas ofertadas neste semestre." ]
                , viewListaDisciplinas "Buscar desejadas por código ou nome"
                    model.buscaDesejadas
                    BuscouDesejadas
                    (viewOpcao AlternarDesejada model.requisicao.desejadas ocupado)
                    (List.filter .temTurmas catalogo.disciplinas)
                ]
            ]
        ]


viewContador : List String -> Html Msg
viewContador selecionadas =
    span [ class "app-contador", attribute "role" "status" ]
        [ text (String.fromInt (List.length selecionadas) ++ " selecionadas") ]


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
    div [ class "disciplinas-selecao" ]
        [ label [ class "disciplinas-busca" ]
            [ span [ class "grade-oculto" ] [ text rotulo ]
            , input [ type_ "search", placeholder "Buscar por nome ou código…", value busca, onInput aoBuscar ] []
            ]
        , div [ class "disciplinas-lista", tabindex 0, attribute "role" "region", attribute "aria-label" rotulo ]
            (if List.isEmpty encontradas then
                [ p [ class "disciplinas-vazia", attribute "role" "status" ] [ text "Nenhuma disciplina encontrada. Tente outro nome ou código." ] ]

             else
                List.map exibirOpcao encontradas
            )
        ]


viewOpcao : (String -> Msg) -> List String -> Bool -> Disciplina -> Html Msg
viewOpcao fazerMsg selecionadas ocupado disciplina =
    let
        selecionada =
            List.member disciplina.codigo selecionadas
    in
    label
        [ class
            (if selecionada then
                "disciplina disciplina-selecionada"

             else
                "disciplina"
            )
        ]
        [ input
            [ type_ "checkbox"
            , checked selecionada
            , disabled ocupado
            , onCheck (\_ -> fazerMsg disciplina.codigo)
            ]
            []
        , span [ class "disciplina-conteudo" ]
            [ span [ class "disciplina-nome" ] [ text disciplina.nome ]
            , span [ class "disciplina-detalhe" ] [ text (disciplina.codigo ++ " · " ++ String.fromInt disciplina.creditos ++ " créditos") ]
            ]
        ]


viewGradeSemanal : List String -> Bool -> Html Msg
viewGradeSemanal bloqueados ocupado =
    div [ class "grade" ]
        [ div [ class "grade-rolagem", tabindex 0, attribute "role" "region", attribute "aria-label" "Horários bloqueados, role para ver todos os dias" ]
            [ table [ class "grade-tabela grade-semanal" ]
                (caption [ class "grade-oculto" ] [ text "Selecione os horários em que você não pode ter aula" ]
                    :: thead []
                        [ tr []
                            (th [ scope "col" ] [ text "Horário" ]
                                :: List.map (\dia -> th [ scope "col" ] [ text (Horario.nomeDia dia) ]) Horario.dias
                            )
                        ]
                    :: List.map (viewLinhasTurno bloqueados ocupado) Horario.turnos
                )
            ]
        ]


viewLinhasTurno : List String -> Bool -> Horario.Turno -> Html Msg
viewLinhasTurno bloqueados ocupado turno =
    tbody []
        (tr [ class "grade-turno" ] [ th [ colspan 7, scope "rowgroup" ] [ text (Horario.nomeTurno turno) ] ]
            :: List.map
                (\periodo ->
                    tr []
                        (th [ class "grade-periodo", scope "row" ]
                            [ span [ class "grade-periodo-codigo" ] [ text (Horario.codigoPeriodo periodo) ]
                            , span [ class "grade-periodo-hora" ] [ text (Horario.inicio periodo ++ "–" ++ Horario.fim periodo) ]
                            ]
                            :: List.map (viewCelula periodo bloqueados ocupado) Horario.dias
                        )
                )
                (Horario.periodosDoTurno turno)
        )


viewCelula : Horario.Periodo -> List String -> Bool -> Horario.Dia -> Html Msg
viewCelula periodo bloqueados ocupado dia =
    let
        codigo =
            Horario.codigoSlot { dia = dia, periodo = periodo }

        bloqueado =
            List.member codigo bloqueados
    in
    td []
        [ button
            [ type_ "button"
            , class
                (if bloqueado then
                    "horario bloqueado"

                 else
                    "horario livre"
                )
            , attribute "aria-label" (Horario.nomeDia dia ++ ", " ++ Horario.codigoPeriodo periodo ++ ", " ++ Horario.inicio periodo ++ "–" ++ Horario.fim periodo)
            , attribute "aria-pressed"
                (if bloqueado then
                    "true"

                 else
                    "false"
                )
            , disabled ocupado
            , onClick (AlternarBloqueio codigo)
            ]
            [ span [ attribute "aria-hidden" "true", class "horario-icone" ]
                [ text
                    (if bloqueado then
                        "×"

                     else
                        "+"
                    )
                ]
            , text
                (if bloqueado then
                    "Bloqueado"

                 else
                    "Livre"
                )
            ]
        ]


viewEstado : Model -> Html Msg
viewEstado model =
    case model.estado of
        Pronto ->
            div [ class "app-resultado-vazio" ]
                [ span [ class "app-resultado-icone", attribute "aria-hidden" "true" ] [ text "▦" ]
                , h2 [] [ text "Sua próxima grade, logo aqui" ]
                , p [ class "app-ajuda" ] [ text "Ao gerar, você poderá comparar até cinco opções e escolher a que funciona melhor para você." ]
                ]

        Carregando ->
            div [ class "app-resultado-vazio", attribute "role" "status" ]
                [ span [ class "app-carregando", attribute "aria-hidden" "true" ] []
                , h2 [] [ text "Encontrando suas melhores combinações…" ]
                , p [ class "app-ajuda" ] [ text "Estamos cruzando disciplinas, pré-requisitos e sua disponibilidade." ]
                ]

        Falhou detalhe ->
            div [ class "app-mensagem app-erro", attribute "role" "alert" ]
                [ h2 [] [ text "Não foi possível gerar as grades" ], p [] [ text detalhe ] ]

        Carregado grades ->
            div []
                [ p [ class "grade-oculto", attribute "role" "status" ] [ text (String.fromInt (List.length grades) ++ " grades encontradas.") ]
                , GradeView.view
                    { selecionada = model.opcaoSelecionada
                    , aoSelecionar = SelecionouOpcao
                    }
                    grades
                ]
