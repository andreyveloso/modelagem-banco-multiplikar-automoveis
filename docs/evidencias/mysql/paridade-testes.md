# Matriz de testes MySQL

A cadeia MySQL 8.4 executa 435 verificações PASS nos 14 arquivos, na ordem do README §25 (a mesma do arquivo único `sql/executar-tudo-workbench.sql`). A contagem agrupa as mensagens PASS emitidas pela massa e pelas suítes de testes; DDL, consultas e auditoria não emitem PASS independentes.

Execução final verificada em 01/11/2026 no MySQL 8.4.13, com o sql_mode padrão (ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION). A cadeia dos 14 arquivos, na ordem do README §25 (a mesma do arquivo único `sql/executar-tudo-workbench.sql`), foi executada numa instância isolada (porta 33307) e concluiu com PASS=435; sql/executar-tudo-workbench.sql também concluiu com atualizações seguras habilitadas (SET SESSION sql_safe_updates=1), código de saída 0 e stderr vazio. O catálogo conferido contém 28 tabelas, 11 views e 259 colunas em tabelas base. Saídas atualizadas em 00-server-info.txt, 01-*.txt a 14-*.txt e executar-tudo-safe.stdout.txt/.stderr.txt.

## Contagem por arquivo

| Arquivo | Escopo | PASS |
|---|---|---:|
| sql/ddl/schema.sql | Criação do modelo relacional e rotinas do núcleo | — |
| sql/dados/massa-dados.sql | Regras do núcleo e cenários de venda/entrada | 36 |
| sql/consultas/gerenciais.sql | 14 consultas gerenciais | — |
| sql/auditoria/auditoria.sql | Consultas de auditoria | — |
| sql/testes/testes-restricoes.sql | PK, UNIQUE, FK, CHECK, NOT NULL, proteção do histórico e revisão de domínios | 61 |
| sql/extensao/01-ddl-propostas-caixa.sql | DDL, gatilhos e views de proposta e caixa | — |
| sql/extensao/02-massa-propostas-caixa.sql | Propostas, alternativas, financiamento e obrigações | 34 |
| sql/extensao/03-ddl-crm.sql | DDL, rotinas e views do CRM | — |
| sql/extensao/04-massa-crm.sql | Temperaturas, revisão, histórico e consentimento | 23 |
| sql/extensao/05-consultas-demo.sql | Previsão, realizado e cenários | 2 |
| sql/extensao/06-estoque-loja.sql | Estoque anunciado e regras de entrada | 8 |
| sql/extensao/07-intencao-regra-v2.sql | Intenção de compra e RN44 | 23 |
| sql/testes/testes-fluxos.sql | Fluxos integrados do núcleo, propostas, caixa e CRM | 71 |
| sql/testes/testes-relacionamentos.sql | Relacionamentos R01–R41 | 177 |
| **Total** |  | **435** |

## Cobertura por regra

| Grupo | Cobertura | PASS |
|---|---|---:|
| Núcleo | RN01–RN33: pessoas, avaliação, ciclos, venda, documentos, garantia e despesas | 36 |
| Restrições | PK, UNIQUE, FK, CHECK, NOT NULL e proteção de histórico; encerramento de ocorrência, booleanos 0/1, UF, textos vazios, opcionais nulos, dados de contrato, laudo pendente e entrada vigente única | 61 |
| Propostas | RN34–RN38 e RN43: alternativas, composição, trocas, simulação, consentimento e retorno R0/R4 | 34 |
| CRM | RN40–RN41: interações, desfechos, classificação, revisão e fatores | 23 |
| Caixa | RN42: realizado, obrigações, funil ponderado e cenários | 2 |
| Estoque | Disponibilidade, avaliação e preservação de resultados das consultas | 8 |
| Intenção | RN44: valor disponível, veículo/forma opcionais e classificação V2 | 23 |
| Fluxos integrados | Alternativas A/B/C, contraproposta, irmãs recusadas, retorno bancário, caixa e CRM; cancelamento de venda financiada sem orientação bancária (P9) | 71 |
| Relacionamentos | R01–R41, detalhes abaixo; 133 comportamentais e 44 estruturais | 177 |

## Cobertura dos relacionamentos R01–R41

Cada linha corresponde ao relacionamento testado nos sentidos Ida/Volta. Os testes comportamentais verificam nulidade mínima obrigatória, referência inexistente, máximo 1 quando existe UNIQUE/PK e aceitação de múltiplos filhos quando permitido. O mínimo opcional no pai está documentado no próprio script. As verificações estruturais conferem FK, nulidade e unicidade aplicável.

| R | Relacionamento | Regra/cobertura |
|---|---|---|
| R01 | funcionario.id_pessoa → pessoa.id_pessoa | Obrigatório e único no funcionário |
| R02 | atendimento.id_pessoa → pessoa.id_pessoa | Obrigatório; uma pessoa pode ter atendimentos |
| R03 | atendimento.id_funcionario → funcionario.id_funcionario | Obrigatório; funcionário pode atender várias pessoas |
| R04 | avaliação.id_veiculo → veículo.id_veiculo | Obrigatório; veículo pode ter várias avaliações |
| R05 | avaliação.id_avaliador → pessoa.id_pessoa | Obrigatório; pessoa pode avaliar vários veículos |
| R06 | laudo.id_veiculo → veículo.id_veiculo | Obrigatório; veículo pode ter vários laudos |
| R07 | avaliacao_laudo.id_avaliacao → avaliação.id_avaliacao; id_laudo → laudo.id_laudo | Avaliação com no máximo um vínculo; laudo reutilizável conforme regra |
| R08 | entrada.id_veiculo → veículo.id_veiculo | Obrigatório; veículo pode ter ciclos sucessivos |
| R09 | entrada.id_contraparte → pessoa.id_pessoa | Obrigatório; pessoa pode ser contraparte de várias entradas |
| R10 | entrada.id_avaliacao → avaliação.id_avaliacao | Obrigatório e único por entrada |
| R11 | venda.id_comprador → pessoa.id_pessoa | Obrigatório; comprador pode fazer várias vendas |
| R12 | venda.id_funcionario → funcionario.id_funcionario | Obrigatório; funcionário pode conduzir várias vendas |
| R13 | venda.id_entrada_principal → entrada.id_entrada | Obrigatório e único por venda |
| R14 | entrada.id_venda_origem → venda.id_venda | Opcional; venda pode originar várias entradas de troca |
| R15 | venda.id_laudo → laudo.id_laudo | Opcional; laudo pode ser referenciado em mais de uma venda |
| R16 | ocorrencia_garantia.id_venda → venda.id_venda | Obrigatório; venda pode ter várias ocorrências |
| R17 | ocorrencia_garantia.id_mecanico → pessoa.id_pessoa | Opcional; pessoa pode atuar em várias ocorrências |
| R18 | despesa.id_veiculo → veículo.id_veiculo | Obrigatório; veículo pode ter várias despesas |
| R19 | entrada.id_entrada_anterior → entrada.id_entrada | Opcional e único para sucessão de ciclo |
| R20 | proposta.id_atendimento → atendimento.id_atendimento | Obrigatório; atendimento pode ter várias propostas |
| R21 | proposta.id_entrada → entrada.id_entrada | Obrigatório; entrada pode receber alternativas |
| R22 | proposta.id_funcionario → funcionario.id_funcionario | Obrigatório; funcionário pode criar propostas |
| R23 | proposta.id_proposta_anterior → proposta.id_proposta | Opcional e único; contraproposta mantém a cadeia |
| R24 | venda.id_proposta → proposta.id_proposta | Opcional e único; proposta aceita pode gerar uma venda |
| R25 | proposta_condicao.id_proposta → proposta; codigo_forma → forma_pagamento | Ambos obrigatórios; proposta admite várias condições |
| R26 | proposta_troca.id_proposta → proposta; id_avaliacao → avaliação | Ambos obrigatórios; proposta admite várias trocas |
| R27 | simulacao_financiamento.id_proposta → proposta | Obrigatório; proposta admite várias simulações |
| R28 | simulacao_financiamento.tabela_retorno → parametro_retorno vigente | Válida instituição, tabela e vigência no cadastro |
| R29 | obrigacao_financeira.id_venda → venda | Opcional; venda pode ter várias obrigações |
| R30 | obrigacao_financeira.id_entrada → entrada | Opcional; entrada pode ter várias obrigações |
| R31 | obrigacao_financeira.id_despesa → despesa | Opcional; despesa pode ter várias obrigações |
| R32 | interacao.id_atendimento → atendimento | Obrigatório; atendimento admite várias interações |
| R33 | interacao.id_funcionario → funcionario | Obrigatório; funcionário registra várias interações |
| R34 | atendimento_desfecho.id_atendimento → atendimento | Obrigatório e único; no máximo um desfecho por atendimento |
| R35 | classificacao_lead.id_atendimento → atendimento | Obrigatório; atendimento mantém histórico de classificações |
| R36 | classificacao_lead.id_revisor → funcionario | Opcional; funcionário pode revisar várias classificações |
| R37 | classificacao_fator.id_classificacao → classificacao_lead | Obrigatório; cada classificação exige fator explicativo |
| R38 | atendimento_desfecho.id_funcionario → funcionario | Obrigatório; funcionário pode registrar vários desfechos |
| R39 | intencao_compra.id_atendimento → atendimento | Obrigatório e único; atendimento pode não ter intenção |
| R40 | intencao_compra.id_entrada → entrada | Opcional; entrada pode aparecer em várias intenções |
| R41 | intencao_compra.codigo_forma → forma_pagamento | Opcional; forma pode aparecer em várias intenções |

R28 verifica vigência do parâmetro de retorno; R37 verifica recusa de INSERT direto sem fator e uso da procedure de classificação. O arquivo 14-testes-relacionamentos.txt contém os resultados estruturais; os PASS comportamentais estão nos logs da cadeia.

## Decisões de implementação no MySQL

- Unicidades condicionais usam colunas geradas armazenadas com UNIQUE.
- Validações entre tabelas ocorrem em triggers ou procedures no ponto de transição.
- Rotinas que precisam alterar a tabela que acionou uma validação são executadas por procedures.
- Exclusões de registros históricos são bloqueadas por triggers.
- A suite relacional roda em transação revertida e restaura AUTO_INCREMENT após os testes.