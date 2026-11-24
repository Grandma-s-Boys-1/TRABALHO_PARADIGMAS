module Ajuda exposing
    ( Ajuda
    , Consulta(..)
    , Destaque
    , Modulo
    , Tabuleiro(..)
    , TipoConsulta(..)
    , marcasEm
    )

import Html exposing (Html)
import Jogo exposing (Direcao, Posicao)
import Json.Decode as Decode


type Tabuleiro
    = NoArmazem
    | NoSudoku


type alias Destaque =
    { tabuleiro : Tabuleiro
    , posicao : Posicao
    , marca : String
    }


type alias Ajuda =
    { texto : String
    , destaques : List Destaque
    , dados : Decode.Value
    }


type Consulta
    = Padrao
    | NaCasa Posicao
    | NaDirecao Direcao


type TipoConsulta
    = PorPadrao
    | PorCasa
    | PorDirecao


type alias Modulo =
    { id : String
    , consultas : List TipoConsulta
    , destacar : Ajuda -> List Destaque
    , exibir : Ajuda -> Html Never
    }


marcasEm : Tabuleiro -> Posicao -> List Destaque -> List String
marcasEm tabuleiro posicao destaques =
    destaques
        |> List.filter (\d -> d.tabuleiro == tabuleiro && d.posicao == posicao)
        |> List.map .marca
