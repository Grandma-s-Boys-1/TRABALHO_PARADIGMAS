module Fases.LargadasTest exposing (suite)

import Expect
import Fases.Largadas exposing (descrever, opcoesDecoder)
import Json.Decode as Decode
import Test exposing (Test, describe, test)


exemplo : String
exemplo =
    """{"opcoes": [[2, "baixo", 9], [4, "baixo", 9]]}"""


suite : Test
suite =
    describe "Fases.Largadas"
        [ test "descrever" <|
            \_ ->
                descrever { caixa = 2, direcao = "baixo", passos = 9 }
                    |> Expect.equal "Caixa 2 para baixo: 9 passos ate vencer"
        , test "decoder da lista do exemplo" <|
            \_ ->
                Decode.decodeString opcoesDecoder exemplo
                    |> Expect.equal
                        (Ok
                            [ { caixa = 2, direcao = "baixo", passos = 9 }
                            , { caixa = 4, direcao = "baixo", passos = 9 }
                            ]
                        )
        , test "item com tipo errado" <|
            \_ ->
                Decode.decodeString opcoesDecoder """{"opcoes": [["2", "baixo", 9]]}"""
                    |> Expect.err
        ]
