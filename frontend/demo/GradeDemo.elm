module GradeDemo exposing (main)

{-| Mostra `GradeView` com respostas JSON fixas, sem depender da API.
`EXE0001` é fictícia; as demais turmas são as de `prolog/turmas.pl`.
-}

import Browser
import Codec
import GradeView
import Html exposing (Html, button, div, p, text)
import Html.Attributes exposing (class, type_)
import Html.Events exposing (onClick)
import Json.Decode as Decode


type alias Model =
    { resposta : String
    , opcao : Int
    }


type Msg
    = EscolheuResposta String
    | SelecionouOpcao Int


main : Program () Model Msg
main =
    Browser.sandbox
        { init = { resposta = cincoOpcoes, opcao = 0 }
        , update = update
        , view = view
        }


update : Msg -> Model -> Model
update msg model =
    case msg of
        EscolheuResposta resposta ->
            { resposta = resposta, opcao = 0 }

        SelecionouOpcao opcao ->
            { model | opcao = opcao }


view : Model -> Html Msg
view model =
    div []
        [ div [ class "demo-respostas" ]
            [ botao "Cinco opções" cincoOpcoes
            , botao "Base demonstrativa" baseDemonstrativa
            , botao "Contrato mínimo" contratoMinimo
            , botao "Choque" comChoque
            , botao "Sem solução" semSolucao
            , botao "Resposta inválida" respostaInvalida
            ]
        , case Decode.decodeString Codec.respostaDecoder model.resposta of
            Ok grades ->
                GradeView.view
                    { selecionada = model.opcao
                    , aoSelecionar = SelecionouOpcao
                    }
                    grades

            Err erro ->
                p [ class "demo-erro" ] [ text (Decode.errorToString erro) ]
        ]


botao : String -> String -> Html Msg
botao rotulo resposta =
    button [ type_ "button", onClick (EscolheuResposta resposta) ] [ text rotulo ]



-- RESPOSTAS


cincoOpcoes : String
cincoOpcoes =
    """
{ "grades":
    [ { "rank": 1, "score": 5, "janelas": 0, "dias_campus": 5,
        "turmas":
          [ {"codigo": "EXE0001", "turma": "A", "nome": "Disciplina de Exemplo", "professor": "Professor 9", "horarios": ["7M1234"]},
            {"codigo": "FGA0124", "turma": "B", "nome": "Engenharia de Requisitos", "professor": "Professor 8", "horarios": ["6T12"]},
            {"codigo": "FGA0158", "turma": "B", "nome": "Orientação a Objetos", "professor": "Professor 2", "horarios": ["35T12"]},
            {"codigo": "FGA0244", "turma": "B", "nome": "Projeto de Algoritmos", "professor": "Professor 6", "horarios": ["46T34"]} ] },
      { "rank": 2, "score": 6, "janelas": 0, "dias_campus": 6,
        "turmas":
          [ {"codigo": "EXE0001", "turma": "A", "nome": "Disciplina de Exemplo", "professor": "Professor 9", "horarios": ["7M1234"]},
            {"codigo": "FGA0124", "turma": "B", "nome": "Engenharia de Requisitos", "professor": "Professor 8", "horarios": ["6T12"]},
            {"codigo": "FGA0158", "turma": "A", "nome": "Orientação a Objetos", "professor": "Professor 1", "horarios": ["24M34"]},
            {"codigo": "FGA0244", "turma": "A", "nome": "Projeto de Algoritmos", "professor": "Professor 5", "horarios": ["35M12"]} ] },
      { "rank": 3, "score": 19, "janelas": 2, "dias_campus": 5,
        "turmas":
          [ {"codigo": "EXE0001", "turma": "B", "nome": "Disciplina de Exemplo", "professor": "Professor 10", "horarios": ["24N12"]},
            {"codigo": "FGA0124", "turma": "B", "nome": "Engenharia de Requisitos", "professor": "Professor 8", "horarios": ["6T12"]},
            {"codigo": "FGA0158", "turma": "B", "nome": "Orientação a Objetos", "professor": "Professor 2", "horarios": ["35T12"]},
            {"codigo": "FGA0244", "turma": "B", "nome": "Projeto de Algoritmos", "professor": "Professor 6", "horarios": ["46T34"]} ] },
      { "rank": 4, "score": 25, "janelas": 3, "dias_campus": 4,
        "turmas":
          [ {"codigo": "EXE0001", "turma": "A", "nome": "Disciplina de Exemplo", "professor": "Professor 9", "horarios": ["7M1234"]},
            {"codigo": "FGA0124", "turma": "B", "nome": "Engenharia de Requisitos", "professor": "Professor 8", "horarios": ["6T12"]},
            {"codigo": "FGA0158", "turma": "A", "nome": "Orientação a Objetos", "professor": "Professor 1", "horarios": ["24M34"]},
            {"codigo": "FGA0244", "turma": "B", "nome": "Projeto de Algoritmos", "professor": "Professor 6", "horarios": ["46T34"]} ] },
      { "rank": 5, "score": 46, "janelas": 6, "dias_campus": 4,
        "turmas":
          [ {"codigo": "EXE0001", "turma": "A", "nome": "Disciplina de Exemplo", "professor": "Professor 9", "horarios": ["7M1234"]},
            {"codigo": "FGA0124", "turma": "B", "nome": "Engenharia de Requisitos", "professor": "Professor 8", "horarios": ["6T12"]},
            {"codigo": "FGA0158", "turma": "B", "nome": "Orientação a Objetos", "professor": "Professor 2", "horarios": ["35T12"]},
            {"codigo": "FGA0244", "turma": "A", "nome": "Projeto de Algoritmos", "professor": "Professor 5", "horarios": ["35M12"]} ] } ]
}
"""


baseDemonstrativa : String
baseDemonstrativa =
    """
{ "grades":
    [ { "rank": 1, "score": 4, "janelas": 0, "dias_campus": 4,
        "turmas":
          [ {"codigo": "FGA0210", "turma": "A", "nome": "Paradigmas de Programação", "professor": "Professor 3", "horarios": ["24M34"]},
            {"codigo": "FGA0244", "turma": "A", "nome": "Projeto de Algoritmos", "professor": "Professor 5", "horarios": ["35M12"]} ] },
      { "rank": 2, "score": 4, "janelas": 0, "dias_campus": 4,
        "turmas":
          [ {"codigo": "FGA0210", "turma": "B", "nome": "Paradigmas de Programação", "professor": "Professor 4", "horarios": ["35M12"]},
            {"codigo": "FGA0244", "turma": "B", "nome": "Projeto de Algoritmos", "professor": "Professor 6", "horarios": ["46T34"]} ] },
      { "rank": 3, "score": 24, "janelas": 3, "dias_campus": 3,
        "turmas":
          [ {"codigo": "FGA0210", "turma": "A", "nome": "Paradigmas de Programação", "professor": "Professor 3", "horarios": ["24M34"]},
            {"codigo": "FGA0244", "turma": "B", "nome": "Projeto de Algoritmos", "professor": "Professor 6", "horarios": ["46T34"]} ] } ]
}
"""


contratoMinimo : String
contratoMinimo =
    """
{ "grades":
    [ { "rank": 1, "score": 95, "janelas": 0, "dias_campus": 2,
        "turmas": [ { "codigo": "FGA0244", "turma": "A", "horarios": ["35M34"] } ] } ]
}
"""


{-| O motor não gera choques. Serve para ver o alerta.
-}
comChoque : String
comChoque =
    """
{ "grades":
    [ { "rank": 1, "score": 2, "janelas": 0, "dias_campus": 2,
        "turmas":
          [ { "codigo": "FGA0158", "turma": "A", "horarios": ["24M34"] },
            { "codigo": "FGA0210", "turma": "A", "horarios": ["2M45"] },
            { "codigo": "FGA0124", "turma": "B", "horarios": [] } ] } ]
}
"""


semSolucao : String
semSolucao =
    """{ "grades": [] }"""


respostaInvalida : String
respostaInvalida =
    """
{ "grades":
    [ { "rank": 1, "score": 1, "janelas": 0, "dias_campus": 1,
        "turmas": [ { "codigo": "FGA0244", "turma": "A", "horarios": ["8M12"] } ] } ]
}
"""
