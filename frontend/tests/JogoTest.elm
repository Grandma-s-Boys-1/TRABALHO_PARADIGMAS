module JogoTest exposing (suite)

import Dict
import Expect
import Jogo exposing (Casa(..), Conteudo(..), Estado, Fase, Posicao, Recusa(..), Regra(..))
import Set
import Test exposing (Test, describe, test)


pistas : List (List Int)
pistas =
    [ [ 1, 0, 0, 4 ], [ 3, 4, 0, 0 ], [ 2, 1, 0, 3 ], [ 4, 3, 0, 1 ] ]


inicio : Estado
inicio =
    { jogador = ( 1, 3 )
    , caixas = [ { numero = 2, posicao = ( 2, 2 ) }, { numero = 4, posicao = ( 2, 4 ) } ]
    , entradas = Dict.empty
    }


fase : Fase
fase =
    { id = "comum"
    , nome = "Fase comum"
    , armazem =
        { linhas = 4
        , colunas = 5
        , paredes = []
        , alvos = [ { letra = "A", posicao = ( 3, 2 ) }, { letra = "B", posicao = ( 3, 4 ) } ]
        }
    , regra =
        Jogo.montarSudoku pistas
            [ { letra = "A", posicao = ( 1, 2 ) }
            , { letra = "B", posicao = ( 3, 3 ) }
            ]
            |> Result.map Combinada
            |> Result.withDefault Classica
    , inicio = inicio
    }


comCaixas : List ( Int, Posicao ) -> Estado
comCaixas caixas =
    { inicio | caixas = List.map caixa caixas }


caixa : ( Int, Posicao ) -> Jogo.Caixa
caixa ( numero, posicao ) =
    { numero = numero, posicao = posicao }


suite : Test
suite =
    describe "Jogo"
        [ test "pista nao aceita digitacao" <|
            \_ ->
                Jogo.digitar fase ( 1, 1 ) (Just 2) inicio
                    |> Expect.equal (Err (PistaFixa 1))
        , test "casa ligada nao aceita digitacao" <|
            \_ ->
                Jogo.digitar fase ( 1, 2 ) (Just 2) inicio
                    |> Expect.equal (Err (LigadaAoAlvo "A"))
        , test "casa editavel aceita e apaga" <|
            \_ ->
                Jogo.digitar fase ( 1, 3 ) (Just 3) inicio
                    |> Result.andThen (Jogo.digitar fase ( 1, 3 ) Nothing)
                    |> Expect.equal (Ok inicio)
        , test "fase classica nao tem grade" <|
            \_ ->
                Jogo.digitar { fase | regra = Classica } ( 1, 3 ) (Just 3) inicio
                    |> Expect.equal (Err SemGrade)
        , test "caixa no alvo preenche a casa ligada" <|
            \_ ->
                Jogo.valorCasa fase (comCaixas [ ( 2, ( 3, 2 ) ), ( 4, ( 2, 4 ) ) ]) ( 1, 2 )
                    |> Expect.equal (Just 2)
        , test "jogada que tira a caixa do alvo limpa a casa ligada" <|
            \_ ->
                let
                    noAlvo =
                        comCaixas [ ( 2, ( 3, 2 ) ), ( 4, ( 2, 4 ) ) ]

                    foraDoAlvo =
                        comCaixas [ ( 2, ( 4, 2 ) ), ( 4, ( 2, 4 ) ) ]
                in
                ( Jogo.valorCasa fase noAlvo ( 1, 2 ), Jogo.valorCasa fase foraDoAlvo ( 1, 2 ) )
                    |> Expect.equal ( Just 2, Nothing )
        , test "inicio sem conflitos" <|
            \_ ->
                Jogo.conflitos fase inicio
                    |> Expect.equal Set.empty
        , test "caixas trocadas geram conflitos na linha 1" <|
            \_ ->
                Jogo.conflitos fase (comCaixas [ ( 4, ( 3, 2 ) ), ( 2, ( 3, 4 ) ) ])
                    |> Set.member ( 1, 2 )
                    |> Expect.equal True
        , test "pistas malformadas sao recusadas" <|
            \_ ->
                Jogo.montarSudoku [ [ 1, 2 ] ] []
                    |> Expect.err
        , test "entradas fora da faixa sao recusadas" <|
            \_ ->
                Jogo.lerEntradas [ [ 5, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ], [ 0, 0, 0, 0 ] ]
                    |> Expect.err
        , test "borda, jogador e caixa no armazem" <|
            \_ ->
                List.map (Jogo.conteudoEm fase inicio) [ ( 0, 3 ), ( 1, 3 ), ( 2, 2 ), ( 4, 5 ) ]
                    |> Expect.equal [ Parede, ComJogador, ComCaixa 2, Chao ]
        , test "tipos de casa da grade" <|
            \_ ->
                List.map (Jogo.casaEm fase) [ ( 1, 1 ), ( 1, 2 ), ( 1, 3 ) ]
                    |> Expect.equal [ Just (Pista 1), Just (Ligada "A"), Just Editavel ]
        ]
