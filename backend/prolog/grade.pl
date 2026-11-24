:- module(grade,
          [ unidades/2,
            sudoku/1,
            conclusao/2,
            admite_conclusao/1,
            completa/1
          ]).

:- use_module(library(clpfd)).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).

unidades([L1, L2, L3, L4], Unidades) :-
    transpose([L1, L2, L3, L4], [C1, C2, C3, C4]),
    blocos(L1, L2, B1, B2),
    blocos(L3, L4, B3, B4),
    Unidades = [ linha(1)-L1, linha(2)-L2, linha(3)-L3, linha(4)-L4,
                 coluna(1)-C1, coluna(2)-C2, coluna(3)-C3, coluna(4)-C4,
                 bloco(1)-B1, bloco(2)-B2, bloco(3)-B3, bloco(4)-B4 ].

blocos([A, B, C, D], [E, F, G, H], [A, B, E, F], [C, D, G, H]).

sudoku(Linhas) :-
    length(Linhas, 4),
    maplist(same_length(Linhas), Linhas),
    append(Linhas, Casas),
    Casas ins 1..4,
    unidades(Linhas, Unidades),
    pairs_values(Unidades, Grupos),
    maplist(all_distinct, Grupos).

conclusao(Grade, Solucao) :-
    maplist(maplist(casa_variavel), Grade, Solucao),
    sudoku(Solucao),
    append(Solucao, Casas),
    once(label(Casas)).

admite_conclusao(Grade) :-
    conclusao(Grade, _).

completa(Grade) :-
    append(Grade, Casas),
    \+ memberchk(0, Casas),
    sudoku(Grade).

casa_variavel(0, _) :- !.
casa_variavel(Valor, Valor).
