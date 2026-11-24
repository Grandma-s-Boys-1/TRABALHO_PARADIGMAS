:- module(dica, [fase/1, diagnostico/4, primeiro_empurrao/5]).

:- use_module(library(apply)).
:- use_module('../motor').

fase(Fase) :-
    fase_combinada("Dica", [], 3-3, [2-(2-2), 4-(2-4)], Fase).

primeiro_empurrao(Fase, Estado, Caminhada, Numero, Direcao) :-
    rota_vencedora(Fase, Estado, Rota),
    separar(Rota, Fase, Estado, Caminhada, Numero, Direcao).

separar([Passo|Resto], Fase, Estado, Caminhada, Numero, Direcao) :-
    once(movimento(Fase, Estado, Passo, Tipo, Proximo)),
    ( Tipo = empurrao(Numero) ->
        Caminhada = [],
        Direcao = Passo
    ; Caminhada = [Passo|Caminhada1],
      separar(Resto, Fase, Proximo, Caminhada1, Numero, Direcao)
    ).

diagnostico(Fase, Estado, padrao, ajuda(Texto, Destaques, Dados)) :-
    ( primeiro_empurrao(Fase, Estado, Caminhada, Numero, Direcao) ->
        rota_vencedora(Fase, Estado, Rota),
        length(Rota, Total),
        destaques(Estado, Caminhada, Numero, Direcao, Destaques),
        texto(Caminhada, Numero, Direcao, Texto),
        Dados = [caminhada-Caminhada, caixa-Numero, empurrao-Direcao, total-Total]
    ; Texto = "Nenhum empurrao a sugerir a partir daqui.",
      Destaques = [],
      Dados = []
    ).

destaques(Estado, Caminhada, Numero, Direcao, [Caixa, Destino|Trilha]) :-
    Estado = estado(Jogador, _, _),
    caixa_em(Estado, Posicao, Numero),
    vizinha(Posicao, Direcao, Alvo),
    Caixa = armazem(Posicao, caixa),
    Destino = armazem(Alvo, destino),
    casas(Jogador, Caminhada, Casas),
    maplist(passo, Casas, Trilha).

passo(Casa, armazem(Casa, passo)).

casas(_, [], []).
casas(Posicao, [Direcao|Resto], [Proxima|Casas]) :-
    vizinha(Posicao, Direcao, Proxima),
    casas(Proxima, Resto, Casas).

texto([], Numero, Direcao, Texto) :-
    format(string(Texto), "Empurre a caixa ~d para ~w.", [Numero, Direcao]).
texto([D|Ds], Numero, Direcao, Texto) :-
    maplist(letra, [D|Ds], Letras),
    atomic_list_concat(Letras, ', ', Lista),
    format(string(Texto), "Caminhe ~w e empurre a caixa ~d para ~w.",
           [Lista, Numero, Direcao]).

letra(Direcao, Letra) :-
    sub_atom(Direcao, 0, 1, _, Inicial),
    upcase_atom(Inicial, Letra).
