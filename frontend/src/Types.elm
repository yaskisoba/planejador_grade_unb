module Types exposing (Request, encodeRequest)

{-| Requisição da tela de entrada para a API de geração de grades.
-}

import Json.Encode as Encode


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
