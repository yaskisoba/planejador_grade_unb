module Types exposing
    ( Grade
    , Request
    , Section
    , decodeGrades
    , encodeRequest
    )

{-| Types shared by the application state and the input/results screens.

The JSON field names follow the minimal contract in the project schedule.
-}

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias Request =
    { cursadas : List String
    , desejadas : List String
    , bloqueados : List String
    , pesoJanelas : Int
    , pesoDias : Int
    }


type alias Section =
    { codigo : String
    , turma : String
    , horarios : List String
    }


type alias Grade =
    { rank : Int
    , score : Int
    , janelas : Int
    , diasCampus : Int
    , turmas : List Section
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


decodeGrades : Decoder (List Grade)
decodeGrades =
    Decode.field "grades" (Decode.list gradeDecoder)


gradeDecoder : Decoder Grade
gradeDecoder =
    Decode.map5 Grade
        (Decode.field "rank" Decode.int)
        (Decode.field "score" Decode.int)
        (Decode.field "janelas" Decode.int)
        (Decode.field "dias_campus" Decode.int)
        (Decode.field "turmas" (Decode.list sectionDecoder))


sectionDecoder : Decoder Section
sectionDecoder =
    Decode.map3 Section
        (Decode.field "codigo" Decode.string)
        (Decode.field "turma" Decode.string)
        (Decode.field "horarios" (Decode.list Decode.string))
