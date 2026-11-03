# Inovação e Valor Agregado frente ao Sistema RevendaMais — ERP Multiplikar Automóveis

Este documento atende ao ponto de inovação e valor agregado da devolutiva da 1ª entrega. Com base no [Briefing Inicial Completo](fontes/briefing-completo.pdf) (p. 7, item 12) e em [`sql/ddl/schema.sql`](../sql/ddl/schema.sql), mostra quais problemas da Multiplikar Automóveis continuam sem solução no sistema atual (RevendaMais) e como o banco de dados proposto os resolve na prática.

---

## Limites da implementação atual

As melhorias abaixo descrevem o modelo e os cenários demonstrados. A proteção integral ainda depende das pendências registradas no README §31: alteração de avaliação vinculada a laudo, alterações de laudos usados em vendas, aviso ao consignante no cancelamento, transferência de linhas entre propostas e inserção direta de ciclo sucessor. O aviso ao consignante é exigência da RN30 e possui campo próprio, mas não é obrigatório no gatilho atual de cancelamento. A regularização de sucessora é verificada no UPDATE; o INSERT ainda precisa de validação equivalente. Não se afirma que os testes existentes cubram esses caminhos.

## 1. Contexto Operacional: O Uso Atual do RevendaMais na Multiplikar

Segundo o levantamento feito na loja ([`docs/fontes/briefing-completo.pdf`](fontes/briefing-completo.pdf), p. 7, item 12, e Seções 2.1, 2.4 e 17.14 do `README.md`), a Multiplikar tem 6 funcionários e usa o software RevendaMais para rotinas básicas de balcão, como cadastro de veículos aceitos no estoque e emissão comercial simples.

Porém, o mapeamento de processos (`P01` a `P08`) e de problemas (`PROB01` a **PROB11**) mostrou que várias regras técnicas, contratuais e de pós-venda da loja não são controladas pelo sistema atual. A equipe acaba mantendo controles paralelos em planilhas e anotações manuais. Isso gera risco de liberar veículos sem quitação bancária ou sem scanner, perder histórico em devoluções e não saber a margem líquida quando entram vários carros na troca.

---

## 2. Oito Problemas sem Solução na Operação Atual e Como o ERP Proposto os Resolve

### 2.1. Múltiplos Veículos como Entrada (Troca) na Mesma Venda e Mesmo Contrato (PROB05 / RN16–RN18)
- Problema atual: em vendas de maior valor, a loja aceita dois ou mais carros usados do comprador como parte do pagamento de um único veículo vendido, todos no mesmo contrato (Briefing, p. 5 e p. 7, item 4). No fluxo atual, associar vários carros de entrada a uma venda com avaliações individuais e abatimento do saldo exige desmembrar a operação ou calcular o saldo em planilha.
- Solução no modelo proposto:
  - A tabela **entrada** tem a FK `id_venda_origem bigint REFERENCES venda (validação imediata por FK/trigger MySQL)` (`R14`), permitindo vincular 0, 1 ou N veículos de troca à mesma `venda` (`venda.id_entrada_principal`).
  - Cada veículo de troca exige vistoria própria em `avaliacao` (`entrada.id_avaliacao UNIQUE`) com `decisao_tecnica = 'APROVADA'` e `interesse_comercial = 'SIM'`. Os triggers MySQL conferem durante a gravação que todos os carros de troca pertencem ao comprador (`t.id_contraparte = v.id_comprador`, sem terceiros — **RN18**) e que nenhum deles é o próprio veículo vendido (`t.id_veiculo <> p.id_veiculo`).
  - A view `vw_venda_validacao` soma `COALESCE(SUM(x.valor_acordado), 0) AS total_trocas` e abate do saldo a pagar. Na Venda 2 de `sql/dados/massa-dados.sql`, um Toyota Corolla de R$ 100.000,00 é pago com um Fiat Uno de R$ 25.000,00, um Ford Ka de R$ 15.000,00 e R$ 60.000,00 em Pix.

### 2.2. Vínculo entre Prospecção, Avaliação em 5 Dimensões, Laudo Cautelar e Entrada no Estoque (PROB02 / RN04–RN08)
- Problema atual: o sistema atual registra o carro apenas quando ele já entrou no estoque. Veículos avaliados e recusados na prospecção não deixam histórico no banco. Também não há trava que impeça dar entrada num carro sem vistoria aprovada ou associar por engano o laudo cautelar de outro veículo.
- Solução no modelo proposto:
  - Separa o cadastro do automóvel (`veiculo`, que aceita `placa` e `chassi` nulos na prospecção — **RN04**) do evento de estoque (`entrada`), mantendo o histórico de veículos recusados (`RN05`).
  - A tabela **avaliação** exige cinco dimensões no fechamento (`condicao_externa`, `condicao_interna`, `condicao_mecanica`, `condicao_estrutural`, `condicao_documental` — `ck_avaliacao_concluida`).
  - A consulta opcional ao laudo fica em `avaliacao_laudo` (3FN). Os triggers MySQL de validação barra vínculos em que `avaliacao.id_veiculo <> laudo.id_veiculo` ou `laudo.data_emissao > avaliacao.data (**RN08**).
  - O banco impede criar uma `entrada` sem `avaliacao` prévia do mesmo veículo com `decisao_tecnica = 'APROVADA'` e `interesse_comercial = 'SIM'` (**RN06** e `RN07`).

### 2.3. Trava Simultânea de Conclusão (RN22) e Bloqueio de Entrega sem Repasse Bancário ou Scanner (PROB06, PROB07 / RN21–RN24)
- Problema atual: dois riscos ocorrem no controle manual (Briefing, p. 4, 6 e 7):
  1. Baixa prematura de financiamento (`PROB06`): o banco aprova o crédito do comprador, mas ainda não transferiu o dinheiro para a loja. Se a venda for dada como concluída só com a aprovação, o carro pode ser entregue antes do repasse cair na conta.
  2. Entrega sem documentação ou sem scanner (`PROB07` / **RN23**): concluir a venda sem conferir os 6 documentos exigidos (`CNH`, `LAUDO_CAUTELAR`, `CRLV`, `ATPV`, `COMPROVANTE_RESIDENCIA` e `CONTRATO`), sem firma reconhecida em `ATPV` e `CONTRATO`, ou entregar o carro sem passar o scanner automotivo.
- Solução no modelo proposto:
  - Na tabela **venda**, `ck_venda_financiamento` separa `'EM_ANALISE'`, `'NAO_APROVADO'`, `'APROVADO_A_RECEBER'` e `'RECEBIDO'`. Enquanto estiver em `'APROVADO_A_RECEBER'` (Venda 6 da massa), o valor financiado não entra em `valor_recebido` e `vw_venda_validacao.financiamento_ok` fica `false`.
  - Os triggers MySQL impedem durante a gravação que `venda.situacao_comercial` passe para `'CONCLUIDA'` se falhar qualquer condição da **RN22**: `saldo <= 0`, `financiamento_ok`, `documentos_ok` (6 documentos datados em `venda_documento`), `reconhecimento_ok` (firma em `ATPV` e `CONTRATO`) e `laudo_ok` (laudo cautelar do próprio veículo principal).
  - A constraint `ck_venda_entrega` bloqueia `data_entrega` se `data_conclusao`, `data_scanner` ou `resultado_scanner` forem nulos (ou se `data_scanner > data_entrega` — **RN23**), sem representar prova de cobertura de todos os caminhos de alteração.

### 2.4. Distrato Não Destrutivo com Devolução de Trocas, Regularização e Encadeamento (PROB08 / RN13, RN28–RN31)
- Problema atual: quando uma venda é desfeita após a entrega, sistemas comuns exigem excluir ou cancelar a venda e voltar o status do veículo manualmente para disponível, ou recadastrar o veículo. Isso apaga o histórico do contrato desfeito, perde o rastro dos carros devolvidos da troca e pode liberar o carro devolvido para nova venda antes de regularizar a documentação.
- Solução no modelo proposto:
  - Preservação histórica: os triggers `entrada_bd` e `venda_bd` bloqueiam `DELETE` em `entrada` e `venda`; os triggers `entrada_bu` e `venda_bu` protegem a identidade de ambas em qualquer `UPDATE` e impedem reabrir entrada encerrada ou editar venda cancelada.
  - Controle de restituições no distrato: para mudar uma venda para `'CANCELADA'`, o banco exige `data_retorno_veiculo`, `valor_restituido_loja`, `orientacao_bancaria` (se financiado — `RN31`) e exige que todas as entradas de troca passem para `situacao = 'DEVOLVIDA'` com `data_devolucao IS NOT NULL` (`RN29`).
  - Encadeamento de ciclos (`id_entrada_anterior`) e regularização: a entrada original é fechada (`situacao = 'ENCERRADA'`, `motivo_encerramento = 'DESFAZIMENTO'`) e abre-se uma entrada sucessora ligada por `id_entrada_anterior UNIQUE REFERENCES entrada`. Enquanto `data_regularizacao IS NULL`, o triggers MySQL de validação exige que a entrada sucessora permaneça em `'EM_REGULARIZACAO'` (`'AGUARDANDO_REGULARIZACAO'` em `vw_veiculo_situacao`), só liberando `'ATIVA'` após preencher `data_regularizacao` e `observacoes_regularizacao` (ciclo do Hyundai HB20 na massa: Veículo 4, Entrada 4 -> Venda 4 cancelada -> Entrada 9 -> Venda 5 concluída).
  - Bloqueio de duplicidade: a coluna gerada `veiculo_vigente` e o índice único `uq_entrada_veiculo_vigente` impedem que um veículo tenha dois ciclos abertos ao mesmo tempo (**RN13**).

### 2.5. Garantia de 2 Meses a partir da Entrega e Regra de Oficina Externa (PROB08 / RN25–RN27)
- Problema atual: a garantia da loja tem duas regras (Briefing, p. 4 e p. 7, item 9): o prazo de 2 meses conta da entrega física do carro (não da data do contrato) e o cliente perde a garantia se levar o veículo a mecânico externo sem autorização (**RN26**). Hoje isso é controlado fora do sistema.
- Solução no modelo proposto:
  - A view `vw_venda_resumo` calcula `data_inicio_garantia = data_entrega` e `data_fim_garantia = data_entrega + interval '2 months'`.
  - A tabela **ocorrencia_garantia** liga cada chamado à `venda` (herdando veículo e comprador), exige pelos triggers MySQL de validação que `venda.concessao_garantia = true` e `data_abertura >= venda.data_entrega`, registra o mecânico (`id_mecanico`), obriga `atendimento_externo_informado` (`NOT NULL`, em `'SIM'`, `'NAO'`, `'NAO_INFORMADO'`) e possui colunas anuláveis/condicionais para `diagnostico` e `responsabilidade_apurada` (`ck_ocorrencia_responsabilidade`: `'EM_ANALISE'`, `'LOJA'`, `'MAU_USO'`, `'INCONCLUSIVA'` — `RN27`), exigindo `solucao` no encerramento (`ck_ocorrencia_encerramento`). Chamados fora do prazo são verificados na Auditoria #7 (`sql/auditoria/auditoria.sql`).

### 2.6. Cadastro Único de Pessoa em Múltiplos Papéis sem Duplicidade de CPF/CNPJ (PROB01 / RN01–RN02)
- Problema atual: a mesma pessoa pode vender seu usado à loja, deixar outro em consignação e comprar um terceiro veículo. Quando o sistema separa tabelas de "Clientes", "Fornecedores" e "Funcionários", o mesmo CPF/CNPJ é cadastrado várias vezes com dados divergentes.
- Solução no modelo proposto:
  - A tabela **pessoa** centraliza identificação e endereço com `CONSTRAINT uq_pessoa_documento UNIQUE (tipo_documento, numero_documento)` e validação `ck_pessoa_documento` (`RN01`), reutilizando o mesmo `id_pessoa` em `funcionario`, `atendimento`, `avaliacao`, `entrada`, `venda` e `ocorrencia_garantia`.

### 2.7. Unificação das Modalidades de Entrada com Regras Contratuais Condicionais (PROB03 / RN09–RN12)
- Problema atual: compra própria, consignação e troca têm regras contratuais diferentes. A consignação exige contrato com reconhecimento de firma realizado e acordo de repasse, enquanto a troca usa o contrato da venda de origem.
- Solução no modelo proposto:
  - A tabela **entrada** unifica o controle de pátio com as constraints `ck_entrada_origem` e `ck_entrada_consignacao`. Elas tornam `reconhecimento_firma = 'REALIZADO'` obrigatório na `'CONSIGNACAO'` (`RN12`), restringem `prazo_consignacao`, `valor_repasse_acordado`, `prazo_repasse` e `criterio_repasse` apenas à `'CONSIGNACAO'` (`IS NULL` nas demais modalidades), exigem contrato próprio em `'COMPRA_PROPRIA'`/`'CONSIGNACAO'` e exigem `id_venda_origem` apenas em `'TROCA'`.

### 2.8. Apuração do Custo por Veículo e Base para BI e IA (PROB09 / RN32)
- Problema atual: despesas de preparação, revisão e garantia ficam anotadas fora do fluxo de estoque e venda, dificultando saber se a margem da venda foi consumida pelos gastos de oficina daquele carro.
- Solução no modelo proposto:
  - A tabela **despesa** vincula cada gasto a `veiculo(id_veiculo)` (`RN32`), permitindo consultar a margem líquida por unidade (Consulta Gerencial #8 em `sql/consultas/gerenciais.sql`) e fornecendo base em 3FN para indicadores de BI e modelos de IA ([`docs/bi-ia.md`](bi-ia.md)).

---

## 3. Matriz Comparativa: Operação Atual (RevendaMais + Planilhas) vs. ERP Proposto

| Dimensão Operacional | Como ocorre hoje (RevendaMais + Planilhas) | Como o ERP Proposto Resolve (`sql/ddl/schema.sql`) | Ganho Prático para a Loja |
|---|---|---|---|
| Troca com múltiplos veículos (PROB05) | Dificuldade para associar 2+ carros de entrada ao mesmo contrato com avaliações individuais e abatimento do saldo. | Relação `R14` (`entrada.id_venda_origem`), avaliação obrigatória por troca e soma `total_trocas` em `vw_venda_validacao`. | Dispensa planilhas de abatimento e garante que os carros de troca pertençam ao comprador (**RN18**). |
| Vistoria técnica e Laudo Cautelar (PROB02 / `RN08`) | Cadastro apenas do veículo já aceito; sem trava entre laudo cautelar, avaliação em 5 dimensões e entrada. | Tabelas `avaliacao`, `laudo` e `avaliacao_laudo` com trigger validando `avaliacao.id_veiculo = laudo.id_veiculo` e exigindo aprovação para criar `entrada` (`RN06`/`RN07`). | Impede entrada sem avaliação aprovada ou com laudo de outro veículo; mantém histórico de recusados. |
| Repasse bancário vs. Aprovação (PROB06) | Risco de dar baixa na venda apenas com a aprovação de crédito, antes de o banco transferir o valor. | Separação entre `'APROVADO_A_RECEBER'` e `'RECEBIDO'` em `ck_venda_financiamento`; trava de conclusão em triggers de validação no DDL MySQL. | Impede concluir e entregar veículo financiado antes do repasse bancário (`RN21`/`RN22`). |
| Checklist documental, Firma e Scanner (PROB07 / `RN22`) | Conferência de CNH, CRLV, ATPV, comprovante, firma e scanner controlada manualmente. | Tabela `venda_documento`, view `vw_venda_validacao` (`requisitos_rn22_ok`), `ck_venda_entrega` (scanner) e gatilho `venda_bu` e restrições de entrega. | Bloqueio no SGBD contra conclusão sem os 6 documentos/firmas e contra entrega sem scanner (`RN23`). |
| Cancelamento e histórico de revenda (PROB08 / **RN13**) | Estorno manual ou exclusão da venda, perdendo histórico do distrato ou abrindo duas entradas ativas. | Trigger `entrada_bd` e `venda_bd` (bloqueia `DELETE`), `id_entrada_anterior`, estado `'EM_REGULARIZACAO'` e índice `uq_entrada_veiculo_vigente`. | Preserva o histórico de todos os ciclos do veículo e impede vendas ou entradas ativas simultâneas. |
| Garantia de 2 meses pós-entrega (PROB08 / `RN25`–RN27) | Prazo contado da entrega e perda de garantia por oficina externa acompanhados fora do sistema. | Cálculo de vigência (`data_entrega + 2 months`) em `vw_venda_resumo` e tabela `ocorrencia_garantia` com `atendimento_externo_informado`. | Vincula cada chamado à venda original, à vigência pós-entrega e ao parecer do mecânico. |
| Cadastro de participantes (PROB01) | Duplicidade quando a mesma pessoa compra, vende ou consigna veículos em momentos diferentes. | Tabela única `pessoa` com `UNIQUE (tipo_documento, numero_documento)` referenciada por todos os papéis. | Cadastro único por CPF/CNPJ reutilizado em todo o histórico comercial (`RN01`/`RN02`). |
| Custos e margem por veículo (PROB09) | Gastos de oficina, preparação e garantia separados do custo de entrada do veículo. | Tabela `despesa` ligada a `veiculo(id_veiculo)` + 14 consultas gerenciais e 22 de auditoria (14 de conformidade e 8 de qualidade). | Apuração da margem líquida por veículo e dados estruturados para BI e IA (`RN32`/`RN33`). |
