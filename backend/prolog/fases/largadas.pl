:- module(largadas, [fase/1, diagnostico/4, largadas/3]).

:- use_module('../motor').

limite(2).

fase(Fase) :-
    fase_combinada("Largadas", [], 4-3, [2-(2-2), 4-(2-4)], Fase).

largadas(Fase, Estado, Opcoes) :-
    melhores(Fase, Estado, Pares),
    pairs_values(Pares, Opcoes).

melhores(Fase, Estado, Melhores) :-
    findall(Total-(N-D), largada(Fase, Estado, N, D, Total), Pares),
    msort(Pares, Ordenados),
    limite(Limite),
    primeiros(Limite, Ordenados, Melhores).

largada(Fase, Estado, N, D, Total) :-
    Estado = estado(_, Caixas, Entradas),
    member(N-Posicao, Caixas),
    direcao(D),
    oposta(D, O),
    vizinha(Posicao, O, Atras),
    caminho_minimo(caminhada(Fase), Estado, jogador_em(Atras), Andar),
    once(movimento(Fase, estado(Atras, Caixas, Entradas), D, empurrao(N), Depois)),
    rota_vencedora(Fase, Depois, Resto),
    length(Andar, A),
    length(Resto, R),
    Total is A + 1 + R.

jogador_em(P, estado(P, _, _)).

primeiros(Limite, Lista, Primeiros) :-
    length(Lista, Tamanho),
    K is min(Limite, Tamanho),
    length(Primeiros, K),
    append(Primeiros, _, Lista).

diagnostico(Fase, Estado, padrao, ajuda(Texto, Destaques, [opcoes-Lista])) :-
    melhores(Fase, Estado, Pares),
    Estado = estado(_, Caixas, _),
    findall(armazem(Posicao, opcao),
            ( member(_-(N-_), Pares), memberchk(N-Posicao, Caixas) ),
            Repetidos),
    sort(Repetidos, Destaques),
    findall([N, D, T], member(T-(N-D), Pares), Lista),
    texto(Pares, Texto).

texto([], "Nenhum empurrao inicial ainda leva a vitoria.").
texto([P|Ps], Texto) :-
    findall(Item,
            ( member(T-(N-D), [P|Ps]),
              format(string(Item), "caixa ~d para ~w (~d passos)", [N, D, T]) ),
            Itens),
    atomic_list_concat(Itens, ", ", Juntos),
    format(string(Texto), "Largadas que ainda vencem: ~w.", [Juntos]).
