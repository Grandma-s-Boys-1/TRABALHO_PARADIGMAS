module Fases.Canto exposing (avisos, modulo)

import Ajuda exposing (Ajuda, Modulo, TipoConsulta(..))
import Html exposing (Html, div, li, p, text, ul)
import Html.Attributes exposing (class)
import Jogo
import Json.Decode as Decode exposing (Decoder)


type alias Presa =
    { caixa : Int
    , posicao : ( Int, Int )
    }


modulo : Modulo
modulo =
    { id = "canto"
    , consultas = [ PorPadrao ]
    , destacar = .destaques
    , exibir = exibir
    }


presaDecoder : Decoder Presa
presaDecoder =
    Decode.map3 (\caixa linha coluna -> Presa caixa ( linha, coluna ))
        (Decode.index 0 Decode.int)
        (Decode.index 1 Decode.int)
        (Decode.index 2 Decode.int)


presasDecoder : Decoder (List Presa)
presasDecoder =
    Decode.field "presas" (Decode.list presaDecoder)


avisos : List Presa -> List String
avisos presas =
    case presas of
        [] ->
            [ "Nenhuma caixa presa em canto." ]

        _ ->
            List.map aviso presas


aviso : Presa -> String
aviso presa =
    "Caixa "
        ++ String.fromInt presa.caixa
        ++ " presa em "
        ++ Jogo.rotulo presa.posicao
        ++ ": reinicie a fase."


exibir : Ajuda -> Html Never
exibir ajuda =
    case Decode.decodeValue presasDecoder ajuda.dados of
        Ok presas ->
            div [ class "modulo" ]
                [ p [ class "modulo-titulo" ] [ text "Caixas presas em canto" ]
                , ul [ class "lista" ] (List.map item (avisos presas))
                ]

        Err _ ->
            p [ class "mensagem mensagem--alerta" ] [ text "Dados invalidos." ]


item : String -> Html Never
item linha =
    li [] [ text linha ]
