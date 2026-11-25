module Fases.AlcanceTest exposing (suite)

import Ajuda exposing (Destaque, Tabuleiro(..))
import Expect
import Fases.Alcance exposing (porLinha)
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Fases.Alcance"
        [ test "conta as 17 casas alcancadas por linha" <|
            \_ ->
                porLinha destaques
                    |> Expect.equal [ ( 1, 5 ), ( 2, 2 ), ( 3, 5 ), ( 4, 5 ) ]
        , test "lista vazia nao tem contagens" <|
            \_ ->
                porLinha [] |> Expect.equal []
        ]


destaques : List Destaque
destaques =
    List.map destaque
        [ ( 1, 1 )
        , ( 1, 2 )
        , ( 1, 3 )
        , ( 1, 4 )
        , ( 1, 5 )
        , ( 2, 1 )
        , ( 2, 5 )
        , ( 3, 1 )
        , ( 3, 2 )
        , ( 3, 3 )
        , ( 3, 4 )
        , ( 3, 5 )
        , ( 4, 1 )
        , ( 4, 2 )
        , ( 4, 3 )
        , ( 4, 4 )
        , ( 4, 5 )
        ]


destaque : ( Int, Int ) -> Destaque
destaque posicao =
    { tabuleiro = NoArmazem
    , posicao = posicao
    , marca = "alcance"
    }
