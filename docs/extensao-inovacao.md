# Extensão de inovação: propostas por CPF, fluxo de caixa e CRM explicável

Este documento descreve as regras e a arquitetura da extensão aditiva implementada em MySQL 8.4. A cadeia local registra 435 PASS; a matriz por arquivo, regra e relacionamento está em docs/evidencias/mysql/paridade-testes.md.
1. **Propostas comerciais por CPF e simulação de financiamento** (estendendo a transição entre `P01`, `P04` e `P05`);
2. **Obrigações financeiras e previsão semanal de fluxo de caixa por cenários** (estendendo `P05` e `P08`);
3. **CRM com histórico de interações, desfecho de atendimento e classificação explicável de leads** (estendendo `P01`).

---

## 1. Problema e valor agregado

### 1.1. O problema operacional: preço, lucro e caixa não são a mesma coisa
No núcleo do projeto ([`sql/ddl/schema.sql`](../sql/ddl/schema.sql)), o banco registra o atendimento inicial (`atendimento`) e o contrato fechado (`venda`), além de apurar a margem operacional por veículo na Consulta Gerencial #8 ([`sql/consultas/gerenciais.sql`](../sql/consultas/gerenciais.sql)). Na operação diária de uma revenda enxuta (6 funcionários), três problemas ocorrem antes e depois da assinatura do contrato:

1. **Mesmo preço e mesma margem, mas efeitos de caixa opostos:** Durante a negociação de um mesmo veículo, o vendedor pode apresentar propostas alternativas simultâneas (`rotulo = 'A'`, `'B'`, `'C'`) com o mesmo valor final (à vista no Pix, financiada ou recebendo usado na troca). Pela ótica contábil da margem do carro, as propostas empatam; pela ótica financeira, uma gera caixa líquido positivo imediato (`D+0`), outra posterga a entrada para o prazo do banco (`D+x`) e a terceira **consome caixa da loja** quando o carro vendido é consignado.
2. **Descasamento entre lucro (competência) e disponibilidade financeira (caixa):** Uma venda lucrativa pode deixar o caixa negativo se o repasse devido ao consignante vencer antes de o banco financiador transferir o valor financiado à loja.
3. **Priorização comercial e financeira sem critério auditável:** Com leads em aberto, carros parados no estoque e financiamentos aprovados aguardando repasse bancário, a equipe precisa de uma fila de ações explicável ordenada pelo valor financeiro em risco.

### 1.2. Diferença entre lucro e caixa já presente nos dados do núcleo
Os próprios dados de [`sql/dados/massa-dados.sql`](../sql/dados/massa-dados.sql) ([`docs/escopo-financeiro.md`](escopo-financeiro.md)) ilustram essa separação:
- **Venda 3 (Honda City consignado, `valor_total = R$ 80.000,00`):** Entraram R$ 80.000,00 no caixa, mas **R$ 74.000,00** pertencem ao proprietário consignante (`valor_repasse_acordado`). Descontada a despesa de preparação de R$ 150,00, a margem líquida da loja é de **R$ 5.850,00**.
- **Venda 2 (Toyota Corolla, `valor_total = R$ 100.000,00`):** Apenas **R$ 60.000,00** viraram caixa (Pix); os outros **R$ 40.000,00** viraram estoque (Fiat Uno de R$ 25.000,00 e Ford Ka de R$ 15.000,00 recebidos na troca, parados há 35 dias na data de referência da demonstração).
- **Venda 6 (Chevrolet Tracker, `valor_total = R$ 90.000,00`):** Há R$ 10.000,00 recebidos em Pix e **R$ 80.000,00** em `situacao_financiamento = 'APROVADO_A_RECEBER'`. É receita contratada que ainda não virou dinheiro em conta.

### 1.3. O valor da integração: comparador em três ângulos e o achado da troca em consignação
A extensão analisa cada proposta comercial sob três ângulos simultâneos em `vw_proposta_comparativo` e `vw_simulacao_parcela`:
1. **Ângulo do cliente:** desembolso imediato, abatimento por veículo de troca (`valor_em_troca`), prestação simulada pela Tabela Price (`parcela_simulada`), custo total (`custo_total_cliente`), CET anual aproximado (`cet_aproximado_anual`) e peso no orçamento familiar (`parcela_sobre_renda_pct`);
2. **Ângulo da loja — margem (competência):** resultado operacional do veículo (`margem_estimada = valor_total - valor_repasse_acordado ou valor_acordado - despesas_preparacao - despesas_garantia`, seguindo a Consulta Gerencial #8), separado do retorno pago pelo banco financiador (`retorno_banco` pela tabela `R0` a `R5`) e da `margem_com_retorno` (`margem_estimada + retorno_banco`);
3. **Ângulo da loja — caixa (liquidez):** quanto entra em `D+0` (`caixa_d0`), quanto fica para `D+x` (`caixa_posterior`, somando o principal em `D+x` e o `retorno_loja` do financiamento) e quanto vira estoque (`valor_em_troca`), confrontado com a saída obrigatória do repasse na consignação.

**Demonstração real no banco — 3 propostas alternativas (`A`, `B`, `C`, todas na `versao = 1`) para o Renault Kwid consignado (`id_veiculo = 9`, `id_entrada = 10`, cliente João Comprador `CPF 00000000010`, `id_atendimento = 7`, `valor_repasse_acordado = R$ 50.000,00`):**

| Dimensão (`vw_proposta_comparativo`) | Alternativa A (`id_proposta = 1`, `v1`): Pix integral | Alternativa B (`id_proposta = 2`, `v1`): Pix + financiamento (`R4`) | Alternativa C (`id_proposta = 3`, `v1`): Pix + Gol na troca |
|---|---|---|---|
| **Valor total da proposta (`valor_total`)** | R$ 55.000,00 | R$ 55.000,00 | R$ 55.000,00 |
| **Margem do veículo (`margem_estimada`)** | **R$ 5.000,00** (`55.000 - 50.000`) | **R$ 5.000,00** (`55.000 - 50.000`) | **R$ 5.000,00** (`55.000 - 50.000`) |
| **Retorno do banco (`retorno_banco`) e `margem_com_retorno`** | R$ 0,00 (`R$ 5.000,00`) | **R$ 1.760,00** em `R4` (**R$ 6.760,00**) — ou R$ 0,00 em `R0` | R$ 0,00 (`R$ 5.000,00`) |
| **Ângulo do cliente** | R$ 55.000,00 à vista | R$ 11.000,00 em Pix + 48x de **R$ 1.402,56** em `R0` (`21,58%` da renda, CET `25,19%` a.a.) ou **R$ 1.490,50** em `R4` (`22,93%` da renda, CET `29,69%` a.a.) | R$ 25.000,00 em Pix + VW Gol 2018 avaliado em **R$ 30.000,00** |
| **Entrada em caixa imediato (`caixa_d0`)** | **R$ 55.000,00** (`D+0`) | **R$ 11.000,00** (`D+0`) | **R$ 25.000,00** (`D+0`) |
| **Entrada em caixa posterior (`caixa_posterior`)** | R$ 0,00 | **R$ 45.760,00** (`D+15`: `44.000` principal + `1.760` retorno `R4`) | R$ 0,00 |
| **Capital imobilizado em troca (`valor_em_troca`)** | R$ 0,00 | R$ 0,00 | **R$ 30.000,00** (vira estoque) |
| **Saída de repasse ao consignante (`D+5` após quitação)** | -R$ 50.000,00 em dinheiro | -R$ 50.000,00 em dinheiro (`D+20`) | -R$ 50.000,00 em dinheiro (`D+5`) |
| **Efeito líquido de caixa no ciclo do Kwid** | **+R$ 5.000,00** | **+R$ 6.760,00** em `R4` (ou `+R$ 5.000,00` em `R0`, após repasse bancário) | **-R$ 25.000,00** (consome caixa até vender o Gol) |

> **Achado prático demonstrado pelo modelo:** Na **Proposta C (Pix + troca)**, a loja apura a mesma margem do veículo (**R$ 5.000,00**), mas **consome R$ 25.000,00 líquidos do próprio caixa** na primeira semana (`R$ 25.000,00` recebidos em Pix menos `R$ 50.000,00` pagos em dinheiro ao consignante do Kwid), porque os outros R$ 30.000,00 entram na forma de um Volkswagen Gol (`id_veiculo = 11`, `id_avaliacao = 11`) que vira estoque até ser revendido. Como as propostas 1 e 3 vencem na primeira semana e o repasse ponderado de ambas sai em dinheiro, o `funil_ponderado` líquido da semana de `2026-02-09` em `vw_previsao_caixa` é de **`-R$ 1.950,00`** (`(55.000 + 11.000 + 25.000 - 50.000 - 50.000) × 0,65 / 3`).

Além disso, o **CRM explicável** registra o histórico de interações (`interacao`), o motivo de ganho ou perda (`atendimento_desfecho`) e a temperatura do lead (`classificacao_lead` + `classificacao_fator`), ponderando o funil na previsão de caixa (`vw_previsao_caixa`) e alimentando a fila de próximas ações (`vw_fila_acoes`).

---

## 2. Arquitetura aditiva e preservação de RN19, RO12 e RN32

### 2.1. Por que a extensão é estritamente aditiva
Nenhum arquivo do núcleo avaliado (`sql/ddl/schema.sql`, `sql/dados/massa-dados.sql`, `sql/consultas/gerenciais.sql`, `sql/auditoria/auditoria.sql`) foi editado. Toda a extensão roda sobre o banco `multiplikar` já populado, na sequência `01` → `02` → `03` → `04` → `05`.

A única alteração em tabela existente do núcleo é a inclusão da coluna opcional e única `id_proposta` em `venda` ([`sql/extensao/01-ddl-propostas-caixa.sql`](../sql/extensao/01-ddl-propostas-caixa.sql), linha 206):

```sql
ALTER TABLE venda ADD COLUMN id_proposta bigint UNIQUE REFERENCES proposta;
```

- Como `id_proposta` aceita `NULL`, todas as 6 vendas da massa original e futuras vendas de balcão sem proposta prévia permanecem válidas.
- Quando preenchida, a constraint `UNIQUE` e os triggers MySQL `venda_proposta_bi` e `venda_proposta_bu` exigem que a proposta esteja `'ACEITA'` para o mesmo cliente (`atendimento.id_pessoa = venda.id_comprador`) e para a mesma entrada (`proposta.id_entrada = venda.id_entrada_principal`).
- A tabela `atendimento` **não** sofre `ALTER TABLE`: o encerramento com motivo de ganho ou perda fica na tabela `atendimento_desfecho` (`id_atendimento PRIMARY KEY REFERENCES atendimento`, cardinalidade `1 : 0..1`).

### 2.2. Decisões de escopo (seção 9 da proposta) sem reabrir RN19, RO12 e RN32

| Questão de negócio (seção 9 da proposta) | Decisão técnica implementada | Regra do núcleo preservada |
|---|---|---|
| **1. Reabrir `RN19`/`RO12` para guardar valor por forma de pagamento?** | **Não reabrir na venda.** `venda_forma_pagamento` continua guardando apenas códigos (`id_venda`, `codigo_forma`). Valores e prazos por forma existem somente na proposta comercial (`proposta_condicao`). | **RN19**, **RN20** e **RO12** intactas em `venda`. |
| **1b. Reabrir `RN32`/`P08` para registrar despesas administrativas?** | **Não reabrir `despesa`.** A tabela `despesa` mantém `id_veiculo NOT NULL` para proteger o cálculo de margem por veículo. Despesas gerais entram em `obrigacao_financeira` com `origem = 'ADMINISTRATIVA'` e FKs de venda/entrada/despesa nulas (`ck_obrigacao_arco`). | **RN32** e **P08** intactas em `despesa`. |
| **2. Tornar `venda.valor_recebido` coluna mantida por trigger de `movimento_caixa`?** | **Não alterar `venda.valor_recebido`.** A tabela de liquidações individuais (`movimento_caixa`) ficou adiada; `venda.valor_recebido` mantém seu comportamento original no núcleo, e os recebimentos na semana de referência são lidos por `vw_caixa_realizado_referencia`. | **RN22** e os 35 `PASS` da massa original intactos. |
| **3. Emissor, validade padrão da proposta e aprovação de descontos (`RO10`)?** | Toda proposta exige `id_funcionario NOT NULL`, tem validade padrão de **7 dias** (`DEFAULT (data_referencia() + 7)`) e exige `data_decisao` ao sair de `'APRESENTADA'` para situação terminal. Alçadas de desconto seguem documentadas em `RO10`. | **RO10** e **RO11** mantidas. |
| **4. Retorno / comissão de bancos em financiamentos?** | **Retorno modelado como `HIPOTESE` na extensão** (`parametro_retorno` de `'R0'` a `'R5'` e `simulacao_financiamento.tabela_retorno`): trata-se de **receita da loja paga pelo banco** sobre o valor financiado, distinta da comissão de vendedor excluída pela `RO13`. Em `vw_proposta_comparativo`, `retorno_banco` e `margem_com_retorno` ficam separados de `margem_estimada` sem alterar `venda`. | **RO13** e **RN21** mantidas em `venda`. |
| **5 e 6. Prazos de compra própria, repasse ao consignante e repasse bancário?** | Parametrizados em `parametro_prazo` com `origem = 'HIPOTESE'` até haver histórico suficiente para calibração (`'CALIBRADA'`). | **RN11**, **RN12** e **RN21** mantidas. |
| **7 e 8. Uso de IA e quem decide a classificação final (`RO11`)?** | A sugestão no banco é calculada por regra pontuada determinística (`registrar_classificacao_lead`, `'REGRA-V1'` e `'REGRA-V2'`, que soma a capacidade de pagamento declarada, RN44). A classificação final (`temperatura_final`) só pode ser preenchida por revisor humano (`id_revisor REFERENCES funcionario`), exigindo `justificativa_revisao` se divergir da sugestão. | **RNF03** e **RO11** atendidas no SGBD. |
| **9. Forma de demonstração?** | Views e procedures demonstradas no MySQL Workbench e nos roteiros SQL de sql/extensao/. | Arquitetura SQL do repositório mantida. |
| **10. LGPD para renda declarada e interações?** | `simulacao_financiamento` exige `consentimento_renda = true` quando `renda_declarada IS NOT NULL` (`ck_simulacao_consentimento_renda`). Interações registram apenas resumo comercial objetivo. | **RNF01** e **RNF02** estendidas. |
| **11. "Troca com troco" (seção 17.14 do `README.md`)?** | **Proibida na proposta:** o trigger `validar_proposta_extensao()` exige que `SUM(proposta_condicao.valor) + SUM(proposta_troca.valor_oferecido) = proposta.valor_total`. | Coerência com **RN16–RN18**. |

---

## 3. Novas regras de negócio (RN34 a RN44)

No [`README.md`](../README.md) (seções 8 e 18.2), as regras do núcleo vão de **RN01 a RN33**. A extensão define onze regras numeradas de **RN34 a RN44**:

| ID | Regra de negócio da extensão | Origem / justificativa | Implementação em `sql/extensao/` |
|---|---|---|---|
| **RN34** | **Alternativas por rótulo, versionamento de contrapropostas e imutabilidade da proposta:** Toda proposta vincula um atendimento, uma entrada e um funcionário, com validade padrão de 7 dias (`validade >= data_criacao`). Alternativas simultâneas para a mesma negociação (`rotulo = 'A'`, `'B'`, `'C'`) nascem como raízes independentes (`id_proposta_anterior IS NULL` e `versao = 1`). Uma contraproposta encadeia `id_proposta_anterior`, herda obrigatoriamente o mesmo `rotulo`, incrementa `versao = anterior.versao + 1` e marca a anterior `'APRESENTADA'` como `'SUBSTITUIDA'` automaticamente. Depois de sair de `'RASCUNHO'`, cabeçalho, condições e trocas são imutáveis; situações terminais (`'ACEITA'`, `'RECUSADA'`, `'EXPIRADA'`, `'SUBSTITUIDA'`) exigem `data_decisao IS NOT NULL` (e `'ACEITA'` exige `DATE(data_decisao) <= validade`). | Permitir comparar opções de pagamento simultâneas (`A`/`B`/`C`) e versionar renegociações em cada cadeia sem perder histórico (`RNF03`). | `ck_proposta_versao`, `ck_proposta_rotulo`, `ck_proposta_raiz_versao`, `ck_proposta_valores`, `ck_proposta_datas`, `ck_proposta_situacao`, `ck_proposta_data_decisao`, `ck_proposta_recusa`, `uq_proposta_alternativa_versao`, `ck_proposta_anterior`, triggers `proposta_sucessora_herda_alternativa`, `proposta_imutavel`, `proposta_condicao_imutavel`, `proposta_troca_imutavel` e `validar_proposta_extensao()` ([`01-ddl-propostas-caixa.sql`](../sql/extensao/01-ddl-propostas-caixa.sql)). |
| **RN35** | **Fechamento exato da composição (vedação de "troca com troco"), unicidade de aceite e recusa automática das alternativas irmãs:** Para uma proposta estar `'APRESENTADA'` ou `'ACEITA'`, a `entrada` ofertada deve estar `'ATIVA'` e a soma de `proposta_condicao.valor` mais `proposta_troca.valor_oferecido` deve igualar exatamente `proposta.valor_total`. Cada entrada admite no máximo uma proposta `'ACEITA'`; ao aceitar uma alternativa, todas as irmãs `'APRESENTADA'` do mesmo `(id_atendimento, id_entrada)` passam automaticamente para `'RECUSADA'` com `motivo_recusa = 'Alternativa nao escolhida: proposta <id> aceita'` e a mesma `data_decisao`. | Resolver o item da seção 17.14 do `README.md`, espelhar a `RN13` na proposta e encerrar automaticamente as opções preteridas pelo cliente. |`id_entrada_aceita` com `UNIQUE` para limitar o aceite a uma proposta por entrada; triggers MySQL `proposta_bi`/`proposta_bu` e triggers das linhas filhas validam composição e situação durante a gravação.|
| **RN36** | **Elegibilidade da avaliação de troca na proposta:** Todo veículo incluído em `proposta_troca` exige uma `avaliacao` com `finalidade = 'TROCA'`, `decisao_tecnica = 'APROVADA'`, `interesse_comercial = 'SIM'`, `data <= proposta.data_criacao`, referente a veículo distinto do ofertado na proposta e ainda não consumida por uma `entrada` de estoque. | Garantir aprovação técnica e interesse comercial prévios (`RN06`, `RN07`, `RN17`) antes de abater valor de troca na proposta. | Triggers MySQL `proposta_troca_bi` e `proposta_troca_bu` ([`01-ddl-propostas-caixa.sql`](../sql/extensao/01-ddl-propostas-caixa.sql)). |
| **RN37** | **Coerência entre venda e proposta aceita:** O vínculo `venda.id_proposta` é opcional (`NULL` para vendas históricas ou de balcão) e único; quando informado, exige que a proposta esteja `'ACEITA'` para a mesma entrada principal (`proposta.id_entrada = venda.id_entrada_principal`) e para o mesmo cliente (`atendimento.id_pessoa = venda.id_comprador`). | Fechar a rastreabilidade exata do funil (`atendimento → proposta → venda`) sem invalidar vendas sem proposta. |FK `venda.id_proposta` com `UNIQUE` e triggers MySQL `venda_proposta_bi`/`venda_proposta_bu`, que validam situação aceita, entrada e cliente.|
| **RN38** | **Simulação de financiamento pré-contratual, imutabilidade pós-análise e consentimento LGPD:** A `simulacao_financiamento` vincula-se à `proposta`, classifica sua `origem` (`'ACADEMICA'`, `'INFORMADA_BANCO'`, `'INTEGRACAO'`), admite no máximo uma simulação `'APROVADA'` por proposta e não substitui o financiamento contratado em `venda` (`RN21`). Não pode ser removida (`DELETE`), só permite atualizar `situacao`, `data_resposta` e `parcela_informada` enquanto estiver em `'EM_ANALISE'` (tornando-se imutável após sair de `'EM_ANALISE'`) e exige `consentimento_renda = true` sempre que `renda_declarada IS NOT NULL`. | Separar simulação de contratação (`RN21`), preservar histórico de análises de crédito (`RNF03`) e impor consentimento expresso para renda declarada (`RNF02` / LGPD). |`ck_simulacao_origem`, `ck_simulacao_valores`, `ck_simulacao_situacao`, `ck_simulacao_datas`, `ck_simulacao_consentimento_renda`, coluna gerada `id_proposta_aprovada` com índice único `uq_simulacao_aprovada_proposta` e triggers `simulacao_imutavel_bu`/`simulacao_imutavel_bd` ([`01-ddl-propostas-caixa.sql`](../sql/extensao/01-ddl-propostas-caixa.sql)).|
| **RN39** | **Arco exclusivo, proteção contra exclusão e máquina de estados de obrigação financeira:** Cada `obrigacao_financeira` válida a combinação entre `natureza` (`'RECEBER'`/`'PAGAR'`), `origem` e a FK correspondente (`id_venda` para `'VENDA'`/`'RECEBER'`; `id_entrada` para `'ENTRADA'`/`'PAGAR'`; `id_despesa` para `'DESPESA_VEICULO'`/`'PAGAR'`; todas nulas para `'ADMINISTRATIVA'`/`'PAGAR'`), exigindo `vencimento_original >= data_competencia` e `vencimento_atual >= data_competencia`. Não admite `DELETE`; em `UPDATE`, mantém `vencimento_original` e os dados de origem/valor imutáveis, permitindo alterar apenas `vencimento_atual` e `situacao` dentro das transições válidas (`PREVISTA → ABERTA | CANCELADA`, `ABERTA → QUITADA | ATRASADA | CANCELADA`, `ATRASADA → QUITADA | CANCELADA`, sendo `'QUITADA'` e `'CANCELADA'` terminais). | Projetar caixa e registrar obrigações administrativas sem ferir a `RN32` em `despesa`, preservando a auditoria de atrasos (`vencimento_atual - vencimento_original`). | `ck_obrigacao_natureza`, `ck_obrigacao_origem`, `ck_obrigacao_arco`, `ck_obrigacao_valores`, `ck_obrigacao_datas`, `ck_obrigacao_situacao`, `ck_obrigacao_estimativa` e trigger `obrigacao_financeira_imutavel` ([`01-ddl-propostas-caixa.sql`](../sql/extensao/01-ddl-propostas-caixa.sql)). |
| **RN40** | **Histórico append-only de interações e desfecho único do atendimento:** Os registros de contato (`interacao`) e de fechamento do atendimento (`atendimento_desfecho`, no máximo um por atendimento, com `tipo_desfecho` em `'GANHO'` ou `'PERDA'` e `motivo` não vazio) são somente de inserção, rejeitando `UPDATE`, `DELETE` e `TRUNCATE`. | Assegurar trilha de auditoria comercial (`RNF03`) e registrar motivo de perda/ganho sem alterar `atendimento`. | PK `atendimento_desfecho(id_atendimento)`, `ck_interacao_*`, `ck_desfecho_*` e triggers `somente_insercao_linha` e `somente_insercao_truncate` ([`03-ddl-crm.sql`](../sql/extensao/03-ddl-crm.sql)). |
| **RN41** | **Classificação de lead explicável por fatores e revisão humana única:** Cada execução em `classificacao_lead` grava seus fatores pontuados e evidências em `classificacao_fator` (somente inserção). Os campos originais da sugestão são imutáveis; a única alteração permitida em `classificacao_lead` é o preenchimento único e completo da revisão humana (`id_revisor`, `data_revisao`, `temperatura_final`), exigindo `justificativa_revisao` sempre que `temperatura_final <> temperatura_sugerida`. | Garantir explicabilidade e supervisão humana sobre classificações por regra ou IA (`RO11`). | `ck_classificacao_origem`, `ck_classificacao_temp_sugerida`, `ck_classificacao_temp_final`, `ck_classificacao_pontuacao`, `ck_classificacao_revisao`, `ck_classificacao_justificativa`, `ck_fator_*` e triggers `revisar`, `revisar_truncate`, `classificacao_exige_fator` e `somente_insercao_*` ([`03-ddl-crm.sql`](../sql/extensao/03-ddl-crm.sql)). |
| **RN42** | **Explicitação de parâmetros de hipótese, data de referência e ponderação sem dupla contagem no funil:** Prazos (`parametro_prazo`), tabelas de retorno (`parametro_retorno`) e probabilidades (`parametro_temperatura`) identificam `origem IN ('HIPOTESE', 'CALIBRADA')`; a data de referência central (`parametro_referencia`) identifica `origem IN ('DEMONSTRACAO', 'OPERACAO')`. Na previsão de caixa, propostas `'APRESENTADAS'` e válidas para o mesmo `(id_atendimento, id_entrada)` dividem uniformemente a probabilidade do lead (`probabilidade / N`) e descontam o repasse ponderado ao consignante. | Evitar dupla contagem de propostas alternativas mutuamente exclusivas para o mesmo veículo e separar hipóteses acadêmicas de fatos operacionais. | `ck_parametro_retorno_*`, `ck_parametro_prazo_origem`, `ck_parametro_origem`, `ck_parametro_referencia_*`, view `vw_caixa_realizado_referencia` e função `fn_previsao_caixa_cenario` ([`01-ddl-propostas-caixa.sql`](../sql/extensao/01-ddl-propostas-caixa.sql), [`03-ddl-crm.sql`](../sql/extensao/03-ddl-crm.sql), [`05-consultas-demo.sql`](../sql/extensao/05-consultas-demo.sql)). |
| **RN43** | **Retorno bancário parametrizado como receita da loja e transparência do impacto no CET do cliente:** Toda `simulacao_financiamento` indica `tabela_retorno` (`'R0'` a `'R5'`, `DEFAULT 'R0'`) e exige parâmetro vigente em `parametro_retorno (instituicao, tabela_retorno, vigencia)` (`vigencia <= data_simulacao```). A view `vw_simulacao_parcela` soma `taxa_mensal + acrescimo_taxa_mensal` (`taxa_cliente_mensal`) para calcular `parcela_calculada`, `custo_total_cliente`, `cet_aproximado_anual` e `retorno_loja = ROUND(valor_financiado * retorno_pct, 2)`. Em `vw_proposta_comparativo`, `retorno_banco` e `margem_com_retorno` ficam separados de `margem_estimada` (do veículo) e entram em `caixa_posterior` e no `funil_ponderado` da previsão semanal junto à liberação do financiamento (`D+x`), como receita da loja paga pelo banco e distinta de comissão de vendedor (`RO13`). | Evitar que o retorno bancário infle ocultamente a prestação do comprador sem visibilidade no comparador e separar o resultado operacional do carro da remuneração financeira do banco. |Tabela `parametro_retorno`, `CHECK`, triggers MySQL `simulacao_retorno_bi`/`simulacao_retorno_bu`, views `vw_simulacao_parcela` e `vw_proposta_comparativo` e procedure `fn_previsao_caixa_cenario` ([`01-ddl-propostas-caixa.sql`](../sql/extensao/01-ddl-propostas-caixa.sql), [`05-consultas-demo.sql`](../sql/extensao/05-consultas-demo.sql)).|
| **RN44** | **Intenção de compra declarada e capacidade de pagamento na classificação (`'REGRA-V2'`):** Cada atendimento `COMPRA` ou `TROCA` tem no máximo uma `intencao_compra`; o veículo pretendido, se informado, deve ter entrada `ATIVA`; `valor_disponivel` e não negativo e, com veículo escolhido, não supera `preco_anunciado`; ao menos um dado de intenção deve existir. A `'REGRA-V2'` acrescenta `CAPACIDADE_PAGAMENTO` sobre `valor_disponivel / preco_anunciado`: `>= 90%` com `PIX` ou `DINHEIRO` vale 40 pontos; `>= 90%` com outra forma ou sem forma informada vale 30; `>= 50%` ou `FINANCIAMENTO` vale 20; cobertura não calculavel com forma vale 10; abaixo de `50%` sem financiamento ou sem intenção vale 0. A `'REGRA-V1'` continua igual e outra versão de regra e recusada. | Um cliente que oferece R$ 5.000 para veículo de R$ 135.900 permanece `FRIO` com 35 pontos; o caso do site (97% a vista) continua de `FRIO` (35) para `QUENTE` (75). | `intencao_compra`, constraints, trigger `validar_intencao_compra()`, `ck_fator_codigo` e `registrar_classificacao_lead` em `07-intencao-regra-v2.sql`. |

---

## 4. Modelo lógico das tabelas novas e cardinalidades (Método Vá e Volte)

O modelo conceitual da extensão está no [DER da extensão](der/der-extensao.svg) ([PNG](der/der-extensao.png) · [Draw.io](der/der-extensao.drawio)), em notação de Chen, com as 14 entidades novas e os relacionamentos R20 a R41 analisados na seção 4.2. O diagrama lógico relacional correspondente está em [`modelo-logico/extensao.svg`](modelo-logico/extensao.svg) ([PNG](modelo-logico/extensao.png) · [fonte Mermaid](modelo-logico/extensao.mmd)); as tabelas do núcleo que aparecem nele (ATENDIMENTO, ENTRADA, VENDA, FUNCIONARIO, AVALIACAO, DESPESA e FORMA_PAGAMENTO) estão ali só para mostrar as chaves estrangeiras.

### 4.1. Catálogo das 14 tabelas novas, funções e views da extensão

A extensão acrescenta **14 tabelas** (8 em [`01-ddl-propostas-caixa.sql`](../sql/extensao/01-ddl-propostas-caixa.sql), 5 em [`03-ddl-crm.sql`](../sql/extensao/03-ddl-crm.sql) e 1 em [`07-intencao-regra-v2.sql`](../sql/extensao/07-intencao-regra-v2.sql)), 1 coluna em `venda`, 7 views e 3 funções de negócio/consulta:

| Tabela nova | Script DDL | Chave primária (PK) | Chaves estrangeiras (FK) e unicidade (UNIQUE) | Atributos-chave e papel no modelo |
|---|---|---|---|---|
| `parametro_referencia` | `01-ddl` | `chave` (`boolean DEFAULT true`, `CHECK (chave)`) | Sem FK (tabela de linha única: `0..1` registro) | `data_referencia`, `origem` (`DEMONSTRACAO`, `OPERACAO`). Lida por `data_referencia()` em toda a extensão (gravada em `02-massa-propostas-caixa.sql` com `2026-02-10`). |
| `proposta` | `01-ddl` | `id_proposta` (`BIGINT AUTO_INCREMENT`) | `id_atendimento NOT NULL FK`, `id_entrada NOT NULL FK`, `id_funcionario NOT NULL FK`, `id_proposta_anterior UNIQUE FK`; `uq_proposta_alternativa_versao UNIQUE (id_atendimento, id_entrada, rotulo, versao)`; coluna gerada `id_entrada_aceita` com índice único `uq_proposta_aceita_entrada` | `rotulo`, `versao`, `data_criacao`, `validade` (`DEFAULT (data_referencia() + 7)`), `valor_base`, `desconto`, `acrescimo`, `taxas`, `valor_total` (`GENERATED ALWAYS`), `situacao`, `data_decisao`, `motivo_recusa`. |
| `proposta_condicao` | `01-ddl` | `(id_proposta, codigo_forma)` | `id_proposta NOT NULL FK -> proposta`, `codigo_forma NOT NULL FK -> forma_pagamento` | `valor > 0`, `prazo_previsto_dias >= 0`. Condições de pagamento e prazo de caixa da proposta. |
| `proposta_troca` | `01-ddl` | `(id_proposta, id_avaliacao)` | `id_proposta NOT NULL FK -> proposta`, `id_avaliacao NOT NULL FK -> avaliacao` | `valor_oferecido > 0`. Veículos avaliados para troca incluídos na proposta. |
| `parametro_retorno` | `01-ddl` | `(instituicao, tabela_retorno, vigencia)` | Sem FK (referenciada temporalmente por `simulacao_financiamento` via trigger `simulacao_retorno_bi` e `simulacao_retorno_bu`) | `tabela_retorno` (`R0`..`R5`), `acrescimo_taxa_mensal >= 0`, `retorno_pct` (`0..0.10`), `origem` (`HIPOTESE`, `CALIBRADA`), `vigencia`. Tabelas de retorno bancário sobre o valor financiado. |
| `simulacao_financiamento` | `01-ddl` | `id_simulacao` (`BIGINT AUTO_INCREMENT`) | `id_proposta NOT NULL FK -> proposta`; triggers MySQL `simulacao_retorno_bi`/`simulacao_retorno_bu`; coluna gerada `id_proposta_aprovada` com índice único `uq_simulacao_aprovada_proposta` | `instituicao`, `tabela_retorno` (`DEFAULT 'R0'`), `origem` (`ACADEMICA`, `INFORMADA_BANCO`, `INTEGRACAO`), `valor_financiado`, `taxa_mensal`, `prazo_meses`, `parcela_informada`, `renda_declarada`, `consentimento_renda`, `situacao`, `data_simulacao`, `data_resposta`. Sem `DELETE`; imutável após `'EM_ANALISE'`. |
| `obrigacao_financeira` | `01-ddl` | `id_obrigacao` (`BIGINT AUTO_INCREMENT`) | Arco exclusivo (`ck_obrigacao_arco`): `id_venda FK`, `id_entrada FK`, `id_despesa FK` (anuláveis) | `natureza` (`RECEBER`, `PAGAR`), `origem` (`VENDA`, `ENTRADA`, `DESPESA_VEICULO`, `ADMINISTRATIVA`), `categoria`, `contraparte`, `valor`, `data_competencia`, `vencimento_original` (imutável), `vencimento_atual`, `situacao`, `origem_estimativa`. Sem `DELETE`; `UPDATE` restrito a `vencimento_atual` e `situacao`. |
| `parametro_prazo` | `01-ddl` | `(banco, tipo_obrigacao, vigencia)` | Sem FK (parâmetro temporal por instituição/tipo) | `dias_previstos >= 0`, `origem` (`HIPOTESE`, `CALIBRADA`), `tipo_obrigacao` (`FINANCIAMENTO_RECEBER`, `CONSIGNANTE_PAGAR`, `COMPRA_PROPRIA_PAGAR`). |
| `interacao` | `03-ddl` | `id_interacao` (`BIGINT AUTO_INCREMENT`) | `id_atendimento NOT NULL FK -> atendimento`, `id_funcionario NOT NULL FK -> funcionario` | `data_hora`, `canal` (`TELEFONE`, `WHATSAPP`, `EMAIL`, `PRESENCIAL`, `OUTRO`), `direcao` (`RECEBIDA`, `ENVIADA`), `resumo`, `proximo_passo`, `data_proximo_passo`. Somente inserção. |
| `atendimento_desfecho` | `03-ddl` | `id_atendimento` | `id_atendimento PK/FK -> atendimento`, `id_funcionario NOT NULL FK -> funcionario` | `data_hora`, `tipo_desfecho` (`GANHO`, `PERDA`), `motivo`, `detalhe`. Somente inserção. |
| `classificacao_lead` | `03-ddl` | `id_classificacao` (`BIGINT AUTO_INCREMENT`) | `id_atendimento NOT NULL FK -> atendimento`, `id_revisor FK -> funcionario` (anulável) | `data_hora`, `origem` (`REGRA`, `IA`), `versao_regra`, `temperatura_sugerida`, `pontuacao`, `temperatura_final`, `data_revisao`, `justificativa_revisao`. |
| `classificacao_fator` | `03-ddl` | `(id_classificacao, codigo_fator)` | `id_classificacao NOT NULL FK -> classificacao_lead` | `codigo_fator` (`URGENCIA_CONTATO`, `ESTAGIO_NEGOCIACAO`, `INTERESSE_FINANCEIRO`, `VOLUME_INTERACOES` e, só na `'REGRA-V2'`, `CAPACIDADE_PAGAMENTO`), `pontos`, `evidencia`. Somente inserção. |
| `parametro_temperatura` | `03-ddl` | `temperatura` | Sem FK (`temperatura IN ('FRIO','MORNO','QUENTE')`) | `probabilidade DECIMAL(5,4)` (`0..1`), `origem` (`HIPOTESE`, `CALIBRADA`), `vigencia`. |
| `intencao_compra` | `07` | `id_atendimento` | `id_atendimento PK/FK -> atendimento`, `id_entrada FK -> entrada` (anulável), `codigo_forma FK -> forma_pagamento` (anulável) | `valor_disponivel`, `data_registro`, `origem` (`SITE`, `VENDEDOR`). Intenção declarada pelo cliente, lida pela `'REGRA-V2'` (RN44). |

**Views e funções de negócio da extensão:**
- `data_referencia()` (`01-ddl`): retorna `parametro_referencia.data_referencia` (ou `CURRENT_DATE` se vazia);
- `vw_cliente_cpf` (`01-ddl`): histórico unificado de `ATENDIMENTO`, `PROPOSTA` e `VENDA` por CPF;
- `vw_simulacao_parcela` (`01-ddl`): prestação calculada pela fórmula Price com `taxa_cliente_mensal` (`parcela_calculada`), `custo_total_cliente`, `cet_aproximado_anual`, `retorno_loja` e comprometimento da renda (`parcela_sobre_renda_pct`);
- `vw_proposta_comparativo` (`01-ddl`): comparativo dos três ângulos de cada proposta (`rotulo`, `versao`, `valor_total`, `caixa_d0`, `caixa_posterior`, `valor_em_troca`, `margem_estimada`, `retorno_banco`, `margem_com_retorno`, `parcela_simulada`, `parcela_sobre_renda_pct`, `dias_ate_recebimento`, `prazo_caixa`);
- `registrar_classificacao_lead(p_id_atendimento, p_versao_regra, p_data_referencia)` (`03-ddl`, redefinida em `07`): motor de pontuação explicável `'REGRA-V1'` (quatro fatores) e `'REGRA-V2'` (os mesmos quatro mais `CAPACIDADE_PAGAMENTO`); outra versão é recusada;
- `vw_lead_atual` (`03-ddl`): fotografia atual de cada atendimento com última classificação, revisão humana, desfecho e `dias_sem_contato`;
- `vw_fila_acoes` (`03-ddl`): fila priorizada por `valor_em_risco DESC` cruzando `CAIXA` (lendo `obrigacao_financeira` e `parametro_prazo`), `CRM` (lendo `vw_lead_atual` e o maior `valor_total` entre as propostas abertas e ainda válidas do atendimento, excluindo leads já convertidos em venda) e `ESTOQUE` (entradas ativas paradas sem venda nem proposta aberta);
- `vw_caixa_realizado_referencia` (`05-consultas-demo.sql`): consolida os recebimentos (`venda.valor_recebido`) registrados entre a segunda-feira da semana de referência e `data_referencia()`, explicando que apenas entradas históricas existem no núcleo e que por isso o saldo inicial é uma `HIPOTESE`;
- `fn_previsao_caixa_cenario(p_cenario, p_saldo_inicial)` e `vw_previsao_caixa` (`05-consultas-demo.sql`): projeção semanal de fluxo de caixa nos cenários `'BASE'`, `'BANCO_ATRA_15_DIAS'` e `'LEADS_QUENTES_NAO_FECHAM'`.

### 4.2. Análise de cardinalidades pelo Método Vá e Volte (R20 a R41)

Continuando a numeração da seção 14 do [`README.md`](../README.md) (`R01` a `R19`), cada novo relacionamento entre tabelas foi analisado nos dois sentidos (**Ida A → B** e **Volta B → A**), em conformidade com [`docs/modelo-logico.md`](modelo-logico.md) e [`docs/modelo-logico/extensao.mmd`](modelo-logico/extensao.mmd):

| Relação | Entidade A — verbo — Entidade B | Ida (A → B) | Volta (B → A) | Conversão física e justificativa (Método Vá e Volte) |
|---|---|---|---|---|
| **R20** | `ATENDIMENTO` — gera — `PROPOSTA` | `(0,N)` | `(1,1)` | **Ida:** um atendimento pode encerrar sem proposta (`0`) ou gerar várias alternativas e versões (`N`). **Volta:** cada proposta pertence a um único atendimento (`proposta.id_atendimento NOT NULL FK`, **RN34**). |
| **R21** | `ENTRADA` — é ofertada em — `PROPOSTA` | `(0,N)` | `(1,1)` | **Ida:** uma entrada pode receber zero ou várias propostas (`N`), sendo no máximo uma `'ACEITA'` (`uq_proposta_aceita_entrada`). **Volta:** cada proposta oferta uma única entrada (`proposta.id_entrada NOT NULL FK`, **RN34–RN35**). |
| **R22** | `FUNCIONARIO` — elabora — `PROPOSTA` | `(0,N)` | `(1,1)` | **Ida:** um funcionário elabora zero ou várias propostas. **Volta:** cada proposta tem um único funcionário emissor (`proposta.id_funcionario NOT NULL FK`, **RN34**). |
| **R23** | `PROPOSTA` — sucede — `PROPOSTA` | `(0,1)` | `(0,1)` | **Ida:** uma proposta apresentada pode ter no máximo uma contraproposta sucessora imediata na mesma alternativa (`rotulo`, `versao + 1`) (`1`). **Volta:** uma proposta raiz (`versao = 1`) não tem anterior (`0`) e uma contraproposta (`versao > 1`) aponta para exatamente uma proposta anterior (`proposta.id_proposta_anterior UNIQUE FK`, `ck_proposta_raiz_versao`, **RN34**). |
| **R24** | `PROPOSTA` — formaliza — `VENDA` | `(0,1)` | `(0,1)` | **Ida:** uma proposta pode não virar venda (`0`) ou originar no máximo uma venda (`1`). **Volta:** uma venda pode vir do histórico/balcão sem proposta (`0`) ou referenciar uma única proposta aceita (`venda.id_proposta UNIQUE FK`, **RN37**). |
| **R25** | `PROPOSTA` — compõe — `PROPOSTA_CONDICAO` — referência — `FORMA_PAGAMENTO` | `PROPOSTA → CONDICAO`: `(0,N)`<br>`FORMA → CONDICAO`: `(0,N)` | `CONDICAO → PROPOSTA`: `(1,1)`<br>`CONDICAO → FORMA`: `(1,1)` | Resolve a relação N:N entre `proposta` e `forma_pagamento` com `valor` e `prazo_previsto_dias` em `proposta_condicao(id_proposta PK/FK, codigo_forma PK/FK)` (**RN35**). O mínimo é `0` mesmo na proposta apresentada: a RN35 exige apenas que condições mais trocas somem exatamente `valor_total`, então uma troca de valor igual ao preço quita a proposta sem condição de pagamento. |
| **R26** | `PROPOSTA` — inclui — `PROPOSTA_TROCA` — utiliza — `AVALIACAO` | `PROPOSTA → TROCA`: `(0,N)`<br>`AVALIACAO → TROCA`: `(0,N)` | `TROCA → PROPOSTA`: `(1,1)`<br>`TROCA → AVALIACAO`: `(1,1)` | Resolve a relação N:N entre `proposta` e `avaliacao` (finalidade `'TROCA'`, aprovada e não consumida por entrada) com `valor_oferecido` em `proposta_troca(id_proposta PK/FK, id_avaliacao PK/FK)` (**RN36**). |
| **R27** | `PROPOSTA` — cotada em — `SIMULACAO_FINANCIAMENTO` | `(0,N)` | `(1,1)` | **Ida:** uma proposta pode ter zero ou várias simulações (`N`, no máximo uma `'APROVADA'` via `uq_simulacao_aprovada_proposta`). **Volta:** cada simulação pertence a uma única proposta (`id_proposta NOT NULL FK`, **RN38**). |
| **R28** | `PARAMETRO_RETORNO` — parametriza — `SIMULACAO_FINANCIAMENTO` | `(0,N)` | `(1,1)` | **Ida:** uma faixa de retorno vigente (`instituicao`, `tabela_retorno` de `R0` a `R5`, `vigencia`) pode parametrizar zero ou várias simulações (`N`). **Volta:** cada simulação aplica exatamente um parâmetro de retorno vigente para sua instituição e data (`simulacao_retorno_bi` e `simulacao_retorno_bu`, **RN43**). |
| **R29** | `VENDA` — origina — `OBRIGACAO_FINANCEIRA` | `(0,N)` | `(0,1)` | **Ida:** uma venda pode gerar zero ou várias obrigações a receber (`N`). **Volta:** cada obrigação aponta para `id_venda` apenas quando `origem = 'VENDA'` (`ck_obrigacao_arco`, **RN39**). |
| **R30** | `ENTRADA` — origina — `OBRIGACAO_FINANCEIRA` | `(0,N)` | `(0,1)` | **Ida:** uma entrada pode gerar zero ou várias obrigações a pagar (`N`). **Volta:** cada obrigação aponta para `id_entrada` apenas quando `origem = 'ENTRADA'` (**RN39**). |
| **R31** | `DESPESA` — origina — `OBRIGACAO_FINANCEIRA` | `(0,N)` | `(0,1)` | **Ida:** uma despesa de veículo pode gerar obrigação a pagar (`0,N`). **Volta:** cada obrigação aponta para `id_despesa` apenas quando `origem = 'DESPESA_VEICULO'` (em `'ADMINISTRATIVA'`, as três FKs são `NULL`, **RN39**). |
| **R32** | `ATENDIMENTO` — registra — `INTERACAO` | `(0,N)` | `(1,1)` | **Ida:** um atendimento pode ter zero ou várias interações ao longo do tempo. **Volta:** cada interação pertence a um único atendimento (`interacao.id_atendimento NOT NULL FK`, **RN40**). |
| **R33** | `FUNCIONARIO` — realiza — `INTERACAO` | `(0,N)` | `(1,1)` | **Ida:** um funcionário realiza zero ou várias interações. **Volta:** cada interação identifica um único funcionário (`interacao.id_funcionario NOT NULL FK`, **RN40**). |
| **R34** | `ATENDIMENTO` — encerra com — `ATENDIMENTO_DESFECHO` | `(0,1)` | `(1,1)` | **Ida:** um atendimento aberto não tem desfecho (`0`) e um encerrado tem no máximo um (`1`). **Volta:** cada desfecho pertence a um único atendimento (`id_atendimento PK/FK`, **RN40**), além de referenciar o funcionário que o registrou `(1,1)`. |
| **R35** | `ATENDIMENTO` — avaliado em — `CLASSIFICACAO_LEAD` | `(0,N)` | `(1,1)` | **Ida:** um atendimento pode receber zero ou várias classificações históricas. **Volta:** cada classificação avalia um único atendimento (`id_atendimento NOT NULL FK`, **RN41**). |
| **R36** | `FUNCIONARIO` — revisa — `CLASSIFICACAO_LEAD` | `(0,N)` | `(0,1)` | **Ida:** um funcionário pode revisar várias classificações. **Volta:** uma classificação pode estar sem revisão (`0`) ou revisada por um único funcionário (`id_revisor FK`, **RN41**). |
| **R37** | CLASSIFICACAO_LEAD — explicada por — CLASSIFICACAO_FATOR | (1,N) | (1,1) | Ida: cada classificação gerada pela regra possui fatores explicativos (4 em REGRA-V1 e 5 em REGRA-V2). O MySQL recusa INSERT direto sem a marca interna e encaminha a gravação por registrar_classificacao_lead, que insere a classificação e seus fatores antes de retornar (RN41). Volta: cada fator pertence a uma única classificação (id_classificacao PK/FK). |
| **R38** | `FUNCIONARIO` — registra — `ATENDIMENTO_DESFECHO` | `(0,N)` | `(1,1)` | **Ida:** um funcionário pode não ter encerrado nenhum atendimento ou ter registrado vários desfechos. **Volta:** cada desfecho é registrado por exatamente um funcionário (`atendimento_desfecho.id_funcionario NOT NULL FK`, **RN40**). |
| **R39** | `ATENDIMENTO` — declara — `INTENCAO_COMPRA` | `(0,1)` | `(1,1)` | **Ida:** um atendimento pode não ter intenção declarada (`0`) e tem no máximo uma (`1`, PK = FK). **Volta:** cada intenção pertence a um único atendimento (`intencao_compra.id_atendimento PK/FK`, **RN44**). |
| **R40** | `ENTRADA` — pretendida em — `INTENCAO_COMPRA` | `(0,N)` | `(0,1)` | **Ida:** uma entrada anunciada pode ser pretendida por vários clientes. **Volta:** a intenção pode ainda não ter carro escolhido (`0`) ou apontar uma única entrada (`id_entrada FK` anulável), que precisa estar `ATIVA` quando a intenção é registrada (**RN44**). |
| **R41** | `FORMA_PAGAMENTO` — pretendida em — `INTENCAO_COMPRA` | `(0,N)` | `(0,1)` | **Ida:** uma forma do catálogo pode aparecer em várias intenções. **Volta:** a intenção pode não informar a forma (`0`, por exemplo forma combinada) ou referenciar uma única (`codigo_forma FK` anulável). |

As tabelas `parametro_referencia`, `parametro_prazo` e `parametro_temperatura` são relações independentes de configuração/calibração temporal, lidas pelas views e funções sem manter FK com registros transacionais.

---

## 5. Normalização (1FN, 2FN e 3FN) das tabelas novas

Seguindo o padrão de [`docs/normalizacao.md`](normalizacao.md), apresentamos a decomposição até a 3FN e o quadro de verificação das 14 tabelas novas.

### 5.1. Primeira forma normal (1FN): condições de pagamento e trocas da proposta

- **Estrutura antes:** `PROPOSTA_BRUTA(id_proposta, rotulo, versao, ..., condicoes = {(PIX, 11000, D+0), (FINANCIAMENTO, 44000, D+15)}, trocas = {(avaliacao 11, 30000)})`.
- **Dependência funcional/multivalorada:** `id_proposta ↠ (codigo_forma, valor, prazo_previsto_dias)` e `id_proposta ↠ (id_avaliacao, valor_oferecido)`.
- **Problema:** atributos multivalorados ou colunas repetidas (`forma1`, `forma2`) violam a 1FN e impedem agregações por prazo (`D+0` vs. `D+x`) e integridade referencial.
- **Correção depois:** decomposição em `proposta_condicao(id_proposta PK/FK, codigo_forma PK/FK, valor, prazo_previsto_dias)` e `proposta_troca(id_proposta PK/FK, id_avaliacao PK/FK, valor_oferecido)`.

### 5.2. Segunda forma normal (2FN): fatores da classificação de lead

- **Estrutura antes:** `CLASSIFICACAO_FATOR_BRUTA(id_classificacao PK, codigo_fator PK, id_atendimento, data_hora, versao_regra, temperatura_sugerida, pontuacao, pontos, evidencia)`.
- **Dependência funcional:** `(id_classificacao, codigo_fator) → pontos, evidencia`, mas `id_classificacao → id_atendimento, data_hora, versao_regra, temperatura_sugerida, pontuacao` (dependência parcial).
- **Problema:** repetir os dados do cabeçalho da classificação em cada um dos 4 fatores gera redundância e anomalia de atualização.
- **Correção depois:** separação entre `classificacao_lead(id_classificacao PK, ...)` e `classificacao_fator(id_classificacao PK/FK, codigo_fator PK, pontos, evidencia)`.

### 5.3. Terceira forma normal (3FN): ausência de dependências transitivas

- **Não duplicação de cliente e veículo em `proposta`:** Como `id_proposta → id_atendimento → id_pessoa` e `id_proposta → id_entrada → id_veiculo`, a tabela `proposta` não armazena `id_pessoa` nem `id_veiculo`. A coerência com a venda é validada por junção no trigger `validar_venda_proposta()`.
- **Separação de parâmetros de retorno bancário (`parametro_retorno`) e cálculo Price em view (`vw_simulacao_parcela`):** Como `(instituicao, tabela_retorno, vigencia) → (acrescimo_taxa_mensal, retorno_pct, origem)`, esses parâmetros ficam isolados em `parametro_retorno` e não repetidos em `simulacao_financiamento`. Já a prestação teórica Price (`parcela_calculada`), o custo total (`custo_total_cliente`), o CET anual (`cet_aproximado_anual`), o retorno em reais (`retorno_loja`) e o percentual sobre a renda (`parcela_sobre_renda_pct`) são calculados em `vw_simulacao_parcela`, enquanto `parcela_informada` registra apenas o valor externo quando cotado junto ao banco.
- **Materialização controlada em `proposta.valor_total`:** Segue a mesma definição de `venda.valor_total`: `GENERATED ALWAYS AS (valor_base - desconto + acrescimo + taxas) STORED`, impedindo divergência entre os componentes e o total.

### 5.4. Verificação consolidada das 14 tabelas novas

| Tabela | Chave(s) candidata(s) | Verificação de 1FN, 2FN e 3FN |
|---|---|---|
| `parametro_referencia` | `chave` | Tabela de linha única (`chave = true`); `data_referencia` e `origem` dependem da chave. Em 3FN. |
| `proposta` | `id_proposta`; `(id_atendimento, id_entrada, rotulo, versao)` | Colunas atômicas. Sem dependências parciais ou transitivas (cliente e veículo vêm de `atendimento` e `entrada`; cada alternativa tem seu `rotulo` e sequência de `versao` garantida por `uq_proposta_alternativa_versao`). `valor_total` é coluna gerada pelo SGBD. Em 3FN. |
| `proposta_condicao` | `(id_proposta, codigo_forma)` | `valor` e `prazo_previsto_dias` dependem do par completo `(id_proposta, codigo_forma)`. Em 3FN. |
| `proposta_troca` | `(id_proposta, id_avaliacao)` | `valor_oferecido` depende do par completo `(id_proposta, id_avaliacao)`. Em 3FN. |
| `parametro_retorno` | `(instituicao, tabela_retorno, vigencia)` | `acrescimo_taxa_mensal`, `retorno_pct` e `origem` dependem da chave tripla completa `(instituicao, tabela_retorno, vigencia)`. Em 3FN. |
| `simulacao_financiamento` | `id_simulacao` | Atributos dependem exclusivamente de `id_simulacao`; parâmetros da faixa de retorno ficam em `parametro_retorno` e prestação/CET/retorno ficam em `vw_simulacao_parcela`. Em 3FN. |
| `obrigacao_financeira` | `id_obrigacao` | Todos os atributos descrevem a obrigação identificada por `id_obrigacao`, com arco exclusivo validado por `ck_obrigacao_arco`. Em 3FN. |
| `parametro_prazo` | `(banco, tipo_obrigacao, vigencia)` | `dias_previstos` e `origem` dependem da chave tripla completa. Em 3FN. |
| `interacao` | `id_interacao` | Todos os campos do contato dependem apenas de `id_interacao`. Em 3FN. |
| `atendimento_desfecho` | `id_atendimento` | Chave simples (`1 : 0..1`); `id_funcionario`, `data_hora`, `tipo_desfecho`, `motivo` e `detalhe` dependem apenas de `id_atendimento`. Em 3FN. |
| `classificacao_lead` | `id_classificacao` | Sugestão e revisão humana dependem apenas de `id_classificacao`; `temperatura_atual` e `revisado` são derivados em `vw_lead_atual`. Em 3FN. |
| `classificacao_fator` | `(id_classificacao, codigo_fator)` | `pontos` e `evidencia` dependem da chave composta completa. Em 3FN. |
| `parametro_temperatura` | `temperatura` | `probabilidade`, `origem` e `vigencia` dependem apenas da chave simples `temperatura`. Em 3FN. |
| `intencao_compra` | `id_atendimento` | Chave simples (`1 : 0..1` com o atendimento); `id_entrada`, `valor_disponivel`, `codigo_forma`, `data_registro` e `origem` dependem só do atendimento. O preço do carro pretendido não é copiado (vem de `entrada.preco_anunciado`) e a cobertura é calculada na regra, não gravada. Em 3FN. |

---

## 6. O que é `HIPOTESE` / `ACADEMICA` e como calibrar

### 6.1. Marcação explícita de suposições no banco
Como a massa do núcleo possui 6 vendas (apenas uma com financiamento já recebido — Venda 3, em 1 dia), não há série estatística real para estimar probabilidades de fechamento nem prazos bancários médios. Tudo o que é premissa de simulação fica explicitamente rotulado no banco (**RN42**):

| Objeto | Marcação no banco | Valores usados na demonstração (`02`, `04` e `05`) |
|---|---|---|
| `parametro_referencia` | `origem = 'DEMONSTRACAO'` | Criada em `01-ddl-propostas-caixa.sql` e populada em `02-massa-propostas-caixa.sql` com `data_referencia = '2026-02-10'` (fixa o "hoje" dos defaults, das views do CRM e da previsão de caixa; se vazia em operação, `data_referencia()` usa `CURRENT_DATE`). |
| `parametro_retorno` | `origem = 'HIPOTESE'` | Para `Banco Demonstracao` (`vigencia = 2026-01-01`): `'R0'` (`acrescimo_taxa_mensal = 0.000000`, `retorno_pct = 0.0000`) e `'R4'` (`acrescimo_taxa_mensal = 0.003000`, `retorno_pct = 0.0400`). |
| `simulacao_financiamento` | `origem = 'ACADEMICA'` | Proposta 2 (`rotulo = 'B'`, `valor_financiado = 44000.00`, `taxa_mensal = 0.018900`, `prazo_meses = 48`, `renda_declarada = 6500.00`): simulação 1 em `'R0'` (`parcela_informada = 1402.56`, `parcela_calculada = 1402.56`, `retorno_loja = 0.00`) e simulação 2 em `'R4'` (`parcela_calculada = 1490.50`, `retorno_loja = 1760.00`). |
| `parametro_prazo` | `origem = 'HIPOTESE'` | `Banco Demonstracao / FINANCIAMENTO_RECEBER = 15 dias`; `Consignante Demonstracao / CONSIGNANTE_PAGAR = 5 dias`; `Fornecedor Demonstracao / COMPRA_PROPRIA_PAGAR = 3 dias`. |
| `obrigacao_financeira` | `origem_estimativa = 'HIPOTESE'` | Obrigação `1` (`RECEBER`, `VENDA 6`, `FINANCIAMENTO`, `R$ 80.000,00`, vencimento `2026-01-25` = aprovação `2026-01-10` + 15 dias do `parametro_prazo`). |
| `parametro_temperatura` | `origem = 'HIPOTESE'` | `FRIO = 0.0500` (5%), `MORNO = 0.3000` (30%), `QUENTE = 0.6500` (65%). |
| `registrar_classificacao_lead` | `versao_regra = 'REGRA-V1'` | Fatores: `URGENCIA_CONTATO` (`>=15d: 40`, `>=7d: 20`), `ESTAGIO_NEGOCIACAO` (`EM_NEGOCIACAO: 30`, `ABERTO: 10`), `INTERESSE_FINANCEIRO` (`COMPRA: 20`, `TROCA: 15`, `VENDA: 10`), `VOLUME_INTERACOES` (`>=3: 10`, `1–2: 5`); cortes: `>=70 QUENTE`, `>=40 MORNO`. |
| `registrar_classificacao_lead` | `versao_regra = 'REGRA-V2'` | Os quatro fatores da V1, iguais, mais `CAPACIDADE_PAGAMENTO` sobre `valor_disponivel / preco_anunciado` da entrada pretendida: Pix ou dinheiro com cobertura `>= 90%`: 40; outra forma ou forma não informada com cobertura `>= 90%`: 30; cobertura `>= 50%` ou forma financiamento: 20; cobertura não calculável com forma informada: 10; cobertura `< 50%` sem financiamento: 0; ausência de intenção: 0. Mesmos cortes de temperatura. Pesos definidos como hipótese, a calibrar como os da V1. |
| `vw_caixa_realizado_referencia` e `fn_previsao_caixa_cenario` | `p_saldo_inicial DEFAULT 25000.00` e escolha uniforme `P(lead)/N` | O núcleo registra apenas entradas acumuladas (`venda.valor_recebido` na data de `data_ultimo_recebimento`), sem saídas históricas; por isso o saldo inicial na semana de referência (`R$ 25.000,00`) é declarado como `HIPOTESE`, somando na camada `REALIZADO` apenas recebimentos ocorridos entre a segunda-feira da semana de referência (`2026-02-09`) e `data_referencia()` (`2026-02-10`), além de dividir `P(lead)` entre as `N = 3` propostas alternativas (`0,6500 / 3 = 0,2167`). |

### 6.2. Como calibrar em produção
1. **Prazos bancários, operacionais e tabelas de retorno (`parametro_prazo` e `parametro_retorno`):** apurar a mediana de `(data_recebimento_financiamento - data_aprovacao_financiamento)` por `instituicao_financeira` nas vendas concluídas e registrar as tabelas comerciais vigentes dos bancos parceiros com `origem = 'CALIBRADA'` e nova `vigencia`.
2. **Probabilidades por temperatura (`parametro_temperatura`):** medir a taxa histórica de conversão `SUM(tipo_desfecho = 'GANHO') / COUNT(*)` em `atendimento_desfecho` agrupada pela temperatura vigente do atendimento antes do encerramento, atualizando `parametro_temperatura` para `origem = 'CALIBRADA'`.
3. **Pesos da regra de CRM (`registrar_classificacao_lead`):** inspecionar os casos em que `temperatura_final <> temperatura_sugerida` (com base em `justificativa_revisao` e `classificacao_fator`) para recalibrar os pesos sem sobrescrever as avaliações históricas. A `'REGRA-V2'` (arquivo 07) nasceu assim, de um caso real do site em que um cliente que oferecia pagar à vista quase o preço cheio ficou `FRIO` pela V1; a V1 continua disponível e cada classificação antiga guarda a versão que a gerou.

---

## 7. Conformidade com a LGPD (renda declarada, consentimento e interações)

Em alinhamento aos requisitos `RNF01` e `RNF02` e à Lei nº 13.709/2018 (LGPD):

1. **Renda declarada condicionada a consentimento expresso (`RN38`):**
   - Na tabela `simulacao_financiamento`, `renda_declarada` é anulável (`NULL`) e protegida pela constraint `ck_simulacao_consentimento_renda CHECK (renda_declarada IS NULL OR consentimento_renda)`.
   - Tentar inserir `renda_declarada` com `consentimento_renda = false` é bloqueado pelo SGBD com erro MySQL 3819 (`ck_simulacao_consentimento_renda`), comprovado nos testes negativos de [`02-massa-propostas-caixa.sql`](../sql/extensao/02-massa-propostas-caixa.sql).
2. **Minimização de dados em `interacao` e `atendimento_desfecho`:**
   - Os campos `resumo`, `proximo_passo`, `motivo` e `detalhe` registram exclusivamente fatos comerciais objetivos da negociação (interesse no veículo, retorno sobre proposta ou fechamento em concorrente), sem coleta de dados pessoais sensíveis.
3. **Explicabilidade e direito à revisão humana (art. 20 da LGPD):**
   - Toda pontuação em `classificacao_lead` é acompanhada das razões exatas em `classificacao_fator`, e a decisão final (`temperatura_final`) depende de revisão humana (`id_revisor`), não havendo decisão automatizada irrecorrível (**RN41**).
4. **Acesso por CPF (`vw_cliente_cpf`) e proteção em relatórios:**
   - `vw_cliente_cpf` consolida os registros do titular para atendimento de balcão por perfil autorizado (`RNF01`), enquanto consultas gerenciais agregadas mantêm o mascaramento de CPF, telefone e e-mail (`RNF02`).

---

## 8. Limitações conhecidas e escopo adiado

1. **Movimentação bancária individual (`movimento_caixa`) e saídas históricas de caixa:**
   - A extensão modela obrigações previstas/abertas (`obrigacao_financeira`), o caixa realizado na semana da referência (`vw_caixa_realizado_referencia`) e a projeção semanal (`vw_previsao_caixa`), mantendo `venda.valor_recebido` como atributo acumulado em `venda`. Como o núcleo não guarda livro-razão de pagamentos históricos já liquidados, o saldo inicial da projeção é informado por parâmetro (`HIPOTESE`). A tabela `movimento_caixa` para baixas parciais e estornos individuais ficou adiada para não reabrir a `RN22` nem alterar os testes do núcleo ([`docs/escopo-financeiro.md`](escopo-financeiro.md) §2.3).
2. **Fila de ações como view (`vw_fila_acoes`) sem tabela de workflow (`sugestao_acao`):**
   - A fila de ações é calculada em tempo real pela view `vw_fila_acoes`, garantindo que uma ação desapareça automaticamente assim que a obrigação for quitada ou o contato for registrado, sem exigir tela para dar baixa manual em alertas.
3. **Modelos de linguagem (LLM) sobre texto livre:**
   - Extração de sinais a partir de texto livre e geração de mensagens dependem de aplicação externa e foram adiadas. O banco já prevê `classificacao_lead.origem IN ('REGRA', 'IA')` subordinada à trava de revisão humana (`revisar_classificacao_lead`).
4. **Integração online com bancos e bureaus de crédito:**
   - Exige contrato comercial e backend externo; o domínio `simulacao_financiamento.origem` já contempla `'INTEGRACAO'` ao lado de `'ACADEMICA'` e `'INFORMADA_BANCO'`.

---

## 9. Roteiro de execução e demonstração no MySQL Workbench

### 9.1. Sequência completa de execução

Conecte ao servidor MySQL 8.4, abra sql/executar-tudo-workbench.sql por File > Open SQL Script e clique no primeiro raio (Execute All), sem selecionar texto. Para executar em arquivos separados, siga a ordem de 14 passos listada no README.md. A evidência local registra 435 PASS e zero erros.

### 9.2. Roteiro de demonstração e resultados reais ([`sql/extensao/05-consultas-demo.sql`](../sql/extensao/05-consultas-demo.sql))

#### 1. Busca única por CPF (`vw_cliente_cpf`)
```sql
SELECT * FROM vw_cliente_cpf
WHERE cpf='00000000010'
ORDER BY data_evento,tipo_registro,id_registro;
```
Retorna o histórico unificado de `Joao Comprador` (`id_pessoa = 10`, CPF `00000000010`): seus atendimentos (`atendimento 4` e `atendimento 7`), a `venda 4` histórica e as 3 propostas apresentadas em `2026-02-03` para a `entrada 10` (`R$ 55.000,00` cada).

#### 2. Comparativo das 3 propostas pelos três ângulos (`vw_proposta_comparativo` e `vw_simulacao_parcela`)
```sql
SELECT id_proposta,rotulo,versao,situacao,valor_total,caixa_d0,caixa_posterior,valor_em_troca,
       margem_estimada,retorno_banco,margem_com_retorno,parcela_simulada,prazo_caixa
FROM vw_proposta_comparativo
WHERE cpf='00000000010'
ORDER BY versao;
```

Resultado real obtido:

```text
 id_proposta | rotulo | versao |  situacao   | valor_total | caixa_d0 | caixa_posterior | valor_em_troca | margem_estimada | retorno_banco | margem_com_retorno | parcela_simulada | prazo_caixa 
-------------+--------+--------+-------------+-------------+----------+-----------------+----------------+-----------------+---------------+--------------------+------------------+-------------
           1 | A      |      1 | APRESENTADA |    55000.00 | 55000.00 |            0.00 |           0.00 |         5000.00 |          0.00 |            5000.00 |             0.00 | D+0
           2 | B      |      1 | APRESENTADA |    55000.00 | 11000.00 |        45760.00 |           0.00 |         5000.00 |       1760.00 |            6760.00 |          1490.50 | D+15
           3 | C      |      1 | APRESENTADA |    55000.00 | 25000.00 |            0.00 |       30000.00 |         5000.00 |          0.00 |            5000.00 |             0.00 | D+0
```

Na Proposta B (`id_proposta = 2`), a margem operacional do veículo permanece em **R$ 5.000,00**, mas o retorno do banco (`R$ 1.760,00` na simulação mais recente, `R4`) eleva a **`margem_com_retorno` para R$ 6.760,00** e o `caixa_posterior` para **R$ 45.760,00** (`D+15`).

#### 3. Retorno bancário (`R0` vs. `R4`) e impacto no custo do cliente (`vw_simulacao_parcela`)
```sql
SELECT id_simulacao,tabela_retorno,taxa_base_mensal,taxa_cliente_mensal,
       parcela_calculada,custo_total_cliente,cet_aproximado_anual,retorno_loja
FROM vw_simulacao_parcela WHERE id_proposta=2 ORDER BY id_simulacao;
```

Resultado real obtido (Proposta B no `Banco Demonstracao`, `valor_financiado = 44000.00`, `48` meses, `renda_declarada = 6500.00` com `consentimento_renda = true`):

```text
 id_simulacao | tabela_retorno | taxa_base_mensal | taxa_cliente_mensal | parcela_calculada | custo_total_cliente | cet_aproximado_anual | retorno_loja 
--------------+----------------+------------------+---------------------+-------------------+---------------------+----------------------+--------------
            1 | R0             |         0.018900 |            0.018900 |           1402.56 |            67322.88 |             0.251926 |         0.00
            2 | R4             |         0.018900 |            0.021900 |           1490.50 |            71544.00 |             0.296883 |      1760.00
```

- **`R0` (`id_simulacao = 1`):** parcela de **R$ 1.402,56** (`21,58%` da renda), custo total do cliente de **R$ 67.322,88**, CET aproximado de **25,2% a.a.** (`0.251926`) e retorno da loja **R$ 0,00**;
- **`R4` (`id_simulacao = 2`):** parcela de **R$ 1.490,50** (`22,93%` da renda), custo total do cliente de **R$ 71.544,00**, CET aproximado de **29,7% a.a.** (`0.296883`) e retorno da loja de **R$ 1.760,00**;
- **Trade-off explícito:** na tabela `R4`, **o cliente paga R$ 4.221,12 a mais (`R$ 71.544,00 - R$ 67.322,88`) para a loja ganhar R$ 1.760,00 de retorno bancário**. Por isso o comparador sempre exibe o ângulo do cliente (`parcela_simulada`, `cet_aproximado_anual` e `%` da renda) ao lado do resultado da loja (`margem_com_retorno = R$ 6.760,00`).

#### 4. Estado atual do lead e revisão humana (`vw_lead_atual`)
```sql
SELECT id_atendimento,nome_cliente,temperatura_sugerida,temperatura_final,
       temperatura_atual,revisado,pontuacao,dias_sem_contato
FROM vw_lead_atual
WHERE id_atendimento=7;
```
Resultado real: `atendimento 7` (`Joao Comprador`), `temperatura_sugerida = 'MORNO'` (`pontuacao = 55.00`, com `dias_sem_contato = 7` na data de referência `2026-02-10`), revisado pelo funcionário `1` para `temperatura_final = 'QUENTE'` (`temperatura_atual = 'QUENTE'`, `revisado = true`) com justificativa registrada.

#### 5. Fila explicável de próximas ações (`vw_fila_acoes`)
```sql
SELECT fonte,id_referencia,descricao,motivo,valor_em_risco,urgencia_dias
FROM vw_fila_acoes
ORDER BY valor_em_risco DESC,urgencia_dias DESC;
```

Resultado real (ordenado por `valor_em_risco DESC`):
1. **`CAIXA` (ref. `1`, obrigação da Venda 6):** `valor_em_risco = 80000.00`, `urgencia_dias = 16` — financiamento de R$ 80.000,00 vencido desde `2026-01-25` (15 dias após a aprovação de `2026-01-10`, conforme `parametro_prazo` do `Banco Demonstracao`). O `atendimento 5` (Mário, já convertido na Venda 6) é automaticamente filtrado da fonte `CRM` para não duplicar essa cobrança.
2. **`CRM` (ref. `7`, atendimento 7 — João Comprador):** `valor_em_risco = 55000.00` (`proposta 3, maior valor entre 3 alternativa(s) aberta(s) e valida(s) (55000.00)`), `urgencia_dias = 7` — lead `QUENTE` sem contato há 7 dias (acima do limite de 3 dias para leads quentes).
3. **`ESTOQUE` (ref. `6`, entrada 6 — Fiat Uno):** `valor_em_risco = 25000.00`, `urgencia_dias = 35` — veículo recebido na troca da Venda 2 parado há 35 dias sem venda nem proposta aberta.
4. **`ESTOQUE` (ref. `7`, entrada 7 — Ford Ka):** `valor_em_risco = 15000.00`, `urgencia_dias = 35` — segundo veículo recebido na troca da Venda 2 parado há 35 dias.

#### 6. Caixa realizado até a referência, previsão semanal e análise de cenários (`vw_caixa_realizado_referencia`, `vw_previsao_caixa` e `fn_previsao_caixa_cenario`)
```sql
SELECT * FROM vw_caixa_realizado_referencia ORDER BY semana;
SELECT * FROM vw_previsao_caixa ORDER BY semana;
SELECT * FROM fn_previsao_caixa_cenario('BANCO_ATRA_15_DIAS',25000.00) ORDER BY semana;
SELECT * FROM fn_previsao_caixa_cenario('LEADS_QUENTES_NAO_FECHAM',25000.00) ORDER BY semana;
```

Resultados reais (com `saldo_inicial = 25000.00` e `data_referencia() = 2026-02-10`):

**Caixa realizado na semana de referência (`vw_caixa_realizado_referencia`):**
- `semana = 2026-02-09` | `realizado = 0.00` | `composicao = Nenhum recebimento registrado entre segunda-feira e a data de referencia; somente entradas historicas; saidas historicas nao registradas, saldo inicial HIPOTESE`.

**Cenário `BASE` (`vw_previsao_caixa`):**

| `semana` | `realizado` | `obrigacoes` | `funil_ponderado` | `saldo_projetado` | Síntese da `composicao` |
|---|---|---|---|---|---|
| `2026-02-09` | `0.00` | `6000.00` | `-1950.00` | **`29050.00`** | Saldo inicial `25000.00` + `RECEBER +80000.00` (Venda 6, vencida em `25/01`) + `PAGAR -74000.00` (repasse Venda 3) = `+6000.00` em obrigações; no funil, Pix `D+0` das propostas 1/2/3 (`55000 + 11000 + 25000`) menos repasse de `50000` das propostas 1 e 3 (`D+5`), ponderados por `0,65 / 3 = 0,2167` (`-1950.00`). |
| `2026-02-16` | `0.00` | `0.00` | `0.00` | **`29050.00`** | Sem movimentos previstos na semana. |
| `2026-02-23` | `0.00` | `0.00` | `9914.67` | **`38964.67`** | Recebimento ponderado do financiamento da Proposta 2 (`44000.00 × 0,65 / 3 = +9533.33`) + retorno bancário `R4` (`1760.00 × 0,65 / 3 = +381.33`) em `D+15`. |
| `2026-03-02` | `0.00` | `0.00` | `-10833.33` | **`28131.34`** | Pagamento ponderado ao consignante da Proposta 2 (`-50000.00 × 0,65 / 3` em `D+20`). |

**Cenário `BANCO_ATRA_15_DIAS` (bancos atrasam repasses de financiamento em 15 dias):**

| `semana` | `realizado` | `obrigacoes` | `funil_ponderado` | `saldo_projetado` | Efeito observado |
|---|---|---|---|---|---|
| `2026-02-09` | `0.00` | `-74000.00` | `-1950.00` | **`-50950.00`** | **Falta caixa:** o repasse da Venda 3 (`-74000.00`) sai na primeira semana, mas o recebível de `+80000.00` da Venda 6 é deslocado para `2026-02-25` (semana de `2026-02-23`). |
| `2026-02-16` | `0.00` | `0.00` | `0.00` | **`-50950.00`** | Caixa permanece negativo aguardando o repasse bancário. |
| `2026-02-23` | `0.00` | `80000.00` | `0.00` | **`29050.00`** | Entrada dos `+80000.00` da Venda 6 recompõe o caixa. |
| `2026-03-02` | `0.00` | `0.00` | `0.00` | **`29050.00`** | Sem movimentos na semana. |
| `2026-03-09` | `0.00` | `0.00` | `9914.67` | **`38964.67`** | Entrada deslocada do financiamento (`+9533.33`) e do retorno `R4` (`+381.33`) da Proposta 2 (`D+15 + 15 dias`). |
| `2026-03-16` | `0.00` | `0.00` | `-10833.33` | **`28131.34`** | Saída deslocada do repasse ao consignante da Proposta 2. |

**Cenário `LEADS_QUENTES_NAO_FECHAM` (conversão zero das propostas abertas de leads quentes):**
- `2026-02-09`: `realizado = 0.00`, `obrigacoes = 6000.00`, `funil_ponderado = 0.00`, `saldo_projetado = 31000.00`.

**Consulta final — "Quando falta dinheiro?" por cenário:**

```text
         cenario          |                 resposta                  
--------------------------+-------------------------------------------
 BANCO_ATRA_15_DIAS       | 2026-02-09 (saldo -50950.00)
 BASE                     | Nao falta dinheiro no horizonte projetado
 LEADS_QUENTES_NAO_FECHAM | Nao falta dinheiro no horizonte projetado
```


## Implementação MySQL 8.4

Os scripts sql/extensao/01..07 usam MySQL 8.4, InnoDB e utf8mb4. A extensão mantém 7 views de negócio e uma view auxiliar; junto ao núcleo, o schema contém 28 tabelas e 11 views. Unicidades condicionais usam colunas geradas armazenadas; validações entre tabelas ocorrem em triggers ou procedures no ponto de transição. fn_previsao_caixa_cenario é chamada com CALL e retorna um conjunto de resultados. Os testes de fluxos registram 71 PASS, os de relacionamentos 177 PASS e a cadeia completa 435 PASS. Veja docs/evidencias/mysql/paridade-testes.md.
