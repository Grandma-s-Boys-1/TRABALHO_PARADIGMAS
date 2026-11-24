:- module(fila, [fase/1, diagnostico/4, bloqueio/4]).

:- use_module('../motor').

fase(Fase) :-
    fase_combinada("Fila", [], 2-1, [2-(2-2), 4-(2-3)], Fase).

bloqueio(Fase, estado(Jogador, Caixas, _), Direcao, Motivo) :-
    vizinha(Jogador, Direcao, Vizinha),
    ( \+ piso(Fase, Vizinha) -> Motivo = parede
    ; memberchk(Numero-Vizinha, Caixas) ->
        bloqueio_caixa(Fase, Caixas, Numero-Vizinha, Direcao, Motivo)
    ).

bloqueio_caixa(Fase, Caixas, Numero-Posicao, Direcao, Motivo) :-
    vizinha(Posicao, Direcao, Destino),
    ( memberchk(Outra-Destino, Caixas) -> Motivo = fila(Numero, Outra)
    ; \+ piso(Fase, Destino) -> Motivo = caixa_na_parede(Numero)
    ).

diagnostico(Fase, Estado, direcao(Direcao), ajuda(Texto, Destaques, Dados)) :-
    motivo(Fase, Estado, Direcao, Motivo),
    numeros(Motivo, Nome, Numeros),
    maplist(caixa_dado(Estado), Numeros, Caixas),
    maplist(destaque, Caixas, Destaques),
    texto(Motivo, Direcao, Texto),
    Dados = [motivo-Nome, caixas-Caixas].

motivo(Fase, Estado, Direcao, Motivo) :-
    ( bloqueio(Fase, Estado, Direcao, Bloqueio) -> Motivo = Bloqueio
    ; Motivo = livre
    ).

numeros(fila(N1, N2), fila, [N1, N2]).
numeros(caixa_na_parede(N), caixa_na_parede, [N]).
numeros(parede, parede, []).
numeros(livre, livre, []).

caixa_dado(Estado, Numero, [Numero, L, C]) :-
    caixa_em(Estado, L-C, Numero).

destaque([_, L, C], armazem(L-C, alerta)).

texto(fila(N1, N2), Direcao, Texto) :-
    format(string(Texto),
           "Bloqueado para ~w: a caixa ~d encosta na caixa ~d. So da para empurrar uma caixa.",
           [Direcao, N1, N2]).
texto(caixa_na_parede(N), Direcao, Texto) :-
    format(string(Texto), "Bloqueado para ~w: a caixa ~d encosta na parede.", [Direcao, N]).
texto(parede, Direcao, Texto) :-
    format(string(Texto), "Bloqueado para ~w: o jogador encosta na parede.", [Direcao]).
texto(livre, _, "Movimento livre.").
