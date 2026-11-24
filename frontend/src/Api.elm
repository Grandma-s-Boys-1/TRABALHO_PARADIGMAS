module Api exposing
    ( Movimento(..)
    , Resposta
    , ResumoFase
    , ajudaDecoder
    , carregarFase
    , carregarFases
    , enviarJogada
    , faseDecoder
    , pedirDiagnostico
    , pedirDica
    , pedirSituacao
    , respostaDecoder
    )

import Ajuda exposing (Ajuda, Consulta(..), Destaque, Tabuleiro(..))
import Dict exposing (Dict)
import Http
import Jogo exposing (Direcao, Estado, Fase, Posicao, Regra(..), Situacao(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias ResumoFase =
    { id : String
    , nome : String
    }


type Movimento
    = Caminhou
    | Empurrou
    | Bloqueado


type alias Resposta =
    { estado : Estado
    , movimento : Movimento
    , situacao : Situacao
    }


carregarFases : (Result String (List ResumoFase) -> msg) -> Cmd msg
carregarFases aoReceber =
    Http.get
        { url = "/api/fases"
        , expect = esperar aoReceber (Decode.list resumoDecoder)
        }


carregarFase : String -> (Result String Fase -> msg) -> Cmd msg
carregarFase ident aoReceber =
    Http.get
        { url = "/api/fases/" ++ ident
        , expect = esperar aoReceber faseDecoder
        }


enviarJogada : Fase -> Estado -> Direcao -> (Result String Resposta -> msg) -> Cmd msg
enviarJogada fase estado direcao aoReceber =
    postar "/api/jogada"
        (pedido fase estado [ ( "direcao", Encode.string (Jogo.nomeDirecao direcao) ) ])
        (esperar aoReceber respostaDecoder)


pedirSituacao : Fase -> Estado -> (Result String Situacao -> msg) -> Cmd msg
pedirSituacao fase estado aoReceber =
    postar "/api/situacao"
        (pedido fase estado [])
        (esperar aoReceber (Decode.field "situacao" situacaoDecoder))


pedirDica : Fase -> Estado -> (Result String Ajuda -> msg) -> Cmd msg
pedirDica fase estado aoReceber =
    postar "/api/dica" (pedido fase estado []) (esperar aoReceber ajudaDecoder)


pedirDiagnostico : Consulta -> Fase -> Estado -> (Result String Ajuda -> msg) -> Cmd msg
pedirDiagnostico consulta fase estado aoReceber =
    postar "/api/diagnostico"
        (pedido fase estado [ ( "consulta", codificarConsulta consulta ) ])
        (esperar aoReceber ajudaDecoder)


postar : String -> Encode.Value -> Http.Expect msg -> Cmd msg
postar url corpo expect =
    Http.post { url = url, body = Http.jsonBody corpo, expect = expect }


pedido : Fase -> Estado -> List ( String, Encode.Value ) -> Encode.Value
pedido fase estado extras =
    Encode.object
        (( "fase", Encode.string fase.id )
            :: ( "estado", codificarEstado estado )
            :: extras
        )


codificarEstado : Estado -> Encode.Value
codificarEstado estado =
    Encode.object
        [ ( "jogador", codificarPosicao estado.jogador [] )
        , ( "caixas", Encode.list codificarCaixa estado.caixas )
        , ( "entradas", Encode.list (Encode.list Encode.int) (matriz estado.entradas) )
        ]


codificarPosicao : Posicao -> List ( String, Encode.Value ) -> Encode.Value
codificarPosicao ( linha, coluna ) extras =
    Encode.object (( "linha", Encode.int linha ) :: ( "coluna", Encode.int coluna ) :: extras)


codificarCaixa : Jogo.Caixa -> Encode.Value
codificarCaixa caixa =
    codificarPosicao caixa.posicao [ ( "numero", Encode.int caixa.numero ) ]


codificarConsulta : Consulta -> Encode.Value
codificarConsulta consulta =
    case consulta of
        Padrao ->
            Encode.object [ ( "tipo", Encode.string "padrao" ) ]

        NaCasa posicao ->
            codificarPosicao posicao [ ( "tipo", Encode.string "casa" ) ]

        NaDirecao direcao ->
            Encode.object
                [ ( "tipo", Encode.string "direcao" )
                , ( "direcao", Encode.string (Jogo.nomeDirecao direcao) )
                ]


matriz : Dict Posicao Int -> List (List Int)
matriz entradas =
    List.map (linhaDe entradas) (List.range 1 4)


linhaDe : Dict Posicao Int -> Int -> List Int
linhaDe entradas linha =
    List.range 1 4
        |> List.map (\coluna -> Maybe.withDefault 0 (Dict.get ( linha, coluna ) entradas))


resumoDecoder : Decoder ResumoFase
resumoDecoder =
    Decode.map2 ResumoFase
        (Decode.field "id" Decode.string)
        (Decode.field "nome" Decode.string)


faseDecoder : Decoder Fase
faseDecoder =
    Decode.map5 Fase
        (Decode.field "id" Decode.string)
        (Decode.field "nome" Decode.string)
        (Decode.field "armazem" armazemDecoder)
        (Decode.field "sudoku" (Decode.nullable sudokuDecoder) |> Decode.map regra)
        (Decode.field "inicio" estadoDecoder)


regra : Maybe (Dict Posicao Jogo.Casa) -> Regra
regra sudoku =
    case sudoku of
        Just casas ->
            Combinada casas

        Nothing ->
            Classica


posicaoDecoder : Decoder Posicao
posicaoDecoder =
    Decode.map2 Tuple.pair
        (Decode.field "linha" Decode.int)
        (Decode.field "coluna" Decode.int)


letraDecoder : Decoder Jogo.Alvo
letraDecoder =
    Decode.map2 Jogo.Alvo
        (Decode.field "letra" Decode.string)
        posicaoDecoder


ligacaoDecoder : Decoder Jogo.Ligacao
ligacaoDecoder =
    Decode.map2 Jogo.Ligacao
        (Decode.field "letra" Decode.string)
        posicaoDecoder


armazemDecoder : Decoder Jogo.Armazem
armazemDecoder =
    Decode.map4 Jogo.Armazem
        (Decode.field "linhas" Decode.int)
        (Decode.field "colunas" Decode.int)
        (Decode.field "paredes" (Decode.list posicaoDecoder))
        (Decode.field "alvos" (Decode.list letraDecoder))


sudokuDecoder : Decoder (Dict Posicao Jogo.Casa)
sudokuDecoder =
    Decode.map2 Jogo.montarSudoku
        (Decode.field "pistas" (Decode.list (Decode.list Decode.int)))
        (Decode.field "ligacoes" (Decode.list ligacaoDecoder))
        |> Decode.andThen resultado


caixaDecoder : Decoder Jogo.Caixa
caixaDecoder =
    Decode.map2 Jogo.Caixa
        (Decode.field "numero" Decode.int)
        posicaoDecoder


estadoDecoder : Decoder Estado
estadoDecoder =
    Decode.map3 Estado
        (Decode.field "jogador" posicaoDecoder)
        (Decode.field "caixas" (Decode.list caixaDecoder))
        (Decode.field "entradas" (Decode.list (Decode.list Decode.int))
            |> Decode.andThen (Jogo.lerEntradas >> resultado)
        )


resultado : Result String a -> Decoder a
resultado valor =
    case valor of
        Ok certo ->
            Decode.succeed certo

        Err erro ->
            Decode.fail erro


respostaDecoder : Decoder Resposta
respostaDecoder =
    Decode.map3 Resposta
        (Decode.field "estado" estadoDecoder)
        (Decode.field "movimento" movimentoDecoder)
        (Decode.field "situacao" situacaoDecoder)


movimentoDecoder : Decoder Movimento
movimentoDecoder =
    Decode.string
        |> Decode.andThen
            (\texto ->
                case texto of
                    "caminhada" ->
                        Decode.succeed Caminhou

                    "empurrao" ->
                        Decode.succeed Empurrou

                    "bloqueado" ->
                        Decode.succeed Bloqueado

                    _ ->
                        Decode.fail ("Movimento desconhecido: " ++ texto)
            )


situacaoDecoder : Decoder Situacao
situacaoDecoder =
    Decode.string
        |> Decode.andThen
            (\texto ->
                case texto of
                    "jogando" ->
                        Decode.succeed EmJogo

                    "vitoria" ->
                        Decode.succeed Vitoria

                    _ ->
                        Decode.fail ("Situacao desconhecida: " ++ texto)
            )


ajudaDecoder : Decoder Ajuda
ajudaDecoder =
    Decode.map3 Ajuda
        (Decode.field "texto" Decode.string)
        (Decode.field "destaques" (Decode.list destaqueDecoder))
        (Decode.field "dados" Decode.value)


destaqueDecoder : Decoder Destaque
destaqueDecoder =
    Decode.map3 Destaque
        (Decode.field "tabuleiro" tabuleiroDecoder)
        posicaoDecoder
        (Decode.field "marca" Decode.string)


tabuleiroDecoder : Decoder Tabuleiro
tabuleiroDecoder =
    Decode.string
        |> Decode.andThen
            (\texto ->
                case texto of
                    "armazem" ->
                        Decode.succeed NoArmazem

                    "sudoku" ->
                        Decode.succeed NoSudoku

                    _ ->
                        Decode.fail ("Tabuleiro desconhecido: " ++ texto)
            )


esperar : (Result String a -> msg) -> Decoder a -> Http.Expect msg
esperar aoReceber decoder =
    Http.expectStringResponse aoReceber <|
        \resposta ->
            case resposta of
                Http.GoodStatus_ _ corpo ->
                    Decode.decodeString decoder corpo
                        |> Result.mapError (\_ -> "Resposta inesperada do servidor.")

                Http.BadStatus_ metadados corpo ->
                    Err (detalhe metadados.statusCode corpo)

                Http.BadUrl_ url ->
                    Err ("Endereco invalido: " ++ url)

                Http.Timeout_ ->
                    Err "O servidor demorou demais para responder."

                Http.NetworkError_ ->
                    Err "Sem conexao com o servidor. O backend esta rodando?"


detalhe : Int -> String -> String
detalhe status corpo =
    case Decode.decodeString (Decode.field "detail" Decode.string) corpo of
        Ok texto ->
            texto

        Err _ ->
            "Erro no servidor (codigo " ++ String.fromInt status ++ ")."
