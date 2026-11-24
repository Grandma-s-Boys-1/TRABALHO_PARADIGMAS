module ApiTest exposing (suite)

import Ajuda exposing (Tabuleiro(..))
import Api exposing (Movimento(..))
import Expect
import Jogo exposing (Casa(..), Regra(..), Situacao(..))
import Json.Decode as Decode
import Test exposing (Test, describe, test)


inicio : String
inicio =
    """
    {"jogador": {"linha": 1, "coluna": 3},
     "caixas": [{"numero": 2, "linha": 2, "coluna": 2},
                {"numero": 4, "linha": 2, "coluna": 4}],
     "entradas": [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]}
    """


fase : String -> String
fase sudoku =
    """
    {"id": "comum",
     "nome": "Fase comum",
     "armazem": {"linhas": 4, "colunas": 5, "paredes": [],
                 "alvos": [{"letra": "A", "linha": 3, "coluna": 2},
                           {"letra": "B", "linha": 3, "coluna": 4}]},
     "sudoku": """ ++ sudoku ++ """,
     "inicio": """ ++ inicio ++ "}"


sudokuValido : String
sudokuValido =
    """
    {"pistas": [[1, 0, 0, 4], [3, 4, 0, 0], [2, 1, 0, 3], [4, 3, 0, 1]],
     "ligacoes": [{"letra": "A", "linha": 1, "coluna": 2},
                  {"letra": "B", "linha": 3, "coluna": 3}]}
    """


resposta : String -> String
resposta movimento =
    """{"estado": """
        ++ inicio
        ++ """, "movimento": \""""
        ++ movimento
        ++ """", "situacao": "jogando"}"""


ajuda : String -> String
ajuda tabuleiro =
    """
    {"texto": "Digite 3 em L1C3.",
     "destaques": [{"tabuleiro": \""""
        ++ tabuleiro
        ++ """", "linha": 1, "coluna": 3, "marca": "dica"}],
     "dados": {"valor": 3}}
    """


resumo : Ajuda.Destaque -> ( Tabuleiro, Jogo.Posicao, String )
resumo destaque =
    ( destaque.tabuleiro, destaque.posicao, destaque.marca )


regraDe : String -> Result Decode.Error Regra
regraDe sudoku =
    Decode.decodeString Api.faseDecoder (fase sudoku) |> Result.map .regra


suite : Test
suite =
    describe "Api"
        [ test "fase combinada marca a casa ligada" <|
            \_ ->
                Decode.decodeString Api.faseDecoder (fase sudokuValido)
                    |> Result.map (\decodificada -> Jogo.casaEm decodificada ( 1, 2 ))
                    |> Expect.equal (Ok (Just (Ligada "A")))
        , test "sudoku nulo vira fase classica" <|
            \_ ->
                regraDe "null"
                    |> Expect.equal (Ok Classica)
        , test "pistas malformadas sao recusadas" <|
            \_ ->
                regraDe """{"pistas": [[1, 0, 0]], "ligacoes": []}"""
                    |> Expect.err
        , test "resposta de jogada bloqueada" <|
            \_ ->
                Decode.decodeString Api.respostaDecoder (resposta "bloqueado")
                    |> Result.map (\r -> ( r.movimento, r.situacao ))
                    |> Expect.equal (Ok ( Bloqueado, EmJogo ))
        , test "movimento desconhecido e recusado" <|
            \_ ->
                Decode.decodeString Api.respostaDecoder (resposta "voo")
                    |> Expect.err
        , test "ajuda com destaque na grade" <|
            \_ ->
                Decode.decodeString Api.ajudaDecoder (ajuda "sudoku")
                    |> Result.map (.destaques >> List.map resumo)
                    |> Expect.equal (Ok [ ( NoSudoku, ( 1, 3 ), "dica" ) ])
        , test "tabuleiro desconhecido e recusado" <|
            \_ ->
                Decode.decodeString Api.ajudaDecoder (ajuda "mesa")
                    |> Expect.err
        ]
