module GradeView exposing (Config, maximoOpcoes, view)

{-| Grade semanal com seletor das melhores opções.

O módulo não guarda estado: quem usa informa a opção selecionada e a mensagem
enviada na troca. A folha de estilos é `frontend/grade.css`.

    GradeView.view
        { selecionada = model.opcao
        , aoSelecionar = SelecionouOpcao
        }
        model.grades

@docs Config, maximoOpcoes, view

-}

import Codec exposing (Grade, Turma)
import Horario exposing (Dia, Horario, Periodo, Turno)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck)
import Semana exposing (Celula, Conteudo(..))


{-| `selecionada` é a posição na lista, a partir de 0. Se não existir, a
primeira grade é exibida, então basta usar 0 ao receber uma nova resposta.
-}
type alias Config msg =
    { selecionada : Int
    , aoSelecionar : Int -> msg
    }


maximoOpcoes : Int
maximoOpcoes =
    5


view : Config msg -> List Grade -> Html msg
view config grades =
    let
        opcoes =
            List.take maximoOpcoes grades
    in
    section [ class "grade", attribute "aria-labelledby" "grade-titulo" ]
        (h2 [ id "grade-titulo", class "grade-titulo" ] [ text "Grades sugeridas" ]
            :: (case escolher config.selecionada opcoes of
                    Just ( posicao, grade ) ->
                        [ viewSeletor config posicao opcoes
                        , viewOpcao opcoes grade
                        ]

                    Nothing ->
                        [ viewVazia ]
               )
        )


escolher : Int -> List Grade -> Maybe ( Int, Grade )
escolher selecionada opcoes =
    let
        numeradas =
            List.indexedMap Tuple.pair opcoes
    in
    case List.filter (\( posicao, _ ) -> posicao == selecionada) numeradas of
        encontrada :: _ ->
            Just encontrada

        [] ->
            List.head numeradas



-- SEM RESULTADOS


viewVazia : Html msg
viewVazia =
    div [ class "grade-vazia", attribute "role" "status" ]
        [ p [ class "grade-vazia-titulo" ] [ text "Nenhuma grade compatível" ]
        , p [] [ text "Não há combinação que inclua todas as disciplinas desejadas. Confira:" ]
        , ul []
            [ li [] [ text "se os pré-requisitos estão entre as disciplinas cursadas;" ]
            , li [] [ text "se alguma disciplina desejada já foi cursada;" ]
            , li [] [ text "se há horários bloqueados que podem ser liberados;" ]
            , li [] [ text "se há choque de horário, falta de vagas ou excesso de créditos." ]
            ]
        ]



-- SELETOR


{-| Botões de rádio nativos: as setas do teclado já trocam a opção.
-}
viewSeletor : Config msg -> Int -> List Grade -> Html msg
viewSeletor config atual opcoes =
    fieldset [ class "grade-seletor" ]
        [ legend [ class "grade-legenda" ] [ text "Escolha uma opção" ]
        , div [ class "grade-opcoes" ]
            (List.indexedMap (viewBotaoOpcao config atual) opcoes)
        ]


viewBotaoOpcao : Config msg -> Int -> Int -> Grade -> Html msg
viewBotaoOpcao config atual posicao grade =
    label [ class "grade-opcao" ]
        [ input
            [ type_ "radio"
            , name "grade-opcao"
            , value (String.fromInt posicao)
            , checked (posicao == atual)
            , onCheck (\_ -> config.aoSelecionar posicao)
            ]
            []
        , span [ class "grade-opcao-corpo" ]
            [ span [ class "grade-opcao-titulo" ] [ text (nomeOpcao grade) ]
            , span [ class "grade-opcao-detalhe" ]
                [ text (textoJanelas grade.janelas ++ " · " ++ textoDias grade.diasCampus) ]
            ]
        ]



-- OPÇÃO SELECIONADA


viewOpcao : List Grade -> Grade -> Html msg
viewOpcao opcoes grade =
    let
        -- Linhas, colunas e cores consideram todas as opções, para que a tabela
        -- não mude de forma ao trocar de uma para outra.
        turmasDasOpcoes =
            List.concatMap .turmas opcoes

        cor =
            corDaDisciplina turmasDasOpcoes
    in
    div [ class "grade-painel" ]
        [ viewResumo grade
        , viewChoques (Semana.choques grade.turmas)
        , viewTabela cor turmasDasOpcoes grade
        , viewTurmas cor grade.turmas
        ]


viewResumo : Grade -> Html msg
viewResumo grade =
    div [ class "grade-resumo", attribute "role" "status" ]
        [ h3 [ class "grade-resumo-titulo" ] [ text (nomeOpcao grade) ]
        , ul [ class "grade-metricas" ]
            [ li [] [ text ("Pontuação " ++ String.fromInt grade.score) ]
            , li [] [ text (textoJanelas grade.janelas) ]
            , li [] [ text (textoDias grade.diasCampus ++ " no campus") ]
            ]
        ]


viewChoques : List String -> Html msg
viewChoques slots =
    if List.isEmpty slots then
        text ""

    else
        p [ class "grade-alerta", attribute "role" "alert" ]
            [ text ("Atenção: há choque de horário em " ++ String.join ", " slots ++ ".") ]



-- TABELA SEMANAL


viewTabela : (Turma -> Html.Attribute msg) -> List Turma -> Grade -> Html msg
viewTabela cor turmasDasOpcoes grade =
    let
        dias =
            Semana.diasVisiveis turmasDasOpcoes
    in
    div
        [ class "grade-rolagem"
        , attribute "role" "region"
        , attribute "aria-label" "Tabela da grade semanal"
        , tabindex 0
        ]
        [ table [ class "grade-tabela" ]
            (caption [ class "grade-oculto" ]
                [ text ("Grade semanal da " ++ nomeOpcao grade) ]
                :: thead []
                    [ tr []
                        (th [ scope "col" ] [ text "Horário" ]
                            :: List.map
                                (\dia -> th [ scope "col" ] [ text (Horario.nomeDia dia) ])
                                dias
                        )
                    ]
                :: List.map
                    (viewTurno cor dias grade.turmas)
                    (Semana.turnosVisiveis turmasDasOpcoes)
            )
        ]


viewTurno : (Turma -> Html.Attribute msg) -> List Dia -> List Turma -> Turno -> Html msg
viewTurno cor dias turmas turno =
    let
        colunas =
            List.map (\dia -> Semana.celulas turmas dia turno) dias
    in
    tbody []
        (tr [ class "grade-turno" ]
            [ th [ scope "rowgroup", colspan (List.length dias + 1) ]
                [ text (Horario.nomeTurno turno) ]
            ]
            :: List.map (viewLinha cor colunas) (Horario.periodosDoTurno turno)
        )


viewLinha : (Turma -> Html.Attribute msg) -> List (List Celula) -> Periodo -> Html msg
viewLinha cor colunas periodo =
    tr []
        (th [ scope "row", class "grade-periodo" ]
            [ span [ class "grade-periodo-codigo" ] [ text (Horario.codigoPeriodo periodo) ]
            , span [ class "grade-periodo-hora" ]
                [ text (intervalo periodo periodo) ]
            ]
            :: List.concatMap
                -- Células iniciadas em linhas anteriores já ocupam esta por rowspan.
                (List.filter (\celula -> celula.inicio == periodo) >> List.map (viewCelula cor))
                colunas
        )


viewCelula : (Turma -> Html.Attribute msg) -> Celula -> Html msg
viewCelula cor celula =
    case celula.conteudo of
        Livre ->
            td [] []

        Janela ->
            td [ class "grade-janela" ] [ span [] [ text "janela" ] ]

        Aula turma ->
            td [ class "grade-ocupada", rowspan celula.duracao ]
                [ viewAula cor celula turma ]

        Choque turmas ->
            td [ class "grade-ocupada grade-choque", rowspan celula.duracao ]
                (span [ class "grade-choque-rotulo" ] [ text "Choque" ]
                    :: List.map (viewAula cor celula) turmas
                )


viewAula : (Turma -> Html.Attribute msg) -> Celula -> Turma -> Html msg
viewAula cor celula turma =
    div [ class "grade-aula", cor turma ]
        [ span [ class "grade-aula-codigo" ] [ text turma.codigo ]
        , viewTalvez "grade-aula-nome" turma.nome
        , span [ class "grade-aula-detalhe" ] [ text ("Turma " ++ turma.turma) ]
        , span [ class "grade-aula-detalhe" ] [ text (intervalo celula.inicio celula.fim) ]
        ]



-- LISTA DE TURMAS


viewTurmas : (Turma -> Html.Attribute msg) -> List Turma -> Html msg
viewTurmas cor turmas =
    div [ class "grade-turmas" ]
        [ h3 [ class "grade-turmas-titulo" ] [ text "Turmas desta opção" ]
        , if List.isEmpty turmas then
            p [] [ text "Esta opção não tem turmas." ]

          else
            ul [] (List.map (viewTurma cor) turmas)
        ]


viewTurma : (Turma -> Html.Attribute msg) -> Turma -> Html msg
viewTurma cor turma =
    li [ class "grade-turma", cor turma ]
        [ span [ class "grade-turma-codigo" ]
            [ text (turma.codigo ++ " · Turma " ++ turma.turma) ]
        , viewTalvez "grade-turma-nome" turma.nome
        , viewTalvez "grade-turma-professor" turma.professor
        , div [ class "grade-turma-horarios" ]
            (if List.isEmpty turma.horarios then
                [ span [] [ text "Sem horário definido" ] ]

             else
                List.map viewHorario turma.horarios
            )
        ]


viewHorario : Horario -> Html msg
viewHorario horario =
    span []
        [ code [] [ text (Horario.paraTexto horario) ]
        , text (" " ++ Horario.descricao horario)
        ]


viewTalvez : String -> Maybe String -> Html msg
viewTalvez classe valor =
    case valor of
        Just conteudo ->
            span [ class classe ] [ text conteudo ]

        Nothing ->
            text ""



-- AUXILIARES


quantidadeCores : Int
quantidadeCores =
    8


{-| A mesma disciplina tem a mesma cor em todas as opções.
-}
corDaDisciplina : List Turma -> Turma -> Html.Attribute msg
corDaDisciplina turmas turma =
    let
        posicao =
            turmas
                |> List.map .codigo
                |> List.filter (\codigo -> codigo < turma.codigo)
                |> semRepeticao
                |> List.length
    in
    class ("grade-cor-" ++ String.fromInt (modBy quantidadeCores posicao + 1))


semRepeticao : List String -> List String
semRepeticao =
    List.foldr
        (\item vistos ->
            if List.member item vistos then
                vistos

            else
                item :: vistos
        )
        []


nomeOpcao : Grade -> String
nomeOpcao grade =
    String.fromInt grade.rank ++ "ª opção"


intervalo : Periodo -> Periodo -> String
intervalo primeiro ultimo =
    Horario.inicio primeiro ++ "–" ++ Horario.fim ultimo


textoJanelas : Int -> String
textoJanelas quantidade =
    case quantidade of
        0 ->
            "Sem janelas"

        1 ->
            "1 janela"

        _ ->
            String.fromInt quantidade ++ " janelas"


textoDias : Int -> String
textoDias quantidade =
    if quantidade == 1 then
        "1 dia"

    else
        String.fromInt quantidade ++ " dias"
