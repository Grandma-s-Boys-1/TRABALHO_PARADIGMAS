:- module(motor,
          [ fase_classica/5,
            fase_combinada/5,
            inicio/2,
            alvo/3,
            direcao/1,
            oposta/2,
            vizinha/3,
            piso/2,
            livre/3,
            caixa_em/3,
            movimento/5,
            passo/4,
            caminhada/4,
            caminho_minimo/4,
            percurso/2,
            executar/4,
            tipo_casa/3,
            valor_ligado/4,
            grade_atual/3,
            alvos_ocupados/2,
            pronto/2,
            vitoria/2,
            situacao/3,
            rota_vencedora/3,
            jogar/5,
            estado_valido/2,
            dica/3
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(library(assoc)).
:- use_module(grade).

:- meta_predicate caminho_minimo(3, +, 1, -).

pistas_padrao([[1, 0, 0, 4],
               [3, 4, 0, 0],
               [2, 1, 0, 3],
               [4, 3, 0, 1]]).

vazias([[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]).

fase_classica(Nome, Paredes, Jogador, Caixas, Fase) :-
    fase_padrao(Nome, Paredes, classica, Jogador, Caixas, Fase).

fase_combinada(Nome, Paredes, Jogador, Caixas, Fase) :-
    pistas_padrao(Pistas),
    Regra = combinada(Pistas, [a-(1-2), b-(3-3)]),
    fase_padrao(Nome, Paredes, Regra, Jogador, Caixas, Fase).

fase_padrao(Nome, Paredes, Regra, Jogador, Caixas, Fase) :-
    sort(Caixas, Ordenadas),
    vazias(Entradas),
    Fase = fase(Nome,
                armazem(4, 5, Paredes, [a-(3-2), b-(3-4)]),
                Regra,
                estado(Jogador, Ordenadas, Entradas)).

inicio(fase(_, _, _, Estado), Estado).

alvo(fase(_, armazem(_, _, _, Alvos), _, _), Letra, Posicao) :-
    member(Letra-Posicao, Alvos).

delta(cima, -1, 0).
delta(baixo, 1, 0).
delta(esquerda, 0, -1).
delta(direita, 0, 1).

direcao(Direcao) :-
    delta(Direcao, _, _).

oposta(cima, baixo).
oposta(baixo, cima).
oposta(esquerda, direita).
oposta(direita, esquerda).

vizinha(L-C, Direcao, L1-C1) :-
    delta(Direcao, DL, DC),
    L1 is L + DL,
    C1 is C + DC.

piso(fase(_, armazem(Linhas, Colunas, Paredes, _), _, _), L-C) :-
    between(1, Linhas, L),
    between(1, Colunas, C),
    \+ memberchk(L-C, Paredes).

livre(Fase, Caixas, Posicao) :-
    piso(Fase, Posicao),
    \+ memberchk(_-Posicao, Caixas).

caixa_em(estado(_, Caixas, _), Posicao, Numero) :-
    memberchk(Numero-Posicao, Caixas).

movimento(Fase, estado(J, Caixas, E), Direcao, caminhada, estado(J1, Caixas, E)) :-
    vizinha(J, Direcao, J1),
    livre(Fase, Caixas, J1).
movimento(Fase, estado(J, Caixas, E), Direcao, empurrao(N), estado(J1, Caixas1, E)) :-
    vizinha(J, Direcao, J1),
    select(N-J1, Caixas, Outras),
    vizinha(J1, Direcao, Destino),
    livre(Fase, Outras, Destino),
    sort([N-Destino|Outras], Caixas1).

passo(Fase, Estado, Direcao, Proximo) :-
    movimento(Fase, Estado, Direcao, _, Proximo).

caminhada(Fase, Estado, Direcao, Proximo) :-
    movimento(Fase, Estado, Direcao, caminhada, Proximo).

caminho_minimo(Passo, Inicio, Objetivo, Caminho) :-
    list_to_assoc([Inicio-sim], Visitados),
    largura(Passo, Objetivo, [Inicio-[]], Visitados, Inverso),
    reverse(Inverso, Caminho).

largura(_, Objetivo, Fila, _, Caminho) :-
    member(Estado-Caminho, Fila),
    call(Objetivo, Estado),
    !.
largura(Passo, Objetivo, Fila, Visitados, Caminho) :-
    Fila \== [],
    findall(Proximo-[Direcao|Anterior],
            ( member(Estado-Anterior, Fila),
              call(Passo, Estado, Direcao, Proximo) ),
            Pares),
    sort(1, @<, Pares, Unicos),
    exclude(visitado(Visitados), Unicos, Novos),
    foldl(visitar, Novos, Visitados, Visitados1),
    largura(Passo, Objetivo, Novos, Visitados1, Caminho).

visitado(Visitados, Estado-_) :-
    get_assoc(Estado, Visitados, _).

visitar(Estado-_, Visitados0, Visitados) :-
    put_assoc(Estado, Visitados0, sim, Visitados).

percurso(Texto, Direcoes) :-
    string_chars(Texto, Letras),
    maplist(letra, Letras, Direcoes).

letra('C', cima).
letra('B', baixo).
letra('E', esquerda).
letra('D', direita).

executar(Fase, Estado, Direcoes, Final) :-
    foldl(avancar(Fase), Direcoes, Estado, Final).

avancar(Fase, Direcao, Estado, Proximo) :-
    once(passo(Fase, Estado, Direcao, Proximo)).

tipo_casa(fase(_, _, combinada(Pistas, Ligacoes), _), L-C, Tipo) :-
    nth1(L, Pistas, Linha),
    nth1(C, Linha, Pista),
    ( memberchk(Letra-(L-C), Ligacoes) -> Tipo = ligada(Letra)
    ; Pista > 0 -> Tipo = pista(Pista)
    ; Tipo = editavel
    ).

valor_ligado(Fase, Estado, Letra, Valor) :-
    once(alvo(Fase, Letra, Posicao)),
    ( caixa_em(Estado, Posicao, Numero) -> Valor = Numero
    ; Valor = 0
    ).

grade_atual(Fase, Estado, Grade) :-
    numlist(1, 4, Indices),
    maplist(linha_atual(Fase, Estado, Indices), Indices, Grade).

linha_atual(Fase, Estado, Indices, L, Linha) :-
    maplist(valor_atual(Fase, Estado, L), Indices, Linha).

valor_atual(Fase, Estado, L, C, Valor) :-
    tipo_casa(Fase, L-C, Tipo),
    valor_tipo(Tipo, Fase, Estado, L-C, Valor).

valor_tipo(pista(Valor), _, _, _, Valor).
valor_tipo(ligada(Letra), Fase, Estado, _, Valor) :-
    valor_ligado(Fase, Estado, Letra, Valor).
valor_tipo(editavel, _, estado(_, _, Entradas), L-C, Valor) :-
    nth1(L, Entradas, Linha),
    nth1(C, Linha, Valor).

alvos_ocupados(Fase, Estado) :-
    forall(alvo(Fase, _, Posicao), caixa_em(Estado, Posicao, _)).

pronto(Fase, Estado) :-
    alvos_ocupados(Fase, Estado),
    Fase = fase(_, _, Regra, _),
    grade_coerente(Regra, Fase, Estado).

vitoria(Fase, Estado) :-
    alvos_ocupados(Fase, Estado),
    Fase = fase(_, _, Regra, _),
    grade_resolvida(Regra, Fase, Estado).

grade_coerente(classica, _, _).
grade_coerente(combinada(_, _), Fase, Estado) :-
    grade_atual(Fase, Estado, Grade),
    admite_conclusao(Grade).

grade_resolvida(classica, _, _).
grade_resolvida(combinada(_, _), Fase, Estado) :-
    grade_atual(Fase, Estado, Grade),
    completa(Grade).

situacao(Fase, Estado, Situacao) :-
    ( vitoria(Fase, Estado) -> Situacao = vitoria
    ; Situacao = jogando
    ).

rota_vencedora(Fase, Estado, Caminho) :-
    caminho_minimo(passo(Fase), Estado, pronto(Fase), Caminho).

jogar(Fase, Estado, Direcao, Proximo, Resultado) :-
    ( movimento(Fase, Estado, Direcao, Tipo, Seguinte) ->
        Proximo = Seguinte,
        resultado(Tipo, Resultado)
    ; Proximo = Estado,
      Resultado = bloqueado
    ).

resultado(caminhada, caminhada).
resultado(empurrao(_), empurrao).

estado_valido(Fase, estado(Jogador, Caixas, Entradas)) :-
    inicio(Fase, estado(_, Iniciais, _)),
    pairs_keys(Iniciais, Numeros),
    pairs_keys_values(Caixas, Numeros, Posicoes),
    is_set(Posicoes),
    maplist(piso(Fase), [Jogador|Posicoes]),
    \+ memberchk(Jogador, Posicoes),
    entradas_validas(Fase, Entradas).

entradas_validas(Fase, Entradas) :-
    length(Entradas, 4),
    forall(( nth1(L, Entradas, Linha), nth1(C, Linha, Valor), Valor =\= 0 ),
           ( between(1, 4, Valor), tipo_casa(Fase, L-C, editavel) )).

dica(Fase, Estado, Ajuda) :-
    ( vitoria(Fase, Estado) -> Ajuda = ajuda("Fase concluida.", [], [situacao-vitoria])
    ; \+ entradas_coerentes(Fase, Estado) -> ajuda_revisar(Estado, Ajuda)
    ; rota_vencedora(Fase, Estado, Caminho) -> ajuda_rota(Fase, Estado, Caminho, Ajuda)
    ; ajuda_impasse(Estado, Ajuda)
    ).

entradas_coerentes(Fase, estado(Jogador, _, Entradas)) :-
    Fase = fase(_, _, Regra, _),
    grade_coerente(Regra, Fase, estado(Jogador, [], Entradas)).

ajuda_revisar(estado(_, _, Entradas), ajuda(Texto, Destaques, [situacao-revisar])) :-
    findall(sudoku(L-C, revisar),
            ( nth1(L, Entradas, Linha), nth1(C, Linha, Valor), Valor > 0 ),
            Destaques),
    Texto = "Revise as entradas destacadas: com elas a grade nao tem conclusao.".

ajuda_rota(Fase, Estado, [], Ajuda) :-
    ajuda_numero(Fase, Estado, Ajuda).
ajuda_rota(Fase, Estado, [Direcao|Resto], ajuda(Texto, Destaques, Dados)) :-
    length([Direcao|Resto], Passos),
    once(movimento(Fase, Estado, Direcao, Tipo, estado(Jogador, _, _))),
    acao(Tipo, Acao),
    destaques_passo(Tipo, Jogador, Direcao, Destaques),
    format(string(Texto), "Proximo passo: ~w (~w). Passos ate os alvos: ~d.",
           [Direcao, Acao, Passos]),
    Dados = [situacao-passo, direcao-Direcao, passos-Passos].

acao(caminhada, "caminhar").
acao(empurrao(N), Acao) :-
    format(string(Acao), "empurrar a caixa ~d", [N]).

destaques_passo(caminhada, Jogador, _, [armazem(Jogador, passo)]).
destaques_passo(empurrao(_), Jogador, Direcao, Destaques) :-
    vizinha(Jogador, Direcao, Destino),
    Destaques = [armazem(Jogador, passo), armazem(Destino, destino)].

ajuda_numero(Fase, Estado, ajuda(Texto, [sudoku(L-C, dica)], Dados)) :-
    grade_atual(Fase, Estado, Grade),
    conclusao(Grade, Solucao),
    once(( nth1(L, Grade, Linha), nth1(C, Linha, 0) )),
    nth1(L, Solucao, LinhaSolucao),
    nth1(C, LinhaSolucao, Valor),
    format(string(Texto), "Os alvos estao certos. Digite ~d em L~dC~d.", [Valor, L, C]),
    Dados = [situacao-digitar, valor-Valor].

ajuda_impasse(estado(_, Caixas, _), ajuda(Texto, Destaques, [situacao-impasse])) :-
    findall(armazem(Posicao, alerta), member(_-Posicao, Caixas), Destaques),
    Texto = "Impasse: nenhuma sequencia de empurroes leva as caixas certas aos alvos. Reinicie.".
