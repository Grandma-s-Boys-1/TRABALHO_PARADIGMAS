:- module(registro, [fases_registradas/1]).

:- use_module(fases/tutorial, []).
:- use_module(fases/comum, []).

fases_base([tutorial, comum]).

modulos([]).

fases_registradas(Fases) :-
    fases_base(Base),
    modulos(Modulos),
    append(Base, Modulos, Fases).
