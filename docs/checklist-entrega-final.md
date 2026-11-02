# Checklist da entrega final

Conferência item a item do manual e da devolutiva contra os artefatos existentes e o catálogo MySQL 8.4.13. Status resumido: **61 ATENDE, 8 PARCIAL, 0 NÃO ATENDE**. Itens parciais apontam evidência que não consta no pacote ou depende da apresentação final.

## 1. Entregáveis solicitados pelo manual

| ID | Exigência | Onde verificar | Resultado |
|---|---|---|---|
| M01 | Revisão da primeira entrega: correções, DER atualizado, regras alteradas e justificativas. | README §19; docs/alteracoes.md; docs/der/; docs/evidencias/mysql/ | ATENDE |
| M02 | Modelo lógico relacional: tabelas, atributos, PK, FK, chaves compostas, relacionamentos, restrições e integridade referencial. | docs/modelo-logico.md; docs/dicionario-dados.md; sql/ddl/schema.sql; sql/extensao/01 e 03 | ATENDE |
| M03 | Normalização em 1FN, 2FN e 3FN, dependências funcionais e justificativas das decomposições. | docs/normalizacao.md; docs/extensao-inovacao.md §5 | ATENDE |
| M04 | Dicionário de dados atualizado e coerente com a estrutura implantada. | docs/dicionario-dados.md; catálogo MySQL 8.4.13 | ATENDE |
| M05 | Script SQL com criação, chaves, restrições, INSERT, SELECT, JOIN, UPDATE, DELETE, consultas gerenciais e auditoria. | sql/ddl/; sql/dados/; sql/consultas/; sql/auditoria/; sql/extensao/ | ATENDE |
| M06 | Massa coerente para relacionamentos, restrições, consultas, processos e integridade. | sql/dados/massa-dados.sql; sql/extensao/02, 04, 06 e 07; sql/testes/ | ATENDE |
| M07 | Repositório com documentação, diagramas, scripts, dicionário, evolução e evidências de colaboração. | README §1, 19 e 25; docs/; sql/; docs/evidencias/ | PARCIAL — o histórico de commits depende da publicação do repositório no GitHub. Os diários de bordo são entregues separadamente, pela pasta específica do professor (README §1.3): NÃO VERIFICÁVEL NO REPOSITÓRIO, e não constituem falha do repositório. |
| M08 | Análise de dados, indicadores, informações gerenciais, apoio à decisão e possibilidades futuras. | README §27-30; docs/bi-ia.md | ATENDE |
| M09 | Apresentação e defesa final seguindo orientação específica do curso. | README §31 contém roteiro de perguntas; nenhum arquivo de apresentação/defesa foi localizado. | PARCIAL — depende da apresentação oral e do material orientado pelo professor. |

## 2. Etapas de execução (1-23)

| ID | Exigência | Onde verificar | Resultado |
|---|---|---|---|
| E01 | Revisar requisitos, regras, entidades, atributos, relacionamentos, cardinalidades, entidades associativas e fracas. | README §5–14, 17-19; docs/der/ | ATENDE |
| E02 | Registrar as principais mudanças, seu motivo e como o modelo ficou. | README §19; docs/alteracoes.md | ATENDE |
| E03 | Converter entidades e atributos para tabelas e colunas relacionais. | docs/modelo-logico.md §1–2; docs/dicionario-dados.md | ATENDE |
| E04 | Definir e justificar PKs sem duplicidade. | docs/modelo-logico.md §1; dicionário; DDL | ATENDE |
| E05 | Converter os relacionamentos e representar as FKs adequadas. | README §14; docs/modelo-logico.md; DDL | ATENDE |
| E06 | Resolver relacionamentos N e chaves compostas por tabelas associativas. | docs/normalizacao.md; docs/modelo-logico.md; dicionário | ATENDE |
| E07 | Verificar entidades fracas e associativas sem criar dependências artificiais. | README §17; docs/modelo-logico.md §1–3 | ATENDE |
| E08 | Verificar atomicidade e grupos repetitivos (1FN). | docs/normalizacao.md §1; docs/extensao-inovacao.md §5 | ATENDE |
| E09 | Verificar dependências parciais em chaves compostas (2FN). | docs/normalizacao.md §2; docs/extensao-inovacao.md §5 | ATENDE |
| E10 | Verificar dependências transitivas (3FN). | docs/normalizacao.md §3; docs/extensao-inovacao.md §5 | ATENDE |
| E11 | Documentar estrutura antes, dependência, problema e decomposição. | docs/normalizacao.md | ATENDE |
| E12 | Justificar PK, FK, NOT NULL, UNIQUE, CHECK e DEFAULT. | docs/modelo-logico.md; docs/dicionario-dados.md | ATENDE |
| E13 | Atualizar o dicionário com tabela, atributo, descrição, tipo, tamanho e restrições. | docs/dicionario-dados.md § 259 atributos de 28 tabelas, sincronizados ao catálogo | ATENDE |
| E14 | Organizar os scripts de banco, carga, consultas, atualização e exclusão conforme aplicável. | sql/ddl/; sql/dados/; sql/consultas/; sql/auditoria/; sql/testes/ | ATENDE |
| E15 | Executar a cadeia desde banco vazio e conferir resultados. | `sql/executar-tudo-workbench.sql` (arquivo único) ou os 14 scripts na ordem do README §25; docs/evidencias/mysql/ | ATENDE |
| E16 | Usar massa variada, coerente e suficiente para cenários significativos. | sql/dados/massa-dados.sql; sql/extensao/02, 04, 06 e 07 | ATENDE |
| E17 | Registrar instruções de geração em escala quando houver uso desse processo. | A massa revisada usa casos determinísticos; não há lote em escala nem instruções auxiliares no pacote. | PARCIAL — não há material aplicável a anexar. |
| E18 | Construir consultas gerenciais a partir de perguntas de negócio. | sql/consultas/gerenciais.sql (14 consultas); README §27 | ATENDE |
| E19 | Construir consultas de auditoria e explicar o que verificam. | sql/auditoria/auditoria.sql; README §28 | ATENDE |
| E20 | Relacionar resultados a decisões gerenciais. | README §27-30; docs/bi-ia.md | ATENDE |
| E21 | Apontar indicadores, dados necessários e potencial de análise. | README §29; docs/bi-ia.md | ATENDE |
| E22 | Organizar artefatos para que outra pessoa localize documentação, modelos, SQL, dados e evidências. | README; docs/; sql/; docs/evidencias/ | ATENDE |
| E23 | Usar o README como porta de entrada que explica o projeto e seus artefatos. | README §1–31 | ATENDE |

## 3. Teste de consistência do manual

| ID | Pergunta | Onde verificar | Resultado |
|---|---|---|---|
| C01 | As necessidades da empresa continuam representadas? | README §5–7, 19 e 23 | ATENDE |
| C02 | As regras de negócio estão claras e atualizadas? | README §8; docs/extensao-inovacao.md §3 | ATENDE |
| C03 | O DER representa as regras? | README §10, 16 e 19; docs/der/ | ATENDE |
| C04 | O modelo lógico representa o DER? | docs/modelo-logico.md; docs/dicionario-dados.md | ATENDE |
| C05 | As tabelas estão adequadamente estruturadas até a 3FN? | docs/normalizacao.md; docs/extensao-inovacao.md §5 | ATENDE |
| C06 | O dicionário representa o modelo implementado? | docs/dicionario-dados.md, sincronizado ao catálogo | ATENDE |
| C07 | O SQL implementa o modelo lógico? | sql/; execução integral MySQL 8.4.13 | ATENDE |
| C08 | A massa permite testar regras e relacionamentos? | sql/testes/; paridade-testes.md | ATENDE |
| C09 | As consultas respondem a perguntas relevantes? | sql/consultas/; sql/extensao/05; README §27-30 | ATENDE |
| C10 | O potencial analítico está identificado? | README §29; docs/bi-ia.md | ATENDE |
| C11 | Outra pessoa consegue compreender e executar o projeto? | README §25 (Workbench, linha de comando e arquivo por arquivo, apenas com arquivos do repositório); cadeia e evidências | ATENDE |

## 4. Checklist final do manual

| ID | Grupo de itens | Onde verificar | Resultado |
|---|---|---|---|
| F01 | Primeira entrega revista: requisitos, regras, DER, cardinalidades e justificativas. | README §19–20; docs/alteracoes.md | ATENDE |
| F02 | Modelo lógico: tabelas, atributos, PK, FK, chaves compostas e relações N. | docs/modelo-logico.md; DDL | ATENDE |
| F03 | Normalização e dependências funcionais. | docs/normalizacao.md; docs/extensao-inovacao.md §5 | ATENDE |
| F04 | Dicionário completo e coerente. | docs/dicionario-dados.md | ATENDE |
| F05 | SQL: estrutura, restrições e execução integral. | sql/; evidências MySQL | ATENDE |
| F06 | Massa coerente e testes dos relacionamentos/restrições. | sql/testes/; PASS por arquivo | ATENDE |
| F07 | Material auxiliar da geração em escala, quando aplicável. | Não houve geração em escala documentada. | PARCIAL — a massa é determinística e não há geração em escala documentada atual. |
| F08 | Consultas gerenciais/de auditoria e sua finalidade. | sql/consultas/; sql/auditoria/; README §27-28 | ATENDE |
| F09 | Indicadores e utilidade analítica para a empresa. | README §29; docs/bi-ia.md | ATENDE |
| F10 | README, DER, modelo lógico, dicionário, normalização e scripts. | README; docs/; sql/ | ATENDE |
| F11 | Histórico, evidências de colaboração e contribuição dos integrantes. | README §1.2, §1.3 e §19.1. Commits: dependem da publicação no GitHub. Diários: entregues separadamente pela pasta do professor — NÃO VERIFICÁVEL NO REPOSITÓRIO. | PARCIAL |

## 5. Devolutiva do professor

| ID | Ponto solicitado | Onde verificar | Resultado |
|---|---|---|---|
| D01 | RNF06 define metas verificáveis de tempo, volume e usuários. | README §23; docs/requisitos-nfr.md §3; EXPLAIN ANALYZE proposto. | ATENDE |
| D02 | RNF07 define perda máxima e tempo de recuperação. | README §23; docs/requisitos-nfr.md §4; roteiro § proposta, não medição de servidor. | ATENDE |
| D03 | RN13 preserva histórico de cancelamento e novo ciclo. | Triggers/rotina no schema; testes de desfazimento e R19. | ATENDE |
| D04 | RN22 verifica conjuntamente as condições de conclusão. | vw_venda_validacao, vw_venda_resumo, concluir_venda e testes negativos. | ATENDE |
| D05 | Impede duas entradas vigentes para o mesmo veículo. | entrada.veiculo_vigente gerada + índice único uq_entrada_veiculo_vigente. | ATENDE |
| D06 | Define escopo de despesas por veículo versus despesas administrativas. | README §24; docs/escopo-financeiro.md; obrigação ADMINISTRATIVA. | ATENDE |
| D07 | Preserva histórico de veículo vendido, devolvido e novamente comercializado. | Ciclos de entrada encadeados e massa de desfazimento/retorno. | ATENDE |
| D08 | Garante que avaliação e laudo pertencem ao mesmo veículo. | R07/RN08, triggers MySQL e testes de tentativa cruzada. | ATENDE |
| D09 | Explica limites do atributo multivalorado de formas de pagamento e evolução financeira. | README §24; docs/escopo-financeiro.md; proposta_condicao e obrigacao_financeira. | ATENDE |
| D10 | Representa recebimentos individuais e obrigações ainda não quitadas. | Pedido da devolutiva: avaliar as limitações das formas de pagamento como atributo multivalorado e compreender como um sistema completo preservaria recebimentos individuais e obrigações. Limitações e modelo proposto em `docs/escopo-financeiro.md` §2 (incluindo §2.3, recebimentos individuais); obrigações pendentes implementadas em `obrigacao_financeira`. Limitação declarada: cada recebimento não é registrado como evento independente (decisão de escopo, RN19). | ATENDE ao pedido de avaliação; registro de recebimentos individuais fora do escopo implementado |
| D11 | Distingue custos de veículos e despesas gerais. | despesa por veículo e obrigações ADMINISTRATIVAS separadas. | ATENDE |
| D12 | Representa obrigações financeiras pendentes e atraso. | obrigacao_financeira com datas original/atual, situação e projeção. | ATENDE |
| D13 | Demonstra valor agregado frente ao sistema comercial existente. | README §30; docs/inovacao-valor.md; docs/extensao-inovacao.md. | ATENDE |
| D14 | Confirma documento consolidado e diário de bordo. | Documento consolidado: README e `docs/`. Diários de bordo: entregues separadamente pela pasta específica do professor (README §1.3) — NÃO VERIFICÁVEL NO REPOSITÓRIO. | ATENDE no repositório; diário não verificável aqui |
| D15 | Testa exceções e preservação do histórico antes do modelo lógico. | Massas core/CRM/propostas, testes de restrições, fluxos e R01-R41. | ATENDE |

## 6. Cobertura dos relacionamentos R01-R41

[`sql/testes/testes-relacionamentos.sql`](../sql/testes/testes-relacionamentos.sql) contém verificações estruturais e comportamentais dos 41 relacionamentos. Os lados obrigatórios rejeitam nulo e referência inexistente; os lados opcionais registram o mínimo zero; PK/UNIQUE testam o máximo um; relações que admitem vários filhos têm ensaio positivo. R28 é validado por trigger temporal, pois não existe FK simples para a vigência. A matriz registra **177 PASS (133 comportamentais e 44 estruturais)**. Na revisão não ficou relacionamento sem sentido Ida/Volta ou cardinalidade aplicável sem cobertura.

## 7. Cobertura dos fluxogramas 01-09

| Fluxo | Caminho principal | Desvios exercitados | Evidência |
|---|---|---|---|
| 01 Atendimento e CRM | Cadastro/atendimento, interação, sugestão e revisão da classificação. | Atendimento convertido fora da fila; revisão humana com justificativa e fatores explicáveis. | `sql/extensao/04-massa-crm.sql`; `sql/testes/testes-fluxos.sql` |
| 02 Entrada e avaliação | Avaliação aprovada que fundamenta entrada do veículo. | Avaliação pendente/reprovada, nulidade, duplicidade de avaliação e inconsistência de laudo. | `sql/dados/massa-dados.sql`; `sql/testes/testes-restricoes.sql`; `sql/testes/testes-relacionamentos.sql` |
| 03 Consignação | Cadastro de entrada, contrato, preço e repasse. | Modalidade inválida, contrato/condições ausentes e datas fora da regra. | `sql/dados/massa-dados.sql`; `sql/testes/testes-restricoes.sql` |
| 04 Venda e troca | Venda com veículo principal e entradas recebidas em troca. | Troca de terceiro/veículo principal, avaliação não elegível e vínculo de venda inválido. | `sql/dados/massa-dados.sql`; testes R13-R18 e R26 |
| 05 Pagamento/financiamento | Pagamentos por forma e simulação R0/R4. | Consentimento ausente, parâmetros inválidos, rejeição e simulação imutável. | `sql/extensao/02-massa-propostas-caixa.sql`; `sql/testes/testes-fluxos.sql` |
| 06 Conclusão e entrega | Venda concluída após verificação financeira, documental e técnica. | Falhas independentes de RN22, scanner, datas, documentos e laudo. | `sql/dados/massa-dados.sql`; `sql/testes/testes-restricoes.sql` |
| 07 Garantia e devolução | Abertura de ocorrência após entrega com cobertura concedida. | Garantia sem entrega/concessão, encerramento inconsistente e desfazimento com histórico. | `sql/dados/massa-dados.sql`; testes R16/R19 e de restrições |
| 08 Despesas e relatérios | Despesa por veículo, obrigação vencida e consultas de custo/caixa. | Margem por ciclo, obrigação atrasada e transições inválidas. | `sql/consultas/gerenciais.sql`; `sql/extensao/05-consultas-demo.sql`; `sql/testes/testes-fluxos.sql` |
| 09 Propostas, caixa e CRM | Alternativas A/B/C, comparativo, simulação, fila e previsão. | Contraproposta, aceite e recusa de irmãs, atraso bancário e não fechamento dos leads quentes. | `sql/extensao/02`, `04`, `05`; `sql/testes/testes-fluxos.sql` |

## 8. Evidência de execução e escopo pendente

Os totais finais e a execução com atualizações seguras estão em [`docs/evidencias/mysql/paridade-testes.md`](evidencias/mysql/paridade-testes.md) e nos logs individuais em `docs/evidencias/mysql/`. Os diários de bordo são entregues separadamente, pela pasta específica do professor, e a defesa oral ainda não ocorreu: ambos são NÃO VERIFICÁVEIS NO REPOSITÓRIO, sem afirmar que foram conferidos. O histórico de commits depende da publicação do repositório no GitHub.
