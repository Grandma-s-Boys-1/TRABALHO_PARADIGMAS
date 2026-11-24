module Fases.Fila exposing (destacarFila, modulo)

import Ajuda exposing (Ajuda, Destaque, Modulo, Tabuleiro(..), TipoConsulta(..))
import Html exposing (Html, div, li, p, text, ul)
import Html.Attributes exposing (class)
import Jogo exposing (Posicao)
import Json.Decode as Decode exposing (Decoder)


type Motivo
    = Fila
    | CaixaNaParede
    | Parede
    | Livre


type alias CaixaBloqueada =
    { numero : Int
    , posicao : Posicao
    }


type alias Bloqueio =
    { motivo : Motivo
    , caixas : List CaixaBloqueada
    }


modulo : Modulo
modulo =
    { id = "fila"
    , consultas = [ PorDirecao ]
    , destacar = destacarFila
    , exibir = exibir
    }


destacarFila : Ajuda -> List Destaque
destacarFila ajuda =
    case Decode.decodeValue (Decode.field "caixas" (Decode.list caixaDecoder)) ajuda.dados of
        Ok caixas ->
            List.map alerta caixas

        Err _ ->
            []


alerta : CaixaBloqueada -> Destaque
alerta caixa =
    { tabuleiro = NoArmazem, posicao = caixa.posicao, marca = "alerta" }


bloqueioDecoder : Decoder Bloqueio
bloqueioDecoder =
    Decode.map2 Bloqueio
        (Decode.field "motivo" (Decode.string |> Decode.andThen motivoDecoder))
        (Decode.field "caixas" (Decode.list caixaDecoder))


motivoDecoder : String -> Decoder Motivo
motivoDecoder nome =
    case nome of
        "fila" ->
            Decode.succeed Fila

        "caixa_na_parede" ->
            Decode.succeed CaixaNaParede

        "parede" ->
            Decode.succeed Parede

        "livre" ->
            Decode.succeed Livre

        _ ->
            Decode.fail ("Motivo desconhecido: " ++ nome)


caixaDecoder : Decoder CaixaBloqueada
caixaDecoder =
    Decode.map3 (\numero linha coluna -> CaixaBloqueada numero ( linha, coluna ))
        (Decode.index 0 Decode.int)
        (Decode.index 1 Decode.int)
        (Decode.index 2 Decode.int)


exibir : Ajuda -> Html Never
exibir ajuda =
    case Decode.decodeValue bloqueioDecoder ajuda.dados of
        Ok bloqueio ->
            div [ class "modulo" ]
                [ p [ class "modulo-titulo" ] [ text ("Motivo: " ++ descrever bloqueio.motivo) ]
                , listaCaixas bloqueio.caixas
                ]

        Err _ ->
            p [ class "mensagem mensagem--alerta" ] [ text "Dados do bloqueio ilegiveis." ]


descrever : Motivo -> String
descrever motivo =
    case motivo of
        Fila ->
            "fila de duas caixas"

        CaixaNaParede ->
            "caixa encostada na parede"

        Parede ->
            "parede na frente do jogador"

        Livre ->
            "nenhum, o passo e legal"


listaCaixas : List CaixaBloqueada -> Html Never
listaCaixas caixas =
    if List.isEmpty caixas then
        p [ class "legenda" ] [ text "Nenhuma caixa envolvida." ]

    else
        ul [ class "lista" ] (List.map itemCaixa caixas)


itemCaixa : CaixaBloqueada -> Html Never
itemCaixa caixa =
    let
        ( linha, coluna ) =
            caixa.posicao
    in
    li []
        [ text
            ("Caixa "
                ++ String.fromInt caixa.numero
                ++ " em L"
                ++ String.fromInt linha
                ++ "C"
                ++ String.fromInt coluna
            )
        ]
