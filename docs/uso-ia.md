# Uso de Inteligência Artificial no Projeto

Este registro atende à Etapa 17 do Manual da Entrega Final ("A IA PODE AUXILIAR. A RESPONSABILIDADE TÉCNICA CONTINUA SENDO DO GRUPO") e documenta apenas o que tem evidência.

## 1. Uso de IA no projeto

### 1.1. Declaração da equipe

> Durante o desenvolvimento do projeto, ferramentas de inteligência artificial foram utilizadas como apoio à organização, revisão e correção do código. Sua utilização teve caráter auxiliar, contribuindo para a identificação de inconsistências, organização dos arquivos e aperfeiçoamento da implementação.

Os prompts dessas etapas anteriores não estão integralmente disponíveis e, por isso, **não são reproduzidos nem reconstruídos** neste documento.

### 1.2. Assistência ao desenvolvimento × geração de massa de dados

| Tipo de uso | Situação no projeto |
|---|---|
| Assistência ao desenvolvimento (organizar, revisar e corrigir código, testes e documentação) | Utilizado ao longo do projeto, com caráter auxiliar (seção 1.1). Na revisão final há registro verificável das sessões e dos prompts (seções 1.3 e 6). |
| Geração de massa de dados em escala | Não utilizado: a massa foi montada por cenários de negócio (seção 3). Não há, portanto, prompts de geração de massa em escala a documentar. |

### 1.3. Revisão final registrada (01/11/2026)

| Ferramenta | Evidência | Papel |
|---|---|---|
| Claude Code (Anthropic) | Registro da sessão de trabalho de 01/11/2026 | Revisão de domínios, formatação do DDL, migrações, testes, auditoria e correções da auditoria |
| Codex (OpenAI) | Mesma sessão, acionado pelo Claude Code com o prompt da seção 6.4 | Formatação das consultas gerenciais e de auditoria (P8), com comparação byte a byte dos resultados |

## 2. Finalidade e arquivos envolvidos

| Atividade | Arquivos | Prompt |
|---|---|---|
| Formatação dos `CREATE TABLE` no padrão apresentado em aula (minúsculas, uma coluna por linha) | `sql/ddl/schema.sql`, `sql/extensao/01`, `03`, `07` | Pedido da equipe, com print do padrão do professor |
| Revisão de domínios: UF, booleanos, textos vazios, e-mail/endereço no contrato, laudo pendente, ocorrência encerrada, formato do e-mail | `sql/ddl/schema.sql`, `sql/extensao/01` e `03`, `sql/testes/testes-restricoes.sql`, `sql/migracoes/`, `docs/dicionario-dados.md`, `docs/alteracoes.md` | Seção 6.1 |
| Correção de tabelas temporárias que impediam reexecutar o script na mesma aba do Workbench | `sql/extensao/06-estoque-loja.sql`, `sql/testes/testes-relacionamentos.sql` | Relato de erro da equipe, com print do Workbench |
| Auditoria completa do projeto (somente leitura e testes em base isolada) | Nenhum arquivo alterado | Seção 6.2 |
| Correções P1–P9 da auditoria | README, `docs/`, `docs/modelo-logico/`, `sql/extensao/06-estoque-loja.sql`, `sql/ddl/schema.sql`, `sql/testes/testes-fluxos.sql` | Seção 6.3 |
| Formatação das consultas (P8) | `sql/consultas/gerenciais.sql`, `sql/auditoria/auditoria.sql` | Seção 6.4 |

## 3. Massa de dados

A IA não foi usada para gerar massa de dados em escala. A massa **não foi gerada em escala**: cada registro de `sql/dados/massa-dados.sql` e das massas da extensão existe para um cenário de negócio e é conferido pelos testes do próprio script. O estoque de `sql/extensao/06-estoque-loja.sql` reproduz 27 veículos do anúncio público da loja; placa e chassi são sintéticos (padrão `LJA1B..` / `9LJAB..`), porque o anúncio não os publica. Em etapas anteriores, a IA apoiou a organização e a correção desses scripts (seção 1.1), mas não gerou registros em escala.

## 4. Revisão humana e validação

- Toda alteração proposta pela IA foi executada numa instância MySQL 8.4.13 isolada e descartável, a partir de um banco vazio, e conferida pela cadeia de 14 scripts (435 verificações PASS, zero erros) e pelo arquivo único `sql/executar-tudo-workbench.sql`, inclusive executado duas vezes na mesma conexão.
- Alterações de formatação foram aceitas apenas com prova de equivalência: estrutura do banco idêntica antes/depois (DDL) e saídas das consultas idênticas byte a byte (P8).
- As decisões de negócio foram tomadas pela equipe: o limite de 10 caracteres para o número do endereço, a aplicação no servidor, o tratamento do diário de bordo e a adoção dos critérios da revisão de domínios, propostos por um colega que revisou o projeto linha a linha.
- A execução pelo MySQL Workbench foi feita pela equipe com a versão final (846 instruções, sem erros), registrada em `docs/evidencias/mysql/workbench.md`.
- Toda alteração, inclusive as anteriores apoiadas por IA, continua sujeita à mesma validação técnica: execução a partir de banco vazio e cadeia de testes.

## 5. Responsabilidade técnica

A IA teve caráter auxiliar na organização, revisão e correção de código, testes e documentação. A responsabilidade técnica pelo conteúdo entregue é da equipe, que revisou as alterações, decidiu os pontos de negócio e validou os resultados pelos testes descritos acima.

## 6. Prompts utilizados (texto integral)

Somente prompts com registro verificável (revisão final de 01/11/2026) são reproduzidos; foram copiados do registro da sessão, sem edição. Pedidos curtos de acompanhamento ("aplique", "rode no Vercel", envio de prints) não são reproduzidos.

### 6.1. Revisão de domínios e integridade (enviado por um colega que revisou o projeto linha a linha)

~~~~text
Revise e atualize a modelagem e a implementação SQL do projeto Multiplikar, mantendo compatibilidade com MySQL 8.4 e preservando as regras de negócio e o histórico das operações. Antes de alterar, leia os requisitos, os scripts originais, as procedures, os gatilhos e os testes; como o arquivo executar-tudo-workbench.sql é gerado, faça as correções nos arquivos de origem e depois regenere o consolidado. Revise o uso generalizado de VARCHAR(512), dimensionando campos de situação, categoria, modalidade, temperatura e códigos conforme os valores permitidos e uma margem justificada; avalie TEXT para conteúdos extensos, como termos contratuais, sem substituir todos os campos indiscriminadamente. Ao modificar códigos usados em PKs ou FKs, atualize as colunas relacionadas de forma consistente e verifique índices, collations e dependências. Mantenha estado_uf como CHAR(2), mas valide a existência da UF por uma lista completa em CHECK ou por uma tabela de referência com FK, garantindo também a padronização em maiúsculas e considerando a collation utilizada. Preserve os documentos e telefones como texto e não troque placa ou chassi para CHAR apenas pelo comprimento esperado, pois isso não valida seu formato. Acrescente validações contra strings vazias ou compostas apenas por espaços nos campos cujo conteúdo é obrigatório, distinguindo NOT NULL de CHECK com TRIM. Reavalie a obrigatoriedade de email e endereço completo no cadastro inicial e de data de emissão e resultado em laudos pendentes, ajustando essas exigências à etapa do processo em que a informação realmente passa a ser necessária. Corrija o CHECK de ocorrencia_garantia para que a situação ENCERRADA exija data de encerramento igual ou posterior à abertura e solução preenchida com conteúdo válido; nas situações em andamento, mantenha a data de encerramento nula, conforme o fluxo de negócio. Revise os demais CHECKs considerando que o MySQL aceita resultados UNKNOWN decorrentes de NULL, sem tratar a presença de campos opcionais como erro automático e sem remover validações corretas. Adicione restrições para limitar os campos BOOLEAN a 0 e 1, permitindo NULL somente quando houver significado definido, como informação desconhecida ou não aplicável. Verifique as cardinalidades antes de alterar PKs, FKs e UNIQUE: confirme se cada avaliação admite apenas um laudo, se uma avaliação pode fundamentar somente uma entrada, se cada entrada participa como principal de no máximo uma venda e se venda_forma_pagamento representa apenas as formas utilizadas ou também transações individuais. Preserve essas restrições quando corresponderem aos requisitos; implemente mudanças estruturais apenas quando houver evidência de necessidade. Verifique também se avaliadores e mecânicos podem ser pessoas externas ou precisam pertencer ao quadro de funcionários com funções específicas, ajustando as referências e validações conforme a regra documentada. Mantenha UNIQUE em placa e chassi com possibilidade de NULL quando esses dados ainda não estiverem disponíveis e preserve o uso simultâneo de PK e FK quando adequado. Se faltar uma definição de negócio, registre a pendência e mantenha o comportamento atual nesse ponto. Atualize os testes afetados e acrescente casos relevantes para encerramentos inconsistentes, booleanos fora do domínio, UFs inválidas, textos obrigatórios vazios, campos opcionais nulos e cardinalidades. Valide a execução completa em uma base de testes isolada, sem apagar dados existentes, e entregue os scripts atualizados acompanhados de um resumo das alterações, justificativas, impactos na integridade e no desempenho, decisões pendentes e resultados dos testes, indicando claramente qualquer verificação que não tenha sido possível executar.
~~~~

### 6.2. Auditoria completa do projeto

~~~~text
# PROMPT — AUDITORIA COMPLETA DO PROJETO INTEGRADOR

## PAPEL E OBJETIVO

Atue como uma banca avaliadora universitária composta por:

- Professor especialista em Modelagem de Dados.
- Engenheiro de Dados sênior.
- Administrador de Banco de Dados (DBA).
- Arquiteto de Software.
- Auditor de qualidade e documentação técnica.

Sua missão é realizar uma **auditoria integral, rigorosa, imparcial e baseada em evidências** do projeto acadêmico **ERP — Multiplikar Automóveis, Grupo 5**.

O objetivo é verificar se o projeto atende integralmente às exigências acadêmicas e técnicas, se corrigiu as observações feitas pelo professor e se o banco de dados realmente funciona conforme as regras de negócio.

**Não presuma que o projeto está correto. Sua função é procurar erros, omissões, inconsistências, problemas de integridade e divergências entre os documentos.**

## 1. FONTES OBRIGATÓRIAS

Utilize como referência:

1. `manual-primeira-entrega.pdf`
2. `MANUAL DA ENTREGA FINAL.pdf`
3. `Devolutiva grupo5.pdf`
4. Todos os arquivos do projeto disponibilizado, incluindo repositório GitHub, documentação, diagramas, scripts SQL, dicionários, evidências e histórico de commits, quando acessíveis.

Estabeleça a seguinte interpretação:

- Os dois manuais determinam os requisitos de entrega e avaliação de suas respectivas etapas.
- A devolutiva determina os problemas e pontos de atenção identificados pelo professor na primeira entrega.
- O projeto atual deve demonstrar como evoluiu e corrigiu os problemas identificados.
- Quando houver alteração de modelagem, verifique sua justificativa e consistência em todos os artefatos.

Não trate exemplos didáticos dos manuais como exigências obrigatórias para a empresa.

Não invente critérios, documentos, testes, evidências ou resultados.

Se algum material não estiver disponível, registre como **NÃO VERIFICÁVEL**, sem presumir aprovação ou reprovação.

## 2. INSPEÇÃO COMPLETA DO REPOSITÓRIO

Antes de avaliar, percorra recursivamente todos os diretórios e arquivos acessíveis.

Verifique:

- README e documentação complementar.
- Requisitos funcionais e não funcionais.
- Regras de negócio.
- Fluxogramas.
- DER conceitual e modelo lógico.
- Dicionário de dados.
- Documentação da normalização.
- Scripts SQL e massa de dados.
- Consultas gerenciais e de auditoria.
- Evidências de testes.
- Histórico de commits e colaboração.
- Diários de bordo.
- Documentação de BI e IA.
- Materiais de apresentação, quando disponíveis.

Inspecione também imagens, PDFs e diagramas visualmente. Não considere um diagrama validado apenas por seu nome ou por uma referência no README.

Verifique links quebrados, arquivos ausentes, versões contraditórias, arquivos vazios, referências desatualizadas e duplicações desnecessárias.

**Não utilize apenas o README como prova de que um requisito foi cumprido.**

## 3. AUDITORIA DA PRIMEIRA ENTREGA

Compare o projeto com todos os requisitos do Manual da Primeira Entrega.

Verifique a caracterização da empresa, justificativa, processos, problemas, requisitos, regras, políticas, fluxogramas, entidades, atributos, relacionamentos, cardinalidades, DER e dicionário conceitual.

Analise a rastreabilidade:

EMPRESA → PROCESSOS → PROBLEMAS → REQUISITOS → REGRAS DE NEGÓCIO → ENTIDADES → ATRIBUTOS → RELACIONAMENTOS → CARDINALIDADES → DER.

Identifique qualquer informação contraditória, ausente ou sem justificativa técnica.

## 4. VALIDAÇÃO OBRIGATÓRIA DA DEVOLUTIVA

A primeira entrega recebeu nota 7,5 e aprovação com ressalvas técnicas.

Verifique individualmente os seguintes pontos:

**RNF06 — Desempenho:** confirmar se foram definidos critérios mensuráveis de tempo de resposta, volume de dados e usuários simultâneos.

**RNF07 — Recuperação:** confirmar se existem parâmetros verificáveis de perda máxima de dados e tempo de recuperação.

**RN13 — Comercialização única:** verificar como o projeto impede múltiplas vendas ativas ou concluídas para a mesma entrada comercial e preserva o histórico após cancelamentos.

**RN22 — Conclusão da venda:** verificar como as condições financeiras, documentais e técnicas são avaliadas conjuntamente.

**Entradas comerciais:** verificar como se impede que um veículo tenha duas entradas comerciais simultaneamente ativas.

**Histórico dos veículos:** verificar a preservação do histórico de venda, devolução e nova comercialização.

**Avaliação e laudo:** verificar se um laudo associado a uma avaliação necessariamente pertence ao mesmo veículo.

**Controle financeiro:** avaliar a representação das formas de pagamento, suas limitações e a preservação das informações financeiras exigidas pelo escopo.

**Despesas e custos:** verificar a distinção entre despesas individualizadas por veículo, despesas administrativas e obrigações pendentes, conforme o escopo declarado.

**Inovação:** verificar quais problemas do sistema comercial existente permanecem sem solução e quais melhorias concretas o ERP proposto oferece.

**Documentação:** confirmar a presença dos documentos consolidados e dos diários de bordo exigidos.

Para cada ponto, informe:

- Problema original.
- Solução encontrada no projeto atual.
- Evidência concreta.
- Situação: CORRIGIDO, PARCIALMENTE CORRIGIDO, NÃO CORRIGIDO ou NÃO VERIFICÁVEL.
- Consequência técnica.
- Correção recomendada.

Não considere um problema corrigido apenas porque a documentação afirma que foi resolvido.

## 5. AUDITORIA DA MODELAGEM CONCEITUAL E LÓGICA

Verifique:

- Correspondência entre DER e modelo lógico.
- Conversão correta de entidades em tabelas.
- PKs e FKs.
- Chaves compostas, quando necessárias.
- Cardinalidades e participações mínimas e máximas.
- Relacionamentos 1:1, 1:N e N:N.
- Tabelas associativas.
- Entidades fortes, fracas e associativas.
- Restrições de unicidade.
- Integridade referencial.
- Ausência de redundâncias inadequadas.
- Coerência com as regras de negócio.

Dê atenção especial aos processos da Multiplikar Automóveis:

- Compra de veículos.
- Consignação.
- Entrada de veículos como parte do pagamento.
- Avaliações e laudos.
- Estoque.
- Negociações.
- Vendas.
- Financiamentos.
- Cancelamentos.
- Devoluções.
- Revendas.
- Garantias e pós-venda.

Não acrescente funcionalidades que não foram aprovadas no escopo sem distinguir claramente uma sugestão de uma exigência.

## 6. NORMALIZAÇÃO — 1FN, 2FN E 3FN

Analise todas as tabelas e suas dependências funcionais.

Verifique:

**1FN:** atomicidade, atributos multivalorados, grupos repetitivos e armazenamento de listas.

**2FN:** dependências parciais em relação às chaves candidatas compostas.

**3FN:** dependências transitivas e atributos armazenados em tabelas inadequadas.

Confira se a documentação apresenta exemplos reais de normalização, dependências funcionais, problemas identificados, correções e justificativas.

Não aceite simplesmente a declaração de que o banco está normalizado.

Não invente estruturas incorretas anteriores apenas para justificar a normalização.

## 7. DICIONÁRIO DE DADOS

Compare cada tabela e coluna implementada com o dicionário.

Verifique:

- Nome e descrição.
- Tipo e tamanho.
- PK e FK.
- NULL e NOT NULL.
- UNIQUE.
- DEFAULT.
- CHECK e outras restrições.
- Correspondência com o SQL.
- Correspondência com o modelo lógico.

Identifique colunas ausentes, nomes divergentes, tipos incompatíveis e documentação desatualizada.

## 8. IMPLEMENTAÇÃO SQL E TESTES REAIS

Verifique a existência e a correção de:

- CREATE DATABASE.
- CREATE TABLE.
- PRIMARY KEY.
- FOREIGN KEY.
- NOT NULL.
- UNIQUE.
- CHECK.
- DEFAULT.
- INSERT.
- SELECT.
- JOIN.
- UPDATE.
- DELETE.
- Consultas gerenciais.
- Consultas de auditoria.

Quando houver ambiente de execução disponível, execute os scripts em um **banco de testes isolado e descartável**, nunca em produção.

Teste o projeto desde um banco vazio até a execução completa das consultas.

Verifique:

1. Erros de sintaxe.
2. Dependências entre scripts.
3. Integridade referencial.
4. Inserções válidas e inválidas.
5. Restrições de unicidade.
6. Exclusões e atualizações.
7. Resultados das consultas.
8. Consistência da massa de dados.
9. Possibilidade de reproduzir a instalação seguindo o README.

Realize testes positivos, negativos e de situações excepcionais.

Não execute comandos destrutivos fora do ambiente de testes.

Se não puder executar os scripts, faça análise estática e classifique os testes como NÃO EXECUTADOS. Nunca apresente execução simulada como evidência real.

## 9. TESTES DE CENÁRIOS DO NEGÓCIO

Avalie especialmente:

- Veículo comprado e posteriormente vendido.
- Veículo recebido em consignação.
- Veículo utilizado como entrada em outra negociação.
- Veículo vendido e devolvido.
- Veículo devolvido e vendido novamente.
- Duas entradas simultâneas para o mesmo veículo.
- Duas vendas incompatíveis para a mesma entrada.
- Avaliação associada ao laudo de outro veículo.
- Financiamento aprovado sem recebimento pela loja.
- Venda cancelada com financiamento.
- Venda concluída sem satisfazer alguma condição obrigatória.
- Despesas vinculadas a veículos.
- Atendimento de garantia e pós-venda.

Para cada cenário, informe se o modelo permite representar a operação corretamente, quais restrições a protegem e se o comportamento foi efetivamente testado.

## 10. CONSULTAS GERENCIAIS, AUDITORIA, BI E IA

Verifique se as consultas gerenciais respondem perguntas relevantes para a empresa, com resultados coerentes e utilidade para a tomada de decisão.

Confirme se as consultas de auditoria procuram inconsistências reais e se sua finalidade está documentada.

Avalie indicadores, métricas, possibilidades de BI e futuras aplicações de IA.

Para cada proposta analítica, identifique:

PROBLEMA → DADOS DISPONÍVEIS → ANÁLISE → BENEFÍCIO.

Não exija implementação completa de BI ou IA, pois o manual solicita demonstrar possibilidades de evolução.

## 11. DOCUMENTAÇÃO, GITHUB E COLABORAÇÃO

Verifique:

- Organização do repositório.
- Clareza do README.
- Instruções de execução.
- Links e caminhos.
- Consistência entre versões.
- Evidências de evolução.
- Commits e participação dos integrantes.
- Diários de bordo.
- Evidências colaborativas.
- Documentação das principais alterações.
- Registro dos prompts utilizados para geração de dados e scripts com IA, conforme exigido pelo manual.

Não conclua que houve colaboração apenas pela existência de vários nomes no README.

Não atribua ausência de participação a integrantes sem evidências suficientes.

A apresentação e a defesa final devem ser classificadas separadamente quando ainda não tiverem ocorrido ou quando o manual específico não estiver disponível.

## 12. MATRIZ DE CONFORMIDADE

Construa uma matriz completa contendo:

| ID | Exigência | Documento e página | Evidência no projeto | Status | Gravidade | Correção |
|---|---|---|---|---|---|---|

Utilize os status:

- CONFORME
- PARCIALMENTE CONFORME
- NÃO CONFORME
- NÃO VERIFICÁVEL
- NÃO APLICÁVEL

Não omita exigências apenas porque foram atendidas.

## 13. CLASSIFICAÇÃO DOS PROBLEMAS

Classifique os problemas encontrados:

**CRÍTICO:** compromete integridade, funcionamento, regra essencial ou requisito obrigatório.

**ALTO:** compromete significativamente a modelagem, implementação, documentação ou avaliação.

**MÉDIO:** inconsistência relevante, mas localizada.

**BAIXO:** melhoria secundária, organização ou apresentação.

Para cada problema, apresente:

1. Identificador.
2. Arquivo e localização exata.
3. Evidência do erro.
4. Explicação técnica.
5. Exigência violada.
6. Impacto.
7. Solução recomendada.
8. Arquivos que precisarão ser atualizados.
9. Teste necessário para comprovar a correção.

## 14. SIMULAÇÃO DA AVALIAÇÃO DO PROFESSOR

Utilize os pesos oficiais do Manual da Entrega Final:

- Dimensão conceitual: 30%.
- Dimensão procedimental: 50%.
- Dimensão atitudinal: 20%.

Respeite os critérios e subpesos específicos apresentados no manual.

Apresente uma nota estimada de 0 a 10 somente para os critérios com evidências suficientes.

Informe separadamente:

- Pontuação comprovada.
- Pontuação potencial ainda não verificada.
- Cobertura percentual da avaliação.
- Riscos de perda de pontos.

Não transforme automaticamente itens não verificáveis em nota zero.

Não atribua nota definitiva à apresentação, participação ou postura profissional sem evidências apropriadas.

## 15. FORMATO OBRIGATÓRIO DO RELATÓRIO

Entregue o resultado nesta ordem:

### A. Parecer executivo
Resumo do estado real do projeto e principais riscos.

### B. Cobertura da auditoria
Arquivos examinados, arquivos inacessíveis e testes executados.

### C. Matriz completa de conformidade
Todos os requisitos dos manuais.

### D. Situação da devolutiva
Análise individual de cada ressalva do professor.

### E. Auditoria técnica
Modelagem, normalização, dicionário, SQL, dados e consultas.

### F. Inconsistências entre arquivos
Divergências entre README, DER, modelo lógico, dicionário, regras e implementação.

### G. Problemas encontrados
Ordenados por gravidade, com localização exata.

### H. Simulação de nota
Pontuação por critério, cobertura e limitações.

### I. Plano de correção
Prioridade, ação necessária, arquivos afetados e critério de aceite.

### J. Checklist final
Todos os itens com status e evidências.

### K. Parecer final
Escolha uma das classificações:

- APTO PARA ENTREGA, COM EVIDÊNCIAS SUFICIENTES.
- APTO COM RESSALVAS.
- NÃO APTO PARA ENTREGA.
- CONFORMIDADE INDETERMINADA POR FALTA DE EVIDÊNCIAS.

## 16. REGRAS INEGOCIÁVEIS

1. Não invente informações.
2. Não aprove itens sem evidência.
3. Não ignore arquivos ou diretórios acessíveis.
4. Não confunda documentação com implementação.
5. Não confunda código aparentemente correto com código testado.
6. Não considere a devolutiva resolvida sem verificar as correções.
7. Não proponha alterações que contradigam o escopo sem justificativa.
8. Não modifique arquivos durante esta auditoria.
9. Não substitua exigências do professor por preferências pessoais de arquitetura.
10. Não declare conformidade total quando existirem pendências não verificadas.
11. Diferencie erros comprovados, riscos potenciais e melhorias opcionais.
12. Fundamente toda conclusão com evidências e referências aos manuais.

**INSTRUÇÃO FINAL:**

Realize a análise com o rigor de uma avaliação universitária e de uma revisão técnica profissional. Procure principalmente os problemas que poderiam passar despercebidos em uma leitura superficial.

Seu objetivo não é elogiar o trabalho, mas determinar com precisão o que está correto, o que está incorreto, o que ainda precisa ser comprovado e o que deve ser corrigido antes da entrega final.

Ao terminar, apresente uma resposta clara à pergunta:

**"Com base nas evidências disponíveis, o projeto ERP — Multiplikar Automóveis está realmente pronto para ser entregue e defendido conforme os manuais e a devolutiva do professor?"**

Justifique a resposta tecnicamente, sem suposições.
~~~~

### 6.3. Correção das pendências da auditoria

~~~~text
# PROMPT — CORREÇÃO INTEGRAL DO PROJETO ERP MULTIPLIKAR AUTOMÓVEIS

## 1. PAPEL E OBJETIVO

Atue como Engenheiro de Software Sênior, DBA MySQL, Arquiteto de Dados e Revisor Técnico de Projetos Acadêmicos.

Sua tarefa é **corrigir todas as pendências identificadas na auditoria do projeto ERP — Multiplikar Automóveis (Grupo 5)**, utilizando como referência:

- Manual da Primeira Entrega.
- Manual da Entrega Final.
- Devolutiva do Grupo 5.
- Relatório completo da auditoria técnica.
- Arquivos atuais do repositório.

Você possui autorização para editar os arquivos necessários, corrigir documentação, atualizar diagramas, ajustar scripts e executar testes em ambiente isolado.

**Objetivo principal:** eliminar as inconsistências identificadas, garantindo conformidade com os manuais e preservando integralmente as funcionalidades já implementadas.

Não reestruture o projeto desnecessariamente. Não faça alterações apenas por preferência arquitetural.

## 2. ESCLARECIMENTO OBRIGATÓRIO — DIÁRIO DE BORDO (P1)

A auditoria classificou a ausência do diário de bordo no GitHub como uma não conformidade.

Entretanto, essa classificação desconsidera uma informação importante sobre o procedimento de entrega.

**O diário de bordo é entregue separadamente, por meio de uma pasta específica disponibilizada pelo professor, fora do repositório GitHub do projeto.**

Portanto:

1. NÃO crie uma pasta de diários de bordo no repositório.
2. NÃO gere diários fictícios.
3. NÃO considere a ausência desses arquivos no GitHub uma falha.
4. Atualize o README para explicar claramente o procedimento de entrega separada.
5. Corrija eventuais checklists que indiquem incorretamente que os diários precisam estar no repositório.
6. Não afirme que os diários foram efetivamente entregues, pois essa confirmação depende de evidência externa.
7. Classifique a entrega efetiva dos diários como NÃO VERIFICÁVEL NO REPOSITÓRIO, e não como NÃO CONFORME.

Utilize uma redação semelhante a:

"Os diários de bordo dos integrantes são entregues separadamente, por meio da pasta específica disponibilizada pelo professor, conforme o procedimento estabelecido para a atividade. Por esse motivo, não integram os arquivos deste repositório."

Preserve as referências existentes aos diários quando forem necessárias para contextualizar o projeto.

## 3. CORREÇÃO P2 — MODELO LÓGICO DESATUALIZADO

A auditoria identificou divergências entre:

- `modelo-logico.md`
- `modelo-logico.mmd`
- `modelo-logico.png`
- `modelo-logico.svg`
- SQL implementado
- Dicionário de dados

Corrija especificamente:

**A. Nulidade dos atributos**

Revise a representação dos atributos de PESSOA e LAUDO, incluindo:

- E-mail de pessoa.
- Endereço de pessoa.
- `data_emissao` de laudo.
- `resultado` de laudo.

Confirme a nulidade real no esquema SQL e atualize o modelo lógico para refletir exatamente a implementação.

**B. Colunas geradas e relacionamentos**

A auditoria apontou a ausência de:

- `veiculo_vigente`
- `id_entrada_aceita`
- `id_proposta_aprovada`

Verifique suas tabelas, tipos, restrições, expressões e relacionamentos.

Atualize o arquivo Mermaid e regenere os diagramas PNG e SVG.

**C. Consistência**

Compare as 28 tabelas e todas as 259 colunas do banco com o modelo lógico e o dicionário.

Critério de aceite: nenhuma divergência não justificada entre o modelo lógico, o SQL e o dicionário.

Não modifique o banco apenas para fazê-lo coincidir com um diagrama desatualizado.

## 4. CORREÇÃO P3 — FLUXOGRAMAS NÃO EXIBIDOS

A auditoria identificou três fluxogramas com links incorretos no README:

- Fluxograma 02 — Entrada e avaliação.
- Fluxograma 05 — Informações de pagamento.
- Fluxograma 06 — Conclusão e entrega.

O problema decorre de diferenças entre os nomes referenciados, com acentos, e os nomes reais dos arquivos.

Corrija os caminhos utilizando os nomes efetivamente existentes no repositório.

Não duplique imagens desnecessariamente.

Verifique se os nove fluxogramas são exibidos corretamente no GitHub.

## 5. CORREÇÃO P4 — DESPESAS ADMINISTRATIVAS

Existe uma contradição entre o README, `escopo-financeiro.md` e a implementação.

A documentação informa que despesas administrativas estão fora do escopo, mas a extensão financeira permite obrigações com origem `ADMINISTRATIVA`.

Corrija a documentação diferenciando:

- Escopo financeiro original.
- Funcionalidades implementadas posteriormente na extensão.
- Despesas diretamente relacionadas aos veículos.
- Obrigações financeiras administrativas contempladas pela extensão.
- Limitações do controle financeiro.

Explique claramente que a extensão amplia as possibilidades do sistema, sem alterar retroativamente as decisões documentadas na primeira entrega.

Verifique se a explicação corresponde ao comportamento real da tabela `obrigacao_financeira`.

Não crie novas tabelas nem altere regras financeiras sem necessidade comprovada.

## 6. CORREÇÃO P5 — VEÍCULOS SEM PLACA E CHASSI

A auditoria identificou 27 veículos sem placa e chassi na massa de dados, apontados pela consulta Q7.

Analise o arquivo:

`06-estoque-loja.sql`

Antes de corrigir, verifique se a ausência desses dados é legítima segundo as regras de negócio.

Se os registros deveriam conter essas informações:

- Corrija a massa de dados.
- Utilize dados sintéticos coerentes.
- Evite duplicidades.
- Respeite os formatos e restrições definidos.
- Preserve os relacionamentos existentes.

Se houver justificativa para a ausência, documente a situação e ajuste a interpretação da consulta de auditoria, sem esconder inconsistências reais.

Não utilize dados pessoais reais.

Critério de aceite: Q7 sem pendências injustificadas.

## 7. CORREÇÃO P6 — DOCUMENTAÇÃO DO USO DE IA

O Manual da Entrega Final exige documentar os prompts utilizados para auxiliar a geração em escala da massa de dados e dos scripts.

Crie ou atualize uma seção de documentação denominada:

**Uso de Inteligência Artificial no Projeto**

Registre, quando houver evidências:

- Ferramentas utilizadas.
- Finalidade da utilização.
- Prompts efetivamente utilizados.
- Arquivos ou atividades envolvidos.
- Procedimentos de revisão humana.
- Testes e validações realizados.
- Responsabilidade técnica da equipe.

Não invente prompts históricos, ferramentas utilizadas ou participação dos integrantes.

Quando informações não estiverem disponíveis, sinalize os pontos que dependem de confirmação da equipe.

Inclua os prompts desta auditoria e correção apenas se forem efetivamente utilizados, distinguindo-os dos prompts de geração de dados e scripts exigidos pelo manual.

Não oculte a utilização de IA nem inclua declarações falsas.

## 8. CORREÇÃO P7 — README, LINKS E REPRODUTIBILIDADE

Corrija todos os problemas identificados:

**A. Arquivo BAT externo**

O README menciona:

`RODAR-BANCO-MULTIPLIKAR.bat`

Esse arquivo não foi localizado no repositório.

Verifique se o script existe no ambiente de trabalho.

Se existir, avalie sua inclusão no repositório, desde que seja seguro e não contenha credenciais.

Se não existir, remova a dependência obrigatória e documente um procedimento alternativo completo e reproduzível.

Não invente a existência do arquivo.

**B. Caminhos**

Corrija as referências inconsistentes entre:

- `mysql-validation`
- `mysql84-validation`

Utilize o caminho real do projeto.

**C. Links internos**

Corrija referências incorretas em:

- `bi-ia.md`
- `extensao-inovacao.md`
- `normalizacao.md`
- README

Revise especialmente referências com acentos que não correspondam aos nomes reais dos arquivos.

**D. Âncoras**

Corrija a referência `#secao-26` e todas as outras âncoras sem destino.

**E. Instruções de execução**

Verifique a numeração dos passos 13 e 14 e revise o procedimento completo.

Critério de aceite: outra pessoa deve conseguir instalar e executar o projeto seguindo exclusivamente as instruções e os arquivos disponibilizados.

Todos os links e âncoras devem funcionar.

## 9. CORREÇÃO P8 — FORMATAÇÃO SQL

A auditoria identificou consultas com linhas de até 3.783 caracteres.

Revise especialmente:

- `gerenciais.sql`
- `auditoria.sql`

Aplique formatação legível:

- Indentação consistente.
- SELECT organizado.
- JOIN em linhas separadas.
- WHERE e condições bem estruturadas.
- GROUP BY e ORDER BY legíveis.
- Comentários preservados.
- Linhas preferencialmente com até 120 caracteres.

Não altere a lógica das consultas, os resultados ou as regras de negócio.

Após a formatação, execute novamente as consultas e compare seus resultados com os anteriores.

## 10. CORREÇÃO P9 — RN22 E TESTES NEGATIVOS

A auditoria identificou dois pontos:

1. Mensagens genéricas no gatilho `venda_bu`.
2. Ausência de teste negativo dedicado para cancelamento de venda financiada sem orientação bancária.

Verifique se é possível melhorar as mensagens sem comprometer a compatibilidade do banco.

Implemente um teste específico para confirmar que o cancelamento indevido é recusado.

O teste deve comprovar:

- Estado inicial.
- Operação tentada.
- Condição de negócio violada.
- Erro esperado.
- Preservação dos dados após a recusa.
- Resultado PASS ou FAIL.

Não altere o comportamento das regras RN13 e RN22 que já foram aprovadas.

## 11. PRESERVAÇÃO DA IMPLEMENTAÇÃO EXISTENTE

A auditoria anterior informou:

- 28 tabelas.
- 11 views.
- 46 chaves estrangeiras.
- 114 regras CHECK.
- 50 gatilhos.
- 431 verificações automáticas aprovadas.
- 259 colunas consistentes com o dicionário.

Esses números representam a linha de base relatada pela auditoria, não uma exigência de manter contagens artificiais.

Antes de modificar qualquer script, registre o estado atual.

Após as correções, execute novamente os testes e compare os resultados.

Se alguma contagem mudar, explique tecnicamente o motivo.

**Nenhuma correção documental deve provocar regressão no banco de dados.**

## 12. VALIDAÇÃO FINAL OBRIGATÓRIA

Após implementar as correções:

1. Releia os três documentos oficiais.
2. Reavalie os nove apontamentos P1 a P9.
3. Compare DER, modelo lógico, dicionário e SQL.
4. Verifique os nove fluxogramas.
5. Valide todos os links.
6. Execute o banco a partir de um ambiente vazio.
7. Execute os testes automatizados.
8. Execute as consultas gerenciais e de auditoria.
9. Confirme a integridade da massa de dados.
10. Verifique as instruções do README.
11. Confirme que as mudanças não introduziram novas contradições.
12. Identifique eventuais pendências que dependam de informação humana ou de entrega externa.

Quando houver recursos disponíveis, utilize MySQL 8.4 em ambiente isolado para os testes.

Não altere bancos de produção ou dados reais.

## 13. RELATÓRIO FINAL DAS CORREÇÕES

Ao concluir, apresente:

### A. Resumo executivo

O que foi corrigido e o que permanece pendente.

### B. Tabela de correções

| ID | Problema | Arquivos modificados | Correção realizada | Resultado |
|---|---|---|---|---|
| P1 | Diário de bordo | README/checklists | Entrega separada esclarecida | |
| P2 | Modelo lógico | Diagramas e documentação | Sincronização com SQL | |
| P3 | Fluxogramas | README | Links corrigidos | |
| P4 | Despesas | Documentação financeira | Escopo reconciliado | |
| P5 | Dados de veículos | Massa de dados/documentação | Inconsistências tratadas | |
| P6 | Uso de IA | Documentação | Registro baseado em evidências | |
| P7 | Execução e links | README e documentos | Reprodutibilidade corrigida | |
| P8 | Formatação SQL | Consultas | Legibilidade melhorada | |
| P9 | RN22 | Testes e, se necessário, gatilho | Teste negativo implementado | |

### C. Testes executados

Informe os comandos, ambiente, resultados e quantidade de testes aprovados e reprovados.

### D. Divergências restantes

Liste qualquer pendência que não tenha sido possível resolver, sem ocultá-la.

### E. Veredito

Informe se o projeto está apto para entrega conforme os manuais, distinguindo a conformidade do repositório das atividades entregues separadamente e da apresentação ainda não realizada.

## 14. INSTRUÇÕES FINAIS

- Execute as correções, não apenas descreva como fazê-las.
- Preserve a estrutura atual sempre que possível.
- Não apague funcionalidades já aprovadas.
- Não altere regras de negócio sem justificativa.
- Não crie arquivos fictícios para cumprir checklists.
- Não invente evidências de participação.
- Não trate a ausência dos diários no GitHub como falha.
- Não faça commit ou push automaticamente.
- Não declare testes aprovados sem executá-los.
- Não encerre a tarefa enquanto houver correções executáveis pendentes, salvo impedimento técnico claramente documentado.

**OBJETIVO FINAL: deixar o projeto tecnicamente consistente, documentado, reproduzível e alinhado aos manuais, eliminando todas as pendências que possam ser corrigidas com os arquivos e recursos disponíveis.**
~~~~

### 6.4. Prompt enviado ao Codex para a formatação das consultas (P8)

~~~~text
Tarefa P8 do projeto Multiplikar: FORMATAR (sem mudar logica) dois arquivos SQL. Trabalhe SOMENTE nestes dois arquivos; nao edite nenhum outro arquivo do repositorio (outro agente esta editando o resto em paralelo). Nao faca commit nem push.

Arquivos (repo: C:\Users\andre\OneDrive\Área de Trabalho\modelagem\modelagem-banco-multiplikar-automoveis-main):
  1. sql\consultas\gerenciais.sql
  2. sql\auditoria\auditoria.sql
Hoje cada consulta esta numa unica linha (ate 3.783 caracteres), com comentarios /* ... */ na mesma linha.

O que fazer:
- Uma clausula por linha, indentacao de 4 espacos: SELECT (uma coluna/expressao por linha quando houver varias), FROM, cada JOIN em linha propria com seu ON, WHERE com cada AND/OR em linha propria, GROUP BY, HAVING, ORDER BY, LIMIT. CTEs (WITH) com cada CTE em bloco proprio. Subconsultas e CASE indentados.
- Palavras-chave em MAIUSCULAS (mantenha como ja estao; nao renomeie identificadores, aliases ou literais).
- Preserve TODOS os comentarios e titulos (/* CONSULTA ...*/, /* AUDITORIA ...*/ etc.), cada um em linha propria antes da consulta. Preserve o texto dos comentarios.
- Linhas preferencialmente <= 120 caracteres (literais longos podem exceder; liste as excecoes).
- NAO altere a logica: mesmas colunas, mesma ordem de colunas, mesmos aliases, mesmos filtros, mesmas ordenacoes, mesmos literais, mesmo numero de instrucoes e mesma ordem das instrucoes. Mantenha USE/SET e quaisquer instrucoes nao-SELECT exatamente equivalentes.
- Mantenha codificacao UTF-8 e o mesmo tipo de quebra de linha do arquivo original (confira se e CRLF ou LF e preserve).

Verificacao OBRIGATORIA (criterio de aceite):
- Ha uma instancia MySQL 8.4 isolada e descartavel em 127.0.0.1:33308 (root sem senha), ja carregada com o banco multiplikar no estado final. Use SOMENTE essa porta (nunca 33306 nem 33307). Cliente: %LOCALAPPDATA%\Temp\mysql84-validation\mysql-8.4.13-winx64\bin\mysql.exe
- Copias dos originais: C:\Users\andre\AppData\Local\Temp\claude\C--Users-andre-OneDrive--rea-de-Trabalho-modelagem\7b58c41b-b56e-477f-8034-ae0bb1cb0106\scratchpad\correcao\originais\gerenciais.sql e C:\Users\andre\AppData\Local\Temp\claude\C--Users-andre-OneDrive--rea-de-Trabalho-modelagem\7b58c41b-b56e-477f-8034-ae0bb1cb0106\scratchpad\correcao\originais\auditoria.sql
- Para cada arquivo, execute o ORIGINAL e o FORMATADO assim: mysql.exe -h127.0.0.1 -P33308 -uroot --default-character-set=utf8mb4 --table < arquivo > saida.txt
  e compare as duas saidas byte a byte (devem ser identicas). Os arquivos sao somente leitura (SELECT), entao rodar varias vezes nao altera o banco; se algum nao for, avise antes de rodar.
- Confirme tambem: (a) numero de instrucoes igual (conte os ';' fora de comentarios/literais), (b) maior linha de cada arquivo, (c) linhas > 120 caracteres restantes e por que.

Quando terminar, responda com o relatorio usando o comando:
maestri ask "Claude Code" "RELATORIO P8: <arquivos alterados; resultado da comparacao byte a byte de cada arquivo (IDENTICO/DIFERENTE, com o diff se diferente); numero de instrucoes antes/depois; maior linha antes/depois; excecoes > 120 caracteres; quebra de linha preservada (CRLF/LF); qualquer duvida ou ponto nao resolvido>"
Se encontrar algo que exija mudar logica para formatar, NAO mude: pare e relate.
~~~~

### 6.5. Finalização das pendências (Workbench, servidor, uso de IA e testes)

~~~~text
# PROMPT — FINALIZAÇÃO DAS PENDÊNCIAS DO ERP MULTIPLIKAR

Dando continuidade às correções realizadas no projeto ERP Multiplikar Automóveis — Grupo 5, preciso que finalize as pendências restantes.

## 1. Evidência de execução no MySQL Workbench

Vou disponibilizar uma nova captura de tela comprovando a execução dos testes.

Quando receber a imagem:

- Verifique se corresponde à versão atual do projeto.
- Confira se a execução ocorreu sem erros.
- Verifique a quantidade de testes aprovados.
- Atualize as referências às evidências no README, se necessário.
- Não altere ou fabrique resultados.

Se a imagem não comprovar todos os testes esperados, explique exatamente o que falta.

## 2. Autorização para atualização do servidor

Autorizo a atualização do banco de dados existente no servidor para incorporar as correções realizadas, incluindo a migração:

`sql/migracoes/2026-11-01-mensagens-venda.sql`

Também autorizo a atualização dos registros de veículos com dados sintéticos, desde que sejam exclusivamente registros de teste identificados como tais.

**Procedimento obrigatório:**

1. Identifique o servidor, a instância e o banco de dados de destino.
2. Confirme que se trata do ambiente correto.
3. Faça um backup completo antes de qualquer alteração.
4. Verifique a integridade do backup e a possibilidade de restauração.
5. Compare o esquema atual com o esquema atualizado.
6. Identifique alterações potencialmente destrutivas.
7. Execute somente as migrações necessárias, sem recriar ou apagar o banco existente.
8. Preserve integralmente os registros reais e o histórico.
9. Não substitua placas, chassis ou outros dados reais por informações sintéticas.
10. Execute os testes de integridade e as consultas de auditoria.
11. Confirme o funcionamento das regras RN13 e RN22.
12. Registre os resultados da atualização.

Caso não seja possível confirmar o ambiente, validar o backup ou garantir a preservação dos dados, interrompa a operação e solicite minha confirmação antes de continuar.

Não execute scripts de limpeza, DROP DATABASE ou recriação integral sobre o banco existente.

## 3. Documentação do uso de IA

Atualize `docs/uso-ia.md` e as referências correspondentes no README.

Informação fornecida pela equipe:

"Durante o desenvolvimento do projeto, ferramentas de inteligência artificial foram utilizadas como apoio à organização, revisão e correção do código. Sua utilização teve caráter auxiliar, contribuindo para a identificação de inconsistências, organização dos arquivos e aperfeiçoamento da implementação."

Considere que:

- Os prompts antigos não estão integralmente disponíveis.
- Não devem ser reconstruídos ou inventados.
- A utilização anterior foi principalmente para organizar e corrigir código durante sua criação.
- Os prompts recentes de auditoria e correção podem ser documentados quando houver registro verificável.
- As alterações devem continuar sendo validadas tecnicamente.
- Não atribua atividades específicas a integrantes sem evidências.

Diferencie claramente o uso de IA para assistência ao desenvolvimento do uso de IA para geração de massa de dados, quando houver.

## 4. Verificação dos testes

O relatório anterior informou:

- 435 PASS na execução completa.
- 431/435 PASS no procedimento documentado no README.

Investigue a diferença de quatro testes.

Determine se ela decorre de procedimentos de execução distintos, arquivos não incluídos ou outro motivo.

Corrija a documentação ou a execução, se necessário, para que os resultados sejam compreensíveis e reproduzíveis.

## 5. Auditoria final

Após concluir:

- Confirme que modelo lógico, DER, dicionário e SQL permanecem consistentes.
- Confirme que os links e fluxogramas continuam funcionando.
- Execute os testes disponíveis.
- Verifique se a atualização do servidor foi bem-sucedida.
- Informe o estado final do banco.
- Liste qualquer pendência restante.

Lembre-se de que **os diários de bordo são entregues separadamente, na pasta disponibilizada pelo professor**, não sendo necessário adicioná-los ao repositório.

Não faça commit ou push sem minha autorização.

Ao final, apresente um relatório objetivo com as alterações, os testes executados, os resultados e a situação de cada pendência.
~~~~
