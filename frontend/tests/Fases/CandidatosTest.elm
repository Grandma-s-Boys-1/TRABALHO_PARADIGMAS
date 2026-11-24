module Fases.CandidatosTest exposing (suite)

import Ajuda exposing (TipoConsulta(..))
import Expect
import Fases.Candidatos exposing (candidatosDecoder, modulo, teclas)
import Json.Decode as Decode
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Fases.Candidatos"
        [ test "so o 3 fica ativo" <|
            \_ ->
                teclas [ 3 ]
                    |> Expect.equal [ ( 1, False ), ( 2, False ), ( 3, True ), ( 4, False ) ]
        , test "sem candidatos todos ficam inativos" <|
            \_ ->
                teclas []
                    |> Expect.equal [ ( 1, False ), ( 2, False ), ( 3, False ), ( 4, False ) ]
        , test "decoder le os candidatos" <|
            \_ ->
                Decode.decodeString candidatosDecoder """{"candidatos": [3]}"""
                    |> Expect.equal (Ok [ 3 ])
        , test "decoder recusa dados invalidos" <|
            \_ ->
                Decode.decodeString candidatosDecoder """{"candidatos": "3"}"""
                    |> Expect.err
        , test "modulo consulta a casa selecionada" <|
            \_ ->
                ( modulo.id, modulo.consultas )
                    |> Expect.equal ( "candidatos", [ PorCasa ] )
        ]
