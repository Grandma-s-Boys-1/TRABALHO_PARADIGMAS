/*  sudoku.pl: Resolução e geração de puzzles de Sudoku em Prolog.

    Este é o "cérebro" do sistema. Todo o raciocínio sobre Sudoku acontece
    aqui; o Python apenas repassa os pedidos HTTP para estes predicados.

    REPRESENTAÇÃO
    -------------
    Um tabuleiro é uma lista com 9 linhas; cada linha é uma lista com 9
    inteiros. O número 0 representa uma casa vazia:

        [[5,3,0, 0,7,0, 0,0,0],
         [6,0,0, 1,9,5, 0,0,0],
         ...]

    Essa é exatamente a forma que o Python (via janus) envia e recebe: uma
    lista de listas do Python vira uma lista de listas do Prolog.

    A IDEIA CENTRAL: PROGRAMAÇÃO POR RESTRIÇÕES
    -------------------------------------------
    Em vez de escrever um algoritmo de busca "na mão" (backtracking com
    laços, como faríamos em Python ou C), usamos a biblioteca CLP(FD)
    (Constraint Logic Programming over Finite Domains). Nós apenas
    DECLARAMOS o que é um Sudoku válido:

        * cada casa contém um número entre 1 e 9;
        * os números de cada linha são todos diferentes;
        * os números de cada coluna são todos diferentes;
        * os números de cada bloco 3x3 são todos diferentes.

    O resolvedor de restrições se encarrega de encontrar valores que
    satisfazem tudo isso. Esse é o espírito do paradigma lógico/declarativo:
    descrevemos O QUE é uma solução, não COMO encontrá-la.

    VARIANTES
    ---------
    Além do Sudoku clássico, o sistema joga o Sudoku DIAGONAL (ou "Sudoku
    X"), em que as duas diagonais principais também não repetem números.
    Os predicados públicos têm uma versão que recebe a variante como
    primeiro argumento (solve/3, generate/3, hint/3...). As versões sem ela
    (solve/2, generate/2, hint/2...) jogam o clássico. Veja a seção 2.

    COMO TESTAR NO TERMINAL
    -----------------------
        $ swipl backend/prolog/sudoku.pl
        ?- example_puzzle(P), solve(P, S), print_grid(S).
        ?- generate(medium, P), print_grid(P).
        ?- generate(diagonal, hard, P), print_grid(P).
        ?- example_diagonal_puzzle(P), count_solutions(classic, P, 10, N).
*/

% Um módulo define quais predicados são "públicos" (exportados). Os demais
% ficam privados ao arquivo. A notação nome/N indica o nome do predicado e
% sua aridade (número de argumentos): solve/2 recebe 2 argumentos.
:- module(sudoku,
          [ solve/2,                    % +Puzzle, -Solution
            solve/3,                    % +Variant, +Puzzle, -Solution
            count_solutions/3,          % +Puzzle, +Limit, -Count
            count_solutions/4,          % +Variant, +Puzzle, +Limit, -Count
            generate/2,                 % +Difficulty, -Puzzle
            generate/3,                 % +Variant, +Difficulty, -Puzzle
            hint/2,                     % +Board, -Result
            hint/3,                     % +Variant, +Board, -Result
            variant/1,                  % ?Variant
            diagonals/3,                % +Rows, -Main, -Anti
            example_puzzle/1,           % -Puzzle
            example_diagonal_puzzle/1,  % -Puzzle
            print_grid/1                % +Grid
          ]).

% Convenção de documentação usada acima e abaixo:
%   +Arg  : argumento de entrada (deve chegar instanciado)
%   -Arg  : argumento de saída (o predicado vai instanciá-lo)
%   ?Arg  : pode ser entrada ou saída

:- use_module(library(clpfd)).    % restrições sobre inteiros: ins, #=, all_distinct...
:- use_module(library(lists)).    % append/2, nth0/3, sum_list/2...
:- use_module(library(apply)).    % maplist/2..N, foldl/4...
:- use_module(library(random)).   % random_permutation/2, random_member/2
:- use_module(library(solution_sequences)).  % limit/2


/* =========================================================================
   1. AS REGRAS DO SUDOKU (restrições)
   ========================================================================= */

%!  sudoku_constraints(+Variant, ?Rows) is det.
%
%   Impõe sobre Rows todas as regras do Sudoku da variante Variant. Rows
%   pode conter tanto números já conhecidos quanto VARIÁVEIS ainda livres
%   (as casas vazias).
%
%   Importante: este predicado NÃO resolve o puzzle. Ele apenas registra as
%   restrições. O CLP(FD) já faz "propagação" nesse momento (por exemplo,
%   se uma linha já tem 1..8, a variável restante só pode ser 9), mas para
%   garantir que todas as casas recebam valores é preciso chamar label/1
%   ou labeling/2 depois.
sudoku_constraints(Variant, Rows) :-
    % length/2 com uma variável livre cria uma lista com 9 elementos, ou
    % verifica que Rows já tem 9 elementos. Predicados Prolog frequentemente
    % funcionam "nos dois sentidos" assim.
    length(Rows, 9),

    % same_length(Rows) aplicado a cada linha: toda linha tem 9 elementos.
    % maplist(P, L) chama P em cada elemento de L (como um "for each").
    maplist(same_length(Rows), Rows),

    % append/2 "achata" a lista de listas em uma única lista de 81 casas.
    append(Rows, Cells),

    % `ins` é o operador do CLP(FD) que define o domínio: toda casa está
    % no intervalo 1..9.
    Cells ins 1..9,

    % Linhas: todos os valores distintos.
    maplist(all_distinct, Rows),

    % Colunas: transpose/2 (da clpfd) transforma colunas em linhas, então
    % reaproveitamos a mesma restrição.
    transpose(Rows, Columns),
    maplist(all_distinct, Columns),

    % Blocos 3x3: pegamos as linhas de 3 em 3 e extraímos os blocos.
    % O casamento de padrões (pattern matching) nomeia as 9 linhas.
    Rows = [R1, R2, R3, R4, R5, R6, R7, R8, R9],
    blocks(R1, R2, R3),
    blocks(R4, R5, R6),
    blocks(R7, R8, R9),

    % Regras extras da variante (nenhuma, no clássico). Veja a seção 2.
    variant_constraints(Variant, Rows).

%!  blocks(?RowA, ?RowB, ?RowC) is det.
%
%   Recebe três linhas consecutivas e impõe all_distinct em cada um dos três
%   blocos 3x3 formados por elas. Funciona por recursão: consome as 3
%   primeiras colunas de cada linha, e chama a si mesmo com o resto.
blocks([], [], []).                       % caso base: linhas consumidas
blocks([A1, A2, A3 | As],
       [B1, B2, B3 | Bs],
       [C1, C2, C3 | Cs]) :-
    % A notação [X, Y | Resto] separa os primeiros elementos da cauda.
    all_distinct([A1, A2, A3, B1, B2, B3, C1, C2, C3]),
    blocks(As, Bs, Cs).


/* =========================================================================
   2. VARIANTES
   =========================================================================

   Uma variante é o Sudoku clássico MAIS algumas restrições. Com o CLP(FD),
   acrescentar uma regra não exige mexer no resolvedor, no gerador nem na
   dica: todos eles chamam sudoku_constraints/2, que chama
   variant_constraints/2, e passam a respeitar a regra nova sozinhos.

   Sudoku diagonal ("Sudoku X"): além de linhas, colunas e blocos, cada uma
   das duas diagonais principais também tem os números de 1 a 9 sem repetir.

       \ . . . . . . . /
       . \ . . . . . / .
       . . \ . . . / . .
       . . . \ . / . . .
       . . . . X . . . .      <- a casa central está nas DUAS diagonais
       . . . / . \ . . .
       . . / . . . \ . .
       . / . . . . . \ .
       / . . . . . . . \
*/

%!  variant(?Variant) is nondet.
%
%   Fatos: as variantes que o sistema conhece. Também servem para validar o
%   que chega do Python (veja check_variant/1).
variant(classic).
variant(diagonal).

%!  variant_constraints(+Variant, ?Rows) is det.
%
%   As regras que cada variante acrescenta ao clássico, uma cláusula por
%   variante. O Prolog escolhe a cláusula pelo casamento do primeiro
%   argumento com o átomo da cabeça (e, por indexar o primeiro argumento,
%   não deixa ponto de escolha). Uma variante nova é só mais uma cláusula.
variant_constraints(classic, _Rows).
variant_constraints(diagonal, Rows) :-
    diagonals(Rows, Main, Anti),
    all_distinct(Main),
    all_distinct(Anti).

%!  diagonals(+Rows, -Main, -Anti) is det.
%
%   Main é a diagonal principal, as casas (0,0), (1,1), ..., (8,8), e Anti é
%   a antidiagonal, as casas (0,8), (1,7), ..., (8,0). As casas podem ser
%   números ou variáveis ainda livres: diagonals/3 não olha os valores, só
%   junta as MESMAS casas (as mesmas variáveis) numa lista nova. Por isso uma
%   restrição sobre Main restringe as casas do tabuleiro.
%
%   Na diagonal principal, a casa I fica na linha I. maplist/4 percorre a
%   lista de índices e a de linhas ao mesmo tempo, chamando
%   nth0(I, Linha, Casa) para cada par. A antidiagonal é a diagonal principal
%   do tabuleiro espelhado (cada linha invertida); reaproveitamos a mesma
%   ideia em vez de fazer contas com 8 - I.
diagonals(Rows, Main, Anti) :-
    numlist(0, 8, Indexes),
    maplist(nth0, Indexes, Rows, Main),
    maplist(reverse, Rows, Mirrored),
    maplist(nth0, Indexes, Mirrored, Anti).

%!  check_variant(+Variant) is det.
%
%   Lança um erro legível se Variant não for uma variante conhecida. Sem
%   isso, uma variante desconhecida faria variant_constraints/2 FALHAR, e
%   solve/3 responderia "sem solução", o que esconderia o erro de verdade.
check_variant(Variant) :-
    findall(Known, variant(Known), Variants),
    must_be(oneof(Variants), Variant).


/* =========================================================================
   3. CONVERSÃO ENTRE "0 = vazio" E VARIÁVEIS LÓGICAS
   ========================================================================= */

%!  grid_vars(+Grid, -Vars) is det.
%
%   Troca cada 0 do tabuleiro por uma variável lógica nova (livre), e
%   mantém os demais números. Exemplo:
%
%       ?- grid_vars([[5,0,3]], V).
%       V = [[5, _A, 3]].
%
%   Usamos maplist/3 duas vezes, aninhado: o de fora percorre as linhas, e
%   `maplist(cell_var)` (uma "aplicação parcial") percorre as casas.
grid_vars(Grid, Vars) :-
    maplist(maplist(cell_var), Grid, Vars).

%   cell_var(+Number, -Var)
%   O "!" (corte / cut) impede que o Prolog tente a segunda cláusula quando
%   a primeira já casou. Sem ele, cell_var(0, X) também poderia responder
%   X = 0 no backtracking, o que estaria errado.
cell_var(0, _Fresh) :- !.
cell_var(N, N).


/* =========================================================================
   4. RESOLVER
   ========================================================================= */

%!  solve(+Puzzle, -Solution) is semidet.
%!  solve(+Variant, +Puzzle, -Solution) is semidet.
%
%   Solution é uma solução de Puzzle segundo as regras de Variant. Falha se
%   o puzzle não tiver solução. solve/2 é o Sudoku clássico.
%   "semidet" significa: ou tem sucesso uma única vez, ou falha.
solve(Puzzle, Solution) :-
    solve(classic, Puzzle, Solution).

solve(Variant, Puzzle, Solution) :-
    check_variant(Variant),
    grid_vars(Puzzle, Solution),
    sudoku_constraints(Variant, Solution),
    append(Solution, Cells),

    % labeling/2 atribui valores concretos às variáveis, fazendo busca com
    % backtracking. A opção `ff` ("first fail") escolhe primeiro a variável
    % com o MENOR domínio restante, heurística clássica que torna a busca
    % muito mais rápida.
    labeling([ff], Cells),

    % Queremos apenas a primeira solução: o corte descarta as demais.
    !.

%!  count_solutions(+Puzzle, +Limit, -Count) is det.
%!  count_solutions(+Variant, +Puzzle, +Limit, -Count) is det.
%
%   Count é o número de soluções de Puzzle, contando no máximo até Limit.
%   Usado para verificar se um puzzle tem solução ÚNICA (Count == 1 com
%   Limit = 2): não precisamos saber se são 2 ou 2 milhões, basta saber que
%   há mais de uma.
count_solutions(Puzzle, Limit, Count) :-
    count_solutions(classic, Puzzle, Limit, Count).

count_solutions(Variant, Puzzle, Limit, Count) :-
    check_variant(Variant),
    grid_vars(Puzzle, Rows),
    append(Rows, Cells),

    % findall/3 coleta TODAS as respostas de um objetivo numa lista.
    % limit/2 interrompe a enumeração depois de Limit respostas.
    % O objetivo entre parênteses é uma conjunção (vírgula = "e").
    findall(x,
            limit(Limit, ( sudoku_constraints(Variant, Rows),
                           labeling([ff], Cells) )),
            Found),
    length(Found, Count).

unique_solution(Variant, Puzzle) :-
    count_solutions(Variant, Puzzle, 2, 1).


/* =========================================================================
   5. GERADOR
   =========================================================================

   Algoritmo em duas etapas:

   (a) Gerar um tabuleiro COMPLETO e aleatório. Usamos o mesmo modelo de
       restrições, mas com uma rotina de labeling que testa os valores em
       ordem aleatória. Assim, cada execução produz uma grade diferente.

   (b) "Cavar buracos": percorremos as 81 casas em ordem aleatória e
       tentamos apagar cada uma. Se o puzzle continua com solução única,
       a remoção é mantida; caso contrário, devolvemos o número. Paramos
       quando o número de pistas (casas preenchidas) chega ao alvo da
       dificuldade escolhida.

   Essa estratégia gulosa nem sempre consegue chegar a poucas pistas (o
   mínimo teórico é 17), mas para ~24 ou mais funciona bem e é rápida.

   O gerador não sabe nada de diagonais. Ele só repassa a variante para
   sudoku_constraints/2 e unique_solution/2, e isso basta: a grade
   completa sai com diagonais válidas, e um buraco só é aceito se a solução
   continuar única SEGUNDO AS REGRAS DA VARIANTE. Por isso um puzzle
   diagonal pode ter várias soluções no clássico (veja os testes).
*/

%!  difficulty_clues(?Difficulty, ?Clues) is nondet.
%
%   Fatos: quantas pistas deixar em cada nível. Ajuste à vontade!
difficulty_clues(easy,   40).
difficulty_clues(medium, 32).
difficulty_clues(hard,   26).

%!  generate(+Difficulty, -Puzzle) is det.
%!  generate(+Variant, +Difficulty, -Puzzle) is det.
generate(Difficulty, Puzzle) :-
    generate(classic, Difficulty, Puzzle).

generate(Variant, Difficulty, Puzzle) :-
    check_variant(Variant),
    % must_be/2 lança um erro legível se o argumento não for do tipo
    % esperado. oneof([...]) aceita só um dos átomos listados.
    must_be(oneof([easy, medium, hard]), Difficulty),
    difficulty_clues(Difficulty, Target),
    random_full_grid(Variant, Full),

    % numlist(0, 80, L) cria [0, 1, ..., 80]: os índices de todas as casas.
    numlist(0, 80, Indexes),
    random_permutation(Indexes, Order),
    append(Full, FlatFull),
    dig_holes(Variant, Order, Target, FlatFull, FlatPuzzle),
    rows_of_9(FlatPuzzle, Puzzle),

    % O corte final torna generate/3 determinístico: não queremos que um
    % backtracking posterior tente "gerar de novo" por caminhos alternativos.
    !.

%!  random_full_grid(+Variant, -Grid) is det.
random_full_grid(Variant, Rows) :-
    length(Rows, 9),                     % 9 linhas, cada uma ainda desconhecida
    sudoku_constraints(Variant, Rows),   % (aqui as linhas ganham 9 variáveis cada)
    append(Rows, Cells),
    random_labeling(Cells),
    !.

%!  random_labeling(+Vars) is nondet.
%
%   Versão caseira de label/1 que tenta os valores de cada variável em ordem
%   aleatória. Graças à propagação do CLP(FD), raramente precisa voltar
%   atrás (backtrack) em um tabuleiro vazio.
random_labeling([]).
random_labeling([Var | Vars]) :-
    % Construção "Se -> Então ; Senão" do Prolog.
    (   integer(Var)
    ->  true                              % já foi determinada pela propagação
    ;   fd_dom(Var, Domain),              % ex.: Domain = 1..3\/7..9

        % Enumera os valores do domínio numa lista comum, ex.: [1,2,3,7,8,9].
        findall(V, (V in Domain, indomain(V)), Values),
        random_permutation(Values, Shuffled),

        % member/2 é um PONTO DE ESCOLHA: se mais adiante alguma restrição
        % falhar, o Prolog volta aqui e tenta o próximo valor da lista.
        member(Var, Shuffled)
    ),
    random_labeling(Vars).

%!  dig_holes(+Variant, +Order, +Target, +Flat0, -Flat) is det.
%
%   Percorre os índices em Order tentando zerar cada casa. `Flat0` e `Flat`
%   são o tabuleiro "achatado" (81 elementos) antes e depois.
%
%   Repare que não há atribuição destrutiva: cada passo cria uma NOVA lista.
%   Em Prolog (e em Elm!) os dados são imutáveis.
dig_holes(_Variant, [], _Target, Flat, Flat).
dig_holes(Variant, [Index | Rest], Target, Flat0, Flat) :-
    clue_count(Flat0, Clues),
    (   Clues =< Target
    ->  Flat = Flat0                      % já chegamos ao alvo: pare
    ;   replace_nth0(Index, Flat0, 0, Candidate),
        rows_of_9(Candidate, CandidateRows),
        (   unique_solution(Variant, CandidateRows)
        ->  Next = Candidate              % remoção aceita
        ;   Next = Flat0                  % remoção recusada
        ),
        dig_holes(Variant, Rest, Target, Next, Flat)
    ).

%   clue_count(+Flat, -N): quantas casas diferentes de 0.
%   include/3 filtra uma lista (como `filter` em outras linguagens).
%   `\==` significa "não idêntico a".
clue_count(Flat, N) :-
    include(\==(0), Flat, Clues),
    length(Clues, N).

%   replace_nth0(+Index, +List, +Elem, -NewList)
%   NewList é List com o elemento na posição Index trocado por Elem.
%   nth0/4 é versátil: "remove" o elemento de uma posição e nos devolve
%   o resto; chamando de novo com o novo elemento, ele é "inserido".
replace_nth0(Index, List, Elem, NewList) :-
    nth0(Index, List, _Old, Rest),
    nth0(Index, NewList, Elem, Rest).

%   rows_of_9(?Flat, ?Rows): converte entre a lista achatada e 9 linhas.
rows_of_9([], []).
rows_of_9(Flat, [Row | Rows]) :-
    length(Row, 9),
    append(Row, Rest, Flat),   % Flat = Row ++ Rest
    rows_of_9(Rest, Rows).


/* =========================================================================
   6. DICA
   ========================================================================= */

%!  hint(+Board, -Result) is det.
%!  hint(+Variant, +Board, -Result) is det.
%
%   Board é o tabuleiro atual do jogador (pistas + o que ele já preencheu).
%   Result diz o que aconteceu:
%
%       [Row, Col, Value]   uma casa vazia, escolhida ao acaso, e o número
%                           que vai nela segundo a solução;
%       complete            não há casa vazia: o tabuleiro já está resolvido;
%       unsolvable          o tabuleiro não tem solução (o jogador errou algo).
%
%   Toda a decisão fica aqui, em Prolog. O Python só traduz cada resultado
%   numa resposta HTTP. Devolvemos uma lista, e não um termo como
%   hint(Row, Col, Value), porque o janus converte listas e átomos para o
%   Python, mas não termos compostos.
hint(Board, Result) :-
    hint(classic, Board, Result).

hint(Variant, Board, Result) :-
    (   solve(Variant, Board, Solution)
    ->  empty_positions(Board, Empty),
        (   Empty == []
        ->  Result = complete
        ;   random_member(Row-Col, Empty),
            nth0(Row, Solution, SolutionRow),
            nth0(Col, SolutionRow, Value),
            Result = [Row, Col, Value]
        )
    ;   Result = unsolvable
    ).

%   empty_positions(+Board, -Positions): todas as posições Row-Col com 0.
%   findall/3 com um objetivo composto: nth0/3 enumera, por backtracking,
%   cada linha e, dentro dela, cada casa que contém 0.
empty_positions(Board, Positions) :-
    findall(R-C,
            ( nth0(R, Board, Row),
              nth0(C, Row, 0) ),
            Positions).


/* =========================================================================
   7. UTILITÁRIOS PARA USO NO TERMINAL
   ========================================================================= */

%   Um puzzle clássico (da Wikipedia) para experimentar.
example_puzzle([[5,3,0, 0,7,0, 0,0,0],
                [6,0,0, 1,9,5, 0,0,0],
                [0,9,8, 0,0,0, 0,6,0],
                [8,0,0, 0,6,0, 0,0,3],
                [4,0,0, 8,0,3, 0,0,1],
                [7,0,0, 0,2,0, 0,0,6],
                [0,6,0, 0,0,0, 2,8,0],
                [0,0,0, 4,1,9, 0,0,5],
                [0,0,0, 0,8,0, 0,7,9]]).

%   Um puzzle diagonal criado por generate(diagonal, hard, P). Ele tem
%   solução ÚNICA no Sudoku diagonal, mas MAIS DE UMA no clássico: são as
%   restrições das diagonais que eliminam as outras. Confira no terminal:
%       ?- example_diagonal_puzzle(P), count_solutions(diagonal, P, 10, N).
%       ?- example_diagonal_puzzle(P), count_solutions(classic, P, 10, N).
example_diagonal_puzzle([[0,3,0, 0,0,4, 0,0,0],
                         [6,0,0, 0,0,5, 0,9,0],
                         [7,0,2, 9,0,6, 3,0,4],
                         [0,9,0, 0,4,0, 0,0,0],
                         [4,0,0, 0,8,0, 0,2,0],
                         [0,0,0, 0,2,0, 4,0,0],
                         [8,0,0, 0,0,0, 0,6,0],
                         [0,0,0, 0,0,0, 0,0,1],
                         [1,0,0, 7,0,0, 8,4,3]]).

%   print_grid(+Grid): imprime o tabuleiro de forma legível.
%   forall(Cond, Ação) executa Ação para cada solução de Cond.
print_grid(Grid) :-
    forall(member(Row, Grid),
           ( maplist(format_cell, Row), nl )).

format_cell(0) :- !, write(' .').
format_cell(N) :- format(' ~w', [N]).
