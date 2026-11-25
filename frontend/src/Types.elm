module Types exposing (Catalogo, Disciplina, Request, decodeCatalogo, encodeRequest)

{-| Dados trocados entre a tela de entrada e a API do planejador.
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Catalogo =
    { matriz : String
    , periodoTurmas : String
    , disciplinas : List Disciplina
    }


type alias Disciplina =
    { codigo : String
    , nome : String
    , creditos : Int
    , temTurmas : Bool
    }


decodeCatalogo : Decoder Catalogo
decodeCatalogo =
    Decode.map3 Catalogo
        (Decode.field "matriz" Decode.string)
        (Decode.field "periodo_turmas" Decode.string)
        (Decode.field "disciplinas" (Decode.list decodeDisciplina))


decodeDisciplina : Decoder Disciplina
decodeDisciplina =
    Decode.map4 Disciplina
        (Decode.field "codigo" Decode.string)
        (Decode.field "nome" Decode.string)
        (Decode.field "creditos" Decode.int)
        (Decode.field "tem_turmas" Decode.bool)


type alias Request =
    { cursadas : List String
    , desejadas : List String
    , bloqueados : List String
    , pesoJanelas : Int
    , pesoDias : Int
    }


encodeRequest : Request -> Encode.Value
encodeRequest request =
    Encode.object
        [ ( "cursadas", Encode.list Encode.string request.cursadas )
        , ( "desejadas", Encode.list Encode.string request.desejadas )
        , ( "bloqueados", Encode.list Encode.string request.bloqueados )
        , ( "peso_janelas", Encode.int request.pesoJanelas )
        , ( "peso_dias", Encode.int request.pesoDias )
        ]
