module Fases.TrocaTest exposing (suite)

import Ajuda exposing (TipoConsulta(..))
import Expect
import Fases.Troca exposing (Conflitos, conflitosDecoder, modulo, resumo)
import Json.Decode as Decode
import Test exposing (Test, describe, test)


exemplo : String
exemplo =
    """{"linhas": [1, 3], "colunas": [2, 3], "blocos": [1, 4]}"""


trocadas : Conflitos
trocadas =
    { linhas = [ 1, 3 ], colunas = [ 2, 3 ], blocos = [ 1, 4 ] }


suite : Test
suite =
    describe "Fases.Troca"
        [ test "resumo das caixas trocadas" <|
            \_ ->
                resumo trocadas
                    |> Expect.equal [ "Linhas: 1, 3", "Colunas: 2, 3", "Blocos: 1, 4" ]
        , test "sem conflitos o resumo fica vazio" <|
            \_ ->
                resumo { linhas = [], colunas = [], blocos = [] }
                    |> Expect.equal []
        , test "grupos vazios nao aparecem" <|
            \_ ->
                resumo { linhas = [], colunas = [ 4 ], blocos = [] }
                    |> Expect.equal [ "Colunas: 4" ]
        , test "decoder le os dados do diagnostico" <|
            \_ ->
                Decode.decodeString conflitosDecoder exemplo
                    |> Expect.equal (Ok trocadas)
        , test "decoder recusa campo ausente" <|
            \_ ->
                Decode.decodeString conflitosDecoder """{"linhas": [1], "colunas": []}"""
                    |> Expect.err
        , test "modulo diagnostica por padrao" <|
            \_ ->
                ( modulo.id, modulo.consultas )
                    |> Expect.equal ( "troca", [ PorPadrao ] )
        ]
