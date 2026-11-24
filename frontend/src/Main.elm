module Main exposing (main)

import Ajuda exposing (Ajuda, Consulta(..), Destaque, Modulo, TipoConsulta(..))
import Api exposing (Movimento(..), Resposta, ResumoFase)
import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (class, classList, disabled)
import Html.Events exposing (onClick)
import Jogo exposing (Direcao(..), Estado, Fase, Posicao, Regra(..), Situacao(..))
import Json.Decode as Decode exposing (Decoder)
import Registro
import Set
import Tabuleiros


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


type alias Model =
    { fases : List ResumoFase
    , numero : Int
    , tela : Tela
    }


type Tela
    = Carregando
    | Falha String
    | Jogando Partida


type alias Partida =
    { fase : Fase
    , estado : Estado
    , situacao : Situacao
    , envio : Envio
    , selecionada : Maybe Posicao
    , ajuda : Maybe Exibicao
    , aviso : Maybe String
    }


type Envio
    = Livre
    | Aguardando


type Origem
    = DaDica
    | DoModulo


type alias Exibicao =
    { origem : Origem
    , ajuda : Ajuda
    }


type alias Requisicao =
    Fase -> Estado -> (Result String Ajuda -> Msg) -> Cmd Msg


type Msg
    = FasesRecebidas (Result String (List ResumoFase))
    | Escolher String
    | FaseRecebida Int (Result String Fase)
    | Mover Direcao
    | JogadaRecebida Int (Result String Resposta)
    | Selecionar Posicao
    | Desmarcar
    | Digitar (Maybe Int)
    | SituacaoRecebida Int (Result String Situacao)
    | PedirDica
    | Consultar Consulta
    | AjudaRecebida Int Origem (Result String Ajuda)
    | Reiniciar


init : () -> ( Model, Cmd Msg )
init _ =
    ( { fases = [], numero = 0, tela = Carregando }
    , Api.carregarFases FasesRecebidas
    )


novaPartida : Fase -> Partida
novaPartida fase =
    { fase = fase
    , estado = fase.inicio
    , situacao = EmJogo
    , envio = Livre
    , selecionada = Nothing
    , ajuda = Nothing
    , aviso = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FasesRecebidas (Ok ((primeira :: _) as fases)) ->
            ( { model | fases = fases }, Api.carregarFase primeira.id (FaseRecebida model.numero) )

        FasesRecebidas (Ok []) ->
            ( { model | tela = Falha "Nenhuma fase registrada." }, Cmd.none )

        FasesRecebidas (Err erro) ->
            ( { model | tela = Falha erro }, Cmd.none )

        Escolher ident ->
            ( { model | numero = model.numero + 1, tela = Carregando }
            , Api.carregarFase ident (FaseRecebida (model.numero + 1))
            )

        FaseRecebida numero (Ok fase) ->
            if numero == model.numero then
                ( { model | tela = Jogando (novaPartida fase) }, Cmd.none )

            else
                ( model, Cmd.none )

        FaseRecebida numero (Err erro) ->
            if numero == model.numero then
                ( { model | tela = Falha erro }, Cmd.none )

            else
                ( model, Cmd.none )

        Reiniciar ->
            { model | numero = model.numero + 1 }
                |> naPartida (\partida -> ( novaPartida partida.fase, Cmd.none ))

        Mover direcao ->
            naPartida (mover model.numero direcao) model

        JogadaRecebida numero resultado ->
            atual numero (receberJogada resultado) model

        Selecionar posicao ->
            naPartida (\partida -> ( { partida | selecionada = Just posicao }, Cmd.none )) model

        Desmarcar ->
            naPartida (\partida -> ( { partida | selecionada = Nothing }, Cmd.none )) model

        Digitar valor ->
            naPartida (digitar model.numero valor) model

        SituacaoRecebida numero resultado ->
            atual numero (receberSituacao resultado) model

        PedirDica ->
            naPartida (pedir model.numero DaDica Api.pedirDica) model

        Consultar consulta ->
            naPartida (pedir model.numero DoModulo (Api.pedirDiagnostico consulta)) model

        AjudaRecebida numero origem resultado ->
            atual numero (receberAjuda origem resultado) model


naPartida : (Partida -> ( Partida, Cmd Msg )) -> Model -> ( Model, Cmd Msg )
naPartida mudar model =
    case model.tela of
        Jogando partida ->
            Tuple.mapFirst (\nova -> { model | tela = Jogando nova }) (mudar partida)

        _ ->
            ( model, Cmd.none )


atual : Int -> (Partida -> Partida) -> Model -> ( Model, Cmd Msg )
atual numero mudar model =
    if numero == model.numero then
        naPartida (\partida -> ( mudar partida, Cmd.none )) model

    else
        ( model, Cmd.none )


livre : Partida -> Bool
livre partida =
    partida.envio == Livre && partida.situacao == EmJogo


mover : Int -> Direcao -> Partida -> ( Partida, Cmd Msg )
mover numero direcao partida =
    if livre partida then
        ( { partida | envio = Aguardando, aviso = Nothing }
        , Api.enviarJogada partida.fase partida.estado direcao (JogadaRecebida numero)
        )

    else
        ( partida, Cmd.none )


receberJogada : Result String Resposta -> Partida -> Partida
receberJogada resultado partida =
    case resultado of
        Ok resposta ->
            { partida
                | estado = resposta.estado
                , situacao = resposta.situacao
                , envio = Livre
                , ajuda = Nothing
                , aviso = avisoDoMovimento resposta.movimento
            }

        Err erro ->
            { partida | envio = Livre, aviso = Just erro }


avisoDoMovimento : Movimento -> Maybe String
avisoDoMovimento movimento =
    case movimento of
        Bloqueado ->
            Just "Bloqueado: ha uma parede ou duas caixas em fila."

        _ ->
            Nothing


digitar : Int -> Maybe Int -> Partida -> ( Partida, Cmd Msg )
digitar numero valor partida =
    case ( partida.selecionada, livre partida ) of
        ( Just posicao, True ) ->
            case Jogo.digitar partida.fase posicao valor partida.estado of
                Ok estado ->
                    ( { partida
                        | estado = estado
                        , envio = Aguardando
                        , ajuda = Nothing
                        , aviso = Nothing
                      }
                    , Api.pedirSituacao partida.fase estado (SituacaoRecebida numero)
                    )

                Err recusa ->
                    ( { partida | aviso = Just (Jogo.recusaTexto posicao recusa) }, Cmd.none )

        _ ->
            ( partida, Cmd.none )


receberSituacao : Result String Situacao -> Partida -> Partida
receberSituacao resultado partida =
    case resultado of
        Ok situacao ->
            { partida | situacao = situacao, envio = Livre }

        Err erro ->
            { partida | envio = Livre, aviso = Just erro }


pedir : Int -> Origem -> Requisicao -> Partida -> ( Partida, Cmd Msg )
pedir numero origem requisicao partida =
    if partida.envio == Livre then
        ( { partida | envio = Aguardando, aviso = Nothing }
        , requisicao partida.fase partida.estado (AjudaRecebida numero origem)
        )

    else
        ( partida, Cmd.none )


receberAjuda : Origem -> Result String Ajuda -> Partida -> Partida
receberAjuda origem resultado partida =
    case resultado of
        Ok ajuda ->
            { partida | envio = Livre, ajuda = Just { origem = origem, ajuda = ajuda } }

        Err erro ->
            { partida | envio = Livre, aviso = Just erro }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onKeyDown teclado


teclado : Decoder Msg
teclado =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\tecla ->
                case comando tecla of
                    Just msg ->
                        Decode.succeed msg

                    Nothing ->
                        Decode.fail "tecla ignorada"
            )


comando : String -> Maybe Msg
comando tecla =
    case tecla of
        "ArrowUp" ->
            Just (Mover Cima)

        "ArrowDown" ->
            Just (Mover Baixo)

        "ArrowLeft" ->
            Just (Mover Esquerda)

        "ArrowRight" ->
            Just (Mover Direita)

        "Backspace" ->
            Just (Digitar Nothing)

        "Delete" ->
            Just (Digitar Nothing)

        "0" ->
            Just (Digitar Nothing)

        "Escape" ->
            Just Desmarcar

        _ ->
            String.toInt tecla |> Maybe.andThen digito


digito : Int -> Maybe Msg
digito valor =
    if valor >= 1 && valor <= 4 then
        Just (Digitar (Just valor))

    else
        Nothing


moduloDa : Fase -> Maybe Modulo
moduloDa fase =
    List.head (List.filter (\modulo -> modulo.id == fase.id) Registro.modulos)


seguinte : List ResumoFase -> String -> Maybe ResumoFase
seguinte fases ident =
    case fases of
        primeira :: segunda :: resto ->
            if primeira.id == ident then
                Just segunda

            else
                seguinte (segunda :: resto) ident

        _ ->
            Nothing


botao : Bool -> Msg -> String -> Html Msg
botao ativo msg rotulo =
    button [ class "botao", disabled (not ativo), onClick msg ] [ text rotulo ]


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ header [ class "cabecalho" ]
            [ h1 [ class "titulo" ] [ text "Sokoban Sudoku" ]
            , span [ class "subtitulo" ] [ text "Prolog + Elm" ]
            ]
        , nav [ class "fases" ] (List.map (botaoFase (faseAtual model)) model.fases)
        , conteudo model
        , footer [ class "rodape" ]
            [ text
                ("Setas movem o jogador. Clique numa casa da grade e use 1 a 4; "
                    ++ "0 ou Backspace apagam; Esc tira a selecao."
                )
            ]
        ]


faseAtual : Model -> Maybe String
faseAtual model =
    case model.tela of
        Jogando partida ->
            Just partida.fase.id

        _ ->
            Nothing


botaoFase : Maybe String -> ResumoFase -> Html Msg
botaoFase ativa resumo =
    button
        [ class "botao"
        , classList [ ( "botao--ativo", ativa == Just resumo.id ) ]
        , onClick (Escolher resumo.id)
        ]
        [ text resumo.nome ]


conteudo : Model -> Html Msg
conteudo model =
    case model.tela of
        Carregando ->
            p [ class "mensagem mensagem--info" ] [ text "Carregando..." ]

        Falha erro ->
            p [ class "mensagem mensagem--erro" ] [ text erro ]

        Jogando partida ->
            viewPartida model.fases partida


viewPartida : List ResumoFase -> Partida -> Html Msg
viewPartida fases partida =
    let
        destaques =
            destaquesAtuais partida
    in
    main_ [ class "partida" ]
        [ section [ class "tabuleiros" ]
            (Tabuleiros.armazem partida.fase partida.estado destaques :: grade partida destaques)
        , aside [ class "painel" ] (mensagens fases partida ++ painel partida)
        ]


painel : Partida -> List (Html Msg)
painel partida =
    [ controles partida, viewAjuda partida, viewModulo partida, legenda partida.fase ]


grade : Partida -> List Destaque -> List (Html Msg)
grade partida destaques =
    case partida.fase.regra of
        Classica ->
            []

        Combinada _ ->
            [ Tabuleiros.sudoku partida.fase
                partida.estado
                partida.selecionada
                destaques
                Selecionar
            ]


destaquesAtuais : Partida -> List Destaque
destaquesAtuais partida =
    case ( partida.ajuda, moduloDa partida.fase ) of
        ( Just { origem, ajuda }, Just modulo ) ->
            if origem == DoModulo then
                modulo.destacar ajuda

            else
                ajuda.destaques

        ( Just { ajuda }, Nothing ) ->
            ajuda.destaques

        ( Nothing, _ ) ->
            []


mensagens : List ResumoFase -> Partida -> List (Html Msg)
mensagens fases partida =
    List.filterMap identity
        [ Maybe.map (mensagem "mensagem--erro") partida.aviso
        , se (partida.envio == Aguardando) (mensagem "mensagem--info" "Aguardando o Prolog...")
        , se (repetidos partida)
            (mensagem "mensagem--alerta"
                ("Ha numeros repetidos na grade (casas em vermelho). "
                    ++ "Corrija uma entrada ou mova uma caixa."
                )
            )
        , se (partida.situacao == Vitoria) (vitoria fases partida.fase)
        ]


se : Bool -> a -> Maybe a
se condicao valor =
    if condicao then
        Just valor

    else
        Nothing


mensagem : String -> String -> Html Msg
mensagem tipo texto =
    p [ class ("mensagem " ++ tipo) ] [ text texto ]


repetidos : Partida -> Bool
repetidos partida =
    not (Set.isEmpty (Jogo.conflitos partida.fase partida.estado))


vitoria : List ResumoFase -> Fase -> Html Msg
vitoria fases fase =
    div [ class "mensagem mensagem--sucesso" ]
        (text "Vitoria! Fase concluida. "
            :: (case seguinte fases fase.id of
                    Just proxima ->
                        [ botao True (Escolher proxima.id) ("Proxima: " ++ proxima.nome) ]

                    Nothing ->
                        []
               )
        )


controles : Partida -> Html Msg
controles partida =
    div [ class "controles" ]
        [ div [ class "setas" ] (List.map (botaoDirecao partida) Jogo.direcoes)
        , teclas partida
        , div [ class "acoes" ]
            [ botao (partida.envio == Livre) PedirDica "Dica"
            , botao True Reiniciar "Reiniciar"
            ]
        ]


botaoDirecao : Partida -> Direcao -> Html Msg
botaoDirecao partida direcao =
    botao (livre partida)
        (Mover direcao)
        (Jogo.letraDirecao direcao ++ " " ++ Jogo.nomeDirecao direcao)


teclas : Partida -> Html Msg
teclas partida =
    let
        ativa =
            partida.selecionada /= Nothing && livre partida

        tecla valor =
            botao ativa (Digitar (Just valor)) (String.fromInt valor)
    in
    case partida.fase.regra of
        Classica ->
            text ""

        Combinada _ ->
            div [ class "teclas" ]
                (List.map tecla (List.range 1 4) ++ [ botao ativa (Digitar Nothing) "Apagar" ])


viewAjuda : Partida -> Html Msg
viewAjuda partida =
    case partida.ajuda of
        Just { origem, ajuda } ->
            div [ class "ajuda" ]
                (p [ class "ajuda-texto" ] [ text ajuda.texto ]
                    :: exibicao origem partida.fase ajuda
                )

        Nothing ->
            text ""


exibicao : Origem -> Fase -> Ajuda -> List (Html Msg)
exibicao origem fase ajuda =
    case ( origem, moduloDa fase ) of
        ( DoModulo, Just modulo ) ->
            [ Html.map never (modulo.exibir ajuda) ]

        _ ->
            []


viewModulo : Partida -> Html Msg
viewModulo partida =
    case moduloDa partida.fase of
        Just modulo ->
            div [ class "diagnostico" ]
                (h2 [ class "painel-titulo" ] [ text "Diagnostico" ]
                    :: List.concatMap (botoesConsulta partida) modulo.consultas
                )

        Nothing ->
            text ""


botoesConsulta : Partida -> TipoConsulta -> List (Html Msg)
botoesConsulta partida tipo =
    let
        ativo =
            partida.envio == Livre
    in
    case tipo of
        PorPadrao ->
            [ botao ativo (Consultar Padrao) "Diagnosticar" ]

        PorCasa ->
            case partida.selecionada of
                Just posicao ->
                    [ consultaCasa ativo posicao ]

                Nothing ->
                    [ p [ class "legenda" ] [ text "Selecione uma casa da grade." ] ]

        PorDirecao ->
            List.map (consultaDirecao ativo) Jogo.direcoes


consultaCasa : Bool -> Posicao -> Html Msg
consultaCasa ativo posicao =
    botao ativo (Consultar (NaCasa posicao)) ("Consultar " ++ Jogo.rotulo posicao)


consultaDirecao : Bool -> Direcao -> Html Msg
consultaDirecao ativo direcao =
    botao ativo (Consultar (NaDirecao direcao)) ("Consultar " ++ Jogo.letraDirecao direcao)


legenda : Fase -> Html Msg
legenda fase =
    p [ class "legenda" ]
        [ text
            (case fase.regra of
                Classica ->
                    "J e o jogador, os numeros sao caixas e A e B sao alvos. Ocupe os dois alvos."

                Combinada _ ->
                    "J e o jogador, os numeros sao caixas e A e B sao alvos. "
                        ++ "Na grade, fundo cinza e pista, fundo branco e editavel "
                        ++ "e borda tracejada com letra e ligada a um alvo. "
                        ++ "Vence quem ocupa os alvos e completa a grade sem repeticao."
            )
        ]
