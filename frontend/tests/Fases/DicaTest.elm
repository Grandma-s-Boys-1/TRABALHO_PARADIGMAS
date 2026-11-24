module Fases.DicaTest exposing (suite)

import Ajuda exposing (TipoConsulta(..))
import Expect
import Fases.Dica exposing (modulo, planoDecoder, roteiro)
import Json.Decode as Decode
import Test exposing (Test, describe, test)


exemplo : { caminhada : List String, caixa : Int, empurrao : String, total : Int }
exemplo =
    { caminhada = [ "cima", "cima", "direita" ], caixa = 4, empurrao = "baixo", total = 8 }


suite : Test
suite =
    describe "Fases.Dica"
        [ test "roteiro do exemplo" <|
            \_ ->
                roteiro exemplo
                    |> Expect.equal
                        [ "Caminhe: C C D (3 passos)"
                        , "Empurre a caixa 4: baixo"
                        , "Rota minima: 8 passos"
                        ]
        , test "roteiro sem caminhada" <|
            \_ ->
                roteiro { exemplo | caminhada = [], total = 5 }
                    |> Expect.equal
                        [ "Caminhe: nenhum passo"
                        , "Empurre a caixa 4: baixo"
                        , "Rota minima: 5 passos"
                        ]
        , test "decoder le o plano" <|
            \_ ->
                Decode.decodeString planoDecoder
                    """{"caminhada": ["cima", "cima", "direita"], "caixa": 4,
                        "empurrao": "baixo", "total": 8}"""
                    |> Expect.equal (Ok exemplo)
        , test "decoder com campo ausente" <|
            \_ ->
                Decode.decodeString planoDecoder
                    """{"caminhada": ["cima"], "caixa": 4, "empurrao": "baixo"}"""
                    |> Expect.err
        , test "modulo usa a consulta padrao" <|
            \_ ->
                ( modulo.id, modulo.consultas )
                    |> Expect.equal ( "dica", [ PorPadrao ] )
        ]
