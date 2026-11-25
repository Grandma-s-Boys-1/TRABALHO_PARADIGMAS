:- module(api,
          [ listar/1,
            existe/1,
            dados/7,
            aceitar/4,
            mover/9,
            avaliar/5,
            pedir_dica/7,
            pedir_diagnostico/8
          ]).

:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(motor).
:- use_module(registro).

listar(Lista) :-
    fases_registradas(Ids),
    maplist(resumo, Ids, Lista).

resumo(Id, [Id, Nome, Regra]) :-
    Id:fase(fase(Nome, _, Termo, _)),
    nome_regra(Termo, Regra).

nome_regra(classica, classica).
nome_regra(combinada(_, _), combinada).

registrada(Texto, Id, Fase) :-
    fases_registradas(Ids),
    member(Id, Ids),
    atom_string(Id, Texto),
    !,
    Id:fase(Fase).

existe(Texto) :-
    registrada(Texto, _, _).

dados(Texto, Nome, Linhas-Colunas, Paredes, Alvos, Sudoku, [J, Cs, E]) :-
    registrada(Texto, _, fase(Nome, armazem(Linhas, Colunas, Paredes, Letras), Regra, Inicio)),
    Inicio = estado(J, Cs, E),
    maplist(maiuscula, Letras, Alvos),
    sudoku_saida(Regra, Sudoku).

maiuscula(Letra-Posicao, Maiuscula-Posicao) :-
    upcase_atom(Letra, Maiuscula).

sudoku_saida(classica, []).
sudoku_saida(combinada(Pistas, Letras), [Pistas, Ligacoes]) :-
    maplist(maiuscula, Letras, Ligacoes).

estado_de(J, Cs, E, estado(J, Caixas, E)) :-
    msort(Cs, Caixas).

aceitar(Texto, J, Cs, E) :-
    registrada(Texto, _, Fase),
    estado_de(J, Cs, E, Estado),
    estado_valido(Fase, Estado).

mover(Texto, J, Cs, E, Sentido, J1, Cs1, Movimento, Situacao) :-
    registrada(Texto, _, Fase),
    estado_de(J, Cs, E, Estado),
    atom_string(Direcao, Sentido),
    direcao(Direcao),
    jogar(Fase, Estado, Direcao, Proximo, Movimento),
    Proximo = estado(J1, Cs1, _),
    situacao(Fase, Proximo, Situacao).

avaliar(Texto, J, Cs, E, Situacao) :-
    registrada(Texto, _, Fase),
    estado_de(J, Cs, E, Estado),
    situacao(Fase, Estado, Situacao).

pedir_dica(Texto, J, Cs, E, Mensagem, Destaques, Dados) :-
    registrada(Texto, _, Fase),
    estado_de(J, Cs, E, Estado),
    dica(Fase, Estado, Ajuda),
    saida(Ajuda, Mensagem, Destaques, Dados).

pedir_diagnostico(Texto, J, Cs, E, Pedido, Mensagem, Destaques, Dados) :-
    registrada(Texto, Id, Fase),
    current_predicate(Id:diagnostico/4),
    estado_de(J, Cs, E, Estado),
    consulta(Pedido, Consulta),
    ( Id:diagnostico(Fase, Estado, Consulta, Ajuda),
      saida(Ajuda, Mensagem, Destaques, Dados) ->
        true
    ; Mensagem = "Sem diagnostico para esta consulta.",
      Destaques = [],
      Dados = []
    ).

consulta([Tipo|Argumentos], Consulta) :-
    atom_string(Nome, Tipo),
    % Cada pedido da API tem uma unica interpretacao, por isso basta a primeira solucao.
    once(consulta_de(Nome, Argumentos, Consulta)).

consulta_de(padrao, [], padrao).
consulta_de(casa, [L, C], casa(L, C)).
consulta_de(direcao, [Sentido], direcao(Direcao)) :-
    atom_string(Direcao, Sentido),
    direcao(Direcao).

saida(ajuda(Texto, Destaques, Dados), Mensagem, Lista, Dados) :-
    text_to_string(Texto, Mensagem),
    maplist(destaque_saida, Destaques, Lista),
    maplist(dado_valido, Dados).

destaque_saida(armazem(L-C, Marca), [armazem, L, C, Marca]).
destaque_saida(sudoku(L-C, Marca), [sudoku, L, C, Marca]).

dado_valido(Chave-Valor) :-
    atom(Chave),
    valor_simples(Valor).

valor_simples(Valor) :-
    ( number(Valor) ; atom(Valor) ; string(Valor) ),
    !.
valor_simples(Valores) :-
    is_list(Valores),
    !,
    maplist(valor_simples, Valores).
valor_simples(A-B) :-
    valor_simples(A),
    valor_simples(B).
