:- module(comum, [fase/1]).

:- use_module('../motor').

fase(Fase) :-
    fase_combinada("Fase comum", [], 1-3, [2-(2-2), 4-(2-4)], Fase).
