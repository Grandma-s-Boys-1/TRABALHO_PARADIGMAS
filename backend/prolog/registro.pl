:- module(registro, [fases_registradas/1]).

:- use_module(fases/tutorial, []).
:- use_module(fases/comum, []).
:- use_module(fases/candidatos, []).
:- use_module(fases/dica, []).
:- use_module(fases/canto, []).
:- use_module(fases/troca, []).
:- use_module(fases/largadas, []).
:- use_module(fases/fila, []).
:- use_module(fases/alcance, []).

fases_base([tutorial, comum]).

modulos([candidatos, dica, canto, troca, largadas, fila, alcance]).

fases_registradas(Fases) :-
    fases_base(Base),
    modulos(Modulos),
    append(Base, Modulos, Fases).
