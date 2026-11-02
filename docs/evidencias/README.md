# Evidências do projeto MySQL

Execução local em MySQL Community Server 8.4.13 com sql_mode padrão. Depois da revisão de domínios de 01/11/2026, a cadeia de 14 arquivos foi executada pela linha de comando numa instância isolada (127.0.0.1:33307, pasta de dados própria, sem tocar a base de trabalho): 435 PASS e exit code 0. O consolidado executar-tudo-workbench.sql também foi executado com --init-command="SET SESSION sql_safe_updates=1": exit code 0, 435 PASS, zero erros SQL e stderr vazio. Os registros atuais estão em mysql/.

| Arquivo | Verificações PASS |
|---|---:|
| sql/dados/massa-dados.sql | 36 |
| sql/testes/testes-restricoes.sql | 61 |
| sql/extensao/02-massa-propostas-caixa.sql | 34 |
| sql/extensao/04-massa-crm.sql | 23 |
| sql/extensao/05-consultas-demo.sql | 2 |
| sql/extensao/06-estoque-loja.sql | 8 |
| sql/extensao/07-intencao-regra-v2.sql | 23 |
| sql/testes/testes-fluxos.sql | 71 |
| sql/testes/testes-relacionamentos.sql | 177 |
| **Total** | **435** |

As 177 verificações de relacionamentos abrangem R01–R41: 133 testes comportamentais e 44 verificações estruturais de FK, nulidade, unicidade e vigência. A matriz completa por arquivo e relacionamento está em [mysql/paridade-testes.md](mysql/paridade-testes.md).

Os arquivos mysql/*.txt guardam as saídas da cadeia, a lista de PASS, catálogo, versão e modo SQL. mysql/workbench.md registra a execução individual no Workbench. O consolidado para abrir pelo Workbench é [sql/executar-tudo-workbench.sql](../../sql/executar-tudo-workbench.sql).

A atualização do banco no servidor do site, com backup validado, migrações aplicadas e testes após a atualização, está registrada em [atualizacao-servidor-2026-11-01.md](atualizacao-servidor-2026-11-01.md).
