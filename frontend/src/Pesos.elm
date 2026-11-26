module Pesos exposing (Mensagem(..), Modelo, aplicar, atualizar, inicial, valido, view)

import Html exposing (Html, div, h3, input, label, p, text)
import Html.Attributes exposing (attribute, disabled, type_, value)
import Html.Events exposing (onInput)
import Types exposing (Request)


type alias Modelo =
    { janelasTexto : String
    , diasTexto : String
    , janelas : Int
    , dias : Int
    }


type Mensagem
    = PesoJanelasAlterado String
    | PesoDiasAlterado String


inicial : Modelo
inicial =
    { janelasTexto = "3"
    , diasTexto = "2"
    , janelas = 3
    , dias = 2
    }


atualizar : Mensagem -> Modelo -> Modelo
atualizar mensagem modelo =
    case mensagem of
        PesoJanelasAlterado texto ->
            { modelo
                | janelasTexto = texto
                , janelas = valorValido texto modelo.janelas
            }

        PesoDiasAlterado texto ->
            { modelo
                | diasTexto = texto
                , dias = valorValido texto modelo.dias
            }


valorValido : String -> Int -> Int
valorValido texto anterior =
    case String.toInt texto of
        Just peso ->
            if peso >= 0 then
                peso

            else
                anterior

        Nothing ->
            anterior


valido : Modelo -> Bool
valido modelo =
    textoValido modelo.janelasTexto && textoValido modelo.diasTexto


textoValido : String -> Bool
textoValido texto =
    case String.toInt texto of
        Just peso ->
            peso >= 0

        Nothing ->
            False


aplicar : Modelo -> Request -> Request
aplicar modelo requisicao =
    { requisicao
        | pesoJanelas = modelo.janelas
        , pesoDias = modelo.dias
    }


view : Bool -> Modelo -> Html Mensagem
view ocupado modelo =
    div [ attribute "class" "pesos", attribute "aria-labelledby" "pesos-titulo" ]
        [ h3 [ attribute "id" "pesos-titulo" ] [ text "Preferências de ranking" ]
        , p [ attribute "class" "app-ajuda" ]
            [ text "A pontuação é peso das janelas × janelas + peso dos dias × dias no campus. Peso 0 zera a contribuição direta no score; em caso de empate, o motor ainda desempata por janelas e dias." ]
        , div [ attribute "class" "pesos-campos" ]
            [ campo "Peso das janelas entre aulas" modelo.janelasTexto ocupado PesoJanelasAlterado
            , campo "Peso dos dias no campus" modelo.diasTexto ocupado PesoDiasAlterado
            ]
        ]


campo : String -> String -> Bool -> (String -> Mensagem) -> Html Mensagem
campo rotulo texto ocupado aoAlterar =
    label [ attribute "class" "peso-campo" ]
        [ text rotulo
        , input
            [ type_ "number"
            , attribute "min" "0"
            , attribute "step" "1"
            , value texto
            , disabled ocupado
            , onInput aoAlterar
            ]
            []
        ]
