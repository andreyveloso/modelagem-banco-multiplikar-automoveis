# Escopo Financeiro, Despesas e Limitações Conhecidas — ERP Multiplikar Automóveis

Este documento trata os três pontos de modelagem financeira indicados na devolutiva da 1ª entrega:
1. (a) Escopo de despesas: no núcleo, a tabela `despesa` cobre apenas custos por veículo; despesas administrativas gerais ficaram fora dela. A extensão da Entrega Final passou a registrar obrigações administrativas a pagar em `obrigacao_financeira` (seção 1.3), sem alterar essa decisão do núcleo;
2. (b) Limitações conhecidas de `formas_pagamento`: análise do tratamento das formas de pagamento como atributo multivalorado de `VENDA` e como um módulo financeiro modelaria recebimentos individuais e parcelas;
3. (c) Obrigações financeiras ainda não quitadas: como saldos pendentes, financiamentos aprovados a receber, repasses de consignação e restituições de cancelamento são representados no banco.

---

## 1. Ponto (a): Escopo de Despesas — Custos por Veículo vs. Despesas Administrativas Gerais

### 1.1. Decisão de Escopo Adotada no Núcleo
O núcleo do banco (`sql/ddl/schema.sql`) cobre, na tabela `despesa`, apenas as despesas diretas vinculadas a cada veículo. Elas ficam na tabela **despesa** com chave estrangeira obrigatória para `veiculo` (`id_veiculo bigint NOT NULL REFERENCES veiculo`, conforme `RN32`, `RF17` e `P08`).

Despesas administrativas e fixas da loja — como aluguel do imóvel na Vila São Geraldo, energia, água, internet, folha salarial dos 6 funcionários, contabilidade, publicidade e impostos gerais — ficam fora do escopo deste banco de dados.

### 1.2. Justificativa Técnica e de Negócio
Manter **RN32** restrita a custos por veículo baseia-se em três motivos:

1. Aderência ao [Briefing Inicial Completo](fontes/briefing-completo.pdf):
   - Na página 7 (item 13), o briefing define que os relatórios de custo exigidos pela loja são os de "despesas relacionadas aos veículos". Na página 7 (item 9), lista exemplos aplicados ao carro: troca de bateria, pneus, alinhamento, balanceamento, pastilhas e discos de freio, além de higienização, preparação e vistorias.
   - A página 8 do briefing estabelece que hipóteses e pontos não confirmados não devem virar entidades ou regras do modelo final. O levantamento não definiu plano de contas administrativo, centros de custo nem critérios de rateio de despesas fixas.

2. Cálculo da margem operacional por veículo (`PROB09`):
   - O problema `PROB09` (Seção 4 do `README.md`) é a falta de clareza sobre as despesas e o lucro de cada automóvel vendido.
   - Com `despesa.id_veiculo NOT NULL`, a Consulta Gerencial #8 ([`sql/consultas/gerenciais.sql`](../sql/consultas/gerenciais.sql)) calcula a margem operacional líquida de cada ciclo de entrada somando as despesas do veículo no período do ciclo:
     - Compra própria ou troca: `Margem = venda.valor_total - entrada.valor_acordado - soma de despesa.valor do ciclo`;
     - Consignação: `Margem = venda.valor_total - entrada.valor_repasse_acordado - soma de despesa.valor do ciclo`.
   - Se `id_veiculo` aceitasse `NULL` para lançar contas de luz ou aluguel na mesma tabela `despesa`, custos de frota seriam misturados com despesas fixas da loja, distorcendo a rentabilidade por veículo.

3. Preservação da 3ª Forma Normal (3FN) e integridade referencial:
   - Na tabela **despesa** (`id_despesa PK, id_veiculo FK NOT NULL, data, categoria, descricao, valor`), cada coluna descreve um gasto sofrido por um veículo. Quem garante no SGBD que não existam despesas sem veículo é a restrição `id_veiculo bigint NOT NULL REFERENCES veiculo` (`fk_despesa_id_veiculo`), enquanto a Auditoria #8 ([`sql/auditoria/auditoria.sql`](../sql/auditoria/auditoria.sql)) confirma essa regra nas checagens.
   - Gastos fixos da loja não entram em `despesa`. A extensão os trata como obrigações a pagar em `obrigacao_financeira` (seção 1.3), e não em uma nova tabela de despesas.

### 1.3. Evolução na Entrega Final: obrigações administrativas na extensão

A decisão acima continua valendo para o núcleo e para a primeira entrega: a tabela `despesa` segue exclusiva de custos por veículo (`id_veiculo NOT NULL`), preservando o cálculo de margem por veículo (consulta gerencial 8, que soma apenas `despesa`). A extensão de propostas e caixa (`sql/extensao/01-ddl-propostas-caixa.sql`) acrescentou a tabela `obrigacao_financeira`, que amplia o controle financeiro sem reescrever a decisão anterior:

| Aspecto | Comportamento implementado |
|---|---|
| Origens aceitas | `VENDA`, `ENTRADA`, `DESPESA_VEICULO` e `ADMINISTRATIVA` (`ck_obrigacao_origem`). |
| Obrigação administrativa | Origem `ADMINISTRATIVA` exige natureza `PAGAR` e as três FKs (`id_venda`, `id_entrada`, `id_despesa`) nulas (`ck_obrigacao_arco`); não se vincula a veículo, venda ou entrada. |
| Dados registrados | Categoria e contraparte (não vazias, `ck_obrigacao_textos`), valor positivo, competência, vencimento original e atual, situação (`PREVISTA`, `ABERTA`, `ATRASADA`, `QUITADA`, `CANCELADA`) e origem da estimativa (`FATO`, `HIPOTESE`, `SIMULADO`). |
| Uso nas consultas | Obrigações não quitadas e não canceladas, inclusive administrativas, entram na previsão de caixa (`vw_fluxos_previsao`/`vw_previsao_caixa`); não entram na margem por veículo. |
| Evidência | `02-massa-propostas-caixa.sql` (arco administrativo com FK é recusado), `testes-fluxos.sql` (obrigação administrativa prevista aberta pelo fluxo permitido) e `testes-relacionamentos.sql` (R29–R31: obrigação administrativa sem arco aceita). |

Limitações que permanecem: não há plano de contas, centro de custo nem rateio das despesas administrativas entre veículos; despesas recorrentes não são geradas automaticamente; a massa de demonstração não mantém obrigações administrativas no estado final (elas aparecem apenas nos testes, que terminam em `ROLLBACK`).

---

## 2. Ponto (b): Limitações Conhecidas do Atributo Multivalorado de Formas de Pagamento

### 2.1. Contexto da Decisão de Modelagem (RN19, RN20 e RO12)
Seguindo o [Briefing Inicial Completo](fontes/briefing-completo.pdf) (Seção 9, p. 4, e Seção 17, p. 7–8), o projeto representou as formas de pagamento no modelo conceitual como atributo multivalorado de `VENDA` (`formas_pagamento`), contendo códigos simples (`PIX`, `DINHEIRO`, `CARTAO`, `FINANCIAMENTO`, `TROCA`), sem valor individual, data ou parcelas (**RN19**).

Na passagem para 1FN ([`docs/normalizacao.md`](normalizacao.md), Seção 1, e [`sql/ddl/schema.sql`](../sql/ddl/schema.sql), linhas 252–260), esse atributo gerou:
- A tabela de domínio `forma_pagamento (codigo PK, descricao UNIQUE)`;
- A tabela associativa `venda_forma_pagamento (id_venda PK/FK, codigo_forma PK/FK)`, formada apenas pela chave composta, enquanto o resumo monetário fica em `venda` (`valor_recebido`, `data_ultimo_recebimento` e dados do financiamento).

### 2.2. Limitações Conhecidas (Solicitado na Devolutiva)

> Tratar `formas_pagamento` como atributo multivalorado de `VENDA` (implementado em `venda_forma_pagamento(id_venda, codigo_forma)` sem colunas de valor, data ou comprovante) atende ao recorte de **RN20** e `RO12`, mas traz quatro limitações conhecidas: (1) Sem rateio de valor entre formas à vista combinadas: se uma venda usa duas modalidades monetárias diretas (como `PIX` + `CARTAO` ou `PIX` + `DINHEIRO`), o banco grava o total em `venda.valor_recebido`, mas não informa quanto entrou em cada meio (só é possível deduzir o valor quando há apenas uma forma à vista somada a `FINANCIAMENTO` e/ou `TROCA`, registrados em `venda.valor_financiado` e `entrada.valor_acordado`); (2) Sem histórico de recebimentos parciais: como `venda.valor_recebido` e `venda.data_ultimo_recebimento` são colunas escalares acumulativas na própria venda, receber um sinal seguido da quitação dias depois sobrescreve a data anterior pela última confirmação; (3) Sem conciliação bancária individual nem parcelas: não há código de transação (E2E do Pix, NSU de cartão, comprovante), conta destino da loja nem vencimentos de parcelas; e (4) Sem estorno discriminado por modalidade no cancelamento: quando a venda é desfeita (`situacao_comercial = 'CANCELADA'`), o total devolvido vai para `venda.valor_restituido_loja`, sem separar quanto foi estornado em cada meio de pagamento.

### 2.3. Como um Módulo Financeiro Completo Modelaria Recebimentos Individuais
Se a restrição de **RN19**/`RO12` fosse retirada para criar um módulo de Contas a Receber, `venda_forma_pagamento` daria lugar a duas tabelas em 3FN:
1. `OBRIGACAO_RECEBER` (ou `PARCELA_VENDA`): ligada a `VENDA` (`1:N`), registrando cada parcela ou obrigação prevista no contrato (`id_obrigacao PK`, `id_venda FK`, `numero_parcela`, `codigo_forma_prevista FK`, `valor_nominal`, `data_vencimento`, `situacao_obrigacao`);
2. `RECEBIMENTO` (ou `LIQUIDACAO_FINANCEIRA`): ligada a `OBRIGACAO_RECEBER` (`0:N`), registrando cada entrada de caixa (`id_recebimento PK`, `id_obrigacao FK`, `codigo_forma_efetiva FK`, `data_hora_recebimento`, `valor_pago`, `juros_multa`, `desconto_liquidacao`, `codigo_comprovante_nsu`, `conta_bancaria_loja`). Assim, `venda.valor_recebido` e `venda.data_ultimo_recebimento` seriam calculados por agregação (`SUM(valor_pago)` e `MAX(data_hora_recebimento)`).

---

## 3. Ponto (c): Como Obrigações Financeiras Ainda Não Quitadas são Representadas

Mesmo sem tabelas de boletos ou parcelas (`RN19` e `RN21`), as obrigações financeiras pendentes da operação são calculadas e validadas no banco ([`sql/ddl/schema.sql`](../sql/ddl/schema.sql)) em quatro categorias:

### 3.1. Obrigação do Comprador perante a Loja (Saldo Devedor da Venda)
Toda **venda** tem um valor contratual (`venda.valor_total`, gerado por `valor_base - desconto + acrescimo + taxas`), amortizado por duas vias:
- Troca (não monetária): soma de `entrada.valor_acordado` dos veículos recebidos na venda (`id_venda_origem = venda.id_venda`) ativos/incorporados (`total_trocas`, mantendo também `total_trocas_historico` para vendas depois desfeitas);
- Monetária: montante já creditado à loja (`venda.valor_recebido`, que inicia em `0`).

As views `vw_venda_validacao` (`sql/ddl/schema.sql`, linhas 311–352) e `vw_venda_resumo` (linhas 354–365) calculam o valor em aberto na coluna `saldo` (e `saldo_historico`):
`saldo = venda.valor_total - venda.valor_recebido - total_trocas`

A coluna derivada `situacao_financeira` classifica o estado da obrigação:
- `'PENDENTE'`: `valor_recebido + total_trocas = 0` (todo o `valor_total` está em aberto);
- `'PARCIAL'`: `0 < valor_recebido + total_trocas < valor_total` (há pagamento parcial ou troca, mas resta `saldo > 0`);
- `'INTEGRAL'`: `valor_recebido + total_trocas >= valor_total` (`saldo <= 0`, obrigação quitada);
- `'EM_DESFAZIMENTO'`: exibido em `vw_venda_resumo` quando `situacao_comercial IN ('EM_DESFAZIMENTO', 'CANCELADA')`, para não tratar venda desfeita como dívida ativa do cliente.

Enquanto houver obrigação aberta (`saldo > 0`), o trigger `venda_bu` impede que a venda mude para `CONCLUIDA` (**RN22**) e bloqueia a entrega do veículo. A Consulta Gerencial #7 ([`sql/consultas/gerenciais.sql`](../sql/consultas/gerenciais.sql)) lista as vendas pendentes ou parciais ordenadas pelo maior `saldo`.

### 3.2. Obrigação da Instituição Financeira perante a Loja (Financiamento Aprovado a Receber)
Para evitar o problema `PROB06` (aprovação de crédito sem repasse bancário), a tabela `venda` separa a aprovação do pagamento à loja (**RN21** e `ck_venda_financiamento`):
- Quando o financiamento foi aprovado pelo banco, mas ainda não foi transferido à loja:
  - `situacao_financiamento = 'APROVADO_A_RECEBER'`;
  - `data_aprovacao_financiamento IS NOT NULL`;
  - `data_recebimento_financiamento IS NULL`;
  - O `valor_financiado` continua pendente fora de `valor_recebido`.
- Exemplo na massa de dados (`sql/dados/massa-dados.sql`, Venda 6):
  - Tracker vendido por `valor_total = R$ 90.000,00`, com sinal via Pix de `valor_recebido = R$ 10.000,00` e financiamento no `'Banco Demonstracao'` de `valor_financiado = R$ 80.000,00` em `'APROVADO_A_RECEBER'`.
  - Em `vw_venda_resumo`: `saldo = R$ 80.000,00`, `situacao_financeira = 'PARCIAL'`, `financiamento_ok = false` e `requisitos_rn22_ok = false`. Tentar concluir a Venda 6 antes do repasse bancário é barrado com erro `RN22` (testado na suíte de regressão de [`sql/dados/massa-dados.sql`](../sql/dados/massa-dados.sql)).

### 3.3. Obrigação da Loja perante o Proprietário Consignante (Repasse de Consignação)
Nas entradas com `modalidade = 'CONSIGNACAO'`, o veículo pertence ao consignante (`entrada.id_contraparte`) até a conclusão da venda (**RN11**). A obrigação da loja perante o proprietário fica na tabela `entrada` em três colunas anuláveis na definição física (pois `entrada` reúne três modalidades), mas obrigatórias (`IS NOT NULL`) quando `modalidade = 'CONSIGNACAO'` (e `NULL` nas demais) via `ck_entrada_consignacao`:
- `valor_repasse_acordado DECIMAL(14,2)` — obrigatório na consignação (`ck_entrada_consignacao`) e limitado por `ck_entrada_valores` (`0 <= valor_repasse_acordado <= valor_acordado`);
- `prazo_repasse text` — obrigatório na consignação (ex.: `'Apos confirmacao da venda'`);
- `criterio_repasse text` — obrigatório na consignação (ex.: `'Valor fixo acordado com o consignante'`).

Na Venda 3 da massa de dados, o Honda City (`id_veiculo = 3`, `id_entrada = 3`) é vendido por `valor_total = R$ 80.000,00`, com repasse ao consignante de `valor_repasse_acordado = R$ 74.000,00` (diferença bruta de R$ 6.000,00) e despesa técnica de R$ 150,00 (`id_despesa = 2`, `'Inspecao de suspensao'`). A Consulta Gerencial #8 ([`sql/consultas/gerenciais.sql`](../sql/consultas/gerenciais.sql)) mostra a obrigação ao proprietário (R$ 74.000,00) e a margem líquida da loja:
`Margem Líquida do Honda City = R$ 80.000,00 - R$ 74.000,00 - R$ 150,00 = R$ 5.850,00`

### 3.4. Obrigações de Restituição em Distratos e Registro de Despesas
1. Restituições no desfazimento de venda (**RN28**–`RN31`):
   - Enquanto a venda está em `'EM_DESFAZIMENTO'`, há pendências de devolução entre loja, comprador, consignante e banco.
   - O banco (`ck_venda_cancelamento` e `venda_bu`) bloqueia a passagem para `'CANCELADA'` até registrar: devolução do veículo vendido (`data_retorno_veiculo`), valor restituído pela loja (`valor_restituido_loja`), devolução dos carros da troca (`entrada.situacao = 'DEVOLVIDA'` e `entrada.data_devolucao IS NOT NULL`), orientação bancária (`orientacao_bancaria`).
2. Despesas de preparação, diagnóstico e garantia (`despesa`):
   - Conforme a Seção 15 do `README.md` (`E10`), `despesa.data` guarda a data do fato gerador do custo no veículo, sem controle de faturas de fornecedores em aberto, seguindo o recorte da Seção 1.

---

## 4. Resumo do Tratamento Financeiro no Modelo

| Dimensão Financeira | Onde é Representada (`schema.sql`) | Como a Pendência / Obrigação é Identificada | Regra / Constraint |
|---|---|---|---|
| Despesas por veículo | Tabela `despesa` (`id_veiculo NOT NULL`) | Soma de custos por veículo (`SUM(despesa.valor)`) | `fk_despesa_id_veiculo` (`NOT NULL`), `ck_despesa_categoria` (`'GARANTIA'`, `'DIAGNOSTICO'`, `'PREPARACAO'`), `ck_despesa_valor` (`valor >= 0`), **RN32** |
| Despesas administrativas gerais | Núcleo: fora de `despesa` (decisão justificada). Extensão: obrigações a pagar em `obrigacao_financeira` com origem `ADMINISTRATIVA` | Entram na previsão de caixa enquanto não quitadas; não entram na margem por veículo | Processo `P08`, Briefing (p. 7, item 13; p. 8), `ck_obrigacao_origem` e `ck_obrigacao_arco` (seção 1.3) |
| Formas de pagamento da venda | Tabelas `forma_pagamento` e `venda_forma_pagamento` | Lista de códigos por venda (`PIX`, `FINANCIAMENTO`, `TROCA`, etc.) | PK composta `(id_venda, codigo_forma)` (1FN) + `vw_venda_validacao.formas_ok` e trigger na conclusão (**RN19**–`RN20`) |
| Saldo a receber do comprador | `venda` + `vw_venda_validacao` / `vw_venda_resumo` | `saldo = valor_total - valor_recebido - total_trocas > 0` (`situacao_financeira` = `'PENDENTE'` ou `'PARCIAL'`), preservando `saldo_historico` | `ck_venda_valores`, `ck_venda_recebimento` e trigger `venda_bu` (**RN22**) |
| Repasse bancário de financiamento | Colunas de financiamento em `venda` | `situacao_financiamento = 'APROVADO_A_RECEBER'` e `data_recebimento_financiamento IS NULL` | `ck_venda_financiamento` e `vw_venda_validacao.financiamento_ok` (**RN21**, `RN22`) |
| Repasse ao consignante | Colunas de consignação em `entrada` | `modalidade = 'CONSIGNACAO'` com `valor_repasse_acordado` e `prazo_repasse` | `ck_entrada_consignacao` e `ck_entrada_valores` (`valor_repasse_acordado <= valor_acordado`, **RN11**–`RN12`) |
| Restituições em venda desfeita | Colunas de cancelamento em `venda` e `entrada` | Venda em `'EM_DESFAZIMENTO'` até cumprir retorno, `valor_restituido_loja` e devolução das trocas | `ck_venda_cancelamento`, `ck_entrada_devolucao` e trigger `venda_bu` (**RN28**–`RN31`) |


## Pendência de implementação da RN30

Na consignação, avisar o proprietário continua sendo regra do negócio. O campo `venda.data_aviso_consignante` permite registrar esse marco, mas o gatilho `venda_bu` atual não exige seu preenchimento para finalizar o cancelamento. Portanto, não se considera essa exigência integralmente protegida pelo banco. A correção do SQL e o teste negativo de cancelamento sem aviso permanecem pendentes; esta revisão altera somente a documentação. Consulte também os limites da validação no README §31.
