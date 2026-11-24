module Fases.Dica exposing (Plano, modulo, planoDecoder, roteiro)

import Ajuda exposing (Ajuda, Modulo, TipoConsulta(..))
import Html exposing (Html, div, li, ol, p, text)
import Html.Attributes exposing (class)
import Jogo exposing (Direcao)
import Json.Decode as Decode exposing (Decoder)


type alias Plano =
    { caminhada : List Direcao
    , caixa : Int
    , direcao : Direcao
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
    List.map caminhar plano.caminhada ++ [ empurrar plano.caixa plano.direcao ]


caminhar : Direcao -> String
caminhar direcao =
    "Caminhar para " ++ Jogo.nomeDirecao direcao


empurrar : Int -> Direcao -> String
empurrar caixa direcao =
    "Empurrar a caixa " ++ String.fromInt caixa ++ " para " ++ Jogo.nomeDirecao direcao


planoDecoder : Decoder Plano
planoDecoder =
    Decode.map3 Plano
        (Decode.field "caminhada" (Decode.list direcaoDecoder))
        (Decode.field "caixa" Decode.int)
        (Decode.field "direcao" direcaoDecoder)


direcaoDecoder : Decoder Direcao
direcaoDecoder =
    Decode.string |> Decode.andThen direcaoDoNome


direcaoDoNome : String -> Decoder Direcao
direcaoDoNome nome =
    case List.filter (\direcao -> Jogo.nomeDirecao direcao == nome) Jogo.direcoes of
        direcao :: _ ->
            Decode.succeed direcao

        [] ->
            Decode.fail ("Direcao desconhecida: " ++ nome)


exibir : Ajuda -> Html Never
exibir ajuda =
    case Decode.decodeValue planoDecoder ajuda.dados of
        Ok plano ->
            div [ class "modulo" ]
                [ p [ class "modulo-titulo" ] [ text "Ate o primeiro empurrao" ]
                , ol [ class "lista" ] (List.map (\linha -> li [] [ text linha ]) (roteiro plano))
                ]

        Err _ ->
            p [ class "legenda" ] [ text "Sem empurrao a mostrar." ]
