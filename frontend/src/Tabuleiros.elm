module Tabuleiros exposing (armazem, sudoku)

import Ajuda exposing (Destaque, Tabuleiro(..))
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (attribute, class, classList, style)
import Html.Events exposing (onClick)
import Jogo exposing (Casa(..), Conteudo(..), Estado, Fase, Posicao)
import Set exposing (Set)


armazem : Fase -> Estado -> List Destaque -> Html msg
armazem fase estado destaques =
    div
        [ class "armazem"
        , style "grid-template-columns" (colunasCss fase.armazem.colunas)
        , attribute "aria-label" "Armazem"
        ]
        (List.map (casaArmazem fase estado destaques) (Jogo.posicoesArmazem fase.armazem))


colunasCss : Int -> String
colunasCss colunas =
    "repeat(" ++ String.fromInt (colunas + 2) ++ ", var(--casa))"


casaArmazem : Fase -> Estado -> List Destaque -> Posicao -> Html msg
casaArmazem fase estado destaques posicao =
    let
        conteudo =
            Jogo.conteudoEm fase estado posicao

        alvo =
            Jogo.alvoEm fase.armazem posicao
    in
    div
        (class "casa"
            :: class (classeConteudo conteudo)
            :: classList [ ( "casa--alvo", alvo /= Nothing ) ]
            :: attribute "aria-label" (descricao posicao conteudo alvo)
            :: marcas NoArmazem posicao destaques
        )
        [ span [ class "casa-letra" ] [ text (Maybe.withDefault "" alvo) ]
        , span [ class "casa-valor" ] [ text (simbolo conteudo) ]
        ]


classeConteudo : Conteudo -> String
classeConteudo conteudo =
    case conteudo of
        Parede ->
            "casa--parede"

        Chao ->
            "casa--chao"

        ComJogador ->
            "casa--jogador"

        ComCaixa _ ->
            "casa--caixa"


simbolo : Conteudo -> String
simbolo conteudo =
    case conteudo of
        ComJogador ->
            "J"

        ComCaixa numero ->
            String.fromInt numero

        _ ->
            ""


descricao : Posicao -> Conteudo -> Maybe String -> String
descricao ( linha, coluna ) conteudo alvo =
    "Linha "
        ++ String.fromInt linha
        ++ ", coluna "
        ++ String.fromInt coluna
        ++ ": "
        ++ nomeConteudo conteudo
        ++ Maybe.withDefault "" (Maybe.map (\letra -> ", alvo " ++ letra) alvo)


nomeConteudo : Conteudo -> String
nomeConteudo conteudo =
    case conteudo of
        Parede ->
            "parede"

        Chao ->
            "chao"

        ComJogador ->
            "jogador"

        ComCaixa numero ->
            "caixa " ++ String.fromInt numero


marcas : Tabuleiro -> Posicao -> List Destaque -> List (Html.Attribute msg)
marcas tabuleiro posicao destaques =
    Ajuda.marcasEm tabuleiro posicao destaques
        |> List.map (\marca -> class ("destaque destaque--" ++ marca))


sudoku : Fase -> Estado -> Maybe Posicao -> List Destaque -> (Posicao -> msg) -> Html msg
sudoku fase estado selecionada destaques aoClicar =
    let
        repetidas =
            Jogo.conflitos fase estado
    in
    div [ class "sudoku", attribute "aria-label" "Sudoku" ]
        (List.map (celula fase estado selecionada destaques repetidas aoClicar) Jogo.posicoesGrade)


celula :
    Fase
    -> Estado
    -> Maybe Posicao
    -> List Destaque
    -> Set Posicao
    -> (Posicao -> msg)
    -> Posicao
    -> Html msg
celula fase estado selecionada destaques repetidas aoClicar posicao =
    let
        casa =
            Jogo.casaEm fase posicao
    in
    button
        (class "celula"
            :: class (classeCasa casa)
            :: classList
                [ ( "celula--selecionada", selecionada == Just posicao )
                , ( "celula--conflito", Set.member posicao repetidas )
                ]
            :: onClick (aoClicar posicao)
            :: attribute "aria-label" (Jogo.rotulo posicao)
            :: marcas NoSudoku posicao destaques
        )
        [ span [ class "celula-letra" ] [ text (letraCasa casa) ]
        , span [ class "celula-valor" ]
            [ text (mostrar (Jogo.valorCasa fase estado posicao)) ]
        ]


mostrar : Maybe Int -> String
mostrar valor =
    Maybe.withDefault "" (Maybe.map String.fromInt valor)


classeCasa : Maybe Casa -> String
classeCasa casa =
    case casa of
        Just (Pista _) ->
            "celula--pista"

        Just Editavel ->
            "celula--editavel"

        Just (Ligada _) ->
            "celula--ligada"

        Nothing ->
            ""


letraCasa : Maybe Casa -> String
letraCasa casa =
    case casa of
        Just (Ligada letra) ->
            letra

        _ ->
            ""
