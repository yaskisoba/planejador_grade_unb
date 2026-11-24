module Codec exposing
    ( Requisicao, requisicaoParaJson
    , Grade, Turma, respostaDecoder
    )

{-| Contrato JSON entre a interface e `POST /gerar-grades`.

@docs Requisicao, requisicaoParaJson
@docs Grade, Turma, respostaDecoder

-}

import Horario exposing (Horario, Slot)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode



-- REQUISIÇÃO


type alias Requisicao =
    { cursadas : List String
    , desejadas : List String
    , bloqueados : List Slot
    , pesoJanelas : Int
    , pesoDias : Int
    }


requisicaoParaJson : Requisicao -> Encode.Value
requisicaoParaJson requisicao =
    Encode.object
        [ ( "cursadas", Encode.list Encode.string requisicao.cursadas )
        , ( "desejadas", Encode.list Encode.string requisicao.desejadas )
        , ( "bloqueados", Encode.list (Horario.codigoSlot >> Encode.string) requisicao.bloqueados )
        , ( "peso_janelas", Encode.int requisicao.pesoJanelas )
        , ( "peso_dias", Encode.int requisicao.pesoDias )
        ]



-- RESPOSTA


type alias Grade =
    { rank : Int
    , score : Int
    , janelas : Int
    , diasCampus : Int
    , turmas : List Turma
    }


{-| `nome` e `professor` não fazem parte do contrato mínimo. A interface os
mostra quando a API os envia.
-}
type alias Turma =
    { codigo : String
    , turma : String
    , horarios : List Horario
    , nome : Maybe String
    , professor : Maybe String
    }


{-| Lê a resposta mantendo a ordem das grades. Lista vazia significa que não há
grade compatível, e não é erro.
-}
respostaDecoder : Decoder (List Grade)
respostaDecoder =
    Decode.field "grades" (Decode.list gradeDecoder)


gradeDecoder : Decoder Grade
gradeDecoder =
    Decode.map5 Grade
        (Decode.field "rank" Decode.int)
        (Decode.field "score" Decode.int)
        (Decode.field "janelas" Decode.int)
        (Decode.field "dias_campus" Decode.int)
        (Decode.field "turmas" (Decode.list turmaDecoder))


turmaDecoder : Decoder Turma
turmaDecoder =
    Decode.map5 Turma
        (Decode.field "codigo" Decode.string)
        (Decode.field "turma" Decode.string)
        (Decode.field "horarios" (Decode.list horarioDecoder))
        (opcional "nome" Decode.string)
        (opcional "professor" Decode.string)


horarioDecoder : Decoder Horario
horarioDecoder =
    Decode.string
        |> Decode.andThen
            (\texto ->
                case Horario.deTexto texto of
                    Just horario ->
                        Decode.succeed horario

                    Nothing ->
                        Decode.fail ("Horário inválido: \"" ++ texto ++ "\"")
            )


{-| Campo que pode faltar ou ser `null`. Se vier com outro tipo, é erro:
`Decode.maybe` sozinho esconderia a falha.
-}
opcional : String -> Decoder a -> Decoder (Maybe a)
opcional campo decoder =
    Decode.maybe (Decode.field campo Decode.value)
        |> Decode.andThen
            (\valor ->
                case valor of
                    Just _ ->
                        Decode.field campo (Decode.nullable decoder)

                    Nothing ->
                        Decode.succeed Nothing
            )
