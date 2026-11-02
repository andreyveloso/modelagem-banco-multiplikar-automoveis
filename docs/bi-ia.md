# Potencial de BI e IA — ERP Multiplikar Automóveis

Este documento apresenta aplicações de Business Intelligence (BI), indicadores de desempenho (KPIs) e Inteligência Artificial (IA) sobre o esquema físico do núcleo ([`sql/ddl/schema.sql`](../sql/ddl/schema.sql) e [`sql/consultas/gerenciais.sql`](../sql/consultas/gerenciais.sql)) e sobre a extensão aditiva implementada em [`sql/extensao/`](../sql/extensao/) ([`docs/extensao-inovacao.md`](extensao-inovacao.md)). Também separa o que está modelado no banco, o que é atendido na extensão e o que permanece como lacuna fora do escopo.

---

## 1. Business Intelligence (BI)

### Exemplo 1: Dashboard de giro de estoque, custo por ciclo e rentabilidade por veículo

Problema:
O gestor não consegue acompanhar num único painel quais veículos estão parados há mais tempo no pátio, quanto cada unidade acumulou em despesas de preparação e garantia e qual a margem líquida por modalidade (`COMPRA_PROPRIA`, `CONSIGNACAO` ou `TROCA`). Sem o banco integrado, esse cálculo depende de planilhas paralelas (**PROB09** e `PROB11`).

Dados necessários (`sql/ddl/schema.sql`):
- `veiculo` (`id_veiculo`, `marca`, `modelo`, `ano_modelo`, `categoria_comercial`)
- `entrada` (`id_entrada`, `id_veiculo`, `modalidade`, `valor_acordado`, `valor_repasse_acordado`, `preco_anunciado`, `data_entrada`, `data_encerramento`, `situacao`)
- `despesa` (`id_despesa`, `id_veiculo`, `data`, `categoria` — `'PREPARACAO'`, `'DIAGNOSTICO'` ou `'GARANTIA'`, `valor`)
- `venda` (`id_venda`, `id_entrada_principal`, `valor_total`, `data_registro`, `data_conclusao`, `data_entrega`, `situacao_comercial`)
- Views `vw_veiculo_situacao` (`situacao_atual`) e `vw_venda_resumo` (`situacao_financeira`, `total_trocas`, `saldo`)

Análise:
- Dias em estoque (Aging): `(COALESCE(venda.data_conclusao`DATE(...)`, CURRENT_DATE) - entrada.data_entrada`DATE(...)`)` para veículos vendidos ou ativos no pátio (Consultas Gerenciais #4 e #12);
- Alocação de despesas ao ciclo: soma de `despesa.valor` no intervalo da entrada (`despesa.data BETWEEN entrada.data_entrada`DATE(...)` AND COALESCE(entrada.data_encerramento`DATE(...)`, CURRENT_DATE)`), separando preparação/diagnóstico de garantia (`categoria = 'GARANTIA'`), conforme a Consulta Gerencial #8;
- Margem operacional líquida por modalidade (Consulta Gerencial #8):
  - Compra própria ou troca: `venda.valor_total - entrada.valor_acordado - total_despesas_ciclo`;
  - Consignação: `venda.valor_total - entrada.valor_repasse_acordado - total_despesas_ciclo` (ex.: Honda City na Venda 3: R$ 80.000,00 - R$ 74.000,00 - R$ 150,00 = R$ 5.850,00);
  - Nota de escopo (lacuna): comissões de vendedores e impostos sobre a venda não são modelados no banco (**RO13** e `P08`). O indicador mede a margem operacional bruta após despesas do veículo, e não o lucro líquido contábil.

Benefício esperado (hipóteses a validar em produção):
- Identificar veículos acima do tempo de alerta no pátio (ex.: > 30 ou 60 dias) para ajuste de `preco_anunciado` ou renegociação com o consignante;
- Medir quais modelos consomem mais oficina (`PREPARACAO` e `GARANTIA`) antes de novas compras;
- Hipótese de meta: redução estimada de 15% a 25% no tempo médio de pátio após série histórica.

---

### Exemplo 2: Desempenho de vendedores, gargalos de formalização e funil de conversão

Problema:
Falta visibilidade sobre o volume vendido por vendedor, a conversão de atendimentos em vendas e a etapa em que as vendas em formalização ficam retidas — pagamento, repasse bancário, documentos, firma ou scanner (**PROB06** e `PROB07`).

Dados necessários (`sql/ddl/schema.sql`):
- `atendimento` (`id_atendimento`, `id_pessoa`, `id_funcionario`, `data`, `tipo_interesse`, `situacao`)
- `venda` (`id_venda`, `id_comprador`, `id_funcionario`, `valor_total`, `data_registro`, `data_conclusao`, `data_scanner`, `data_entrega`, `situacao_comercial`, `instituicao_financeira`, `situacao_financiamento`, `valor_financiado`)
- `venda_documento` (`id_venda`, `tipo_documento`, `data_conferencia`, `reconhecimento_aplicavel`, `data_reconhecimento`)
- Views `vw_venda_validacao` (`financiamento_ok`, `documentos_ok`, `reconhecimento_ok`, `laudo_ok`, `formas_ok`, `contrato_ok`) e `vw_venda_resumo` (`situacao_financeira`, `situacao_documental`, `requisitos_rn22_ok`)

Análise:
- Taxa de conversão aproximada por vendedor (Consulta Gerencial #9): `COUNT(DISTINCT venda.id_venda) / COUNT(DISTINCT atendimento.id_atendimento)` cruzando `atendimento.id_pessoa = venda.id_comprador` para vendas concluídas com `venda.data_registro >= atendimento.data`. No núcleo sem extensão não há FK `atendimento -> venda`, portanto o funil é aproximado por cliente e data (na extensão, `venda.id_proposta` fecha o vínculo exato);
- Gargalos de conclusão e entrega (Consulta Gerencial #11): leitura das flags de `vw_venda_validacao` nas vendas `'EM_FORMALIZACAO'` (**RN22**), separando pendências de saldo/banco (`NOT financiamento_ok`), documentos/cartório (`NOT documentos_ok OR NOT reconhecimento_ok`) ou scanner pré-entrega (`requisitos_rn22_ok = true AND data_scanner IS NULL`).

Benefício esperado (hipóteses a validar):
- Destravar diariamente as pendências que impedem concluir vendas e entregar veículos;
- Apoiar a distribuição de atendimentos entre os 6 funcionários.

---

### Exemplo 3: Comparador de propostas e previsão semanal de caixa por cenários (BI implementado na extensão)

Problema:
Na negociação de um veículo, propostas alternativas (`rotulo = 'A'`, `'B'`, `'C'`) com o mesmo preço final (`valor_total`) e a mesma margem contábil produzem efeitos de caixa opostos (`D+0` vs. `D+x` vs. entrada de veículo na troca). Além disso, atrasos no repasse de financiamentos bancários ou frustração de leads quentes podem deixar o caixa da loja negativo mesmo com vendas lucrativas contratadas.

Dados necessários (`sql/extensao/01-ddl-propostas-caixa.sql`, `03-ddl-crm.sql` e `05-consultas-demo.sql`):
- `proposta` (`id_proposta`, `id_atendimento`, `id_entrada`, `rotulo`, `versao`, `valor_total`, `situacao`, `validade`)
- `proposta_condicao` (`codigo_forma`, `valor`, `prazo_previsto_dias`) e `proposta_troca` (`id_avaliacao`, `valor_oferecido`)
- `parametro_retorno` (`instituicao`, `tabela_retorno`, `acrescimo_taxa_mensal`, `retorno_pct`, `origem`, `vigencia`) e `simulacao_financiamento` (`instituicao`, `valor_financiado`, `taxa_mensal`, `prazo_meses`, `tabela_retorno`, `renda_declarada`, `consentimento_renda`)
- `obrigacao_financeira` (`natureza`, `origem`, `categoria`, `valor`, `vencimento_original`, `vencimento_atual`, `situacao`) e `parametro_prazo` (`banco`, `tipo_obrigacao`, `dias_previstos`)
- `classificacao_lead`, `parametro_temperatura` e `parametro_referencia` (`data_referencia()`)
- Views e função implementadas: `vw_simulacao_parcela`, `vw_proposta_comparativo`, `vw_fila_acoes`, `vw_caixa_realizado_referencia`, `fn_previsao_caixa_cenario` e `vw_previsao_caixa`

Análise (implementada e executada em [`sql/extensao/05-consultas-demo.sql`](../sql/extensao/05-consultas-demo.sql)):
- Comparação simultânea em 3 ângulos (`vw_proposta_comparativo` e `vw_simulacao_parcela`): separa para cada alternativa do mesmo atendimento/entrada o desembolso, a prestação e o CET do cliente (`parcela_simulada`, `cet_aproximado_anual`, `parcela_sobre_renda_pct`), a rentabilidade da loja (`margem_estimada`, `retorno_banco` e `margem_com_retorno`) e o desdobramento de liquidez (`caixa_d0`, `caixa_posterior`, `valor_em_troca` e `prazo_caixa`). Na demonstração do Kwid consignado (`id_entrada = 10`, repasse de R$ 50.000,00), comprova que as alternativas A, B e C empatam na margem do veículo (**R$ 5.000,00**), que a simulação de financiamento em `R4` acrescenta **R$ 1.760,00** de `retorno_banco` (`margem_com_retorno = R$ 6.760,00`) ao custo de elevar a parcela do cliente de R$ 1.402,56 (`R0`, CET 25,19% a.a.) para R$ 1.490,50 (`R4`, CET 29,69% a.a.), e que a alternativa C (R$ 25.000,00 em Pix + Gol de R$ 30.000,00 na troca) consome **R$ 25.000,00** líquidos de caixa;
- Projeção semanal de caixa em 4 camadas (`fn_previsao_caixa_cenario` e `vw_previsao_caixa`): combina `saldo_inicial` (`HIPOTESE`), `realizado` na semana de referência (`vw_caixa_realizado_referencia`), `obrigacoes` líquidas (`obrigacao_financeira` + repasses sintéticos de consignação) e `funil_ponderado` (dividindo a probabilidade da temperatura do lead por `N` alternativas abertas e válidas da mesma entrada, somando o `retorno_loja` do banco e descontando o repasse ponderado ao consignante);
- Teste de estresse por cenários: compara `'BASE'` (sem falta de caixa; saldo de R$ 29.050,00 em `2026-02-09`, R$ 38.964,67 em `2026-02-23` e R$ 28.131,34 em `2026-03-02`), `'BANCO_ATRA_15_DIAS'` (desloca recebíveis de financiamento em +15 dias e aponta ruptura de caixa já na semana de `2026-02-09` com **`-R$ 50.950,00`**) e `'LEADS_QUENTES_NAO_FECHAM'` (zera o funil de leads quentes, estabilizando o saldo em R$ 31.000,00).

Benefício demonstrado:
- Evitar aceitar proposta com troca em veículo consignado sem reserva de caixa para pagar o consignante em dinheiro;
- Acionar cobrança bancária ou linha de giro antes da semana em que o atraso do banco deixa o saldo negativo, guiado pela fila priorizada por valor em risco (`vw_fila_acoes`).

---

## 2. Matriz de indicadores de desempenho (KPIs)

A tabela liga cada indicador à sua fórmula sobre `sql/ddl/schema.sql` (KPIs 1 a 14, em [`sql/consultas/gerenciais.sql`](../sql/consultas/gerenciais.sql)) e sobre a extensão `sql/extensao/` (KPIs 15 a 18, em [`sql/extensao/05-consultas-demo.sql`](../sql/extensao/05-consultas-demo.sql)):

| KPI / Indicador | Fórmula / Regra de Cálculo no Banco (`schema.sql` e `sql/extensao/`) | Consulta / View | Decisão Apoiada |
|---|---|---|---|
| 1. Giro e Volume por Marca/Modelo | `COUNT(venda.id_venda)`, `SUM(venda.valor_total)` e `AVG(venda.valor_total)` em vendas `CONCLUIDA` (`data_conclusao`), por `veiculo.marca, veiculo.modelo`. | Consulta #1 (`Veículos mais vendidos por período`) | Priorizar marcas e modelos na reposição do estoque. |
| 2. LTV / Recorrência de Clientes | `COUNT(venda.id_venda)` e `SUM(venda.valor_total)` por `venda.id_comprador` (`CONCLUIDA`), classificando em `VIP` (>= 3), `RECORRENTE` (2) ou `OCASIONAL` (1), com máscara LGPD. | Consulta #2 (`Clientes que mais compram`) | Retenção e oferta ativa na entrada de seminovos. |
| 3. Faturamento Mensal e Ticket Médio | `SUM(venda.valor_total)`, `SUM(venda.valor_recebido)`, `SUM(valor_financiado)` e `AVG(venda.valor_total)` por `YEAR(data_conclusao), MONTH(data_conclusao)`. | Consulta #3 (`Volume de vendas concluídas por período`) | Planejamento de caixa, metas mensais e sazonalidade. |
| 4. Aging de Estoque (Dias em Pátio) | `DATEDIFF(CURRENT_DATE, DATE(entrada.data_entrada))` para entradas `situacao = 'ATIVA'` sem venda (`venda.id_venda IS NULL`). | Consulta #4 (`Veículos parados há mais tempo no estoque`) | Revisão de preço ou devolução de consignados sem giro. |
| 5. Vencimento de Consignações | `(entrada.prazo_consignacao - CURRENT_DATE)` para entradas `'CONSIGNACAO'` `'ATIVA'` com `prazo_consignacao <= CURRENT_DATE + 30 days`. | Consulta #5 (`Veículos em consignação próximos ao vencimento`) | Renegociar prazo/preço com o consignante ou preparar retirada. |
| 6. Absorção de Trocas | `COUNT(e_troca.id_entrada)` e `SUM(e_troca.valor_acordado)` por `venda.id_venda` onde `e_troca.id_venda_origem = venda.id_venda`. | Consulta #6 (`Vendas com troca`) | Medir o peso das trocas na liquidez de cada venda. |
| 7. Saldo Financeiro a Receber | `vw_venda_resumo.saldo` (`valor_total - valor_recebido - total_trocas`) para `situacao_financeira IN ('PENDENTE','PARCIAL')`. | Consulta #7 (`Posição financeira das vendas`) | Cobrar repasses bancários (`APROVADO_A_RECEBER`) e saldos de clientes. |
| 8. Margem Operacional por Veículo | Compra/Troca: `valor_total - valor_acordado - total_despesas_ciclo`; Consignação: `valor_total - valor_repasse_acordado - total_despesas_ciclo` (separando `PREPARACAO` e `GARANTIA`). | Consulta #8 (`Margem por veículo e modalidade`) | Definir preço mínimo e apurar rentabilidade por unidade. |
| 9. Conversão Comercial (Aproximada) | `ROUND(CAST(COUNT(DISTINCT id_venda) AS DECIMAL) / COUNT(DISTINCT id_atendimento) * 100, 2)` por `funcionario.id_funcionario` (`id_pessoa = id_comprador` e `data_registro >= atendimento.data`). | Consulta #9 (`Funil de vendas: atendimentos convertidos`) | Avaliar conversão de leads por vendedor. |
| 10. Incidência de Garantia por Modelo | `COUNT(ocorrencia_garantia.id_ocorrencia)` e `COUNT(DISTINCT venda.id_venda)` por veículo/modelo, com problemas e soluções. | Consulta #10 (`Ocorrências de garantia por veículo`) | Ajustar critérios de vistoria de entrada (`AVALIACAO`). |
| 11. Prontidão de Conclusão (**RN22**) e Entrega (`RN23`) | `vw_venda_resumo.requisitos_rn22_ok` e `(requisitos_rn22_ok AND venda.data_scanner IS NOT NULL)` para vendas `'EM_FORMALIZACAO'`. | Consulta #11 (`Vendas aptas para conclusão e entrega`) | Destravar cartório, laudo, banco e scanner para entrega. |
| 12. Capital Imobilizado por Modalidade | `COUNT(*)`, `SUM(entrada.valor_acordado)` e `AVG(CURRENT_DATE - data_entrada`DATE(...)`)` por `entrada.modalidade` e `vw_veiculo_situacao.situacao_atual` (`<> 'VENDIDO'`). | Consulta #12 (`Resumo gerencial: estoque atual`) | Balancear estoque próprio e consignado. |
| 13. Histórico de Reavaliações Técnicas | Evolução de `avaliacao.quilometragem`, `condicao_externa/interna/mecanica/estrutural/documental`, `decisao_tecnica` e `laudo.resultado` por `id_veiculo`. | Consulta #13 (`Histórico de reavaliações do veículo`) | Auditar veículos reintegrados pós-distrato antes de revender. |
| 14. Taxa e Custo de Distratos | Vendas `'CANCELADA'` com `valor_restituido_loja`, `data_retorno_veiculo`, `data_aviso_consignante`, `orientacao_bancaria` e trocas devolvidas. | Consulta #14 (`Vendas canceladas com detalhes de restituição`) | Auditar devoluções e reduzir causas de cancelamento. |
| 15. Comparativo de Liquidez, Margem e Retorno por Proposta (Extensão) | `caixa_d0` (`SUM(valor)` em `PIX`/`DINHEIRO` com `prazo_previsto_dias = 0`), `caixa_posterior` (`prazo_previsto_dias > 0` + `retorno_loja`), `valor_em_troca` (`SUM(valor_oferecido)`), `margem_estimada` (`valor_total - custo/repasse - despesas`), `retorno_banco` e `margem_com_retorno` (`margem_estimada + retorno_banco`). | View `vw_proposta_comparativo` (`01-ddl` / Demo #2 em `05-consultas-demo.sql`) | Escolher a alternativa comercial (`A`/`B`/`C`) que preserva a margem sem descapitalizar o caixa. |
| 16. Comprometimento de Renda, CET e Retorno na Simulação Price (Extensão) | `taxa_cliente_mensal = taxa_mensal + acrescimo_taxa_mensal`, `parcela_calculada = ROUND(valor_financiado * taxa_cliente_mensal / (1 - (1 + taxa_cliente_mensal)^(-prazo_meses)), 2)`, `cet_aproximado_anual = (1 + taxa_cliente_mensal)^12 - 1`, `retorno_loja = ROUND(valor_financiado * retorno_pct, 2)` e `parcela_sobre_renda_pct = ROUND(parcela_calculada / renda_declarada * 100, 2)` (com `consentimento_renda = true`). | View `vw_simulacao_parcela` (`01-ddl` / Demo #3 e #4 em `05-consultas-demo.sql`) | Avaliar viabilidade de crédito e o trade-off entre prestação/CET do cliente e retorno financeiro da loja (`R0` a `R5`). |
| 17. Saldo Semanal de Caixa Projetado por Cenário (Extensão) | `saldo_inicial + SUM(realizado + obrigacoes + funil_ponderado) OVER (ORDER BY semana)`, ponderando cada proposta aberta válida por `P(temperatura) / N_alternativas` menos repasse ponderado ao consignante. | Views `vw_caixa_realizado_referencia`, `vw_previsao_caixa` e `fn_previsao_caixa_cenario` (`05-consultas-demo.sql`) | Identificar em qual semana falta caixa no cenário base, com atraso bancário (+15d) ou sem fechamento de leads quentes. |
| 18. Valor Financeiro em Risco na Fila de Ações (Extensão) | União ordenada (`ORDER BY valor_em_risco DESC`) de recebíveis vencidos (`obrigacao_financeira.valor`), leads sem retorno (`COALESCE(maior proposta aberta válida, preco_anunciado)`) e estoque parado >= 30d (`valor_acordado + despesas`). | View `vw_fila_acoes` (`03-ddl-crm.sql` / Demo #5 em `05-consultas-demo.sql`) | Priorizar diariamente qual cobrança bancária, lead comercial ou veículo em estoque atacar primeiro. |

---

## 3. Inteligência Artificial (IA)

### Exemplo 1: Regressão para precificação de entrada e tempo de giro

Problema:
Na avaliação de um usado, o `valor_acordado` (ou `valor_repasse_acordado`) e o `preco_anunciado` costumam seguir apenas tabela de mercado e experiência do avaliador, sem cruzar quanto a loja gasta em preparação naquele modelo nem quantos dias ele leva para girar.

Dados para treinamento:
- Features: `veiculo.marca`, `veiculo.modelo`, `veiculo.ano_modelo`, `veiculo.combustivel`, `veiculo.cambio`, `veiculo.categoria_comercial`, `avaliacao.quilometragem`, `avaliacao.quantidade_proprietarios`, `avaliacao.condicao_externa`, `avaliacao.condicao_interna`, `avaliacao.condicao_mecanica`, `avaliacao.condicao_estrutural`, `avaliacao.condicao_documental` e `entrada.modalidade`;
- Targets: `venda.valor_total` nas vendas `'CONCLUIDA'`, giro `(venda.data_conclusao`DATE(...)` - entrada.data_entrada`DATE(...)`)` e `SUM(despesa.valor)` do ciclo.

Análise (regressão supervisionada / Gradient Boosting):
- Com histórico acumulado, um modelo (ex.: LightGBM/XGBoost) estima para cada nova **avaliação**: (1) faixa esperada de preço de venda, (2) despesa média de `PREPARACAO` e `GARANTIA` e (3) dias estimados em pátio.

Benefício esperado (hipótese a validar):
- Apoiar a definição de `interesse_comercial` e do teto de proposta em `TROCA` e `COMPRA_PROPRIA`.

---

### Exemplo 2: Classificação de risco de pós-venda (garantia ou distrato)

Problema:
Chamados em **ocorrencia_garantia**, gastos de reparo (`despesa` com `categoria = 'GARANTIA'`) e vendas `'CANCELADA'` geram custo financeiro e retrabalho (devolução de trocas, restituição em dinheiro e reavaliação para novo ciclo `RN13`).

Dados para treinamento:
- Target binário: abertura de `ocorrencia_garantia` com `responsabilidade_apurada = 'LOJA'`, despesa `categoria = 'GARANTIA'` ou venda `'CANCELADA'`;
- Features pré-entrega: idade (`EXTRACT(YEAR FROM venda.data_registro) - veiculo.ano_modelo`), `avaliacao.quilometragem`, `avaliacao.condicao_mecanica`, `condicao_estrutural`, `laudo.resultado`, `venda.resultado_scanner`, `providencias_scanner`, `entrada.modalidade`, financiamento (`venda.instituicao_financeira IS NOT NULL`) e número de trocas.

Análise (classificação supervisionada):
- Classificar cada venda em formalização em risco Baixo, Médio ou Alto antes de `venda.data_entrega`.

Benefício esperado (hipótese a validar):
- Reforçar a revisão pré-entrega (`venda.preparacao` e `venda.providencias_scanner`) nos carros de alto risco;
- Hipótese de meta: reduzir em 20% a 30% o retrabalho de garantia nos 2 meses pós-entrega (**RN25**).

---

### Exemplo 3: Classificação de conversão de leads treinada com dados rotulados pela revisão humana do CRM

Problema:
No módulo de CRM da extensão ([`sql/extensao/03-ddl-crm.sql`](../sql/extensao/03-ddl-crm.sql)), a função `registrar_classificacao_lead` opera inicialmente com uma regra determinística (`versao_regra = 'REGRA-V1'`) cujos pesos e probabilidades em `parametro_temperatura` são hipóteses acadêmicas (`origem = 'HIPOTESE'`). Regras fixas não capturam o efeito combinado de sinais fortes de fechamento — como ter veículo de troca já aprovado e três propostas formalizadas (caso do atendimento 7, sugerido como `'MORNO'` com 65 pontos pela regra e elevado para `'QUENTE'` na revisão humana).

Dados para treinamento (estruturados e rotulados pela extensão):
- Features por atendimento: `atendimento.tipo_interesse`, `atendimento.situacao`, pontos e evidências estruturadas em `classificacao_fator` (`URGENCIA_CONTATO`, `ESTAGIO_NEGOCIACAO`, `INTERESSE_FINANCEIRO`, `VOLUME_INTERACOES`), quantidade e direção de contatos em `interacao` (`canal`, `direcao`, `dias_sem_contato`), existência de propostas em `proposta`, proporção de caixa imediato (`caixa_d0 / valor_total`), presença de troca aprovada (`proposta_troca`) e comprometimento de renda na simulação (`vw_simulacao_parcela.parcela_sobre_renda_pct`);
- Rótulos supervisionados (targets): (1) o rótulo humano imediato em `classificacao_lead.temperatura_final`, acompanhado de `id_revisor` e `justificativa_revisao` obrigatória quando o funcionário corrige `temperatura_sugerida` (**RN41**), e (2) o desfecho real da negociação registrado em `atendimento_desfecho.tipo_desfecho` (`'GANHO'` ou `'PERDA'` e `motivo`, **RN40**) e em `venda.id_proposta` (**RN37**).

Análise (classificação supervisionada e calibração de probabilidades):
- À medida que a loja acumula atendimentos encerrados e revisões humanas, treina-se um modelo supervisionado interpretável (como regressão logística multinomial calibrada ou Gradient Boosting com decomposição de contribuições por fator) que grava sugestões em `classificacao_lead` com `origem = 'IA'` e seus fatores em `classificacao_fator`, além de atualizar `parametro_temperatura` de `origem = 'HIPOTESE'` para `'CALIBRADA'`, mantendo a trava de revisão humana (`id_revisor`) exigida pela **RN41** e pela `RO11`.

Benefício esperado (hipótese a validar):
- Calibrar a probabilidade de fechamento usada no `funil_ponderado` da previsão semanal de caixa (`vw_previsao_caixa`) com o histórico real de ganhos e perdas da loja;
- Reduzir falsos mornos/quentes na fila de próximas ações (`vw_fila_acoes`), priorizando o tempo dos vendedores nos leads com maior probabilidade real de conversão.

---

## 4. Requisitos de dados para BI e IA (cobertura e lacunas)

| Capacidade Analítica | Representação em `sql/ddl/schema.sql` e `sql/extensao/` | Status | Observação Técnica |
|---|---|---|---|
| Histórico temporal de entradas, vendas e entregas | `entrada.data_entrada`, `entrada.data_encerramento`, `venda.data_registro`, `venda.data_conclusao`, `venda.data_entrega`, `despesa.data` | Modelado (Núcleo) | Calcula tempo de pátio, sazonalidade e vigência de garantia. |
| Múltiplos ciclos e trocas do mesmo veículo | `entrada.id_venda_origem` (troca), `entrada.id_entrada_anterior` (pós-distrato) e `venda.id_entrada_principal` (`UNIQUE`) | Modelado (**RN13**) | Preserva todos os ciclos sem sobrescrever vendas canceladas. |
| Marcos documentais, financeiros e técnicos (`RN22` / `RN23`) | `venda_documento`, `venda.data_scanner`, `vw_venda_validacao` e `vw_venda_resumo` (`requisitos_rn22_ok`, `situacao_financeira`, `situacao_documental`) | Modelado (Núcleo) | `situacao_financeira` e `situacao_documental` são colunas das views, não de `venda`. |
| Cancelamentos e restituições | `venda.situacao_comercial`, `data_cancelamento`, `motivo_cancelamento`, `data_retorno_veiculo`, `valor_restituido_loja`, `data_aviso_consignante`, `orientacao_bancaria` | Modelado (Núcleo) | Complementado por `vw_venda_validacao.saldo_historico` e `total_trocas_historico`. |
| Avaliação técnica em 5 dimensões | `avaliacao.condicao_externa`, `condicao_interna`, `condicao_mecanica`, `condicao_estrutural`, `condicao_documental`, `decisao_tecnica`, `interesse_comercial` | Modelado (Núcleo) | Atributo composto `condicoes` decomposto em 5 colunas atômicas (1FN). |
| Ocorrências e custos de garantia | Chamados em `ocorrencia_garantia` + vigência em `vw_venda_resumo` (`data_inicio_garantia`, `data_fim_garantia`); custo em `despesa` (`categoria = 'GARANTIA'`) | Modelado (Núcleo) | `ocorrencia_garantia` guarda o chamado técnico; o gasto financeiro fica em `despesa`. |
| Funil de conversão (`atendimento` -> `proposta` -> `venda`) e motivo de perda | No núcleo, sem FK `id_atendimento` em `venda`; na extensão (`sql/extensao/`), `proposta.id_atendimento`, `venda.id_proposta UNIQUE` (**RN37**) e `atendimento_desfecho` (**RN40**) | Atendido na extensão | A extensão fecha o vínculo exato `atendimento -> proposta -> venda` e registra `GANHO`/`PERDA` com motivo; vendas antigas sem proposta mantêm o pareamento por comprador e data. |
| CRM explicável e geração de dados rotulados para IA | `interacao`, `classificacao_lead` (`temperatura_sugerida`, `temperatura_final`, `id_revisor`, `justificativa_revisao`), `classificacao_fator` e `parametro_temperatura` (`03-ddl-crm.sql`) | Modelado (Extensão — **RN41**) | Cada sugestão guarda evidência por fator e a revisão humana cria pares `(sugestão, rótulo humano, desfecho real)` prontos para aprendizado supervisionado. |
| Comparador de propostas, retorno bancário, vencimentos e previsão semanal de caixa | `proposta_condicao`, `proposta_troca`, `parametro_retorno`, `simulacao_financiamento`, `obrigacao_financeira`, `parametro_prazo`, `vw_simulacao_parcela`, `vw_proposta_comparativo` e `vw_previsao_caixa` (`01-ddl` e `05-consultas-demo.sql`) | Modelado (Extensão — **RN34–RN39, RN42–RN43**) | Separa margem de caixa (`D+0` vs. `D+x`), calcula CET e retorno do banco (`R0`–`R5`), agenda obrigações (inclusive administrativas) e projeta saldo semanal por cenários. |
| Alocação de despesa ao ciclo de entrada | `despesa` tem FK para `veiculo(id_veiculo)`, mas não tem FK para `entrada(id_entrada)` nem `ocorrencia_garantia(id_ocorrencia)` | Parcial (Alocação temporal) | Se o veículo tiver mais de um ciclo, a Consulta #8 e `vw_proposta_comparativo` filtram `despesa.data` dentro do intervalo do ciclo. |
| Recebimentos/baixas bancárias individuais (`movimento_caixa`) e valor por forma na venda | Na proposta (`proposta_condicao`) há valor e prazo por forma; em `venda`, `venda_forma_pagamento` guarda só os códigos (`PIX`, `FINANCIAMENTO`, etc.) e `venda.valor_recebido` é acumulado | Parcial / Lacuna planejada | Preserva `RN19`–`RN22` e `RO12` em `venda`. O livro-razão de baixas parciais e saídas históricas (`movimento_caixa`) ficou adiado, razão pela qual o saldo inicial da previsão é `HIPOTESE`. |
| Comissões de vendedores e impostos sobre a venda | Despesas administrativas gerais entram em `obrigacao_financeira` (`origem = 'ADMINISTRATIVA'`), mas não há colunas de comissão de vendedor nem tributos por nota fiscal | Lacuna (Fora do escopo) | Excluídos pelo escopo do projeto (`RO13`, `P08`, **RN32**); a margem calculada é operacional bruta por veículo. |
