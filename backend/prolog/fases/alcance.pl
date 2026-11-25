:- module(alcance, [fase/1, diagnostico/4, alcance/3]).

:- use_module('../motor').
:- use_module(library(lists)).

fase(Fase) :-
    fase_combinada("Alcance", [2-3], 1-3, [2-(2-2), 4-(2-4)], Fase).

alcance(Fase, estado(Jogador, Caixas, _), Casas) :-
    visitar(Fase, Caixas, [Jogador], [Jogador], Alcancadas),
    sort(Alcancadas, Casas).

visitar(_, _, [], Visitadas, Visitadas) :-
    !.
visitar(Fase, Caixas, [Atual|Fila], Visitadas, Casas) :-
    findall(Proxima,
            ( vizinha(Atual, _, Proxima),
              livre(Fase, Caixas, Proxima),
              \+ memberchk(Proxima, Visitadas)
            ),
            Novas),
    append(Fila, Novas, Fila1),
    append(Visitadas, Novas, Visitadas1),
    visitar(Fase, Caixas, Fila1, Visitadas1, Casas).

diagnostico(Fase, Estado, padrao, ajuda(Texto, Destaques, [casas-Total])) :-
    alcance(Fase, Estado, Casas),
    length(Casas, Total),
    maplist(destaque, Casas, Destaques),
    format(string(Texto),
           'O jogador alcanca ~d casas sem mexer nas caixas.',
           [Total]).

destaque(Posicao, armazem(Posicao, alcance)).
