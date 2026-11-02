# Requisitos não funcionais — ERP Multiplikar Automóveis

Este documento registra os requisitos não funcionais do sistema em MySQL 8.4 e os critérios de verificação. As metas de desempenho e recuperação são requisitos de operação; apenas os testes locais descritos nas evidências foram executados.

## 1. Quadro consolidado

| ID | Requisito | Critério e situação |
|---|---|---|
| RNF01 | Dados pessoais e financeiros acessíveis apenas a perfis autorizados. | Papéis MySQL propostos na seção 2; o schema de demonstração não os cria. |
| RNF02 | CPF/CNPJ, contatos e endereço protegidos contra consulta não autorizada. | Restrições de documento e mascaramento nas consultas públicas. |
| RNF03 | Mudanças financeiras e encerramento de ciclos rastreáveis; entradas e vendas preservadas. | Triggers bloqueiam exclusões e alterações de identidade; trilha com autor e antes/depois é proposta. |
| RNF04 | Concorrência não pode criar ciclos ativos incompatíveis para o mesmo veículo. | Índices UNIQUE, transações InnoDB e validações no ponto de gravação. |
| RNF05 | Vínculos entre veículo, avaliação, laudo, entrada e venda devem ser íntegros. | Chaves estrangeiras, CHECKs, triggers e procedures testados pela cadeia. |
| RNF06 | Com até 6 usuários simultâneos ativos, pico de 15 conexões e base projetada de 5 anos, consultas de balcão: média até 0,5 s e p95 até 1,0 s; escritas: p95 até 1,0 s; relatórios/auditoria: p95 até 3,0 s. | Meta projetada; medir em homologação com a volumetria da seção 3. |
| RNF07 | RPO até 15 minutos e RTO até 2 horas em falha de servidor ou disco. | Metas de operação; o roteiro de backup e restauração da seção 4 ainda precisa ser aplicado e ensaiado no servidor de destino. |
| RNF08 | Estado comercial, financeiro, documental e de entrega deve aparecer separado. | Views vw_venda_resumo, vw_venda_validacao e vw_veiculo_situacao. |

## 2. Perfis e auditoria

A API deve usar contas de menor privilégio, separadas por função. Os comandos abaixo são DCL do MySQL 8.4 e servem como configuração proposta; não fazem parte do schema de demonstração.

~~~sql
CREATE ROLE 'perfil_comercial';
CREATE ROLE 'perfil_avaliacao_oficina';
CREATE ROLE 'perfil_administrativo_gerencial';

GRANT SELECT ON multiplikar.vw_veiculo_situacao TO 'perfil_comercial';
GRANT SELECT ON multiplikar.vw_venda_resumo TO 'perfil_comercial';
GRANT SELECT, INSERT, UPDATE ON multiplikar.atendimento TO 'perfil_comercial';

GRANT SELECT ON multiplikar.entrada TO 'perfil_avaliacao_oficina';
GRANT SELECT, INSERT, UPDATE ON multiplikar.avaliacao TO 'perfil_avaliacao_oficina';
GRANT SELECT, INSERT, UPDATE ON multiplikar.laudo TO 'perfil_avaliacao_oficina';

GRANT SELECT ON multiplikar.* TO 'perfil_administrativo_gerencial';
GRANT 'perfil_comercial' TO 'api_comercial'@'localhost';
SET DEFAULT ROLE 'perfil_comercial' TO 'api_comercial'@'localhost';
~~~

A aplicação também deve ter contas separadas para leitura, testes revertidos, cadastro e CRM. As contas de cadastro e CRM recebem EXECUTE somente nas procedures necessárias. A conta definidora das rotinas não deve permitir login interativo.

A imutabilidade de entradas, vendas e documentos relacionados é implementada no banco. O registro de autor, instante e valores antes/depois de cada alteração continua proposto; o schema atual não possui uma tabela geral de auditoria.

## 3. RNF06 — desempenho e capacidade

Dimensionamento inicial de cinco anos: 2.000 veículos, 6.000 atendimentos, 1.800 entradas, 1.500 vendas e 15.000 despesas. Em homologação, gerar essa volumetria, executar as consultas de sql/consultas/gerenciais.sql e sql/auditoria/auditoria.sql, e medir média e p95 para consultas de balcão, escrita e relatórios. Usar EXPLAIN ANALYZE nas consultas lentas, conferir índices de chaves estrangeiras e medir a contenção dos triggers.

A cadeia acadêmica comprova execução funcional da massa, consultas e regras; ela não comprova as metas de tempo sob carga.

## 4. RNF07 — recuperação

A política proposta combina backup lógico consistente e cópia frequente dos logs binários para permitir restauração e recuperação a um ponto no tempo. Os artefatos devem ficar fora do host do banco, criptografados, com retenção definida e teste periódico de restauração.

Exemplo de backup lógico:

~~~sh
mysqldump --single-transaction --routines --triggers --events multiplikar > multiplikar.sql
~~~

Com log binário habilitado e arquivado, o procedimento de recuperação usa uma cópia lógica válida como base e reaplica os eventos até o instante desejado com mysqlbinlog. A política deve gerar pontos de recuperação em intervalos de no máximo 15 minutos e restaurar o serviço em até 2 horas.

A cadeia de criação do banco e a suíte de 435 verificações foram executadas localmente. O backup, a reaplicação dos logs e os objetivos de RPO/RTO são procedimentos propostos e não foram medidos em servidor remoto.