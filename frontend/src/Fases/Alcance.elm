module Fases.Alcance exposing (modulo, porLinha)

import Ajuda exposing (Ajuda, Destaque, Modulo, TipoConsulta(..))
import Dict exposing (Dict)
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import Json.Decode as Decode


modulo : Modulo
modulo =
    { id = "alcance"
    , consultas = [ PorPadrao ]
    , destacar = .destaques
    , exibir = exibir
    }


porLinha : List Destaque -> List ( Int, Int )
porLinha destaques =
    destaques
        |> List.foldl contar Dict.empty
        |> Dict.toList


contar : Destaque -> Dict Int Int -> Dict Int Int
contar destaque contagens =
    if destaque.marca == "alcance" then
        let
            ( linha, _ ) =
                destaque.posicao
        in
        Dict.update linha (\atual -> Just (Maybe.withDefault 0 atual + 1)) contagens

    else
        contagens


exibir : Ajuda -> Html Never
exibir ajuda =
    case Decode.decodeValue (Decode.field "casas" Decode.int) ajuda.dados of
        Ok total ->
            div [ class "modulo" ]
                (p [ class "modulo-titulo" ] [ text ("Total: " ++ String.fromInt total ++ " casas") ]
                    :: List.map exibirLinha (porLinha ajuda.destaques)
                )

        Err _ ->
            p [ class "modulo-titulo" ] [ text "Dados invalidos." ]


exibirLinha : ( Int, Int ) -> Html Never
exibirLinha ( linha, total ) =
    p [] [ text ("Linha " ++ String.fromInt linha ++ ": " ++ String.fromInt total ++ " casas") ]
