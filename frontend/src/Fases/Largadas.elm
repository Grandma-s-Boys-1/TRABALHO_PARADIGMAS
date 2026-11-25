module Fases.Largadas exposing (Opcao, descrever, modulo, opcoesDecoder)

import Ajuda exposing (Ajuda, Modulo, TipoConsulta(..))
import Html exposing (Html, div, li, p, text, ul)
import Html.Attributes exposing (class)
import Json.Decode as Decode exposing (Decoder)


type alias Opcao =
    { caixa : Int
    , direcao : String
    , passos : Int
    }


modulo : Modulo
modulo =
    { id = "largadas"
    , consultas = [ PorPadrao ]
    , destacar = .destaques
    , exibir = exibir
    }


descrever : Opcao -> String
descrever opcao =
    "Caixa "
        ++ String.fromInt opcao.caixa
        ++ " para "
        ++ opcao.direcao
        ++ ": "
        ++ String.fromInt opcao.passos
        ++ " passos ate vencer"


opcoesDecoder : Decoder (List Opcao)
opcoesDecoder =
    Decode.field "opcoes"
        (Decode.list
            (Decode.map3 Opcao
                (Decode.index 0 Decode.int)
                (Decode.index 1 Decode.string)
                (Decode.index 2 Decode.int)
            )
        )


exibir : Ajuda -> Html Never
exibir ajuda =
    div [ class "modulo" ]
        [ p [ class "modulo-titulo" ] [ text "Largadas vencedoras" ]
        , case Decode.decodeValue opcoesDecoder ajuda.dados of
            Ok [] ->
                p [ class "mensagem mensagem--alerta" ] [ text ajuda.texto ]

            Ok opcoes ->
                ul [ class "lista" ] (List.map (\o -> li [] [ text (descrever o) ]) opcoes)

            Err _ ->
                p [ class "mensagem mensagem--alerta" ] [ text "Dados da ajuda invalidos." ]
        ]
