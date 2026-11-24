:- module(canto, [fase/1, diagnostico/4, presas_no_canto/3]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module('../motor').

fase(Fase) :-
    fase_combinada("Canto", [], 3-2, [2-(2-2), 4-(2-4)], Fase).

presas_no_canto(Fase, estado(_, Caixas, _), Presas) :-
    include(presa(Fase), Caixas, Presas).

presa(Fase, _-Posicao) :-
    \+ alvo(Fase, _, Posicao),
    encostada(Fase, Posicao, [cima, baixo]),
    encostada(Fase, Posicao, [esquerda, direita]).

encostada(Fase, Posicao, Direcoes) :-
    once(( member(Direcao, Direcoes), parede(Fase, Posicao, Direcao) )).

parede(Fase, Posicao, Direcao) :-
    vizinha(Posicao, Direcao, Vizinha),
    \+ piso(Fase, Vizinha).

diagnostico(Fase, Estado, padrao, ajuda(Texto, Destaques, [presas-Lista])) :-
    presas_no_canto(Fase, Estado, Presas),
    maplist(destaque, Presas, Destaques),
    maplist(dado, Presas, Lista),
    length(Presas, Total),
    texto(Total, Texto).

destaque(_-Posicao, armazem(Posicao, alerta)).

dado(Numero-(L-C), [Numero, L, C]).

texto(Total, Texto) :-
    ( Total =:= 0 -> Texto = "Nenhuma caixa presa em canto."
    ; Total =:= 1 -> Texto = "Uma caixa presa em canto fora dos alvos: reinicie a fase."
    ; format(string(Texto), "~d caixas presas em canto fora dos alvos.", [Total])
    ).
