# Modelo lógico relacional — Multiplikar Automóveis

## 1. Escopo e conferência física

O modelo físico validado usa MySQL 8.4, InnoDB e utf8mb4. O catálogo contém **28 tabelas e 11 views**: 14 tabelas e 3 views no núcleo; 14 tabelas e 8 views na extensão. As definições de coluna, tipo, tamanho, nulidade, default, PK, FK, `UNIQUE` e `CHECK` estão listadas a partir do catálogo no [`dicionario-dados.md`](dicionario-dados.md).

O núcleo deriva de 10 entidades conceituais e quatro relações associativas. Os diagramas e suas fontes editáveis estão em [`modelo-logico/`](modelo-logico/): [`modelo-logico.svg`](modelo-logico/modelo-logico.svg) mostra as 14 tabelas do núcleo e [`extensao.svg`](modelo-logico/extensao.svg) as 14 tabelas da extensão. A extensão adiciona propostas, condições, trocas, simulações, obrigações, CRM e intenção de compra, sem alterar as regras do núcleo.

IDs operacionais usam `BIGINT AUTO_INCREMENT`; associações usam chaves compostas quando a própria combinação identifica a linha. FKs, `NOT NULL`, `UNIQUE`, `CHECK`, colunas geradas e triggers/procedures MySQL aplicam as regras. O MySQL valida FKs imediatamente; regras que envolvem outras linhas ficam em triggers ou procedures executados durante a gravação. O banco não usa triggers adiados até o `COMMIT`.

### Decisões de identidade e histórico

- `pessoa` centraliza CPF/CNPJ; o documento tem `UNIQUE`, enquanto o identificador substituto continua estável se houver correção cadastral.
- `funcionario` representa o vínculo funcional e restringe `id_pessoa` a no máximo um registro.
- `veiculo` guarda a identidade do automóvel; `entrada` representa cada ciclo de estoque. `entrada.id_entrada_anterior` preserva a cadeia após desfazimento, e a coluna gerada `veiculo_vigente` com índice único impede dois ciclos vigentes para o mesmo veículo.
- `venda_forma_pagamento`, `venda_documento` e `avaliacao_laudo` resolvem associações e atributos multivalorados. Valores e prazos individuais por forma de pagamento são registrados em `proposta_condicao` na extensão.
- `valor_total` de `venda` e `proposta` é calculado por coluna gerada. Restrições condicionais de aceite/aprovação usam colunas geradas armazenadas com índices únicos (`id_entrada_aceita`, `id_proposta_aprovada`).
- Descrições livres usam `TEXT`/`MEDIUMTEXT`; atributos delimitados pelo domínio usam comprimentos compatíveis com os valores admitidos. A carga e os testes da cadeia foram executados com esses limites.

## 2. Relações do núcleo (R01 a R19)

A matriz indica a cardinalidade em ambos os sentidos. O lado dependente tem participação obrigatória quando indicado por `1`; o lado pai admite `0` quando não há participação obrigatória no modelo.

| R | Conversão relacional | Cardinalidade ida / volta |
|---|---|---|
| R01 | `funcionario.id_pessoa` FK `UNIQUE` | Pessoa 0..1 funcionário; funcionário 1 pessoa. |
| R02 | `atendimento.id_pessoa` FK obrigatória | Pessoa 0..N atendimentos; atendimento 1 pessoa. |
| R03 | `atendimento.id_funcionario` FK obrigatória | Funcionário 0..N atendimentos; atendimento 1 responsável. |
| R04 | `avaliacao.id_veiculo` FK obrigatória | Veículo 0..N avaliações; avaliação 1 veículo. |
| R05 | `avaliacao.id_avaliador` FK obrigatória | Pessoa 0..N avaliações; avaliação 1 avaliador. |
| R06 | `laudo.id_veiculo` FK obrigatória | Veículo 0..N laudos; laudo 1 veículo. |
| R07 | `avaliacao_laudo(id_avaliacao PK/FK, id_laudo FK)` | Avaliação 0..1 laudo; laudo 0..N avaliações, sujeito à igualdade de veículo pela RN08. |
| R08 | `entrada.id_veiculo` FK obrigatória | Veículo 0..N ciclos históricos, no máximo 1 vigente; entrada 1 veículo. |
| R09 | `entrada.id_contraparte` FK obrigatória | Pessoa 0..N entradas; entrada 1 contraparte. |
| R10 | `entrada.id_avaliacao` FK `UNIQUE NOT NULL` | Avaliação 0..1 entrada; entrada 1 avaliação aprovada. |
| R11 | `venda.id_comprador` FK obrigatória | Pessoa 0..N vendas; venda 1 comprador. |
| R12 | `venda.id_funcionario` FK obrigatória | Funcionário 0..N vendas; venda 1 responsável. |
| R13 | `venda.id_entrada_principal` FK obrigatória e `UNIQUE` | Entrada 0..1 venda principal; venda 1 entrada. |
| R14 | `entrada.id_venda_origem` FK opcional | Venda 0..N entradas recebidas em troca; entrada 0..1 venda de origem. |
| R15 | `venda.id_laudo` FK opcional | Laudo 0..N vendas; venda 0..1 laudo até a formalização exigida pela RN22. |
| R16 | `ocorrencia_garantia.id_venda` FK obrigatória | Venda 0..N ocorrências; ocorrência 1 venda. |
| R17 | `ocorrencia_garantia.id_mecanico` FK opcional | Pessoa 0..N ocorrências como mecânico; ocorrência 0..1 mecânico. |
| R18 | `despesa.id_veiculo` FK obrigatória | Veículo 0..N despesas individualizadas; despesa 1 veículo. |
| R19 | `entrada.id_entrada_anterior` FK opcional e `UNIQUE` | Entrada anterior 0..1 sucessora; sucessora 0..1 anterior. A aplicação restringe a finalidade da cadeia a ciclos do mesmo veículo. |

## 3. Relações da extensão (R20 a R41)

A extensão documenta individualmente cada relacionamento, a participação dos dois lados e a restrição correspondente em [`extensao-inovacao.md`, seção 4.2](extensao-inovacao.md). As particularidades físicas são:

- R20 a R22: proposta exige atendimento, entrada ofertada e funcionário; cada pai pode sustentar várias propostas.
- R23: contraproposta possui no máximo uma anterior, e uma proposta pode ter no máximo uma sucessora; versão e rótulo são verificados pelo trigger.
- R24: venda e proposta podem não estar vinculadas; quando o vínculo existe, `venda.id_proposta` é único e validado contra cliente, entrada e situação aceita.
- R25 a R27: condições, trocas e simulações pertencem a uma proposta; parâmetros de forma de pagamento e avaliação podem ser reutilizados conforme as regras.
- R28: o trigger de simulação confirma instituição, tabela de retorno e vigência. Não é uma FK declarativa para a tabela de parâmetros.
- R29 a R31: cada obrigação tem um arco de origem exclusivo entre venda, entrada ou despesa de veículo; obrigações administrativas não preenchem essas FKs.
- R32 a R38: interação, desfecho e classificação ligam-se ao atendimento e aos funcionários; classificação exige fator explicativo por procedure.
- R39 a R41: cada atendimento admite no máximo uma intenção; entrada e forma de pagamento são escolhas opcionais.

## 4. Formas normais e regras de integridade

A normalização do núcleo está documentada em [`normalizacao.md`](normalizacao.md), com dependências funcionais e decomposições verificadas em 1FN, 2FN e 3FN. A extensão faz análise equivalente em [`extensao-inovacao.md`, seção 5](extensao-inovacao.md).

As regras inter-relacionais incluem: avaliação aprovada e correspondente ao veículo da entrada; laudo do mesmo veículo e anterior ao evento; troca pertencente ao comprador e distinta do veículo principal; conclusão da venda condicionada simultaneamente a saldo, documentos, financiamento e laudo; cancelamento não destrutivo com cadeia de entrada; proposta fechada exatamente por condições mais trocas; e imutabilidade de histórico financeiro e comercial. O DDL MySQL implementa essas regras com `CHECK`, FKs, colunas geradas, triggers e procedures conforme a capacidade de cada regra.

## 5. Prova de cobertura

`sql/testes/testes-relacionamentos.sql` percorre R01-R41 nos sentidos Ida/Volta e verifica os metadados de FK, nulidade e unicidade, além de casos comportamentais. `sql/testes/testes-fluxos.sql` cobre os desvios integrados da extensão. As massas e os testes de restrição cobrem os caminhos principais e exceções dos fluxogramas 01-09. O resultado consolidado da execução atual está em [`docs/evidencias/mysql/paridade-testes.md`](evidencias/mysql/paridade-testes.md).
