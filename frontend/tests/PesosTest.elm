module PesosTest exposing (suite)

import Expect
import Html.Attributes as Attr
import Pesos
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Pesos"
        [ test "exibe os dois campos com os pesos iniciais" <|
            \_ ->
                Pesos.view False Pesos.inicial
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "input" ]
                    |> Query.count (Expect.equal 2)
        , test "os campos enviam alterações de janelas e dias" <|
            \_ ->
                let
                    pagina =
                        Pesos.view False Pesos.inicial |> Query.fromHtml
                in
                Expect.all
                    [ \_ ->
                        pagina
                            |> Query.find [ Selector.tag "input", Selector.attribute (Attr.value "3") ]
                            |> Event.simulate (Event.input "5")
                            |> Event.expect (Pesos.PesoJanelasAlterado "5")
                    , \_ ->
                        pagina
                            |> Query.find [ Selector.tag "input", Selector.attribute (Attr.value "2") ]
                            |> Event.simulate (Event.input "0")
                            |> Event.expect (Pesos.PesoDiasAlterado "0")
                    ]
                    ()
        , test "valores válidos são enviados à requisição" <|
            \_ ->
                let
                    atualizados =
                        Pesos.inicial
                            |> Pesos.atualizar (Pesos.PesoJanelasAlterado "5")
                            |> Pesos.atualizar (Pesos.PesoDiasAlterado "0")

                    requisicao =
                        Pesos.aplicar atualizados
                            { cursadas = [], desejadas = [], bloqueados = [], pesoJanelas = 3, pesoDias = 2 }
                in
                Expect.equal ( 5, 0 ) ( requisicao.pesoJanelas, requisicao.pesoDias )
        , test "pesos negativos, vazios e fracionários são inválidos" <|
            \_ ->
                [ "", "-1", "1.5" ]
                    |> List.map
                        (\texto ->
                            Pesos.inicial
                                |> Pesos.atualizar (Pesos.PesoJanelasAlterado texto)
                                |> Pesos.valido
                        )
                    |> Expect.equal [ False, False, False ]
        , test "campo inválido preserva o último peso válido" <|
            \_ ->
                Pesos.inicial
                    |> Pesos.atualizar (Pesos.PesoJanelasAlterado "-1")
                    |> .janelas
                    |> Expect.equal 3
        , test "explica que pesos zero ainda usam desempate por métricas" <|
            \_ ->
                Pesos.view False Pesos.inicial
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.text "Peso 0 zera a contribuição direta no score; em caso de empate, o motor ainda desempata por janelas e dias." ]
        , test "desabilita os campos enquanto busca grades" <|
            \_ ->
                Pesos.view True Pesos.inicial
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "input", Selector.attribute (Attr.value "3") ]
                    |> Query.has [ Selector.attribute (Attr.disabled True) ]
        ]
