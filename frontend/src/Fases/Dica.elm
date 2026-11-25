module Fases.Dica exposing (modulo, planoDecoder, roteiro)

import Ajuda exposing (Ajuda, Modulo, TipoConsulta(..))
import Html exposing (Html, div, li, p, text, ul)
import Html.Attributes exposing (class)
import Json.Decode as Decode exposing (Decoder)


type alias Plano =
    { caminhada : List String
    , caixa : Int
    , empurrao : String
    , total : Int
    }


modulo : Modulo
modulo =
    { id = "dica"
    , consultas = [ PorPadrao ]
    , destacar = .destaques
    , exibir = exibir
    }


roteiro : Plano -> List String
roteiro plano =
    [ caminhe plano.caminhada
    , "Empurre a caixa " ++ String.fromInt plano.caixa ++ ": " ++ plano.empurrao
    , "Rota minima: " ++ String.fromInt plano.total ++ " passos"
    ]


caminhe : List String -> String
caminhe caminhada =
    case caminhada of
        [] ->
            "Caminhe: nenhum passo"

        _ ->
            "Caminhe: "
                ++ String.join " " (List.map letra caminhada)
                ++ " ("
                ++ passos (List.length caminhada)
                ++ ")"


letra : String -> String
letra direcao =
    String.toUpper (String.left 1 direcao)


passos : Int -> String
passos quantidade =
    if quantidade == 1 then
        "1 passo"

    else
        String.fromInt quantidade ++ " passos"


planoDecoder : Decoder Plano
planoDecoder =
    Decode.map4 Plano
        (Decode.field "caminhada" (Decode.list Decode.string))
        (Decode.field "caixa" Decode.int)
        (Decode.field "empurrao" Decode.string)
        (Decode.field "total" Decode.int)


exibir : Ajuda -> Html Never
exibir ajuda =
    case Decode.decodeValue planoDecoder ajuda.dados of
        Ok plano ->
            div [ class "modulo" ]
                [ p [ class "modulo-titulo" ] [ text "Primeiro empurrao" ]
                , ul [ class "lista" ] (List.map item (roteiro plano))
                ]

        Err _ ->
            p [ class "legenda" ] [ text "Sem empurrao a mostrar." ]


item : String -> Html Never
item linha =
    li [] [ text linha ]
