# Atualização do banco no servidor — 01/11/2026

Registro da aplicação das correções da auditoria ao banco já existente no servidor do site, autorizada pela equipe. O banco não foi recriado nem apagado: foram aplicadas somente as migrações necessárias.

## 1. Ambiente identificado

| Item | Valor |
|---|---|
| Máquina | `multiplikar-db` (Debian 13) |
| Instância | MySQL Community Server 8.4.13, porta 3306, `datadir` `/var/lib/mysql/` |
| Bancos | `multiplikar` (alvo) e `app` (camada do site, não alterada) |
| Estado antes | 21 pessoas, 17 atendimentos, 6 vendas, 37 entradas, 39 veículos; 114 `CHECK`, 50 gatilhos; `venda_bu` na versão antiga; 27 veículos de teste do estoque sem placa e chassi; 10 veículos com placa/chassi (não alterados) |

## 2. Backup e validação da restauração

- Backup completo (`multiplikar` + `app`, com rotinas, gatilhos e eventos) e backup do `multiplikar` para restauro, com hash SHA-256 registrado e conferido.
- Restauração num banco temporário separado: as 28 tabelas restauraram com checksum idêntico ao banco real; gatilhos (50), rotinas (8) e `CHECK` (114) completos; **9 de 11 views** — `vw_fluxos_previsao` falhou (erro 1166: nome automático de coluna com mais de 64 caracteres, defeito corrigido nesta atualização) e `vw_previsao_caixa`, que depende dela.
- Validação complementar antes de alterar: no banco temporário, `vw_fluxos_previsao` foi recriada pela migração e `vw_previsao_caixa` pela definição contida no próprio backup; resultado **11 de 11 views**, e o conteúdo de `vw_fluxos_previsao`, `vw_previsao_caixa`, `vw_fila_acoes`, `vw_veiculo_situacao` e `vw_venda_resumo` ficou idêntico ao do banco real. O banco temporário foi removido.

## 3. Alterações aplicadas

| Migração | Efeito |
|---|---|
| `sql/migracoes/2026-11-01-mensagens-venda.sql` | `venda_bu` recriado (mesma posição de disparo): mesmas condições de RN22 e RN13/RN28-RN31, mensagem passa a listar as pendências |
| `sql/migracoes/2026-11-01-view-fluxos-previsao.sql` | `vw_fluxos_previsao` com aliases explícitos em todos os ramos do `UNION ALL`; resultado inalterado |
| Placas sintéticas | 27 veículos de **teste** da carga do estoque (laudo `LAUDO-LOJA-n`, `id_veiculo = 11 + n`), que tinham placa e chassi nulos, receberam `LJA1B..` / `9LJAB..`; o script exigia exatamente 27 alvos e nenhuma colisão, caso contrário não alteraria nada. Nenhuma placa ou chassi existente foi alterado |

Nenhuma tabela, linha de dados reais ou histórico foi apagado. Operações com potencial destrutivo analisadas antes: o gatilho `venda_bu` fica ausente por um instante entre `DROP` e `CREATE`; a substituição da view não envolve dados.

## 4. Testes após a atualização

| Teste | Resultado |
|---|---|
| RN13: índice `uq_entrada_veiculo_vigente` existe | PASS |
| RN13: nenhum veículo com duas entradas vigentes | PASS |
| RN13: nenhuma entrada com mais de uma venda principal | PASS |
| RN22: concluir a venda 6 sem os requisitos | Recusado: `RN22: pendente: entrada; pagamento; financiamento;` |
| RN13/RN28-RN31: cancelar a venda 6 sem os requisitos | Recusado: `cancelamento pendente: encerrar entrada por DESFAZIMENTO; novo ciclo; orientacao bancaria;` |
| Apagar venda e entrada históricas | Recusado pelos gatilhos de histórico |
| UF minúscula | Recusado por `ck_pessoa_uf` |
| Estado antes/depois dos testes (transação desfeita) | Idêntico: 21 pessoas, 17 atendimentos, 6 vendas com as mesmas situações |
| Catálogo | 28 tabelas, 11 views, 46 FK, 114 `CHECK`, 50 gatilhos, 8 rotinas |
| Consultas de auditoria | 0 erros; 3 alertas de demonstração (venda em formalização parada, financiamento aprovado a receber, ocorrência aberta); Q7 (veículo ativo sem placa nem chassi) vazia |
| API do site | `saude` respondeu; 8 de 8 regras recusadas em `testar-regras` |
| Backup após a atualização, restaurado em banco temporário | 0 erros; 28 tabelas com checksum idêntico; 11 de 11 views |

## 5. Arquivos mantidos no servidor

Os backups antes e depois da atualização e os registros dos testes ficaram em `/root/atualizacao-2026-11-01/` (acesso restrito ao administrador). As migrações aplicadas foram arquivadas em `/opt/modelagem-banco-multiplikar-automoveis/sql/migracoes/`. Os arquivos temporários de transferência foram removidos.
