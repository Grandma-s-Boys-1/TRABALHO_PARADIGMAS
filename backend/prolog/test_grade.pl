:- use_module(grade).
:- use_module(library(clpfd)).
:- use_module(library(plunit)).

:- begin_tests(grade).

inicial([[1, 0, 0, 4], [3, 4, 0, 0], [2, 1, 0, 3], [4, 3, 0, 1]]).

solucao(Grade, Solucao) :-
    maplist(maplist(variavel), Grade, Solucao),
    sudoku(Solucao),
    append(Solucao, Casas),
    label(Casas).

variavel(0, _) :- !.
variavel(Valor, Valor).

test(solucao_unica, true(Solucoes == [Unica])) :-
    Unica = [[1, 2, 3, 4], [3, 4, 1, 2], [2, 1, 4, 3], [4, 3, 2, 1]],
    inicial(Grade),
    findall(Solucao, solucao(Grade, Solucao), Solucoes).

test(admite_mas_nao_completa) :-
    inicial(Grade),
    admite_conclusao(Grade),
    \+ completa(Grade).

test(completa) :-
    completa([[1, 2, 3, 4], [3, 4, 1, 2], [2, 1, 4, 3], [4, 3, 2, 1]]).

test(repeticao_impede_conclusao, fail) :-
    admite_conclusao([[1, 4, 0, 4], [3, 4, 0, 0], [2, 1, 0, 3], [4, 3, 0, 1]]).

test(contradicao_sem_repeticao, fail) :-
    admite_conclusao([[1, 0, 2, 4], [3, 4, 0, 0], [2, 1, 0, 3], [4, 3, 0, 1]]).

test(nomes_das_unidades, true(Nomes == [linha(1), linha(2), linha(3), linha(4),
                                        coluna(1), coluna(2), coluna(3), coluna(4),
                                        bloco(1), bloco(2), bloco(3), bloco(4)])) :-
    inicial(Grade),
    unidades(Grade, Unidades),
    pairs_keys(Unidades, Nomes).

test(bloco_superior_direito, true(Bloco == [0, 4, 0, 0])) :-
    inicial(Grade),
    unidades(Grade, Unidades),
    memberchk(bloco(2)-Bloco, Unidades).

:- end_tests(grade).
