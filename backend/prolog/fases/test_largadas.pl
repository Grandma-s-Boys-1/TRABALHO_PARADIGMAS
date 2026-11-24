:- use_module(largadas).
:- use_module('../motor').
:- use_module(library(plunit)).

:- begin_tests(largadas).

inicial(Fase, Estado) :-
    largadas:fase(Fase),
    inicio(Fase, Estado).

test(inicio, true(Opcoes == [2-baixo, 4-baixo])) :-
    inicial(Fase, Estado),
    largadas(Fase, Estado, Opcoes).

test(depois_de_ccc, true(Opcoes == [2-baixo, 4-baixo])) :-
    inicial(Fase, Estado),
    percurso("CCC", Direcoes),
    executar(Fase, Estado, Direcoes, Final),
    Final = estado(1-3, _, _),
    largadas(Fase, Final, Opcoes).

test(rota_minima, true(Passos == 9)) :-
    inicial(Fase, Estado),
    rota_vencedora(Fase, Estado, Caminho),
    length(Caminho, Passos).

test(diagnostico, true(Lista == [[2, baixo, 9], [4, baixo, 9]])) :-
    inicial(Fase, Estado),
    largadas:diagnostico(Fase, Estado, padrao, ajuda(_, Destaques, [opcoes-Lista])),
    Destaques == [armazem(2-2, opcao), armazem(2-4, opcao)].

:- end_tests(largadas).
