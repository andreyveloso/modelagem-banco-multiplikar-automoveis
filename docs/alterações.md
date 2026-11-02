Registro de decisões e alterações — ERP Multiplikar Automóveis
Este documento resume as decisões finais do modelo lógico e sua implementação em MySQL 8.4.
Tema
Decisão implementada
Motivo
Modelo lógico e físico
14 tabelas no núcleo e 14 tabelas adicionais na extensão, documentadas no modelo lógico e dicionário.
Preservar entidades e cardinalidades do DER em estruturas normalizadas.
RN13 — ciclos de entrada
Encerramentos mantêm o histórico; um novo ciclo referência a entrada anterior.
Permitir rastrear compra, venda, distrato e regularização.
RN22 — conclusão da venda
A conclusão confere quitação, financiamento, documentos e laudo em conjunto.
Impedir estado comercial concluído com pendências.
RN08 — avaliação e laudo
Chaves e validações relacionam o laudo ao mesmo veículo e à data da avaliação.
Evitar vínculo documental entre veículos diferentes.
RNF06 — desempenho
Metas de concorrência e latência definidas em docs/requisitos-nfr.md.
Permitir medição objetiva na volumetria prevista.
RNF07 — recuperação
RPO/RTO e procedimentos MySQL de backup lógico e log binário especificados.
Definir objetivos mensuráveis e roteiro de restauração.
RN34–RN38, RN43
Propostas com rótulos/versões, condições, trocas e simulações R0–R5.
Comparar preço, custo do cliente, margem e prazo de caixa.
RN39, RN42
Obrigações financeiras e projeção semanal com cenários parametrizados.
Acompanhar vencimentos, recebimentos, pagamentos e saldo projetado.
RN40–RN41, RN44
CRM com interações, desfechos, classificação explicável e intenção de compra.
Preservar histórico e justificar prioridade e temperatura do lead.
R37
Trigger exige ao menos um fator e a gravação é feita pela procedure oficial.
Garantir explicação para cada classificação.
Unicidade condicional
Colunas geradas armazenadas e índices UNIQUE.
Implementar unicidade por estado sem depender de índices parciais.
Validações entre tabelas
Triggers e procedures verificam regras no ponto de transição.
Aplicar as regras com a semântica disponível no MySQL.
Relacionamentos
Chaves estrangeiras, nulidade, unicidade e testes R01–R41 documentados.
Tornar explícitas as cardinalidades garantidas pelo banco.
Formatação do DDL
create table em minúsculas, uma coluna ou restrição por linha.
Seguir o padrão apresentado em aula; estrutura do banco conferida como idêntica antes e depois.
Etapa do cadastro (RO02)
E-mail e endereço de PESSOA passam a ser opcionais no primeiro contato; os gatilhos entrada_contrato_*, venda_contrato_* e pessoa_contrato_bu os exigem quando a pessoa assina contrato. O endereço é informado completo ou não informado (ck_pessoa_endereco).
O dicionário já previa "Obrigatório (contratos)"; o banco exigia esses dados antes da etapa em que são necessários.
UF
ck_pessoa_uf compara com a lista das 27 UFs usando collate utf8mb4_bin.
A collation padrão ignora maiúsculas e a expressão regular anterior aceitava sp e siglas inexistentes como XX.
Formato do e-mail
ck_pessoa_email exige texto@domínio.sufixo, sem espaços e com um único @, o mesmo formato validado pelo site; e-mail ausente continua permitido até o contrato. Migração sql/migracoes/2026-11-01-validacao-email.sql.
O banco aceitava qualquer texto como e-mail; a validação ficava só no site.
Textos obrigatórios
CHECK (trim(campo) <> '') nos textos livres obrigatórios de pessoa, funcionário, veículo, atendimento, laudo, avaliação concluída, despesa, ocorrência, forma de pagamento e extensões.
NOT NULL barra a ausência, mas aceita texto vazio ou só de espaços.
Laudo pendente
data_emissao e resultado só existem a partir de EMITIDO (ck_laudo_emissao); laudo PENDENTE não pode ser vinculado a avaliação nem a venda.
Permitir registrar o laudo solicitado antes da emissão.
Ocorrência de garantia
ENCERRADA exige data de encerramento igual ou posterior à abertura e solução com texto; ABERTA, EM_ANALISE e EM_ATENDIMENTO mantêm a data nula.
A regra anterior aceitava ocorrência ENCERRADA sem data e em andamento com data.
Booleanos
CHECK (campo in (0, 1)) em possui_cnh, condicao_repasse, concessao_garantia, reconhecimento_aplicavel e consentimento_renda; só possui_cnh aceita NULL (não informado).
No MySQL, BOOLEAN é TINYINT e aceitaria 2 ou -1.
Cardinalidades revisadas
Mantidas: avaliação com no máximo um laudo (R07), avaliação que fundamenta no máximo uma entrada (R10), entrada principal de no máximo uma venda (R13), formas de pagamento como conjunto de valores (RN19) e uma entrada vigente por veículo.
Todas correspondem aos requisitos documentados; nenhuma mudança estrutural era necessária.
Migração sem recriar o banco
sql/migracoes/2026-11-01-revisao-dominios.sql aplica a revisão a um banco existente: confere os dados antes, recusa reaplicação e resulta em estrutura idêntica à instalação nova. Aplicada no servidor em 01/11/2026, após backup, preservando os cadastros.
O servidor do site tem leads reais que não podem ser apagados pela recriação do banco.
Mensagens de RN22 e do cancelamento
O gatilho venda_bu lista as condições pendentes ("RN22: pendente: ..." e "RN13/RN28-RN31: cancelamento pendente: ..."), sem mudar nenhuma condição; teste dedicado do cancelamento de venda financiada sem orientação bancária em testes-fluxos.sql. Migração sql/migracoes/2026-11-01-mensagens-venda.sql para bancos existentes.
A mensagem única não indicava qual condição impediu a operação; o cancelamento sem orientação bancária não tinha teste isolado.
View vw_fluxos_previsao restaurável
Aliases explícitos em todos os ramos do UNION ALL (sql/extensao/05-consultas-demo.sql); migração sql/migracoes/2026-11-01-view-fluxos-previsao.sql. Resultado da view inalterado.
Sem alias, o MySQL gerava nome de coluna com mais de 64 caracteres; um backup (mysqldump) não conseguia recriar a view nem a vw_previsao_caixa, que depende dela.
Atualização do servidor
Migrações aplicadas ao banco existente após backup validado; registro em docs/evidencias/atualizacao-servidor-2026-11-01.md.
Manter o servidor do site com as mesmas regras do repositório, sem recriar o banco.
Linhas longas da auditoria
Em sql/auditoria/auditoria.sql, três textos de alerta divididos com CONCAT (texto idêntico) e o comentário da Q7 quebrado e corrigido (a Q7 retorna 0 linhas desde as placas sintéticas). Nenhuma linha acima de 120 caracteres nas consultas.
Legibilidade (P8); saída das consultas idêntica byte a byte.
Placa e chassi do estoque
Os 27 veículos de 06-estoque-loja.sql recebem placa e chassi sintéticos.
Veículo em estoque ativo, com laudo e contrato, tem identificação conhecida; sem ela a auditoria Q7 acusava a própria massa.
Modelo lógico sincronizado
modelo-logico.mmd e extensao.mmd conferidos coluna a coluna com o catálogo (259 colunas: tipo, nulidade e colunas geradas); PNG e SVG gerados de novo; modelo-logico.drawio refeito a partir do mesmo modelo, com tipos MySQL.
Após a revisão de domínios, o diagrama ainda mostrava e-mail, endereço e dados do laudo como obrigatórios e omitia as colunas geradas.
Avaliador e mecânico
Mantidos como PESSOA.
O modelo documenta especialista e mecânico como papéis de PESSOA (podem ser externos); FUNCIONARIO só quando há vínculo de trabalho.
Rastreabilidade
Modelo e cardinalidades: docs/modelo-lógico.md e docs/extensão-inovacao.md.
DDL e massa: sql/ddl/, sql/dados/ e sql/extensao/.
Normalização e tipos: docs/normalizacao.md e docs/dicionario-dados.md.
Requisitos não funcionais: docs/requisitos-nfr.md.
Evidências e total de testes: docs/evidencias/README.md e docs/evidencias/mysql/paridade-testes.md.