module Jogo exposing
    ( Alvo
    , Armazem
    , Caixa
    , Casa(..)
    , Conteudo(..)
    , Direcao(..)
    , Estado
    , Fase
    , Ligacao
    , Posicao
    , Recusa(..)
    , Regra(..)
    , Situacao(..)
    , alvoEm
    , caixaEm
    , casaEm
    , conflitos
    , conteudoEm
    , digitar
    , direcoes
    , lerEntradas
    , letraDirecao
    , montarSudoku
    , nomeDirecao
    , posicoesArmazem
    , posicoesGrade
    , recusaTexto
    , rotulo
    , valorCasa
    )

import Dict exposing (Dict)
import Set exposing (Set)


type alias Posicao =
    ( Int, Int )


type Direcao
    = Cima
    | Baixo
    | Esquerda
    | Direita


type alias Caixa =
    { numero : Int
    , posicao : Posicao
    }


type alias Alvo =
    { letra : String
    , posicao : Posicao
    }


type alias Ligacao =
    { letra : String
    , posicao : Posicao
    }


type alias Armazem =
    { linhas : Int
    , colunas : Int
    , paredes : List Posicao
    , alvos : List Alvo
    }


type Casa
    = Pista Int
    | Editavel
    | Ligada String


type Regra
    = Classica
    | Combinada (Dict Posicao Casa)


type alias Estado =
    { jogador : Posicao
    , caixas : List Caixa
    , entradas : Dict Posicao Int
    }


type alias Fase =
    { id : String
    , nome : String
    , armazem : Armazem
    , regra : Regra
    , inicio : Estado
    }


type Situacao
    = EmJogo
    | Vitoria


type Recusa
    = PistaFixa Int
    | LigadaAoAlvo String
    | SemGrade


type Conteudo
    = Parede
    | Chao
    | ComJogador
    | ComCaixa Int


direcoes : List Direcao
direcoes =
    [ Cima, Baixo, Esquerda, Direita ]


nomeDirecao : Direcao -> String
nomeDirecao direcao =
    case direcao of
        Cima ->
            "cima"

        Baixo ->
            "baixo"

        Esquerda ->
            "esquerda"

        Direita ->
            "direita"


letraDirecao : Direcao -> String
letraDirecao direcao =
    case direcao of
        Cima ->
            "C"

        Baixo ->
            "B"

        Esquerda ->
            "E"

        Direita ->
            "D"


rotulo : Posicao -> String
rotulo ( linha, coluna ) =
    "L" ++ String.fromInt linha ++ "C" ++ String.fromInt coluna


posicoesGrade : List Posicao
posicoesGrade =
    List.concatMap (\linha -> List.map (Tuple.pair linha) (List.range 1 4)) (List.range 1 4)


posicoesArmazem : Armazem -> List Posicao
posicoesArmazem armazem =
    List.concatMap
        (\linha -> List.map (Tuple.pair linha) (List.range 0 (armazem.colunas + 1)))
        (List.range 0 (armazem.linhas + 1))


elemento : Int -> List a -> Maybe a
elemento indice lista =
    List.head (List.drop (indice - 1) lista)


quatroPorQuatro : List (List Int) -> Bool
quatroPorQuatro linhas =
    List.length linhas == 4 && List.all (\linha -> List.length linha == 4) linhas


montarSudoku : List (List Int) -> List Ligacao -> Result String (Dict Posicao Casa)
montarSudoku pistas ligacoes =
    if quatroPorQuatro pistas then
        posicoesGrade
            |> List.map (\posicao -> ( posicao, classificar pistas ligacoes posicao ))
            |> Dict.fromList
            |> Ok

    else
        Err "A grade de pistas deve ter 4 linhas de 4 numeros."


classificar : List (List Int) -> List Ligacao -> Posicao -> Casa
classificar pistas ligacoes (( linha, coluna ) as posicao) =
    case List.filter (\ligacao -> ligacao.posicao == posicao) ligacoes of
        ligacao :: _ ->
            Ligada ligacao.letra

        [] ->
            case elemento linha pistas |> Maybe.andThen (elemento coluna) |> Maybe.withDefault 0 of
                0 ->
                    Editavel

                valor ->
                    Pista valor


lerEntradas : List (List Int) -> Result String (Dict Posicao Int)
lerEntradas linhas =
    let
        valores =
            List.concat linhas
    in
    if quatroPorQuatro linhas && List.all (\valor -> valor >= 0 && valor <= 4) valores then
        List.map2 Tuple.pair posicoesGrade valores
            |> List.filter (\( _, valor ) -> valor > 0)
            |> Dict.fromList
            |> Ok

    else
        Err "As entradas devem ter 4 linhas de 4 numeros entre 0 e 4."


casaEm : Fase -> Posicao -> Maybe Casa
casaEm fase posicao =
    case fase.regra of
        Classica ->
            Nothing

        Combinada casas ->
            Dict.get posicao casas


caixaEm : Posicao -> Estado -> Maybe Int
caixaEm posicao estado =
    estado.caixas
        |> List.filter (\caixa -> caixa.posicao == posicao)
        |> List.head
        |> Maybe.map .numero


alvoEm : Armazem -> Posicao -> Maybe String
alvoEm armazem posicao =
    armazem.alvos
        |> List.filter (\alvo -> alvo.posicao == posicao)
        |> List.head
        |> Maybe.map .letra


caixaNoAlvo : Armazem -> Estado -> String -> Maybe Int
caixaNoAlvo armazem estado letra =
    armazem.alvos
        |> List.filter (\alvo -> alvo.letra == letra)
        |> List.head
        |> Maybe.andThen (\alvo -> caixaEm alvo.posicao estado)


valorCasa : Fase -> Estado -> Posicao -> Maybe Int
valorCasa fase estado posicao =
    case casaEm fase posicao of
        Just (Pista valor) ->
            Just valor

        Just Editavel ->
            Dict.get posicao estado.entradas

        Just (Ligada letra) ->
            caixaNoAlvo fase.armazem estado letra

        Nothing ->
            Nothing


digitar : Fase -> Posicao -> Maybe Int -> Estado -> Result Recusa Estado
digitar fase posicao valor estado =
    case casaEm fase posicao of
        Just Editavel ->
            Ok { estado | entradas = Dict.update posicao (always valor) estado.entradas }

        Just (Pista fixo) ->
            Err (PistaFixa fixo)

        Just (Ligada letra) ->
            Err (LigadaAoAlvo letra)

        Nothing ->
            Err SemGrade


recusaTexto : Posicao -> Recusa -> String
recusaTexto posicao recusa =
    case recusa of
        PistaFixa valor ->
            rotulo posicao ++ " e uma pista fixa (" ++ String.fromInt valor ++ ")."

        LigadaAoAlvo letra ->
            rotulo posicao ++ " e ligada ao alvo " ++ letra ++ ": so uma caixa preenche esta casa."

        SemGrade ->
            "Esta fase nao tem grade."


conflitos : Fase -> Estado -> Set Posicao
conflitos fase estado =
    let
        preenchidas =
            List.filterMap
                (\posicao -> Maybe.map (Tuple.pair posicao) (valorCasa fase estado posicao))
                posicoesGrade

        repetida casa =
            List.any (repete casa) preenchidas
    in
    preenchidas
        |> List.filter repetida
        |> List.map Tuple.first
        |> Set.fromList


repete : ( Posicao, Int ) -> ( Posicao, Int ) -> Bool
repete ( posicao, valor ) ( outra, outro ) =
    valor == outro && posicao /= outra && mesmaUnidade posicao outra


mesmaUnidade : Posicao -> Posicao -> Bool
mesmaUnidade ( l1, c1 ) ( l2, c2 ) =
    l1 == l2 || c1 == c2 || (bloco l1 == bloco l2 && bloco c1 == bloco c2)


bloco : Int -> Int
bloco indice =
    (indice - 1) // 2


entre : Int -> Int -> Int -> Bool
entre minimo maximo valor =
    minimo <= valor && valor <= maximo


noPiso : Armazem -> Posicao -> Bool
noPiso armazem (( linha, coluna ) as posicao) =
    entre 1 armazem.linhas linha
        && entre 1 armazem.colunas coluna
        && not (List.member posicao armazem.paredes)


conteudoEm : Fase -> Estado -> Posicao -> Conteudo
conteudoEm fase estado posicao =
    if not (noPiso fase.armazem posicao) then
        Parede

    else if posicao == estado.jogador then
        ComJogador

    else
        case caixaEm posicao estado of
            Just numero ->
                ComCaixa numero

            Nothing ->
                Chao
