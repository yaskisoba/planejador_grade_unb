module GradeViewTest exposing (suite)

import Codec exposing (Grade)
import Expect
import GradeView
import Horario
import Html.Attributes as Attr
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "GradeView"
        [ test "informa quando não há grade compatível" <|
            \_ ->
                exibir 0 []
                    |> Query.has [ Selector.text "Nenhuma grade compatível" ]
        , test "sem grades, não mostra seletor nem tabela" <|
            \_ ->
                exibir 0 []
                    |> Expect.all
                        [ Query.hasNot [ Selector.tag "input" ]
                        , Query.hasNot [ Selector.tag "table" ]
                        ]
        , test "mostra no máximo cinco opções" <|
            \_ ->
                exibir 0 (List.map (\rank -> grade rank [ "2M12" ]) (List.range 1 7))
                    |> Query.findAll [ Selector.tag "input" ]
                    |> Query.count (Expect.equal 5)
        , test "marca só a opção selecionada" <|
            \_ ->
                exibir 1 duas
                    |> Query.findAll [ Selector.attribute (Attr.checked True) ]
                    |> Query.count (Expect.equal 1)
        , test "exibe a grade selecionada" <|
            \_ ->
                exibir 1 duas
                    |> Query.find [ Selector.class "grade-resumo" ]
                    |> Query.has [ Selector.text "2ª opção" ]
        , test "posição inexistente exibe a primeira grade" <|
            \_ ->
                exibir 9 duas
                    |> Query.find [ Selector.class "grade-resumo" ]
                    |> Query.has [ Selector.text "1ª opção" ]
        , test "trocar de opção envia a posição escolhida" <|
            \_ ->
                exibir 0 duas
                    |> Query.find [ Selector.tag "input", Selector.attribute (Attr.value "1") ]
                    |> Event.simulate (Event.check True)
                    |> Event.expect 1
        , test "aula de dois períodos ocupa duas linhas" <|
            \_ ->
                exibir 0 [ grade 1 [ "2M34" ] ]
                    |> Query.find [ Selector.class "grade-ocupada" ]
                    |> Query.has [ Selector.attribute (Attr.rowspan 2) ]
        , test "cada janela aparece na tabela" <|
            \_ ->
                exibir 0 [ grade 1 [ "2M14" ] ]
                    |> Query.findAll [ Selector.class "grade-janela" ]
                    |> Query.count (Expect.equal 2)
        , test "sábado aparece se alguma opção tiver aula nesse dia" <|
            \_ ->
                exibir 0 [ grade 1 [ "2M1" ], grade 2 [ "7M1" ] ]
                    |> Query.find [ Selector.tag "thead" ]
                    |> Query.has [ Selector.text "Sábado" ]
        , test "turma sem horário continua na lista" <|
            \_ ->
                exibir 0 [ grade 1 [] ]
                    |> Query.find [ Selector.class "grade-turmas" ]
                    |> Query.has [ Selector.text "Sem horário definido" ]
        , test "grade sem choque não mostra alerta" <|
            \_ ->
                exibir 0 duas
                    |> Query.hasNot [ Selector.class "grade-alerta" ]
        , test "choque mostra alerta com o horário" <|
            \_ ->
                exibir 0 [ comChoque ]
                    |> Query.find [ Selector.class "grade-alerta" ]
                    |> Query.has [ Selector.text "Atenção: há choque de horário em 2M4." ]
        , test "a mesma disciplina mantém a cor ao trocar de opção" <|
            \_ ->
                let
                    temCor posicao _ =
                        exibir posicao [ duasDisciplinas, so "FGA0244" ]
                            |> Query.find [ Selector.class "grade-turmas" ]
                            |> Query.find
                                [ Selector.tag "li"
                                , Selector.containing [ Selector.text "FGA0244 · Turma A" ]
                                ]
                            |> Query.has [ Selector.class "grade-cor-2" ]
                in
                Expect.all [ temCor 0, temCor 1 ] ()
        ]


exibir : Int -> List Grade -> Query.Single Int
exibir selecionada grades =
    GradeView.view { selecionada = selecionada, aoSelecionar = identity } grades
        |> Query.fromHtml


duas : List Grade
duas =
    [ grade 1 [ "24M34" ], grade 2 [ "35T12" ] ]


grade : Int -> List String -> Grade
grade rank horarios =
    { rank = rank
    , score = 4
    , janelas = 0
    , diasCampus = 2
    , turmas = [ turma "FGA0158" horarios ]
    }


comChoque : Grade
comChoque =
    let
        base =
            grade 1 []
    in
    { base | turmas = [ turma "FGA0158" [ "2M34" ], turma "FGA0210" [ "2M45" ] ] }


duasDisciplinas : Grade
duasDisciplinas =
    let
        base =
            grade 1 []
    in
    { base | turmas = [ turma "FGA0244" [ "2M12" ], turma "FGA0158" [ "3M12" ] ] }


so : String -> Grade
so codigo =
    let
        base =
            grade 2 []
    in
    { base | turmas = [ turma codigo [ "2M12" ] ] }


turma : String -> List String -> Codec.Turma
turma codigo horarios =
    { codigo = codigo
    , turma = "A"
    , horarios = List.filterMap Horario.deTexto horarios
    , nome = Nothing
    , professor = Nothing
    }
