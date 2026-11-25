module Fases.Troca exposing (Conflitos, conflitosDecoder, modulo, resumo)

import Ajuda exposing (Ajuda, Modulo, TipoConsulta(..))
import Html exposing (Html, div, li, p, text, ul)
import Html.Attributes exposing (class)
import Json.Decode as Decode exposing (Decoder)


type alias Conflitos =
    { linhas : List Int
    , colunas : List Int
    , blocos : List Int
    }


modulo : Modulo
modulo =
    { id = "troca"
    , consultas = [ PorPadrao ]
    , destacar = .destaques
    , exibir = exibir
    }


resumo : Conflitos -> List String
resumo conflitos =
    [ ( "Linhas", conflitos.linhas )
    , ( "Colunas", conflitos.colunas )
    , ( "Blocos", conflitos.blocos )
    ]
        |> List.filter (\( _, numeros ) -> not (List.isEmpty numeros))
        |> List.map grupo


grupo : ( String, List Int ) -> String
grupo ( nome, numeros ) =
    nome ++ ": " ++ String.join ", " (List.map String.fromInt numeros)


conflitosDecoder : Decoder Conflitos
conflitosDecoder =
    Decode.map3 Conflitos
        (Decode.field "linhas" (Decode.list Decode.int))
        (Decode.field "colunas" (Decode.list Decode.int))
        (Decode.field "blocos" (Decode.list Decode.int))


exibir : Ajuda -> Html Never
exibir ajuda =
    div [ class "modulo" ]
        [ p [ class "modulo-titulo" ] [ text "Unidades em conflito" ]
        , case Decode.decodeValue conflitosDecoder ajuda.dados of
            Ok conflitos ->
                lista (resumo conflitos)

            Err _ ->
                p [ class "mensagem mensagem--alerta" ] [ text "Dados invalidos." ]
        ]


lista : List String -> Html Never
lista linhas =
    if List.isEmpty linhas then
        p [ class "legenda" ] [ text "Nenhuma unidade listada." ]

    else
        div [ class "mensagem mensagem--alerta" ]
            [ ul [ class "lista" ] (List.map (\linha -> li [] [ text linha ]) linhas) ]
