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

test(inicio_so_caminhadas, true(Tipos == [caminhada, caminhada, caminhada, caminhada])) :-
    inicial(Fase, Estado),
    findall(Tipo, movimento(Fase, Estado, _, Tipo, _), Tipos).

test(primeiro_empurrao, true(Plano == [cima, cima, direita]-4-baixo)) :-
    inicial(Fase, Estado),
    primeiro_empurrao(Fase, Estado, Caminhada, Numero, Direcao),
    Plano = Caminhada-Numero-Direcao.

test(rota_minima, true(Passos == 8)) :-
    inicial(Fase, Estado),
    rota_vencedora(Fase, Estado, Rota),
    length(Rota, Passos).

test(empurrao_imediato, true(Plano == []-4-baixo)) :-
    depois("CCD", Fase, Estado),
    primeiro_empurrao(Fase, Estado, Caminhada, Numero, Direcao),
    Plano = Caminhada-Numero-Direcao.

test(segunda_caixa, true(Plano == [cima, esquerda, esquerda]-2-baixo)) :-
    depois("CCDB", Fase, Estado),
    primeiro_empurrao(Fase, Estado, Caminhada, Numero, Direcao),
    Plano = Caminhada-Numero-Direcao.

test(alvos_prontos, fail) :-
    depois("CCDBCEEB", Fase, Estado),
    primeiro_empurrao(Fase, Estado, _, _, _).

test(diagnostico_inicial,
     true(Ajuda == ajuda("Caminhe C, C, D e empurre a caixa 4 para baixo.",
                         [ armazem(2-3, passo), armazem(1-3, passo), armazem(1-4, passo),
                           armazem(2-4, dica), armazem(3-4, destino) ],
                         [caminhada-[cima, cima, direita], caixa-4, direcao-baixo]))) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, padrao, Ajuda).

test(diagnostico_sem_caminhada,
     true(Ajuda == ajuda("Empurre a caixa 4 para baixo.",
                         [armazem(2-4, dica), armazem(3-4, destino)],
                         [caminhada-[], caixa-4, direcao-baixo]))) :-
    depois("CCD", Fase, Estado),
    diagnostico(Fase, Estado, padrao, Ajuda).

test(diagnostico_sem_empurrao, true(Dados == [])) :-
    depois("CCDBCEEB", Fase, Estado),
    diagnostico(Fase, Estado, padrao, ajuda(_, _, Dados)).

test(outra_consulta_falha, fail) :-
    inicial(Fase, Estado),
    diagnostico(Fase, Estado, casa(1, 3), _).

:- end_tests(dica).
