:- use_module(alcance).
:- use_module('../motor').
:- use_module(library(plunit)).

:- begin_tests(alcance).

test(casas_alcancadas_sem_caixas) :-
    fase(Fase),
    inicio(Fase, Estado),
    alcance(Fase, Estado, Casas),
    length(Casas, 17),
    memberchk(3-3, Casas),
    \+ memberchk(2-2, Casas),
    \+ memberchk(2-3, Casas),
    \+ memberchk(2-4, Casas).

test(caminhada_minima_ate_3_3) :-
    fase(Fase),
    inicio(Fase, Estado),
    caminho_minimo(caminhada(Fase), Estado, jogador_em(3-3), Caminho),
    length(Caminho, 6).

test(rota_vencedora_tem_seis_passos) :-
    fase(Fase),
    inicio(Fase, Estado),
    rota_vencedora(Fase, Estado, Caminho),
    length(Caminho, 6).

:- end_tests(alcance).

jogador_em(Posicao, estado(Posicao, _, _)).
