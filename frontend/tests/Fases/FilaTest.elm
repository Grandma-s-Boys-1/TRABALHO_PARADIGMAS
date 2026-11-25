module Fases.FilaTest exposing (suite)

import Ajuda exposing (Ajuda, Tabuleiro(..), TipoConsulta(..))
import Expect
import Fases.Fila exposing (destacarFila, modulo)
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (Test, describe, test)


ajudaCom : String -> Ajuda
ajudaCom dados =
    { texto = "Bloqueado."
    , destaques = []
    , dados =
        Decode.decodeString Decode.value dados
            |> Result.withDefault Encode.null
    }


resumo : Ajuda.Destaque -> ( Tabuleiro, ( Int, Int ), String )
resumo destaque =
    ( destaque.tabuleiro, destaque.posicao, destaque.marca )


suite : Test
suite =
    describe "Fases.Fila"
        [ test "fila destaca as duas caixas" <|
            \_ ->
                ajudaCom """{"motivo": "fila", "caixas": [[2, 2, 2], [4, 2, 3]]}"""
                    |> destacarFila
                    |> List.map resumo
                    |> Expect.equal
                        [ ( NoArmazem, ( 2, 2 ), "alerta" )
                        , ( NoArmazem, ( 2, 3 ), "alerta" )
                        ]
        , test "parede nao destaca caixas" <|
            \_ ->
                ajudaCom """{"motivo": "parede", "caixas": []}"""
                    |> destacarFila
                    |> Expect.equal []
        , test "dados ilegiveis nao destacam nada" <|
            \_ ->
                ajudaCom """{"motivo": "fila", "caixas": [[2, 2]]}"""
                    |> destacarFila
                    |> Expect.equal []
        , test "consulta por direcao" <|
            \_ ->
                modulo.consultas
                    |> Expect.equal [ PorDirecao ]
        ]
