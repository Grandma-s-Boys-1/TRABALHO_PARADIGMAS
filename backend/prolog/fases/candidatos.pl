:- module(candidatos, [fase/1, diagnostico/4, candidatos/4]).

:- use_module('../motor').
:- use_module('../grade').

fase(Fase) :-
    fase_combinada("Candidatos", [], 2-3, [2-(2-2), 4-(2-4)], Fase).

candidatos(Fase, Estado, Posicao, Valores) :-
    grade_atual(Fase, Estado, Grade),
    tipo_casa(Fase, Posicao, Tipo),
    valores(Tipo, Grade, Posicao, Valores).

valores(pista(Valor), _, _, [Valor]).
valores(editavel, Grade, Posicao, Valores) :-
    admitidos(Grade, Posicao, Valores).
valores(ligada(_), Grade, Posicao, Valores) :-
    admitidos(Grade, Posicao, Valores).

admitidos(Grade, Posicao, Valores) :-
    findall(Valor,
            ( between(1, 4, Valor),
              colocar(Grade, Posicao, Valor, Tentativa),
              admite_conclusao(Tentativa) ),
            Valores).

colocar(Grade, L-C, Valor, Nova) :-
    nth1(L, Grade, Linha, OutrasLinhas),
    nth1(C, Linha, _, OutrasCasas),
    nth1(C, NovaLinha, Valor, OutrasCasas),
    nth1(L, Nova, NovaLinha, OutrasLinhas).

diagnostico(Fase, Estado, casa(L, C), ajuda(Texto, Destaques, [candidatos-Valores])) :-
    candidatos(Fase, Estado, L-C, Valores),
    Destaques = [sudoku(L-C, consulta)],
    texto(L-C, Valores, Texto).

texto(L-C, Valores, Texto) :-
    ( Valores == [] -> format(string(Texto), "L~dC~d nao admite nenhum numero.", [L, C])
    ; atomic_list_concat(Valores, ', ', Lista),
      format(string(Texto), "L~dC~d admite: ~w", [L, C, Lista])
    ).
