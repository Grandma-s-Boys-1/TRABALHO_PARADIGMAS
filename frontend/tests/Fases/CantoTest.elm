module Fases.CantoTest exposing (suite)

import Ajuda exposing (Ajuda)
import Expect
import Fases.Canto as Canto
import Json.Encode as Encode
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


ajudaCom : List (List Int) -> Ajuda
ajudaCom presas =
    { texto = ""
    , destaques = []
    , dados = Encode.object [ ( "presas", Encode.list (Encode.list Encode.int) presas ) ]
    }


suite : Test
suite =
    describe "Fases.Canto"
        [ test "sem caixas presas" <|
            \_ ->
                Canto.avisos []
                    |> Expect.equal [ "Nenhuma caixa presa em canto." ]
        , test "caixa 2 presa em L1C1" <|
            \_ ->
                Canto.avisos [ { caixa = 2, posicao = ( 1, 1 ) } ]
                    |> Expect.equal [ "Caixa 2 presa em L1C1: reinicie a fase." ]
        , test "decoder le a lista [n, l, c]" <|
            \_ ->
                Canto.modulo.exibir (ajudaCom [ [ 2, 1, 1 ] ])
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Caixa 2 presa em L1C1: reinicie a fase." ]
        , test "decoder recusa lista curta" <|
            \_ ->
                Canto.modulo.exibir (ajudaCom [ [ 2, 1 ] ])
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Dados invalidos." ]
        ]
