module Fases.DicaTest exposing (suite)

import Ajuda exposing (TipoConsulta(..))
import Expect
import Fases.Dica exposing (modulo, planoDecoder, roteiro)
import Jogo exposing (Direcao(..))
import Json.Decode as Decode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Fases.Dica"
        [ test "caminhadas antes do empurrao" <|
            \_ ->
                roteiro { caminhada = [ Cima, Cima, Direita ], caixa = 4, direcao = Baixo }
                    |> Expect.equal
                        [ "Caminhar para cima"
                        , "Caminhar para cima"
                        , "Caminhar para direita"
                        , "Empurrar a caixa 4 para baixo"
                        ]
        , test "empurrao imediato" <|
            \_ ->
                roteiro { caminhada = [], caixa = 2, direcao = Baixo }
                    |> Expect.equal [ "Empurrar a caixa 2 para baixo" ]
        , test "decoder le o plano" <|
            \_ ->
                Decode.decodeString planoDecoder
                    """{"caminhada": ["cima", "cima", "direita"], "caixa": 4, "direcao": "baixo"}"""
                    |> Expect.equal (Ok { caminhada = [ Cima, Cima, Direita ], caixa = 4, direcao = Baixo })
        , test "decoder recusa direcao desconhecida" <|
            \_ ->
                Decode.decodeString planoDecoder
                    """{"caminhada": ["diagonal"], "caixa": 4, "direcao": "baixo"}"""
                    |> Expect.err
        , test "decoder recusa dados vazios" <|
            \_ ->
                Decode.decodeString planoDecoder "{}"
                    |> Expect.err
        , test "modulo usa a consulta padrao" <|
            \_ ->
                ( modulo.id, modulo.consultas )
                    |> Expect.equal ( "dica", [ PorPadrao ] )
        ]
