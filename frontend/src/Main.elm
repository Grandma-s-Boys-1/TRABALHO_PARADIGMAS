module Main exposing (main)

{-| Interface gráfica do Sudoku.

Todo programa Elm interativo segue "A Arquitetura Elm" (The Elm Architecture):

  - `Model`: o estado completo da aplicação, num único valor imutável.
  - `Msg`: tudo o que pode acontecer (cliques, teclas, respostas HTTP...).
  - `update`: recebe uma `Msg` e o `Model`, devolve o novo `Model` (e os
    efeitos a executar).
  - `view`: recebe o `Model` e devolve o `Html`. A tela é uma função do estado.

O ciclo é sempre o mesmo: a `view` desenha o `Model`; o usuário interage e
gera uma `Msg`; o `update` produz um `Model` novo; a `view` desenha de novo.
Não há variáveis globais nem alterações "escondidas" do estado.

-}

import Api exposing (Difficulty(..))
import Browser
import Browser.Events
import Html exposing (Html, aside, button, div, footer, h1, header, input, label, main_, p, span, text)
import Html.Attributes exposing (attribute, checked, class, classList, disabled, type_, value)
import Html.Events exposing (onCheck, onClick)
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)
import Sudoku exposing (Board, Cell(..), Position, Variant(..))



-- MAIN


{-| `Browser.element` cria uma aplicação que controla um elemento da página
(veja src/main.js). O tipo `Program Flags Model Msg` diz: recebe dados de
inicialização do tipo `Flags`, o estado é `Model` e as mensagens são `Msg`.
-}
main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


{-| FLAGS são dados que o JavaScript entrega ao Elm na inicialização:

    Elm.Main.init({ node: ..., flags: { darkTheme: true } })

O Elm não tem acesso direto a coisas como `localStorage` ou às preferências
do sistema operacional; quem lê isso é o main.js. O runtime do Elm confere
se o objeto JS tem o formato deste record. Se não tiver, a aplicação nem
inicia, e o console mostra o erro.

-}
type alias Flags =
    { darkTheme : Bool
    }


{-| `variant` diz com que regras o `board` está sendo jogado. Os dois só
mudam juntos, quando chega um puzzle novo (veja `GotPuzzle` no `update`).
-}
type alias Model =
    { board : Board
    , variant : Variant
    , selected : Maybe Position
    , difficulty : Difficulty
    , mode : InputMode
    , darkTheme : Bool
    , loading : Bool
    , error : Maybe String
    }


{-| O que acontece quando o jogador digita um número: ele é colocado na casa,
ou vira uma marcação de canto (um candidato anotado).

Poderíamos usar um `Bool` (`markingMode : Bool`), mas um tipo próprio deixa o
código mais legível: `mode == CornerMarks` diz mais do que `markingMode ==
True`, e se um dia surgir um terceiro modo (marcações de centro, cores...),
basta acrescentar um construtor.

-}
type InputMode
    = Numbers
    | CornerMarks


{-| Estado inicial. Além do Model, `init` devolve um comando: já começamos
pedindo um puzzle ao backend.
-}
init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { board = Sudoku.empty
      , variant = Diagonal
      , selected = Nothing
      , difficulty = Medium
      , mode = Numbers
      , darkTheme = flags.darkTheme
      , loading = True
      , error = Nothing
      }
    , Api.generate Diagonal Medium (GotPuzzle Diagonal)
    )



-- UPDATE


{-| Tudo o que pode acontecer na aplicação.

Repare nas mensagens `Got...`: elas carregam um `Result`. Quem cria essas
mensagens é o runtime do Elm, quando uma resposta HTTP chega.

-}
type Msg
    = NewGame Variant Difficulty
    | GotPuzzle Variant (Result String Board)
    | CellClicked Position
    | NumberPressed Int
    | ErasePressed
    | ModeToggled
    | ThemeToggled Bool
    | MoveSelection Int Int
    | HintRequested
    | GotHint (Result String Api.Hint)
    | SolveRequested
    | GotSolution (Result String Board)
    | ResetRequested
    | ErrorDismissed


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewGame variant difficulty ->
            -- `{ model | campo = valor }` cria uma CÓPIA do record com alguns
            -- campos alterados. O `model` original não muda.
            --
            -- A variante NÃO muda aqui. Ela vai "guardada" na mensagem de
            -- resposta: `GotPuzzle variant` é uma aplicação parcial, uma
            -- função que ainda espera o `Result`. Se mudássemos a variante
            -- agora, o tabuleiro antigo seria julgado pelas regras novas
            -- enquanto o Prolog trabalha, e continuaria assim se o pedido
            -- falhasse.
            ( { model | difficulty = difficulty, loading = True, error = Nothing }
            , Api.generate variant difficulty (GotPuzzle variant)
            )

        GotPuzzle variant (Ok board) ->
            -- Podemos casar padrões "por dentro": aqui tratamos só o caso
            -- `Ok`, e o caso `Err` fica num ramo separado abaixo.
            -- Tabuleiro e variante chegam na MESMA mensagem e entram juntos
            -- no Model.
            ( { model | board = board, variant = variant, selected = Nothing, loading = False }
            , Cmd.none
            )

        GotPuzzle _ (Err error) ->
            ( failed error model, Cmd.none )

        CellClicked position ->
            ( { model | selected = Just position }, Cmd.none )

        NumberPressed n ->
            case model.mode of
                Numbers ->
                    ( updateSelected (placeNumber model.variant (Guess n) n) model, Cmd.none )

                CornerMarks ->
                    ( updateSelected (\position -> Sudoku.toggleMark position n) model
                    , Cmd.none
                    )

        ErasePressed ->
            ( updateSelected (\position -> Sudoku.setCell position Empty) model
            , Cmd.none
            )

        ModeToggled ->
            let
                newMode =
                    case model.mode of
                        Numbers ->
                            CornerMarks

                        CornerMarks ->
                            Numbers
            in
            ( { model | mode = newMode }, Cmd.none )

        ThemeToggled dark ->
            -- A troca de cores em si é feita pelo CSS do daisyUI. Aqui só
            -- guardamos o estado do checkbox para a `view` continuar
            -- desenhando-o marcado ou desmarcado corretamente.
            ( { model | darkTheme = dark }, Cmd.none )

        MoveSelection dRow dCol ->
            let
                -- `modBy 9` faz a seleção "dar a volta" nas bordas.
                move ( row, col ) =
                    ( modBy 9 (row + dRow), modBy 9 (col + dCol) )
            in
            ( { model | selected = Just (Maybe.withDefault ( 0, 0 ) (Maybe.map move model.selected)) }
            , Cmd.none
            )

        HintRequested ->
            ( { model | loading = True, error = Nothing }
            , Api.hint model.variant model.board GotHint
            )

        GotHint (Ok { row, col, value }) ->
            -- Desestruturação de record: extrai os campos direto no padrão.
            ( { model
                | board = placeNumber model.variant (Revealed value) value ( row, col ) model.board
                , selected = Just ( row, col )
                , loading = False
              }
            , Cmd.none
            )

        GotHint (Err error) ->
            ( failed error model, Cmd.none )

        SolveRequested ->
            -- Mandamos só as pistas originais: se o jogador errou algo, isso
            -- não deve impedir o Prolog de achar a solução.
            ( { model | loading = True, error = Nothing }
            , Api.solve model.variant (Sudoku.clearGuesses model.board) GotSolution
            )

        GotSolution (Ok solution) ->
            ( { model | board = Sudoku.revealSolution solution model.board, loading = False }
            , Cmd.none
            )

        GotSolution (Err error) ->
            ( failed error model, Cmd.none )

        ResetRequested ->
            ( { model | board = Sudoku.clearGuesses model.board, error = Nothing }, Cmd.none )

        ErrorDismissed ->
            ( { model | error = Nothing }, Cmd.none )


{-| Funções auxiliares deixam o `update` curto. Esta é usada por todos os
ramos de erro.
-}
failed : String -> Model -> Model
failed error model =
    { model | loading = False, error = Just error }


{-| Altera o tabuleiro na posição selecionada (se houver alguma).

O primeiro argumento é uma FUNÇÃO: recebe a posição e o tabuleiro, e devolve
o tabuleiro novo. Funções que recebem funções são chamadas de funções de
ordem superior. Assim, a mesma `updateSelected` serve para colocar número,
apagar e marcar; quem chama só diz O QUE fazer com a casa.

-}
updateSelected : (Position -> Board -> Board) -> Model -> Model
updateSelected change model =
    case model.selected of
        Just position ->
            { model | board = change position model.board }

        Nothing ->
            model


{-| Coloca um número numa casa e apaga essa marcação dos vizinhos.

Se a casa é uma pista original, nada muda: nem a casa, nem as marcações dos
vizinhos. (Sem esse `if`, `setCell` recusaria a alteração, mas
`removeMarkFromPeers` rodaria mesmo assim e apagaria marcações à toa.)

Repare que a assinatura termina em `Position -> Board -> Board`. Por isso
`placeNumber model.variant (Guess n) n` (só com três argumentos) já é uma
função do tipo que `updateSelected` espera. Isso é APLICAÇÃO PARCIAL: em Elm,
toda função de vários argumentos pode receber só os primeiros e devolver uma
função que espera o resto.

A variante decide quem são os vizinhos: no diagonal, colocar um número numa
diagonal também apaga essa marcação do resto da diagonal.

-}
placeNumber : Variant -> Cell -> Int -> Position -> Board -> Board
placeNumber variant cell n position board =
    if Sudoku.isGiven (Sudoku.cellAt position board) then
        board

    else
        board
            |> Sudoku.setCell position cell
            |> Sudoku.removeMarkFromPeers variant position n



-- SUBSCRIPTIONS


{-| Subscriptions são fontes de eventos externos que queremos escutar
continuamente. Aqui: as teclas pressionadas em qualquer lugar da página.
-}
subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onKeyDown keyDecoder


{-| Eventos do navegador chegam como JSON; lemos o campo `key` do evento.

Truque útil: para teclas que não nos interessam, o decoder FALHA
(`Decode.fail`). Um decoder que falha simplesmente não gera mensagem, então o
`update` nunca fica sabendo dessas teclas.

-}
keyDecoder : Decoder Msg
keyDecoder =
    Decode.field "key" Decode.string
        |> Decode.andThen keyToMsg


keyToMsg : String -> Decoder Msg
keyToMsg key =
    case key of
        "ArrowUp" ->
            Decode.succeed (MoveSelection -1 0)

        "ArrowDown" ->
            Decode.succeed (MoveSelection 1 0)

        "ArrowLeft" ->
            Decode.succeed (MoveSelection 0 -1)

        "ArrowRight" ->
            Decode.succeed (MoveSelection 0 1)

        "Backspace" ->
            Decode.succeed ErasePressed

        "Delete" ->
            Decode.succeed ErasePressed

        "n" ->
            Decode.succeed ModeToggled

        "N" ->
            Decode.succeed ModeToggled

        _ ->
            case String.toInt key of
                Just n ->
                    -- A tecla "0" também apaga a casa.
                    if n >= 1 && n <= 9 then
                        Decode.succeed (NumberPressed n)

                    else
                        Decode.succeed ErasePressed

                Nothing ->
                    Decode.fail "tecla ignorada"



-- VIEW
--
-- As funções de HTML do Elm seguem sempre o formato:
--
--     elemento [ atributos ] [ filhos ]
--
-- As classes usadas aqui são SEMÂNTICAS: dizem o que o elemento é
-- ("board", "cell", "number-key"), e não como ele aparece. A aparência fica
-- toda em src/style.css. Para mudar o visual, quase nunca é preciso mexer
-- neste arquivo.
--
-- Os modificadores (classes com `--`, como "cell--selected") são ligados e
-- desligados com `classList`, que recebe pares (classe, condição).


view : Model -> Html Msg
view model =
    div
        [ class "app"

        -- Um atributo `data-*` guarda um estado que o CSS pode ler com o
        -- seletor [data-mode="marks"]. Veja `.number-key` no style.css.
        , attribute "data-mode"
            (case model.mode of
                Numbers ->
                    "numbers"

                CornerMarks ->
                    "marks"
            )
        ]
        [ header [ class "app-header" ]
            [ div [ class "app-container app-header-content" ]
                [ h1 [ class "app-title" ] [ text "Sudoku" ]
                , span [ class "app-subtitle" ] [ text "Prolog + Elm" ]
                , viewThemeToggle model
                ]
            ]
        , main_ [ class "app-main" ]
            -- Um elemento pode ter várias classes: "app-container" define a
            -- largura (a mesma do cabeçalho) e "game" define o layout interno.
            [ div [ class "app-container game" ]
                [ viewBoard model
                , aside [ class "side-panel" ]
                    [ span [ class "panel-label" ] [ text "Regras" ]
                    , viewVariant model
                    , p [ class "variant-rule" ] [ text (variantRule model.variant) ]
                    , span [ class "panel-label" ] [ text "Novo jogo" ]
                    , viewDifficulty model
                    , div [ class "message-area" ] [ viewMessages model ]
                    , span [ class "panel-label" ] [ text "Números" ]
                    , viewNumberPad model
                    , span [ class "panel-label" ] [ text "Ajuda" ]
                    , viewActions model
                    ]
                ]
            ]
        , footer [ class "app-footer" ]
            [ text "Teclado: "
            , kbd [] [ text "1–9" ]
            , text " coloca, "
            , kbd [] [ text "setas" ]
            , text " movem, "
            , kbd [] [ text "⌫" ]
            , text " apaga, "
            , kbd [] [ text "N" ]
            , text " liga as marcações de canto."
            ]
        ]


{-| Botão sol/lua para trocar entre os temas claro e escuro.

É o componente `theme-controller` do daisyUI: um checkbox cujo `value` é o
nome do tema. Quando está marcado, o CSS aplica o tema `dark`
(veja a seção 2 do style.css). O `<label>` envolve o checkbox, então clicar
em qualquer parte dele (no ícone, por exemplo) marca ou desmarca a caixa.

-}
viewThemeToggle : Model -> Html Msg
viewThemeToggle model =
    label [ class "theme-toggle", attribute "aria-label" "Alternar tema claro/escuro" ]
        [ input
            [ type_ "checkbox"
            , class "theme-controller"
            , value "dark"
            , checked model.darkTheme

            -- `onCheck` entrega o novo estado (True/False) do checkbox.
            , onCheck ThemeToggled
            ]
            []
        , span [ class "swap-off" ] [ text "☀" ]
        , span [ class "swap-on" ] [ text "☾" ]
        ]


{-| `Html.node` cria um elemento com qualquer nome de tag. O pacote elm/html
não tem uma função `kbd` pronta, então definimos a nossa.
-}
kbd : List (Html.Attribute msg) -> List (Html msg) -> Html msg
kbd =
    Html.node "kbd"


{-| Escolha das regras. Trocar de variante começa um jogo novo, na
dificuldade atual. O botão ativo é o da variante do jogo que está NA TELA,
que só muda quando o puzzle novo chega.
-}
viewVariant : Model -> Html Msg
viewVariant model =
    let
        option variant =
            button
                [ class "variant-option"
                , classList [ ( "variant-option--active", variant == model.variant ) ]
                , disabled model.loading
                , onClick (NewGame variant model.difficulty)
                ]
                [ text (variantLabel variant) ]
    in
    div [ class "variant-picker" ] (List.map option [ Classic, Diagonal ])


variantLabel : Variant -> String
variantLabel variant =
    case variant of
        Classic ->
            "Clássico"

        Diagonal ->
            "Diagonal"


variantRule : Variant -> String
variantRule variant =
    case variant of
        Classic ->
            "Linhas, colunas e blocos sem números repetidos."

        Diagonal ->
            "Como no clássico, e as duas diagonais destacadas também não repetem números."


viewDifficulty : Model -> Html Msg
viewDifficulty model =
    let
        option difficulty =
            button
                [ class "difficulty-option"
                , classList [ ( "difficulty-option--active", difficulty == model.difficulty ) ]
                , disabled model.loading
                , onClick (NewGame model.variant difficulty)
                ]
                [ text (Api.difficultyLabel difficulty) ]
    in
    div [ class "difficulty-picker" ] (List.map option [ Easy, Medium, Hard ])


viewMessages : Model -> Html Msg
viewMessages model =
    case ( model.error, model.loading ) of
        -- Casamento de padrões numa tupla: tratamos combinações de dois
        -- valores de uma só vez.
        ( Just error, _ ) ->
            div [ class "message message--error" ]
                [ span [] [ text error ]
                , button [ class "message-close", onClick ErrorDismissed ] [ text "✕" ]
                ]

        ( Nothing, True ) ->
            div [ class "message message--loading" ]
                [ span [ class "spinner" ] []
                , span [] [ text "O Prolog está pensando..." ]
                ]

        ( Nothing, False ) ->
            if Sudoku.isComplete model.variant model.board then
                div [ class "message message--success" ]
                    [ text (completionMessage model.board) ]

            else
                text ""


completionMessage : Board -> String
completionMessage board =
    let
        revealed =
            Sudoku.positions
                |> List.any (\pos -> Sudoku.isRevealed (Sudoku.cellAt pos board))
    in
    if revealed then
        "Resolvido (com ajuda do Prolog)."

    else
        "Parabéns! Você resolveu o puzzle!"


viewBoard : Model -> Html Msg
viewBoard model =
    let
        conflicts =
            Sudoku.conflicts model.variant model.board
    in
    div
        [ class "board"
        , classList [ ( "board--solved", Sudoku.isComplete model.variant model.board ) ]
        ]
        (List.map (viewCell model conflicts) Sudoku.positions)


viewCell : Model -> Set Position -> Position -> Html Msg
viewCell model conflicts (( row, col ) as position) =
    let
        cell =
            Sudoku.cellAt position model.board

        value =
            Sudoku.valueOf cell

        -- A casa está numa mesma região da selecionada (linha, coluna,
        -- bloco e, no diagonal, diagonal)?
        isRelated =
            case model.selected of
                Just sel ->
                    Sudoku.sameRegion model.variant sel position

                Nothing ->
                    False

        -- Número da casa selecionada. `Maybe.andThen` encadeia dois passos
        -- que podem dar Nothing: não haver seleção, ou a casa estar vazia.
        selectedValue =
            model.selected
                |> Maybe.andThen (\sel -> Sudoku.valueOf (Sudoku.cellAt sel model.board))
    in
    button
        [ class "cell"
        , classList
            [ ( "cell--selected", model.selected == Just position )
            , ( "cell--diagonal", Sudoku.isOnDiagonal model.variant position )
            , ( "cell--related", isRelated )
            , ( "cell--same-value", value /= Nothing && value == selectedValue )
            , ( "cell--conflict", Set.member position conflicts )
            , ( "cell--given", Sudoku.isGiven cell )
            , ( "cell--guess", Sudoku.isGuess cell )
            , ( "cell--revealed", Sudoku.isRevealed cell )
            ]

        -- Leitores de tela anunciam este texto (acessibilidade). As linhas
        -- grossas dos blocos 3x3 são desenhadas pelo CSS com :nth-child,
        -- então o Elm não precisa passar linha e coluna para o estilo.
        , attribute "aria-label"
            ("Linha " ++ String.fromInt (row + 1) ++ ", coluna " ++ String.fromInt (col + 1))
        , onClick (CellClicked position)
        ]
        [ case cell of
            Marks marks ->
                viewCornerMarks selectedValue marks

            _ ->
                -- O número fica num <span> próprio para que as animações do
                -- CSS movam só o número, e não a casa com suas bordas.
                span [ class "cell-value" ]
                    [ text (Maybe.map String.fromInt value |> Maybe.withDefault "") ]
        ]


{-| Desenha as marcações de canto de uma casa.

O Elm só coloca as marcações em ordem crescente (`Set.toList` já devolve os
elementos ordenados). Quem decide em que canto cada uma aparece é o CSS, com
`:nth-child` (veja `.corner-mark` no style.css). Cada linguagem faz o que
faz melhor: o Elm cuida dos dados e o CSS cuida do posicionamento.

-}
viewCornerMarks : Maybe Int -> Set Int -> Html Msg
viewCornerMarks selectedValue marks =
    let
        viewMark n =
            span
                [ class "corner-mark"
                , classList [ ( "corner-mark--highlight", Just n == selectedValue ) ]
                ]
                [ text (String.fromInt n) ]
    in
    div [ class "corner-marks" ] (List.map viewMark (Set.toList marks))


viewNumberPad : Model -> Html Msg
viewNumberPad model =
    let
        marking =
            model.mode == CornerMarks

        noSelection =
            model.selected == Nothing

        numberKey n =
            button
                [ class "number-key"
                , disabled noSelection
                , onClick (NumberPressed n)
                ]
                [ text (String.fromInt n) ]
    in
    div [ class "number-pad" ]
        (List.map numberKey (List.range 1 9)
            ++ [ button [ class "erase-key", disabled noSelection, onClick ErasePressed ] [ text "⌫" ]
               , button
                    [ class "mode-toggle"
                    , classList [ ( "mode-toggle--on", marking ) ]
                    , onClick ModeToggled
                    ]
                    [ text
                        (if marking then
                            "✎ Marcando"

                         else
                            "✎ Marcar"
                        )
                    ]
               ]
        )


viewActions : Model -> Html Msg
viewActions model =
    let
        -- Com o tabuleiro completo não há o que revelar: os botões de ajuda
        -- ficam desativados, e a mensagem de parabéns continua na tela.
        nothingToReveal =
            model.loading || Sudoku.isComplete model.variant model.board
    in
    div [ class "actions" ]
        [ button [ class "action-button action-button--hint", disabled nothingToReveal, onClick HintRequested ] [ text "Dica" ]
        , button [ class "action-button action-button--solve", disabled nothingToReveal, onClick SolveRequested ] [ text "Resolver" ]
        , button [ class "action-button action-button--reset", disabled model.loading, onClick ResetRequested ] [ text "Limpar" ]
        ]
