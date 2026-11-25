module Fases.Candidatos exposing (candidatosDecoder, modulo, teclas)

import Ajuda exposing (Ajuda, Modulo, TipoConsulta(..))
import Html exposing (Html, div, p, span, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode exposing (Decoder)


modulo : Modulo
modulo =
    { id = "candidatos"
    , consultas = [ PorCasa ]
    , destacar = .destaques
    , exibir = exibir
    }


teclas : List Int -> List ( Int, Bool )
teclas candidatos =
    List.map (\numero -> ( numero, List.member numero candidatos )) (List.range 1 4)


candidatosDecoder : Decoder (List Int)
candidatosDecoder =
    Decode.field "candidatos" (Decode.list Decode.int)


exibir : Ajuda -> Html Never
exibir ajuda =
    case Decode.decodeValue candidatosDecoder ajuda.dados of
        Ok candidatos ->
            div [ class "modulo" ]
                [ p [ class "modulo-titulo" ] [ text "Candidatos" ]
                , div [ class "chips" ] (List.map chip (teclas candidatos))
                ]

        Err _ ->
            p [ class "legenda" ] [ text "Dados invalidos." ]


chip : ( Int, Bool ) -> Html Never
chip ( numero, ativo ) =
    span [ class "chip", class (estadoChip ativo) ] [ text (String.fromInt numero) ]


estadoChip : Bool -> String
estadoChip ativo =
    if ativo then
        "chip--ativo"

    else
        "chip--inativo"
