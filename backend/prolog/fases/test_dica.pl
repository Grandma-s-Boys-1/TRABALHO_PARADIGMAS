:- use_module(dica).
:- use_module('../motor').
:- use_module(library(plunit)).

:- begin_tests(dica).

inicial(Fase, Estado) :-
    fase(Fase),
    inicio(Fase, Estado).

depois(Texto, Fase, Final) :-
    inicial(Fase, Estado),
    percurso(Texto, Direcoes),
    executar(Fase, Estado, Direcoes, Final).

test(inicio) :-
    inicial(Fase, Estado),
    primeiro_empurrao(Fase, Estado, [cima, cima, direita], 4, baixo).

test(sem_empurrao_no_inicio) :-
    inicial(Fase, Estado),
    \+ movimento(Fase, Estado, _, empurrao(_), _).

test(rota_minima, true(Passos == 8)) :-
    inicial(Fase, Estado),
    rota_vencedora(Fase, Estado, Rota),
    length(Rota, Passos).

test(empurrao_imediato) :-
    depois("CCD", Fase, Estado),
    primeiro_empurrao(Fase, Estado, [], 4, baixo).

test(segunda_caixa) :-
    depois("CCDB", Fase, Estado),
    primeiro_empurrao(Fase, Estado, [cima, esquerda, esquerda], 2, baixo).

test(alvos_prontos, fail) :-
    depois("CCDBCEEB", Fase, Estado),
    primeiro_empurrao(Fase, Estado, _, _, _).

test(diagnostico_inicial,
     true(Ajuda == ajuda("Caminhe C, C, D e empurre a caixa 4 para baixo.",
                         [ armazem(2-4, caixa), armazem(3-4, destino), armazem(2-3, passo),
                           armazem(1-3, passo), armazem(1-4, passo) ],
                         [ caminhada-[cima, cima, direita], caixa-4, empurrao-baixo,
                           total-8 ]))) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, padrao, Ajuda).

test(diagnostico_sem_caminhada,
     true(Ajuda == ajuda("Empurre a caixa 4 para baixo.",
                         [armazem(2-4, caixa), armazem(3-4, destino)],
                         [caminhada-[], caixa-4, empurrao-baixo, total-5]))) :-
    depois("CCD", Fase, Estado),
    diagnostico(Fase, Estado, padrao, Ajuda).

test(diagnostico_sem_empurrao, true(Dados == [])) :-
    depois("CCDBCEEB", Fase, Estado),
    diagnostico(Fase, Estado, padrao, ajuda(_, _, Dados)).

test(outra_consulta_falha, fail) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, casa(1, 3), _).

:- end_tests(dica).
