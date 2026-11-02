# Dicionário de dados físico e lógico — ERP Multiplikar Automóveis

## 1. Escopo e convenções

O catálogo foi conferido no MySQL 8.4.13 após a execução completa da cadeia. São 28 tabelas e 11 views: 14 tabelas e 3 views no núcleo; 14 tabelas e 8 views na extensão. Os tipos, nulidade, chaves, defaults e colunas geradas abaixo refletem `information_schema` do banco executado.

Para cada atributo, o dicionário informa nome, descrição, tipo MySQL, tamanho, PK, FK, nulidade, unicidade, default e restrições vinculadas. A camada semântica das regras está em [README](../README.md), [modelo lógico](modelo-logico.md) e [extensão](extensao-inovacao.md).

### Legenda

- `PK`: coluna participa da chave primária; `UNIQUE`: identificação única individual ou composta.
- `NULL`: informa se a coluna aceita `NULL`.
- `DEFAULT`: valor padrão; `AUTO_INCREMENT` e `GENERATED` identificam colunas automáticas.
- As regras listadas são nomes reais do catálogo MySQL; as expressões exatas de `CHECK` estão na seção 3.

## 2. Tabela `atendimento`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `atendimento` | `id_atendimento` | Identificador único do atendimento. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_atendimento_descricao, ck_atendimento_interesse, ck_atendimento_situacao |
| `atendimento` | `id_pessoa` | Cliente/interessado atendido. | `BIGINT` | 8 bytes | — | fk_atendimento_id_pessoa -> pessoa(id_pessoa) | NÃO | — | — | FK: fk_atendimento_id_pessoa -> pessoa(id_pessoa); CHECK: ck_atendimento_descricao, ck_atendimento_interesse, ck_atendimento_situacao |
| `atendimento` | `id_funcionario` | Funcionário responsável pelo atendimento. | `BIGINT` | 8 bytes | — | fk_atendimento_id_funcionario -> funcionario(id_funcionario) | NÃO | — | — | FK: fk_atendimento_id_funcionario -> funcionario(id_funcionario); CHECK: ck_atendimento_descricao, ck_atendimento_interesse, ck_atendimento_situacao |
| `atendimento` | `data` | Data e hora do registro do atendimento. | `DATETIME` | 5 bytes | — | — | NÃO | — | `CURRENT_TIMESTAMP` | CHECK: ck_atendimento_descricao, ck_atendimento_interesse, ck_atendimento_situacao |
| `atendimento` | `tipo_interesse` | Natureza da demanda inicial do cliente. | `VARCHAR(6)` | 6 caracteres | — | — | NÃO | — | — | CHECK: ck_atendimento_descricao, ck_atendimento_interesse, ck_atendimento_situacao |
| `atendimento` | `descricao_interesse` | Detalhamento da necessidade ou veículo procurado/ofertado. | `TEXT` | até 65.535 caracteres | — | — | NÃO | — | — | CHECK: ck_atendimento_descricao, ck_atendimento_interesse, ck_atendimento_situacao |
| `atendimento` | `situacao` | Andamento do atendimento comercial. | `VARCHAR(13)` | 13 caracteres | — | — | NÃO | — | — | CHECK: ck_atendimento_descricao, ck_atendimento_interesse, ck_atendimento_situacao |
| `atendimento` | `observacoes` | Anotações complementares do contato comercial. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_atendimento_descricao, ck_atendimento_interesse, ck_atendimento_situacao |

## 2. Tabela `atendimento_desfecho`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `atendimento_desfecho` | `id_atendimento` | Atendimento encerrado (chave primária compartilhada com a FK). | `BIGINT` | 8 bytes | SIM | fk_atendimento_desfecho_id_atendimento -> atendimento(id_atendimento) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_atendimento_desfecho_id_atendimento -> atendimento(id_atendimento); CHECK: ck_desfecho_motivo, ck_desfecho_tipo |
| `atendimento_desfecho` | `id_funcionario` | Funcionário responsável pelo registro do desfecho. | `BIGINT` | 8 bytes | — | fk_atendimento_desfecho_id_funcionario -> funcionario(id_funcionario) | NÃO | — | — | FK: fk_atendimento_desfecho_id_funcionario -> funcionario(id_funcionario); CHECK: ck_desfecho_motivo, ck_desfecho_tipo |
| `atendimento_desfecho` | `data_hora` | Data e hora do registro do desfecho do atendimento. | `DATETIME` | 5 bytes | — | — | NÃO | — | `CURRENT_TIMESTAMP` | CHECK: ck_desfecho_motivo, ck_desfecho_tipo |
| `atendimento_desfecho` | `tipo_desfecho` | Resultado final do atendimento (`GANHO` ou `PERDA`). | `VARCHAR(16)` | 16 caracteres | — | — | NÃO | — | — | CHECK: ck_desfecho_motivo, ck_desfecho_tipo |
| `atendimento_desfecho` | `motivo` | Razão principal do ganho ou da perda do negócio. | `TEXT` | até 65.535 caracteres | — | — | NÃO | — | — | CHECK: ck_desfecho_motivo, ck_desfecho_tipo |
| `atendimento_desfecho` | `detalhe` | Observação complementar sobre o encerramento do atendimento. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_desfecho_motivo, ck_desfecho_tipo |

## 2. Tabela `avaliacao`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `avaliacao` | `id_avaliacao` | Identificador único da avaliação técnica. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `id_veiculo` | Veículo inspecionado na avaliação. | `BIGINT` | 8 bytes | — | fk_avaliacao_id_veiculo -> veiculo(id_veiculo) | NÃO | — | — | FK: fk_avaliacao_id_veiculo -> veiculo(id_veiculo); CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `id_avaliador` | Especialista/funcionário responsável técnico pela análise. | `BIGINT` | 8 bytes | — | fk_avaliacao_id_avaliador -> pessoa(id_pessoa) | NÃO | — | — | FK: fk_avaliacao_id_avaliador -> pessoa(id_pessoa); CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `data` | Data e hora da realização da avaliação. | `DATETIME` | 5 bytes | — | — | NÃO | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `finalidade` | Modalidade pretendida para a avaliação. | `VARCHAR(14)` | 14 caracteres | — | — | NÃO | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `quilometragem` | Quilometragem registrada no hodômetro no ato da vistoria. | `INT` | 4 bytes | — | — | NÃO | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `quantidade_proprietarios` | Quantidade de proprietários anteriores informada. | `INT` | 4 bytes | — | — | SIM | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `condicao_externa` | Estado de lataria, pintura, vidros e pneus. | `VARCHAR(120)` | 120 caracteres | — | — | SIM | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `condicao_interna` | Estado de estofamento, painel e equipamentos internos. | `VARCHAR(120)` | 120 caracteres | — | — | SIM | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `condicao_mecanica` | Estado de motor, câmbio, freios e suspensão. | `VARCHAR(120)` | 120 caracteres | — | — | SIM | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `condicao_estrutural` | Integridade de chassi, longarinas, colunas e monobloco. | `VARCHAR(120)` | 120 caracteres | — | — | SIM | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `condicao_documental` | Situação de multas, débitos, gravames e restrições. | `VARCHAR(120)` | 120 caracteres | — | — | SIM | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `decisao_tecnica` | Parecer técnico final da inspeção. | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | `PENDENTE` | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `interesse_comercial` | Manifestação de viabilidade comercial pela loja. | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | `EM_ANALISE` | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |
| `avaliacao` | `justificativa` | Fundamentação técnica da aprovação ou reprovação. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_avaliacao_concluida, ck_avaliacao_decisao, ck_avaliacao_finalidade, ck_avaliacao_interesse, ck_avaliacao_medidas |

## 2. Tabela `avaliacao_laudo`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `avaliacao_laudo` | `id_avaliacao` | Avaliação técnica que consultou o laudo. | `BIGINT` | 8 bytes | SIM | fk_avaliacao_laudo_id_avaliacao -> avaliacao(id_avaliacao) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_avaliacao_laudo_id_avaliacao -> avaliacao(id_avaliacao) |
| `avaliacao_laudo` | `id_laudo` | Laudo cautelar consultado na avaliação. | `BIGINT` | 8 bytes | — | fk_avaliacao_laudo_id_laudo -> laudo(id_laudo) | NÃO | — | — | FK: fk_avaliacao_laudo_id_laudo -> laudo(id_laudo) |

## 2. Tabela `classificacao_fator`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `classificacao_fator` | `id_classificacao` | Classificação de lead explicada por este fator. | `BIGINT` | 8 bytes | SIM | fk_classificacao_fator_id_classificacao -> classificacao_lead(id_classificacao) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_classificacao_fator_id_classificacao -> classificacao_lead(id_classificacao); CHECK: ck_fator_codigo, ck_fator_evidencia |
| `classificacao_fator` | `codigo_fator` | Dimensão avaliada na regra de pontuação do lead. | `VARCHAR(32)` | 32 caracteres | SIM | — | NÃO | PRIMARY | — | PRIMARY KEY; CHECK: ck_fator_codigo, ck_fator_evidencia |
| `classificacao_fator` | `pontos` | Pontuação atribuída especificamente a este fator. | `DECIMAL(6,2)` | (6,2) | — | — | NÃO | — | — | CHECK: ck_fator_codigo, ck_fator_evidencia |
| `classificacao_fator` | `evidencia` | Descrição auditável com os valores e limiares verificados na avaliação do fator. | `TEXT` | até 65.535 caracteres | — | — | NÃO | — | — | CHECK: ck_fator_codigo, ck_fator_evidencia |

## 2. Tabela `classificacao_lead`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `classificacao_lead` | `id_classificacao` | Identificador único da execução de classificação do lead. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `id_atendimento` | Atendimento avaliado nesta execução. | `BIGINT` | 8 bytes | — | fk_classificacao_lead_id_atendimento -> atendimento(id_atendimento) | NÃO | — | — | FK: fk_classificacao_lead_id_atendimento -> atendimento(id_atendimento); CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `data_hora` | Instante de referência em que a classificação foi calculada. | `DATETIME` | 5 bytes | — | — | NÃO | — | — | CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `origem` | Mecanismo gerador da sugestão (`REGRA` ou `IA`). | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | — | CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `versao_regra` | Identificador da versão da regra (`'REGRA-V1'` ou `'REGRA-V2'`). | `VARCHAR(16)` | 16 caracteres | — | — | NÃO | — | — | CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `temperatura_sugerida` | Temperatura calculada pela regra/modelo antes da revisão humana. | `VARCHAR(8)` | 8 caracteres | — | — | NÃO | — | — | CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `pontuacao` | Pontuação total obtida pela soma dos fatores em `classificacao_fator`. | `DECIMAL(6,2)` | (6,2) | — | — | NÃO | — | — | CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `temperatura_final` | Temperatura atribuída pelo revisor humano (quando revisada). | `VARCHAR(8)` | 8 caracteres | — | — | SIM | — | — | CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `id_revisor` | Funcionário que revisou a sugestão de classificação. | `BIGINT` | 8 bytes | — | fk_classificacao_lead_id_revisor -> funcionario(id_funcionario) | SIM | — | — | FK: fk_classificacao_lead_id_revisor -> funcionario(id_funcionario); CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `data_revisao` | Data e hora da revisão humana da classificação. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |
| `classificacao_lead` | `justificativa_revisao` | Fundamentação registrada pelo revisor humano, obrigatória ao divergir da sugestão. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_classificacao_justificativa, ck_classificacao_origem, ck_classificacao_pontuacao, ck_classificacao_revisao, ck_classificacao_temp_final, ck_classificacao_temp_sugerida |

## 2. Tabela `despesa`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `despesa` | `id_despesa` | Identificador único da despesa veicular. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_despesa_categoria, ck_despesa_descricao, ck_despesa_valor |
| `despesa` | `id_veiculo` | Veículo que originou a despesa. | `BIGINT` | 8 bytes | — | fk_despesa_id_veiculo -> veiculo(id_veiculo) | NÃO | — | — | FK: fk_despesa_id_veiculo -> veiculo(id_veiculo); CHECK: ck_despesa_categoria, ck_despesa_descricao, ck_despesa_valor |
| `despesa` | `data` | Data de ocorrência do custo/serviço no veículo. | `DATE` | 3 bytes | — | — | NÃO | — | — | CHECK: ck_despesa_categoria, ck_despesa_descricao, ck_despesa_valor |
| `despesa` | `categoria` | Classificação gerencial do custo veicular. | `VARCHAR(11)` | 11 caracteres | — | — | NÃO | — | — | CHECK: ck_despesa_categoria, ck_despesa_descricao, ck_despesa_valor |
| `despesa` | `descricao` | Especificação do item ou serviço (ex.: `Bateria e instalacao`, `Higienizacao`). | `TEXT` | até 65.535 caracteres | — | — | NÃO | — | — | CHECK: ck_despesa_categoria, ck_despesa_descricao, ck_despesa_valor |
| `despesa` | `valor` | Valor monetário do custo imputado ao veículo. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | — | CHECK: ck_despesa_categoria, ck_despesa_descricao, ck_despesa_valor |

## 2. Tabela `entrada`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `entrada` | `id_entrada` | Identificador único do ciclo de entrada no estoque. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `id_veiculo` | Veículo objeto da entrada. | `BIGINT` | 8 bytes | — | fk_entrada_id_veiculo -> veiculo(id_veiculo) | NÃO | — | — | FK: fk_entrada_id_veiculo -> veiculo(id_veiculo); CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `id_contraparte` | Proprietário vendedor, consignante ou comprador que entregou o carro em troca. | `BIGINT` | 8 bytes | — | fk_entrada_id_contraparte -> pessoa(id_pessoa) | NÃO | — | — | FK: fk_entrada_id_contraparte -> pessoa(id_pessoa); CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `id_avaliacao` | Avaliação técnica aprovada que fundamenta esta entrada. | `BIGINT` | 8 bytes | — | fk_entrada_id_avaliacao -> avaliacao(id_avaliacao) | NÃO | id_avaliacao | — | FK: fk_entrada_id_avaliacao -> avaliacao(id_avaliacao); UNIQUE: id_avaliacao; CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `id_venda_origem` | Venda na qual este veículo foi recebido como parte de pagamento (troca). | `BIGINT` | 8 bytes | — | fk_entrada_venda_origem -> venda(id_venda) | SIM | — | — | FK: fk_entrada_venda_origem -> venda(id_venda); CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `id_entrada_anterior` | Entrada anterior do mesmo veículo encerrada por desfazimento de venda. | `BIGINT` | 8 bytes | — | fk_entrada_id_entrada_anterior -> entrada(id_entrada) | SIM | id_entrada_anterior | — | FK: fk_entrada_id_entrada_anterior -> entrada(id_entrada); UNIQUE: id_entrada_anterior; CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `modalidade` | Via de incorporação do veículo ao estoque. | `VARCHAR(14)` | 14 caracteres | — | — | NÃO | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `data_entrada` | Data e hora da aceitação operacional no estoque. | `DATETIME` | 5 bytes | — | — | NÃO | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `situacao` | Estado operacional do ciclo de entrada. | `VARCHAR(18)` | 18 caracteres | — | — | NÃO | — | `ATIVA` | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `data_encerramento` | Data e hora em que o ciclo de entrada foi encerrado. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `motivo_encerramento` | Causa do encerramento (`VENDA_CONCLUIDA`, `DESFAZIMENTO`, `DEVOLUCAO_TROCA`, `RETIRADA`). | `VARCHAR(32)` | 32 caracteres | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `data_regularizacao` | Data/hora de conclusão da regularização documental/física de veículo reintegrado pós-distrato. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `observacoes_regularizacao` | Detalhamento da conferência de regularização após desfazimento. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `valor_acordado` | Custo de aquisição (compra), valor base combinado (consignação) ou valor aceito na troca. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `preco_anunciado` | Preço pedido para comercialização do veículo neste ciclo de entrada. | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `numero_contrato` | Número/identificador do contrato de compra própria ou consignação. | `VARCHAR(40)` | 40 caracteres | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `data_emissao` | Data de emissão/assinatura do contrato de entrada. | `DATE` | 3 bytes | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `termos_ajustes` | Cláusulas e condições contratuais específicas da entrada. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `reconhecimento_firma` | Situação do reconhecimento de firma no contrato de entrada (ex.: `'REALIZADO'`). | `VARCHAR(12)` | 12 caracteres | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `prazo_consignacao` | Data limite de vigência da consignação, quando excepcionalmente estipulada. | `DATE` | 3 bytes | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `valor_repasse_acordado` | Valor líquido contratado para repasse ao proprietário consignante após a venda. | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `prazo_repasse` | Prazo contratual para pagamento do repasse ao consignante. | `VARCHAR(50)` | 50 caracteres | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `criterio_repasse` | Regra/forma pactuada para liquidação do repasse ao consignante. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `data_devolucao` | Data e hora da devolução ao comprador de veículo recebido em troca, em caso de venda desfeita. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores |
| `entrada` | `veiculo_vigente` | Coluna gerada: repete `id_veiculo` enquanto a entrada não foi encerrada e fica nula depois; com o índice UNIQUE, impede duas entradas vigentes do mesmo veículo (RN13). | `BIGINT` | 8 bytes | — | — | SIM | uq_entrada_veiculo_vigente | GENERATED | UNIQUE: uq_entrada_veiculo_vigente; CHECK: ck_entrada_consignacao, ck_entrada_datas, ck_entrada_devolucao, ck_entrada_encerramento, ck_entrada_modalidade, ck_entrada_origem, ck_entrada_preco, ck_entrada_regularizacao, ck_entrada_situacao, ck_entrada_valores; coluna gerada |

## 2. Tabela `forma_pagamento`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `forma_pagamento` | `codigo` | Código identificador da forma de pagamento (ex.: `PIX`, `FINANCIAMENTO`). | `VARCHAR(20)` | 20 caracteres | SIM | — | NÃO | PRIMARY | — | PRIMARY KEY |
| `forma_pagamento` | `descricao` | Nome descritivo da forma de pagamento. | `VARCHAR(40)` | 40 caracteres | — | — | NÃO | descricao | — | UNIQUE: descricao |

## 2. Tabela `funcionario`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `funcionario` | `id_funcionario` | Identificador único do vínculo funcional. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_funcionario_cargo, ck_funcionario_situacao |
| `funcionario` | `id_pessoa` | Pessoa correspondente ao colaborador. | `BIGINT` | 8 bytes | — | fk_funcionario_id_pessoa -> pessoa(id_pessoa) | NÃO | id_pessoa | — | FK: fk_funcionario_id_pessoa -> pessoa(id_pessoa); UNIQUE: id_pessoa; CHECK: ck_funcionario_cargo, ck_funcionario_situacao |
| `funcionario` | `cargo` | Função exercida na loja (ex.: `Vendas`, `Administrativo`). | `VARCHAR(80)` | 80 caracteres | — | — | NÃO | — | — | CHECK: ck_funcionario_cargo, ck_funcionario_situacao |
| `funcionario` | `data_admissao` | Data de início do vínculo funcional na empresa. | `DATE` | 3 bytes | — | — | NÃO | — | — | CHECK: ck_funcionario_cargo, ck_funcionario_situacao |
| `funcionario` | `situacao` | Estado atual do vínculo funcional. | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | — | CHECK: ck_funcionario_cargo, ck_funcionario_situacao |

## 2. Tabela `intencao_compra`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `intencao_compra` | `id_atendimento` | Atendimento ao qual pertence a intenção de compra. | `BIGINT` | 8 bytes | SIM | fk_intencao_atendimento -> atendimento(id_atendimento) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_intencao_atendimento -> atendimento(id_atendimento); CHECK: ck_intencao_conteudo, ck_intencao_origem, ck_intencao_valor |
| `intencao_compra` | `id_entrada` | Veículo de estoque pretendido, quando já escolhido. | `BIGINT` | 8 bytes | — | fk_intencao_entrada -> entrada(id_entrada) | SIM | — | — | FK: fk_intencao_entrada -> entrada(id_entrada); CHECK: ck_intencao_conteudo, ck_intencao_origem, ck_intencao_valor |
| `intencao_compra` | `valor_disponivel` | Valor que o cliente declara disponível para pagamento, sem incluir eventual troca. | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | — | CHECK: ck_intencao_conteudo, ck_intencao_origem, ck_intencao_valor |
| `intencao_compra` | `codigo_forma` | Forma de pagamento pretendida, quando informada. | `VARCHAR(20)` | 20 caracteres | — | fk_intencao_forma -> forma_pagamento(codigo) | SIM | — | — | FK: fk_intencao_forma -> forma_pagamento(codigo); CHECK: ck_intencao_conteudo, ck_intencao_origem, ck_intencao_valor |
| `intencao_compra` | `data_registro` | Data e hora em que a intenção foi registrada. | `DATETIME` | 5 bytes | — | — | NÃO | — | — | CHECK: ck_intencao_conteudo, ck_intencao_origem, ck_intencao_valor |
| `intencao_compra` | `origem` | Canal de registro da intenção. | `VARCHAR(20)` | 20 caracteres | — | — | NÃO | — | — | CHECK: ck_intencao_conteudo, ck_intencao_origem, ck_intencao_valor |

## 2. Tabela `interacao`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `interacao` | `id_interacao` | Identificador único do registro de interação comercial. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |
| `interacao` | `id_atendimento` | Atendimento comercial ao qual o contato pertence. | `BIGINT` | 8 bytes | — | fk_interacao_id_atendimento -> atendimento(id_atendimento) | NÃO | — | — | FK: fk_interacao_id_atendimento -> atendimento(id_atendimento); CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |
| `interacao` | `id_funcionario` | Funcionário que realizou ou registrou a interação. | `BIGINT` | 8 bytes | — | fk_interacao_id_funcionario -> funcionario(id_funcionario) | NÃO | — | — | FK: fk_interacao_id_funcionario -> funcionario(id_funcionario); CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |
| `interacao` | `data_hora` | Data e hora da ocorrência do contato. | `DATETIME` | 5 bytes | — | — | NÃO | — | `CURRENT_TIMESTAMP` | CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |
| `interacao` | `canal` | Meio de comunicação utilizado no contato. | `VARCHAR(16)` | 16 caracteres | — | — | NÃO | — | — | CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |
| `interacao` | `direcao` | Sentido da comunicação (`RECEBIDA` do cliente ou `ENVIADA` pela loja). | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | — | CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |
| `interacao` | `resumo` | Síntese objetiva do conteúdo comercial tratado na interação. | `TEXT` | até 65.535 caracteres | — | — | NÃO | — | — | CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |
| `interacao` | `proximo_passo` | Ação comercial combinada para sequência do atendimento, quando houver. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |
| `interacao` | `data_proximo_passo` | Data e hora agendada para o próximo passo comercial. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_interacao_canal, ck_interacao_direcao, ck_interacao_proximo_passo, ck_interacao_resumo |

## 2. Tabela `laudo`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `laudo` | `id_laudo` | Identificador único do laudo cautelar. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_laudo_emissao, ck_laudo_referencia, ck_laudo_situacao |
| `laudo` | `id_veiculo` | Veículo ao qual o laudo cautelar pertence. | `BIGINT` | 8 bytes | — | fk_laudo_id_veiculo -> veiculo(id_veiculo) | NÃO | — | — | FK: fk_laudo_id_veiculo -> veiculo(id_veiculo); CHECK: ck_laudo_emissao, ck_laudo_referencia, ck_laudo_situacao |
| `laudo` | `referencia_documental` | Código ou protocolo externo para localização do documento. | `VARCHAR(80)` | 80 caracteres | — | — | NÃO | — | — | CHECK: ck_laudo_emissao, ck_laudo_referencia, ck_laudo_situacao |
| `laudo` | `data_emissao` | Data de emissão do laudo cautelar; nula enquanto PENDENTE e obrigatória quando EMITIDO. | `DATE` | 3 bytes | — | — | SIM | — | — | CHECK: ck_laudo_emissao, ck_laudo_referencia, ck_laudo_situacao |
| `laudo` | `situacao` | Situação documental do laudo. | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | — | CHECK: ck_laudo_emissao, ck_laudo_referencia, ck_laudo_situacao |
| `laudo` | `resultado` | Síntese dos apontamentos e conclusões cautelares; nula enquanto PENDENTE e obrigatória, sem texto vazio, quando EMITIDO. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_laudo_emissao, ck_laudo_referencia, ck_laudo_situacao |

## 2. Tabela `obrigacao_financeira`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `obrigacao_financeira` | `id_obrigacao` | Identificador único da obrigação financeira. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `natureza` | Direção financeira da obrigação (`RECEBER` ou `PAGAR`). | `VARCHAR(8)` | 8 caracteres | — | — | NÃO | — | — | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `origem` | Fato gerador da obrigação (`VENDA`, `ENTRADA`, `DESPESA_VEICULO`, `ADMINISTRATIVA`). | `VARCHAR(16)` | 16 caracteres | — | — | NÃO | — | — | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `id_venda` | Venda associada quando `origem = 'VENDA'`. | `BIGINT` | 8 bytes | — | fk_obrigacao_financeira_id_venda -> venda(id_venda) | SIM | — | — | FK: fk_obrigacao_financeira_id_venda -> venda(id_venda); CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `id_entrada` | Entrada associada quando `origem = 'ENTRADA'`. | `BIGINT` | 8 bytes | — | fk_obrigacao_financeira_id_entrada -> entrada(id_entrada) | SIM | — | — | FK: fk_obrigacao_financeira_id_entrada -> entrada(id_entrada); CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `id_despesa` | Despesa veicular associada quando `origem = 'DESPESA_VEICULO'`. | `BIGINT` | 8 bytes | — | fk_obrigacao_financeira_id_despesa -> despesa(id_despesa) | SIM | — | — | FK: fk_obrigacao_financeira_id_despesa -> despesa(id_despesa); CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `categoria` | Classificação operacional da obrigação (ex.: `'FINANCIAMENTO'`, `'REPASSE'`, `'ALUGUEL'`). | `VARCHAR(40)` | 40 caracteres | — | — | NÃO | — | — | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `contraparte` | Nome do banco, consignante, fornecedor ou credor/devedor. | `VARCHAR(150)` | 150 caracteres | — | — | NÃO | — | — | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `valor` | Valor monetário nominal da obrigação financeira. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | — | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `data_competencia` | Data do fato gerador (competência) da obrigação. | `DATE` | 3 bytes | — | — | NÃO | — | — | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `vencimento_original` | Data de vencimento originalmente prevista ou contratada. | `DATE` | 3 bytes | — | — | NÃO | — | — | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `vencimento_atual` | Data de vencimento vigente (atualizável em reprogramações/prorrogações). | `DATE` | 3 bytes | — | — | NÃO | — | — | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `situacao` | Estado atual de liquidação da obrigação financeira. | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | `PREVISTA` | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |
| `obrigacao_financeira` | `origem_estimativa` | Grau de certeza do vencimento/valor (`FATO`, `HIPOTESE` ou `SIMULADO`). | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | `FATO` | CHECK: ck_obrigacao_arco, ck_obrigacao_datas, ck_obrigacao_estimativa, ck_obrigacao_natureza, ck_obrigacao_origem, ck_obrigacao_situacao, ck_obrigacao_textos, ck_obrigacao_valores |

## 2. Tabela `ocorrencia_garantia`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `ocorrencia_garantia` | `id_ocorrencia` | Identificador único da ocorrência de garantia. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `id_venda` | Venda entregue à qual a reclamação de garantia se refere. | `BIGINT` | 8 bytes | — | fk_ocorrencia_garantia_id_venda -> venda(id_venda) | NÃO | — | — | FK: fk_ocorrencia_garantia_id_venda -> venda(id_venda); CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `id_mecanico` | Mecânico/especialista principal designado para análise e reparo. | `BIGINT` | 8 bytes | — | fk_ocorrencia_garantia_id_mecanico -> pessoa(id_pessoa) | SIM | — | — | FK: fk_ocorrencia_garantia_id_mecanico -> pessoa(id_pessoa); CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `data_abertura` | Data e hora de abertura do chamado de garantia. | `DATETIME` | 5 bytes | — | — | NÃO | — | — | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `problema_relatado` | Sintoma ou defeito descrito pelo cliente no momento da abertura. | `TEXT` | até 65.535 caracteres | — | — | NÃO | — | — | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `atendimento_externo_informado` | Registro sobre encaminhamento prévio do veículo a mecânico externo não autorizado. | `VARCHAR(14)` | 14 caracteres | — | — | NÃO | — | `NAO_INFORMADO` | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `diagnostico` | Parecer técnico elaborado pelo mecânico da loja após inspeção. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `responsabilidade_apurada` | Conclusão sobre responsabilidade após análise técnica. | `VARCHAR(12)` | 12 caracteres | — | — | SIM | — | — | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `servico_realizado` | Descrição do reparo ou substituição de peças executada na oficina parceira. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `solucao` | Desfecho acordado com o cliente ou encaminhamento para desfazimento da venda. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `situacao` | Estado operacional da ocorrência de garantia. | `VARCHAR(16)` | 16 caracteres | — | — | NÃO | — | — | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |
| `ocorrencia_garantia` | `data_encerramento` | Data e hora de conclusão do atendimento de garantia. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_ocorrencia_encerramento, ck_ocorrencia_externo, ck_ocorrencia_problema, ck_ocorrencia_responsabilidade, ck_ocorrencia_situacao |

## 2. Tabela `parametro_prazo`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `parametro_prazo` | `banco` | Nome da instituição financeira ou contraparte padrão do parâmetro. | `VARCHAR(100)` | 100 caracteres | SIM | — | NÃO | PRIMARY | — | PRIMARY KEY; CHECK: ck_parametro_prazo_banco, ck_parametro_prazo_dias, ck_parametro_prazo_origem, ck_parametro_prazo_tipo |
| `parametro_prazo` | `tipo_obrigacao` | Espécie de evento temporal parametrizado. | `VARCHAR(32)` | 32 caracteres | SIM | — | NÃO | PRIMARY | — | PRIMARY KEY; CHECK: ck_parametro_prazo_banco, ck_parametro_prazo_dias, ck_parametro_prazo_origem, ck_parametro_prazo_tipo |
| `parametro_prazo` | `dias_previstos` | Quantidade de dias corridos prevista para liquidação. | `INT` | 4 bytes | — | — | NÃO | — | — | CHECK: ck_parametro_prazo_banco, ck_parametro_prazo_dias, ck_parametro_prazo_origem, ck_parametro_prazo_tipo |
| `parametro_prazo` | `origem` | Classificação metodológica do prazo (`HIPOTESE` ou `CALIBRADA`). | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | `HIPOTESE` | CHECK: ck_parametro_prazo_banco, ck_parametro_prazo_dias, ck_parametro_prazo_origem, ck_parametro_prazo_tipo |
| `parametro_prazo` | `vigencia` | Data de início de vigência do parâmetro de prazo. | `DATE` | 3 bytes | SIM | — | NÃO | PRIMARY | `CURDATE()` | PRIMARY KEY; CHECK: ck_parametro_prazo_banco, ck_parametro_prazo_dias, ck_parametro_prazo_origem, ck_parametro_prazo_tipo |

## 2. Tabela `parametro_referencia`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `parametro_referencia` | `chave` | Trava booleana que restringe a tabela a uma única linha (`true`). | `TINYINT(1)` | 1 byte | SIM | — | NÃO | PRIMARY | `1` | PRIMARY KEY; CHECK: ck_parametro_referencia_chave, ck_parametro_referencia_origem |
| `parametro_referencia` | `data_referencia` | Data de referência ativa da extensão (`2026-02-10` na massa de demonstração). | `DATE` | 3 bytes | — | — | NÃO | — | — | CHECK: ck_parametro_referencia_chave, ck_parametro_referencia_origem |
| `parametro_referencia` | `origem` | Natureza da data configurada (`DEMONSTRACAO` ou `OPERACAO`). | `VARCHAR(12)` | 12 caracteres | — | — | NÃO | — | — | CHECK: ck_parametro_referencia_chave, ck_parametro_referencia_origem |

## 2. Tabela `parametro_retorno`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `parametro_retorno` | `instituicao` | Nome da instituição financeira à qual a tabela de retorno pertence. | `VARCHAR(100)` | 100 caracteres | SIM | — | NÃO | PRIMARY | — | PRIMARY KEY; CHECK: ck_parametro_retorno_acrescimo, ck_parametro_retorno_instituicao, ck_parametro_retorno_origem, ck_parametro_retorno_pct, ck_parametro_retorno_tabela |
| `parametro_retorno` | `tabela_retorno` | Código da faixa de retorno bancário (`R0` sem retorno até `R5`). | `VARCHAR(2)` | 2 caracteres | SIM | — | NÃO | PRIMARY | — | PRIMARY KEY; CHECK: ck_parametro_retorno_acrescimo, ck_parametro_retorno_instituicao, ck_parametro_retorno_origem, ck_parametro_retorno_pct, ck_parametro_retorno_tabela |
| `parametro_retorno` | `acrescimo_taxa_mensal` | Acréscimo mensal somado à `taxa_mensal` base na simulação do cliente. | `DECIMAL(8,6)` | (8,6) | — | — | NÃO | — | `0.000000` | CHECK: ck_parametro_retorno_acrescimo, ck_parametro_retorno_instituicao, ck_parametro_retorno_origem, ck_parametro_retorno_pct, ck_parametro_retorno_tabela |
| `parametro_retorno` | `retorno_pct` | Percentual sobre `valor_financiado` pago pelo banco à loja (`0` a `0.10`). | `DECIMAL(5,4)` | (5,4) | — | — | NÃO | — | `0.0000` | CHECK: ck_parametro_retorno_acrescimo, ck_parametro_retorno_instituicao, ck_parametro_retorno_origem, ck_parametro_retorno_pct, ck_parametro_retorno_tabela |
| `parametro_retorno` | `origem` | Classificação metodológica do parâmetro (`HIPOTESE` ou `CALIBRADA`). | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | `HIPOTESE` | CHECK: ck_parametro_retorno_acrescimo, ck_parametro_retorno_instituicao, ck_parametro_retorno_origem, ck_parametro_retorno_pct, ck_parametro_retorno_tabela |
| `parametro_retorno` | `vigencia` | Data de início de vigência da tabela de retorno para a instituição. | `DATE` | 3 bytes | SIM | — | NÃO | PRIMARY | `CURDATE()` | PRIMARY KEY; CHECK: ck_parametro_retorno_acrescimo, ck_parametro_retorno_instituicao, ck_parametro_retorno_origem, ck_parametro_retorno_pct, ck_parametro_retorno_tabela |

## 2. Tabela `parametro_temperatura`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `parametro_temperatura` | `temperatura` | Faixa de temperatura do lead (`FRIO`, `MORNO` ou `QUENTE`). | `VARCHAR(8)` | 8 caracteres | SIM | — | NÃO | PRIMARY | — | PRIMARY KEY; CHECK: ck_parametro_origem, ck_parametro_probabilidade, ck_parametro_temperatura |
| `parametro_temperatura` | `probabilidade` | Peso probabilístico de conversão (`0.0000` a `1.0000`) aplicado ao funil de caixa. | `DECIMAL(5,4)` | (5,4) | — | — | NÃO | — | — | CHECK: ck_parametro_origem, ck_parametro_probabilidade, ck_parametro_temperatura |
| `parametro_temperatura` | `origem` | Classificação metodológica da probabilidade (`HIPOTESE` ou `CALIBRADA`). | `VARCHAR(10)` | 10 caracteres | — | — | NÃO | — | — | CHECK: ck_parametro_origem, ck_parametro_probabilidade, ck_parametro_temperatura |
| `parametro_temperatura` | `vigencia` | Data de início de validade do parâmetro. | `DATE` | 3 bytes | — | — | NÃO | — | — | CHECK: ck_parametro_origem, ck_parametro_probabilidade, ck_parametro_temperatura |

## 2. Tabela `pessoa`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `pessoa` | `id_pessoa` | Identificador único substituto da pessoa. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `nome` | Nome completo (PF) ou razão social (PJ). | `VARCHAR(150)` | 150 caracteres | — | — | NÃO | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `tipo_documento` | Espécie do documento fiscal/civil (`CPF` ou `CNPJ`). | `VARCHAR(4)` | 4 caracteres | — | — | NÃO | uq_pessoa_documento (tipo_documento, numero_documento) | — | UNIQUE: uq_pessoa_documento (tipo_documento, numero_documento); CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `numero_documento` | Número do CPF (11 dígitos) ou CNPJ (14 dígitos), sem máscara. | `VARCHAR(14)` | 14 caracteres | — | — | NÃO | uq_pessoa_documento (tipo_documento, numero_documento) | — | UNIQUE: uq_pessoa_documento (tipo_documento, numero_documento); CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `telefone` | Telefone principal de contato. | `VARCHAR(20)` | 20 caracteres | — | — | NÃO | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `email` | Endereço eletrônico; opcional no primeiro contato e exigido quando a pessoa assina contrato (gatilhos `*_contrato_*`, RO02). | `VARCHAR(254)` | 254 caracteres | — | — | SIM | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `logradouro` | Rua, avenida ou via pública; o endereço é informado completo ou não informado (ck_pessoa_endereco) e é exigido no contrato. | `VARCHAR(150)` | 150 caracteres | — | — | SIM | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `numero` | Número predial do endereço (ou `"S/N"`). | `VARCHAR(10)` | 10 caracteres | — | — | SIM | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `complemento` | Complemento do endereço (apartamento, bloco, sala). | `VARCHAR(60)` | 60 caracteres | — | — | SIM | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `bairro` | Bairro do endereço da pessoa. | `VARCHAR(80)` | 80 caracteres | — | — | SIM | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `cidade` | Município de domicílio ou sede. | `VARCHAR(80)` | 80 caracteres | — | — | SIM | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `estado_uf` | Sigla de uma das 27 Unidades Federativas, em maiúsculas (ex.: `SP`); lista fechada em ck_pessoa_uf. | `CHAR(2)` | 2 caracteres | — | — | SIM | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |
| `pessoa` | `possui_cnh` | Declaração sobre possuir CNH (pertinente na compra/crédito); 0 ou 1, e NULL quando não informada. | `TINYINT(1)` | 1 byte | — | — | SIM | — | — | CHECK: ck_pessoa_cnh, ck_pessoa_documento, ck_pessoa_email, ck_pessoa_endereco, ck_pessoa_nome, ck_pessoa_textos, ck_pessoa_uf |

## 2. Tabela `proposta`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `proposta` | `id_proposta` | Identificador único substituto da proposta comercial. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `id_atendimento` | Atendimento comercial em que a proposta foi formulada. | `BIGINT` | 8 bytes | — | fk_proposta_id_atendimento -> atendimento(id_atendimento) | NÃO | uq_proposta_alternativa_versao (id_atendimento, id_entrada, rotulo, versao) | — | FK: fk_proposta_id_atendimento -> atendimento(id_atendimento); UNIQUE: uq_proposta_alternativa_versao (id_atendimento, id_entrada, rotulo, versao); CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `id_entrada` | Ciclo de entrada do veículo de estoque ofertado na proposta. | `BIGINT` | 8 bytes | — | fk_proposta_id_entrada -> entrada(id_entrada) | NÃO | uq_proposta_alternativa_versao (id_atendimento, id_entrada, rotulo, versao) | — | FK: fk_proposta_id_entrada -> entrada(id_entrada); UNIQUE: uq_proposta_alternativa_versao (id_atendimento, id_entrada, rotulo, versao); CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `id_funcionario` | Funcionário responsável pela emissão da proposta. | `BIGINT` | 8 bytes | — | fk_proposta_id_funcionario -> funcionario(id_funcionario) | NÃO | — | — | FK: fk_proposta_id_funcionario -> funcionario(id_funcionario); CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `id_proposta_anterior` | Proposta imediatamente anterior da mesma alternativa substituída por contraproposta. | `BIGINT` | 8 bytes | — | fk_proposta_id_proposta_anterior -> proposta(id_proposta) | SIM | id_proposta_anterior | — | FK: fk_proposta_id_proposta_anterior -> proposta(id_proposta); UNIQUE: id_proposta_anterior; CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `rotulo` | Identificador da alternativa comercial dentro da mesma negociação (ex.: `'A'`, `'B'`, `'C'`). | `VARCHAR(1)` | 1 caracteres | — | — | NÃO | uq_proposta_alternativa_versao (id_atendimento, id_entrada, rotulo, versao) | — | UNIQUE: uq_proposta_alternativa_versao (id_atendimento, id_entrada, rotulo, versao); CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `versao` | Número sequencial da versão dentro do mesmo `(id_atendimento, id_entrada, rotulo)`. | `INT` | 4 bytes | — | — | NÃO | uq_proposta_alternativa_versao (id_atendimento, id_entrada, rotulo, versao) | — | UNIQUE: uq_proposta_alternativa_versao (id_atendimento, id_entrada, rotulo, versao); CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `data_criacao` | Data de criação da proposta comercial. | `DATE` | 3 bytes | — | — | NÃO | — | `CURDATE()` | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `validade` | Data limite de validade comercial da proposta. | `DATE` | 3 bytes | — | — | NÃO | — | `(CURDATE() + INTERVAL 7 DAY)` | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `valor_base` | Preço base negociado na proposta antes de descontos, acréscimos e taxas. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | — | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `desconto` | Desconto comercial concedido na proposta. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | `0.00` | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `acrescimo` | Acréscimo comercial aplicado na proposta. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | `0.00` | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `taxas` | Total de taxas previstas na proposta. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | `0.00` | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `valor_total` | Valor final da proposta (`valor_base - desconto + acrescimo + taxas`). | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | GENERATED | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao; coluna gerada |
| `proposta` | `id_entrada_aceita` | Entrada vinculada quando a proposta está aceita; nulo nos demais estados. | `BIGINT` | 8 bytes | — | — | SIM | uq_proposta_aceita_entrada | GENERATED | UNIQUE: uq_proposta_aceita_entrada; CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao; coluna gerada |
| `proposta` | `situacao` | Estado do ciclo de vida da proposta comercial. | `VARCHAR(12)` | 12 caracteres | — | — | NÃO | — | `RASCUNHO` | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `data_decisao` | Data e hora do aceite, recusa, expiração ou substituição da proposta. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |
| `proposta` | `motivo_recusa` | Justificativa da recusa (informada pelo cliente ou gerada no aceite de alternativa irmã). | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_proposta_data_decisao, ck_proposta_datas, ck_proposta_raiz_versao, ck_proposta_recusa, ck_proposta_rotulo, ck_proposta_situacao, ck_proposta_valores, ck_proposta_versao |

## 2. Tabela `proposta_condicao`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `proposta_condicao` | `id_proposta` | Proposta comercial à qual a condição pertence. | `BIGINT` | 8 bytes | SIM | fk_proposta_condicao_id_proposta -> proposta(id_proposta) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_proposta_condicao_id_proposta -> proposta(id_proposta); CHECK: ck_proposta_condicao_prazo, ck_proposta_condicao_valor |
| `proposta_condicao` | `codigo_forma` | Código da modalidade de pagamento no catálogo `forma_pagamento`. | `VARCHAR(20)` | 20 caracteres | SIM | fk_proposta_condicao_codigo_forma -> forma_pagamento(codigo) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_proposta_condicao_codigo_forma -> forma_pagamento(codigo); CHECK: ck_proposta_condicao_prazo, ck_proposta_condicao_valor |
| `proposta_condicao` | `valor` | Montante alocado a esta forma de pagamento na proposta. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | — | CHECK: ck_proposta_condicao_prazo, ck_proposta_condicao_valor |
| `proposta_condicao` | `prazo_previsto_dias` | Prazo estimado em dias corridos para conversão em caixa (`0` para `D+0`). | `INT` | 4 bytes | — | — | NÃO | — | `0` | CHECK: ck_proposta_condicao_prazo, ck_proposta_condicao_valor |

## 2. Tabela `proposta_troca`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `proposta_troca` | `id_proposta` | Proposta comercial que inclui o veículo de troca. | `BIGINT` | 8 bytes | SIM | fk_proposta_troca_id_proposta -> proposta(id_proposta) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_proposta_troca_id_proposta -> proposta(id_proposta); CHECK: ck_proposta_troca_valor |
| `proposta_troca` | `id_avaliacao` | Avaliação técnica aprovada do veículo oferecido em troca. | `BIGINT` | 8 bytes | SIM | fk_proposta_troca_id_avaliacao -> avaliacao(id_avaliacao) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_proposta_troca_id_avaliacao -> avaliacao(id_avaliacao); CHECK: ck_proposta_troca_valor |
| `proposta_troca` | `valor_oferecido` | Valor atribuído ao veículo de troca para abatimento na proposta. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | — | CHECK: ck_proposta_troca_valor |

## 2. Tabela `simulacao_financiamento`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `simulacao_financiamento` | `id_simulacao` | Identificador único da simulação de financiamento. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `id_proposta` | Proposta comercial à qual a simulação está vinculada. | `BIGINT` | 8 bytes | — | fk_simulacao_financiamento_id_proposta -> proposta(id_proposta) | NÃO | — | — | FK: fk_simulacao_financiamento_id_proposta -> proposta(id_proposta); CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `instituicao` | Nome do banco/financeira da cotação. | `VARCHAR(100)` | 100 caracteres | — | — | NÃO | — | — | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `tabela_retorno` | Faixa de retorno bancário aplicada na simulação (`R0` a `R5`). | `VARCHAR(2)` | 2 caracteres | — | — | NÃO | — | `R0` | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `origem` | Origem dos parâmetros da simulação (`ACADEMICA`, `INFORMADA_BANCO`, `INTEGRACAO`). | `VARCHAR(16)` | 16 caracteres | — | — | NÃO | — | — | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `valor_financiado` | Montante financiado cotado na simulação. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | — | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `taxa_mensal` | Taxa mensal base de juros do banco (antes do acréscimo de `tabela_retorno`). | `DECIMAL(8,6)` | (8,6) | — | — | NÃO | — | — | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `prazo_meses` | Quantidade de parcelas mensais da simulação. | `SMALLINT` | 2 bytes | — | — | NÃO | — | — | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `parcela_informada` | Valor da prestação informado externamente pelo banco, quando houver. | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | — | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `renda_declarada` | Renda mensal declarada pelo cliente para análise de comprometimento. | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | — | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `consentimento_renda` | Registro de consentimento expresso do titular para uso da renda declarada (LGPD). | `TINYINT(1)` | 1 byte | — | — | NÃO | — | `0` | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `situacao` | Estado da análise da simulação de financiamento. | `VARCHAR(12)` | 12 caracteres | — | — | NÃO | — | `EM_ANALISE` | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `id_proposta_aprovada` | Coluna gerada: repete `id_proposta` quando a simulação está APROVADA e fica nula nos demais estados; com o índice UNIQUE, permite uma única simulação aprovada por proposta. | `BIGINT` | 8 bytes | — | — | SIM | uq_simulacao_aprovada_proposta | GENERATED | UNIQUE: uq_simulacao_aprovada_proposta; CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores; coluna gerada |
| `simulacao_financiamento` | `data_simulacao` | Data e hora de realização da simulação. | `DATETIME` | 5 bytes | — | — | NÃO | — | `CURRENT_TIMESTAMP` | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |
| `simulacao_financiamento` | `data_resposta` | Data e hora do retorno da análise da simulação. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_simulacao_consentimento_dominio, ck_simulacao_consentimento_renda, ck_simulacao_datas, ck_simulacao_instituicao, ck_simulacao_origem, ck_simulacao_situacao, ck_simulacao_tabela_retorno, ck_simulacao_valores |

## 2. Tabela `veiculo`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `veiculo` | `id_veiculo` | Identificador único do veículo. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `marca` | Fabricante/marca do automóvel (ex.: `Fiat`, `Toyota`). | `VARCHAR(60)` | 60 caracteres | — | — | NÃO | — | — | CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `modelo` | Modelo comercial do veículo (ex.: `Argo`, `Corolla`). | `VARCHAR(80)` | 80 caracteres | — | — | NÃO | — | — | CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `ano_modelo` | Ano de referência do modelo (ex.: `2024`). | `SMALLINT` | 2 bytes | — | — | NÃO | — | — | CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `cor` | Cor predominante informada do veículo. | `VARCHAR(30)` | 30 caracteres | — | — | NÃO | — | — | CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `placa` | Placa de identificação veicular, quando disponível. | `VARCHAR(7)` | 7 caracteres | — | — | SIM | placa | — | UNIQUE: placa; CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `chassi` | Número do chassi (VIN), quando disponível. | `VARCHAR(17)` | 17 caracteres | — | — | SIM | chassi | — | UNIQUE: chassi; CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `combustivel` | Tipo de combustível (ex.: `Flex`, `Gasolina`, `Diesel`). | `VARCHAR(20)` | 20 caracteres | — | — | NÃO | — | — | CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `cambio` | Tipo de transmissão (`Manual` ou `Automatico`). | `VARCHAR(20)` | 20 caracteres | — | — | NÃO | — | — | CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |
| `veiculo` | `categoria_comercial` | Classificação comercial do automóvel na loja. | `VARCHAR(8)` | 8 caracteres | — | — | NÃO | — | — | CHECK: ck_veiculo_ano, ck_veiculo_categoria, ck_veiculo_textos |

## 2. Tabela `venda`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `venda` | `id_venda` | Identificador único da venda. | `BIGINT` | 8 bytes | SIM | — | NÃO | PRIMARY | AUTO_INCREMENT | PRIMARY KEY; CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `id_comprador` | Cliente comprador do veículo principal. | `BIGINT` | 8 bytes | — | fk_venda_id_comprador -> pessoa(id_pessoa) | NÃO | — | — | FK: fk_venda_id_comprador -> pessoa(id_pessoa); CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `id_funcionario` | Vendedor/funcionário responsável pela negociação. | `BIGINT` | 8 bytes | — | fk_venda_id_funcionario -> funcionario(id_funcionario) | NÃO | — | — | FK: fk_venda_id_funcionario -> funcionario(id_funcionario); CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `id_entrada_principal` | Ciclo de entrada do veículo principal que está sendo vendido. | `BIGINT` | 8 bytes | — | fk_venda_id_entrada_principal -> entrada(id_entrada) | NÃO | id_entrada_principal | — | FK: fk_venda_id_entrada_principal -> entrada(id_entrada); UNIQUE: id_entrada_principal; CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `id_laudo` | Laudo cautelar do veículo principal que documenta a venda. | `BIGINT` | 8 bytes | — | fk_venda_id_laudo -> laudo(id_laudo) | SIM | — | — | FK: fk_venda_id_laudo -> laudo(id_laudo); CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_registro` | Data e hora de abertura/aceite da proposta comercial. | `DATETIME` | 5 bytes | — | — | NÃO | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `situacao_comercial` | Estado comercial do ciclo da venda. | `VARCHAR(18)` | 18 caracteres | — | — | NÃO | — | `EM_FORMALIZACAO` | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_conclusao` | Data e hora da conclusão formal da venda (cumprimento da RN22). | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `valor_base` | Preço negociado do veículo antes de descontos, acréscimos e taxas. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `desconto` | Valor de desconto comercial concedido na negociação. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | `0.00` | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `acrescimo` | Valor de acréscimo comercial aplicado na operação. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | `0.00` | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `taxas` | Total de taxas e encargos discriminados no contrato. | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | `0.00` | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `valor_total` | Valor final do contrato (`valor_base - desconto + acrescimo + taxas`). | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | GENERATED | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores; coluna gerada |
| `venda` | `numero_contrato` | Identificador formal do contrato de compra e venda. | `VARCHAR(40)` | 40 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_emissao` | Data de emissão/assinatura do contrato de venda. | `DATE` | 3 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `termos_condicoes` | Cláusulas contratuais, discriminando encargos e veículos de troca aceitos. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `condicao_repasse` | Indica se o veículo foi vendido na condição de repasse (sem garantia de reparos). | `TINYINT(1)` | 1 byte | — | — | NÃO | — | `0` | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `valor_recebido` | Total monetário efetivamente recebido pela loja (inclui financiamento já creditado; exclui valor das trocas). | `DECIMAL(14,2)` | (14,2) | — | — | NÃO | — | `0.00` | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_ultimo_recebimento` | Data e hora da confirmação monetária mais recente. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `instituicao_financeira` | Nome do banco do único financiamento da venda, quando houver. | `VARCHAR(100)` | 100 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `valor_financiado` | Montante contratado via financiamento bancário. | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `situacao_financiamento` | Estado do financiamento perante a loja. | `VARCHAR(20)` | 20 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_aprovacao_financiamento` | Data/hora da aprovação de crédito pelo banco. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_recebimento_financiamento` | Data/hora do efetivo repasse bancário à conta da loja. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_scanner` | Data e hora da verificação eletrônica via scanner automotivo antes da entrega. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `resultado_scanner` | Resultado técnico da leitura do scanner pré-entrega. | `VARCHAR(100)` | 100 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `providencias_scanner` | Ajustes ou providências adotadas a partir do scanner. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `preparacao` | Descrição das atividades de preparação e higienização para entrega. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_entrega` | Data e hora da entrega física do veículo ao comprador (início da garantia). | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `concessao_garantia` | Indica se a venda possui concessão da garantia contratual de 2 meses. | `TINYINT(1)` | 1 byte | — | — | NÃO | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `termos_politica` | Condições declaradas da garantia (2 meses da entrega; perda em oficina externa). | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_cancelamento` | Data e hora da formalização do cancelamento/distrato da venda. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `motivo_cancelamento` | Razão declarada para o desfazimento da venda. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_retorno_veiculo` | Data e hora em que o veículo vendido retornou fisicamente ao pátio da loja. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `valor_restituido_loja` | Montante em dinheiro devolvido pela loja ao comprador no distrato. | `DECIMAL(14,2)` | (14,2) | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `data_aviso_consignante` | Data/hora de comunicação ao consignante para estorno de sua parte em venda consignada desfeita. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `orientacao_bancaria` | Registro da orientação e tratativa junto ao banco em venda financiada desfeita. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `observacoes_cancelamento` | Síntese geral das restituições, devoluções de troca e encerramento do distrato. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |
| `venda` | `id_proposta` | Proposta comercial aceita que deu origem à venda, quando houver. | `BIGINT` | 8 bytes | — | fk_venda_id_proposta -> proposta(id_proposta) | SIM | id_proposta | — | FK: fk_venda_id_proposta -> proposta(id_proposta); UNIQUE: id_proposta; CHECK: ck_venda_booleanos, ck_venda_cancelamento, ck_venda_conclusao, ck_venda_entrega, ck_venda_financiamento, ck_venda_formalizacao, ck_venda_garantia, ck_venda_marcos, ck_venda_recebimento, ck_venda_situacao, ck_venda_valores |

## 2. Tabela `venda_documento`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `venda_documento` | `id_venda` | Venda cujos documentos estão sendo conferidos. | `BIGINT` | 8 bytes | SIM | fk_venda_documento_id_venda -> venda(id_venda) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_venda_documento_id_venda -> venda(id_venda); CHECK: ck_documento_aplicavel, ck_documento_firma, ck_documento_tipo |
| `venda_documento` | `tipo_documento` | Espécie documental exigida na formalização da venda. | `VARCHAR(24)` | 24 caracteres | SIM | — | NÃO | PRIMARY | — | PRIMARY KEY; CHECK: ck_documento_aplicavel, ck_documento_firma, ck_documento_tipo |
| `venda_documento` | `data_conferencia` | Data e hora em que o documento foi apresentado e conferido pela loja. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_documento_aplicavel, ck_documento_firma, ck_documento_tipo |
| `venda_documento` | `reconhecimento_aplicavel` | Indica se o reconhecimento de firma em cartório é exigível para este documento. | `TINYINT(1)` | 1 byte | — | — | NÃO | — | — | CHECK: ck_documento_aplicavel, ck_documento_firma, ck_documento_tipo |
| `venda_documento` | `data_reconhecimento` | Data e hora da efetivação do reconhecimento de firma em cartório. | `DATETIME` | 5 bytes | — | — | SIM | — | — | CHECK: ck_documento_aplicavel, ck_documento_firma, ck_documento_tipo |
| `venda_documento` | `justificativa_dispensa` | Justificativa formal caso `ATPV` ou `CONTRATO` tenha `reconhecimento_aplicavel = false`. | `TEXT` | até 65.535 caracteres | — | — | SIM | — | — | CHECK: ck_documento_aplicavel, ck_documento_firma, ck_documento_tipo |

## 2. Tabela `venda_forma_pagamento`

| Tabela | Atributo | Descrição | Tipo | Tamanho | PK | FK | NULL | UNIQUE | DEFAULT | Regra / restrição |
|---|---|---|---|---|---|---|---|---|---|---|
| `venda_forma_pagamento` | `id_venda` | Venda à qual a forma de pagamento está associada. | `BIGINT` | 8 bytes | SIM | fk_venda_forma_pagamento_id_venda -> venda(id_venda) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_venda_forma_pagamento_id_venda -> venda(id_venda) |
| `venda_forma_pagamento` | `codigo_forma` | Forma de pagamento utilizada na venda. | `VARCHAR(20)` | 20 caracteres | SIM | fk_venda_forma_pagamento_codigo_forma -> forma_pagamento(codigo) | NÃO | PRIMARY | — | PRIMARY KEY; FK: fk_venda_forma_pagamento_codigo_forma -> forma_pagamento(codigo) |

## 3. Expressões das restrições CHECK

| Tabela | Restrição | Expressão registrada no MySQL |
|---|---|---|
| `atendimento` | `ck_atendimento_descricao` | `(trim(`descricao_interesse`) <> _utf8mb4\\'\\')` |
| `atendimento` | `ck_atendimento_interesse` | `(`tipo_interesse` in (_utf8mb4\\'COMPRA\\',_utf8mb4\\'VENDA\\',_utf8mb4\\'TROCA\\'))` |
| `atendimento` | `ck_atendimento_situacao` | `(`situacao` in (_utf8mb4\\'ABERTO\\',_utf8mb4\\'EM_NEGOCIACAO\\',_utf8mb4\\'CONVERTIDO\\',_utf8mb4\\'ENCERRADO\\'))` |
| `atendimento_desfecho` | `ck_desfecho_motivo` | `(trim(`motivo`) <> _utf8mb4\\'\\')` |
| `atendimento_desfecho` | `ck_desfecho_tipo` | `(`tipo_desfecho` in (_utf8mb4\\'GANHO\\',_utf8mb4\\'PERDA\\'))` |
| `avaliacao` | `ck_avaliacao_concluida` | `((`decisao_tecnica` = _utf8mb4\\'PENDENTE\\') or ((`condicao_externa` is not null) and (`condicao_interna` is not null) and (`condicao_mecanica` is not null) and (`condicao_estrutural` is not null) and (`condicao_documental` is not null) and (`justificativa` is not null) and (trim(`justificativa`) <> _utf8mb4\\'\\')))` |
| `avaliacao` | `ck_avaliacao_decisao` | `(`decisao_tecnica` in (_utf8mb4\\'PENDENTE\\',_utf8mb4\\'APROVADA\\',_utf8mb4\\'REPROVADA\\'))` |
| `avaliacao` | `ck_avaliacao_finalidade` | `(`finalidade` in (_utf8mb4\\'COMPRA_PROPRIA\\',_utf8mb4\\'CONSIGNACAO\\',_utf8mb4\\'TROCA\\'))` |
| `avaliacao` | `ck_avaliacao_interesse` | `(`interesse_comercial` in (_utf8mb4\\'EM_ANALISE\\',_utf8mb4\\'SIM\\',_utf8mb4\\'NAO\\'))` |
| `avaliacao` | `ck_avaliacao_medidas` | `((`quilometragem` >= 0) and (`quantidade_proprietarios` >= 0))` |
| `classificacao_fator` | `ck_fator_codigo` | `(`codigo_fator` in (_utf8mb4\\'URGENCIA_CONTATO\\',_utf8mb4\\'ESTAGIO_NEGOCIACAO\\',_utf8mb4\\'INTERESSE_FINANCEIRO\\',_utf8mb4\\'VOLUME_INTERACOES\\',_utf8mb4\\'CAPACIDADE_PAGAMENTO\\'))` |
| `classificacao_fator` | `ck_fator_evidencia` | `(trim(`evidencia`) <> _utf8mb4\\'\\')` |
| `classificacao_lead` | `ck_classificacao_justificativa` | `((`temperatura_final` is null) or (`temperatura_final` = `temperatura_sugerida`) or (`justificativa_revisao` is not null))` |
| `classificacao_lead` | `ck_classificacao_origem` | `(`origem` in (_utf8mb4\\'REGRA\\',_utf8mb4\\'IA\\'))` |
| `classificacao_lead` | `ck_classificacao_pontuacao` | `(`pontuacao` >= 0)` |
| `classificacao_lead` | `ck_classificacao_revisao` | `(((`temperatura_final` is null) and (`id_revisor` is null) and (`data_revisao` is null) and (`justificativa_revisao` is null)) or ((`temperatura_final` is not null) and (`id_revisor` is not null) and (`data_revisao` is not null)))` |
| `classificacao_lead` | `ck_classificacao_temp_final` | `((`temperatura_final` is null) or (`temperatura_final` in (_utf8mb4\\'FRIO\\',_utf8mb4\\'MORNO\\',_utf8mb4\\'QUENTE\\')))` |
| `classificacao_lead` | `ck_classificacao_temp_sugerida` | `(`temperatura_sugerida` in (_utf8mb4\\'FRIO\\',_utf8mb4\\'MORNO\\',_utf8mb4\\'QUENTE\\'))` |
| `despesa` | `ck_despesa_categoria` | `(`categoria` in (_utf8mb4\\'GARANTIA\\',_utf8mb4\\'DIAGNOSTICO\\',_utf8mb4\\'PREPARACAO\\'))` |
| `despesa` | `ck_despesa_descricao` | `(trim(`descricao`) <> _utf8mb4\\'\\')` |
| `despesa` | `ck_despesa_valor` | `(`valor` >= 0)` |
| `entrada` | `ck_entrada_consignacao` | `(((`modalidade` = _utf8mb4\\'CONSIGNACAO\\') and (`reconhecimento_firma` is not null) and (`reconhecimento_firma` = _utf8mb4\\'REALIZADO\\') and (`valor_repasse_acordado` is not null) and (`prazo_repasse` is not null) and (`criterio_repasse` is not null)) or ((`modalidade` <> _utf8mb4\\'CONSIGNACAO\\') and (`prazo_consignacao` is null) and (`valor_repasse_acordado` is null) and (`prazo_repasse` is null) and (`criterio_repasse` is null)))` |
| `entrada` | `ck_entrada_datas` | `((`data_encerramento` >= `data_entrada`) and (`data_devolucao` >= `data_entrada`) and (`data_regularizacao` >= `data_entrada`) and (`prazo_consignacao` >= cast(`data_entrada` as date)))` |
| `entrada` | `ck_entrada_devolucao` | `((`situacao` <> _utf8mb4\\'DEVOLVIDA\\') or (`data_devolucao` is not null))` |
| `entrada` | `ck_entrada_encerramento` | `(((`situacao` in (_utf8mb4\\'ATIVA\\',_utf8mb4\\'EM_REGULARIZACAO\\')) and (`data_encerramento` is null) and (`motivo_encerramento` is null)) or ((`situacao` in (_utf8mb4\\'COMERCIALIZADA\\',_utf8mb4\\'ENCERRADA\\',_utf8mb4\\'RETIRADA\\',_utf8mb4\\'DEVOLVIDA\\')) and (`data_encerramento` is not null) and (`motivo_encerramento` is not null)))` |
| `entrada` | `ck_entrada_modalidade` | `(`modalidade` in (_utf8mb4\\'COMPRA_PROPRIA\\',_utf8mb4\\'CONSIGNACAO\\',_utf8mb4\\'TROCA\\'))` |
| `entrada` | `ck_entrada_origem` | `(((`modalidade` = _utf8mb4\\'TROCA\\') and (`id_venda_origem` is not null) and (`numero_contrato` is null) and (`data_emissao` is null) and (`termos_ajustes` is null)) or ((`modalidade` <> _utf8mb4\\'TROCA\\') and (`id_venda_origem` is null) and (`numero_contrato` is not null) and (`data_emissao` is not null) and (`termos_ajustes` is not null)))` |
| `entrada` | `ck_entrada_preco` | `((`situacao` <> _utf8mb4\\'ATIVA\\') or (`preco_anunciado` is not null))` |
| `entrada` | `ck_entrada_regularizacao` | `((`data_regularizacao` is null) or (`observacoes_regularizacao` is not null))` |
| `entrada` | `ck_entrada_situacao` | `(`situacao` in (_utf8mb4\\'ATIVA\\',_utf8mb4\\'EM_REGULARIZACAO\\',_utf8mb4\\'COMERCIALIZADA\\',_utf8mb4\\'ENCERRADA\\',_utf8mb4\\'RETIRADA\\',_utf8mb4\\'DEVOLVIDA\\'))` |
| `entrada` | `ck_entrada_valores` | `((`valor_acordado` >= 0) and (`preco_anunciado` >= 0) and (`valor_repasse_acordado` >= 0) and (`valor_repasse_acordado` <= `valor_acordado`))` |
| `forma_pagamento` | `ck_forma_pagamento_textos` | `((trim(`codigo`) <> _utf8mb4\\'\\') and (trim(`descricao`) <> _utf8mb4\\'\\'))` |
| `funcionario` | `ck_funcionario_cargo` | `(trim(`cargo`) <> _utf8mb4\\'\\')` |
| `funcionario` | `ck_funcionario_situacao` | `(`situacao` in (_utf8mb4\\'ATIVO\\',_utf8mb4\\'INATIVO\\',_utf8mb4\\'AFASTADO\\'))` |
| `intencao_compra` | `ck_intencao_conteudo` | `((`id_entrada` is not null) or (`valor_disponivel` is not null) or (`codigo_forma` is not null))` |
| `intencao_compra` | `ck_intencao_origem` | `(`origem` in (_utf8mb4\\'SITE\\',_utf8mb4\\'VENDEDOR\\'))` |
| `intencao_compra` | `ck_intencao_valor` | `((`valor_disponivel` is null) or (`valor_disponivel` >= 0))` |
| `interacao` | `ck_interacao_canal` | `(`canal` in (_utf8mb4\\'TELEFONE\\',_utf8mb4\\'WHATSAPP\\',_utf8mb4\\'EMAIL\\',_utf8mb4\\'PRESENCIAL\\',_utf8mb4\\'OUTRO\\'))` |
| `interacao` | `ck_interacao_direcao` | `(`direcao` in (_utf8mb4\\'RECEBIDA\\',_utf8mb4\\'ENVIADA\\'))` |
| `interacao` | `ck_interacao_proximo_passo` | `((`data_proximo_passo` is null) or ((`proximo_passo` is not null) and (`data_proximo_passo` >= `data_hora`)))` |
| `interacao` | `ck_interacao_resumo` | `(trim(`resumo`) <> _utf8mb4\\'\\')` |
| `laudo` | `ck_laudo_emissao` | `(((`situacao` <> _utf8mb4\\'PENDENTE\\') or ((`data_emissao` is null) and (`resultado` is null))) and ((`situacao` <> _utf8mb4\\'EMITIDO\\') or ((`data_emissao` is not null) and (`resultado` is not null) and (trim(`resultado`) <> _utf8mb4\\'\\'))) and ((`situacao` <> _utf8mb4\\'CANCELADO\\') or (`resultado` is null) or (trim(`resultado`) <> _utf8mb4\\'\\')))` |
| `laudo` | `ck_laudo_referencia` | `(trim(`referencia_documental`) <> _utf8mb4\\'\\')` |
| `laudo` | `ck_laudo_situacao` | `(`situacao` in (_utf8mb4\\'PENDENTE\\',_utf8mb4\\'EMITIDO\\',_utf8mb4\\'CANCELADO\\'))` |
| `obrigacao_financeira` | `ck_obrigacao_arco` | `(((`origem` = _utf8mb4\\'VENDA\\') and (`id_venda` is not null) and (`id_entrada` is null) and (`id_despesa` is null) and (`natureza` = _utf8mb4\\'RECEBER\\')) or ((`origem` = _utf8mb4\\'ENTRADA\\') and (`id_venda` is null) and (`id_entrada` is not null) and (`id_despesa` is null) and (`natureza` = _utf8mb4\\'PAGAR\\')) or ((`origem` = _utf8mb4\\'DESPESA_VEICULO\\') and (`id_venda` is null) and (`id_entrada` is null) and (`id_despesa` is not null) and (`natureza` = _utf8mb4\\'PAGAR\\')) or ((`origem` = _utf8mb4\\'ADMINISTRATIVA\\') and (`id_venda` is null) and (`id_entrada` is null) and (`id_despesa` is null) and (`natureza` = _utf8mb4\\'PAGAR\\')))` |
| `obrigacao_financeira` | `ck_obrigacao_datas` | `((`vencimento_original` >= `data_competencia`) and (`vencimento_atual` >= `data_competencia`))` |
| `obrigacao_financeira` | `ck_obrigacao_estimativa` | `(`origem_estimativa` in (_utf8mb4\\'FATO\\',_utf8mb4\\'HIPOTESE\\',_utf8mb4\\'SIMULADO\\'))` |
| `obrigacao_financeira` | `ck_obrigacao_natureza` | `(`natureza` in (_utf8mb4\\'RECEBER\\',_utf8mb4\\'PAGAR\\'))` |
| `obrigacao_financeira` | `ck_obrigacao_origem` | `(`origem` in (_utf8mb4\\'VENDA\\',_utf8mb4\\'ENTRADA\\',_utf8mb4\\'DESPESA_VEICULO\\',_utf8mb4\\'ADMINISTRATIVA\\'))` |
| `obrigacao_financeira` | `ck_obrigacao_situacao` | `(`situacao` in (_utf8mb4\\'PREVISTA\\',_utf8mb4\\'ABERTA\\',_utf8mb4\\'QUITADA\\',_utf8mb4\\'CANCELADA\\',_utf8mb4\\'ATRASADA\\'))` |
| `obrigacao_financeira` | `ck_obrigacao_textos` | `((trim(`categoria`) <> _utf8mb4\\'\\') and (trim(`contraparte`) <> _utf8mb4\\'\\'))` |
| `obrigacao_financeira` | `ck_obrigacao_valores` | `(`valor` > 0)` |
| `ocorrencia_garantia` | `ck_ocorrencia_encerramento` | `(((`situacao` <> _utf8mb4\\'ENCERRADA\\') or ((`data_encerramento` is not null) and (`data_encerramento` >= `data_abertura`) and (`solucao` is not null) and (trim(`solucao`) <> _utf8mb4\\'\\'))) and ((`situacao` not in (_utf8mb4\\'ABERTA\\',_utf8mb4\\'EM_ANALISE\\',_utf8mb4\\'EM_ATENDIMENTO\\')) or (`data_encerramento` is null)))` |
| `ocorrencia_garantia` | `ck_ocorrencia_externo` | `(`atendimento_externo_informado` in (_utf8mb4\\'SIM\\',_utf8mb4\\'NAO\\',_utf8mb4\\'NAO_INFORMADO\\'))` |
| `ocorrencia_garantia` | `ck_ocorrencia_problema` | `(trim(`problema_relatado`) <> _utf8mb4\\'\\')` |
| `ocorrencia_garantia` | `ck_ocorrencia_responsabilidade` | `(`responsabilidade_apurada` in (_utf8mb4\\'EM_ANALISE\\',_utf8mb4\\'LOJA\\',_utf8mb4\\'MAU_USO\\',_utf8mb4\\'INCONCLUSIVA\\'))` |
| `ocorrencia_garantia` | `ck_ocorrencia_situacao` | `(`situacao` in (_utf8mb4\\'ABERTA\\',_utf8mb4\\'EM_ANALISE\\',_utf8mb4\\'EM_ATENDIMENTO\\',_utf8mb4\\'ENCERRADA\\'))` |
| `parametro_prazo` | `ck_parametro_prazo_banco` | `(trim(`banco`) <> _utf8mb4\\'\\')` |
| `parametro_prazo` | `ck_parametro_prazo_dias` | `(`dias_previstos` >= 0)` |
| `parametro_prazo` | `ck_parametro_prazo_origem` | `(`origem` in (_utf8mb4\\'HIPOTESE\\',_utf8mb4\\'CALIBRADA\\'))` |
| `parametro_prazo` | `ck_parametro_prazo_tipo` | `(`tipo_obrigacao` in (_utf8mb4\\'FINANCIAMENTO_RECEBER\\',_utf8mb4\\'CONSIGNANTE_PAGAR\\',_utf8mb4\\'COMPRA_PROPRIA_PAGAR\\'))` |
| `parametro_referencia` | `ck_parametro_referencia_chave` | `(`chave` = true)` |
| `parametro_referencia` | `ck_parametro_referencia_origem` | `(`origem` in (_utf8mb4\\'DEMONSTRACAO\\',_utf8mb4\\'OPERACAO\\'))` |
| `parametro_retorno` | `ck_parametro_retorno_acrescimo` | `(`acrescimo_taxa_mensal` >= 0)` |
| `parametro_retorno` | `ck_parametro_retorno_instituicao` | `(trim(`instituicao`) <> _utf8mb4\\'\\')` |
| `parametro_retorno` | `ck_parametro_retorno_origem` | `(`origem` in (_utf8mb4\\'HIPOTESE\\',_utf8mb4\\'CALIBRADA\\'))` |
| `parametro_retorno` | `ck_parametro_retorno_pct` | `(`retorno_pct` between 0 and 0.10)` |
| `parametro_retorno` | `ck_parametro_retorno_tabela` | `(`tabela_retorno` in (_utf8mb4\\'R0\\',_utf8mb4\\'R1\\',_utf8mb4\\'R2\\',_utf8mb4\\'R3\\',_utf8mb4\\'R4\\',_utf8mb4\\'R5\\'))` |
| `parametro_temperatura` | `ck_parametro_origem` | `(`origem` in (_utf8mb4\\'HIPOTESE\\',_utf8mb4\\'CALIBRADA\\'))` |
| `parametro_temperatura` | `ck_parametro_probabilidade` | `(`probabilidade` between 0 and 1)` |
| `parametro_temperatura` | `ck_parametro_temperatura` | `(`temperatura` in (_utf8mb4\\'FRIO\\',_utf8mb4\\'MORNO\\',_utf8mb4\\'QUENTE\\'))` |
| `pessoa` | `ck_pessoa_cnh` | `(`possui_cnh` in (0,1))` |
| `pessoa` | `ck_pessoa_documento` | `(((`tipo_documento` = _utf8mb4\\'CPF\\') and regexp_like(`numero_documento`,_utf8mb4\\'^[0-9]{11}$\\')) or ((`tipo_documento` = _utf8mb4\\'CNPJ\\') and regexp_like(`numero_documento`,_utf8mb4\\'^[0-9]{14}$\\')))` |
| `pessoa` | `ck_pessoa_email` | `regexp_like(`email`,_utf8mb4\\'^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$\\')` |
| `pessoa` | `ck_pessoa_endereco` | `(((`logradouro` is null) and (`numero` is null) and (`complemento` is null) and (`bairro` is null) and (`cidade` is null) and (`estado_uf` is null)) or ((`logradouro` is not null) and (`numero` is not null) and (`bairro` is not null) and (`cidade` is not null) and (`estado_uf` is not null)))` |
| `pessoa` | `ck_pessoa_nome` | `(trim(`nome`) <> _utf8mb4\\'\\')` |
| `pessoa` | `ck_pessoa_textos` | `((trim(`telefone`) <> _utf8mb4\\'\\') and (trim(`email`) <> _utf8mb4\\'\\') and (trim(`logradouro`) <> _utf8mb4\\'\\') and (trim(`numero`) <> _utf8mb4\\'\\') and (trim(`bairro`) <> _utf8mb4\\'\\') and (trim(`cidade`) <> _utf8mb4\\'\\'))` |
| `pessoa` | `ck_pessoa_uf` | `((`estado_uf` collate utf8mb4_bin) in (_utf8mb4\\'AC\\',_utf8mb4\\'AL\\',_utf8mb4\\'AP\\',_utf8mb4\\'AM\\',_utf8mb4\\'BA\\',_utf8mb4\\'CE\\',_utf8mb4\\'DF\\',_utf8mb4\\'ES\\',_utf8mb4\\'GO\\',_utf8mb4\\'MA\\',_utf8mb4\\'MT\\',_utf8mb4\\'MS\\',_utf8mb4\\'MG\\',_utf8mb4\\'PA\\',_utf8mb4\\'PB\\',_utf8mb4\\'PR\\',_utf8mb4\\'PE\\',_utf8mb4\\'PI\\',_utf8mb4\\'RJ\\',_utf8mb4\\'RN\\',_utf8mb4\\'RS\\',_utf8mb4\\'RO\\',_utf8mb4\\'RR\\',_utf8mb4\\'SC\\',_utf8mb4\\'SP\\',_utf8mb4\\'SE\\',_utf8mb4\\'TO\\'))` |
| `proposta` | `ck_proposta_data_decisao` | `(((`situacao` in (_utf8mb4\\'ACEITA\\',_utf8mb4\\'RECUSADA\\',_utf8mb4\\'EXPIRADA\\',_utf8mb4\\'SUBSTITUIDA\\')) and (`data_decisao` is not null)) or ((`situacao` in (_utf8mb4\\'RASCUNHO\\',_utf8mb4\\'APRESENTADA\\')) and (`data_decisao` is null)))` |
| `proposta` | `ck_proposta_datas` | `(`validade` >= `data_criacao`)` |
| `proposta` | `ck_proposta_raiz_versao` | `(((`id_proposta_anterior` is null) and (`versao` = 1)) or ((`id_proposta_anterior` is not null) and (`versao` > 1)))` |
| `proposta` | `ck_proposta_recusa` | `(((`situacao` = _utf8mb4\\'RECUSADA\\') and (`motivo_recusa` is not null)) or ((`situacao` <> _utf8mb4\\'RECUSADA\\') and (`motivo_recusa` is null)))` |
| `proposta` | `ck_proposta_rotulo` | `(trim(`rotulo`) <> _utf8mb4\\'\\')` |
| `proposta` | `ck_proposta_situacao` | `(`situacao` in (_utf8mb4\\'RASCUNHO\\',_utf8mb4\\'APRESENTADA\\',_utf8mb4\\'ACEITA\\',_utf8mb4\\'RECUSADA\\',_utf8mb4\\'EXPIRADA\\',_utf8mb4\\'SUBSTITUIDA\\'))` |
| `proposta` | `ck_proposta_valores` | `((`valor_base` >= 0) and (`desconto` >= 0) and (`acrescimo` >= 0) and (`taxas` >= 0) and (`valor_total` > 0) and (`desconto` <= `valor_base`))` |
| `proposta` | `ck_proposta_versao` | `(`versao` > 0)` |
| `proposta_condicao` | `ck_proposta_condicao_prazo` | `(`prazo_previsto_dias` >= 0)` |
| `proposta_condicao` | `ck_proposta_condicao_valor` | `(`valor` > 0)` |
| `proposta_troca` | `ck_proposta_troca_valor` | `(`valor_oferecido` > 0)` |
| `simulacao_financiamento` | `ck_simulacao_consentimento_dominio` | `(`consentimento_renda` in (0,1))` |
| `simulacao_financiamento` | `ck_simulacao_consentimento_renda` | `((`renda_declarada` is null) or (0 <> `consentimento_renda`))` |
| `simulacao_financiamento` | `ck_simulacao_datas` | `((`data_resposta` is null) or (`data_resposta` >= `data_simulacao`))` |
| `simulacao_financiamento` | `ck_simulacao_instituicao` | `(trim(`instituicao`) <> _utf8mb4\\'\\')` |
| `simulacao_financiamento` | `ck_simulacao_origem` | `(`origem` in (_utf8mb4\\'ACADEMICA\\',_utf8mb4\\'INFORMADA_BANCO\\',_utf8mb4\\'INTEGRACAO\\'))` |
| `simulacao_financiamento` | `ck_simulacao_situacao` | `(`situacao` in (_utf8mb4\\'EM_ANALISE\\',_utf8mb4\\'APROVADA\\',_utf8mb4\\'RECUSADA\\',_utf8mb4\\'CANCELADA\\'))` |
| `simulacao_financiamento` | `ck_simulacao_tabela_retorno` | `(`tabela_retorno` in (_utf8mb4\\'R0\\',_utf8mb4\\'R1\\',_utf8mb4\\'R2\\',_utf8mb4\\'R3\\',_utf8mb4\\'R4\\',_utf8mb4\\'R5\\'))` |
| `simulacao_financiamento` | `ck_simulacao_valores` | `((`valor_financiado` > 0) and (`taxa_mensal` > 0) and (`taxa_mensal` < 1) and (`prazo_meses` > 0) and (`parcela_informada` > 0) and (`renda_declarada` > 0))` |
| `veiculo` | `ck_veiculo_ano` | `(`ano_modelo` between 1886 and 2100)` |
| `veiculo` | `ck_veiculo_categoria` | `(`categoria_comercial` in (_utf8mb4\\'NOVO\\',_utf8mb4\\'SEMINOVO\\',_utf8mb4\\'USADO\\'))` |
| `veiculo` | `ck_veiculo_textos` | `((trim(`marca`) <> _utf8mb4\\'\\') and (trim(`modelo`) <> _utf8mb4\\'\\') and (trim(`cor`) <> _utf8mb4\\'\\') and (trim(`combustivel`) <> _utf8mb4\\'\\') and (trim(`cambio`) <> _utf8mb4\\'\\'))` |
| `venda` | `ck_venda_booleanos` | `((`condicao_repasse` in (0,1)) and (`concessao_garantia` in (0,1)))` |
| `venda` | `ck_venda_cancelamento` | `((`situacao_comercial` <> _utf8mb4\\'CANCELADA\\') or ((`data_cancelamento` is not null) and (`motivo_cancelamento` is not null) and (`data_retorno_veiculo` is not null) and (`data_cancelamento` >= `data_retorno_veiculo`) and (`valor_restituido_loja` is not null) and (`observacoes_cancelamento` is not null)))` |
| `venda` | `ck_venda_conclusao` | `((`situacao_comercial` <> _utf8mb4\\'CONCLUIDA\\') or ((`data_conclusao` is not null) and (`numero_contrato` is not null) and (`data_emissao` is not null) and (`termos_condicoes` is not null) and (`id_laudo` is not null)))` |
| `venda` | `ck_venda_entrega` | `((`data_entrega` is null) or ((`data_conclusao` is not null) and (`data_scanner` is not null) and (`resultado_scanner` is not null) and (`data_scanner` <= `data_entrega`)))` |
| `venda` | `ck_venda_financiamento` | `(((`instituicao_financeira` is null) and (`valor_financiado` is null) and (`situacao_financiamento` is null) and (`data_aprovacao_financiamento` is null) and (`data_recebimento_financiamento` is null)) or ((`instituicao_financeira` is not null) and (`valor_financiado` is not null) and (`valor_financiado` > 0) and (`situacao_financiamento` is not null) and (((`situacao_financiamento` in (_utf8mb4\\'EM_ANALISE\\',_utf8mb4\\'NAO_APROVADO\\')) and (`data_aprovacao_financiamento` is null) and (`data_recebimento_financiamento` is null)) or ((`situacao_financiamento` = _utf8mb4\\'APROVADO_A_RECEBER\\') and (`data_aprovacao_financiamento` is not null) and (`data_recebimento_financiamento` is null)) or ((`situacao_financiamento` = _utf8mb4\\'RECEBIDO\\') and (`data_aprovacao_financiamento` is not null) and (`data_recebimento_financiamento` is not null) and (`data_recebimento_financiamento` >= `data_aprovacao_financiamento`) and (`valor_recebido` >= `valor_financiado`) and (`data_ultimo_recebimento` >= `data_recebimento_financiamento`)))))` |
| `venda` | `ck_venda_formalizacao` | `((`situacao_comercial` <> _utf8mb4\\'EM_FORMALIZACAO\\') or ((`data_conclusao` is null) and (`data_entrega` is null)))` |
| `venda` | `ck_venda_garantia` | `((0 = `concessao_garantia`) or (`termos_politica` is not null))` |
| `venda` | `ck_venda_marcos` | `((`data_conclusao` >= `data_registro`) and (`data_entrega` >= `data_conclusao`) and (`data_cancelamento` >= `data_registro`) and (`data_retorno_veiculo` >= `data_registro`))` |
| `venda` | `ck_venda_recebimento` | `(((`valor_recebido` = 0) and (`data_ultimo_recebimento` is null)) or ((`valor_recebido` > 0) and (`data_ultimo_recebimento` is not null)))` |
| `venda` | `ck_venda_situacao` | `(`situacao_comercial` in (_utf8mb4\\'EM_FORMALIZACAO\\',_utf8mb4\\'CONCLUIDA\\',_utf8mb4\\'EM_DESFAZIMENTO\\',_utf8mb4\\'CANCELADA\\'))` |
| `venda` | `ck_venda_valores` | `((`valor_base` >= 0) and (`desconto` >= 0) and (`acrescimo` >= 0) and (`taxas` >= 0) and (`valor_total` >= 0) and (`valor_recebido` >= 0) and (`valor_restituido_loja` >= 0) and (`valor_restituido_loja` <= `valor_recebido`))` |
| `venda_documento` | `ck_documento_aplicavel` | `(`reconhecimento_aplicavel` in (0,1))` |
| `venda_documento` | `ck_documento_firma` | `(((0 <> `reconhecimento_aplicavel`) and (`tipo_documento` in (_utf8mb4\\'ATPV\\',_utf8mb4\\'CONTRATO\\')) and (`justificativa_dispensa` is null)) or ((0 = `reconhecimento_aplicavel`) and (`data_reconhecimento` is null) and ((`tipo_documento` not in (_utf8mb4\\'ATPV\\',_utf8mb4\\'CONTRATO\\')) or (`justificativa_dispensa` is not null))))` |
| `venda_documento` | `ck_documento_tipo` | `(`tipo_documento` in (_utf8mb4\\'CNH\\',_utf8mb4\\'LAUDO_CAUTELAR\\',_utf8mb4\\'CRLV\\',_utf8mb4\\'ATPV\\',_utf8mb4\\'COMPROVANTE_RESIDENCIA\\',_utf8mb4\\'CONTRATO\\'))` |

## 4. Views

| View | Colunas e tipos físicos |
|---|---|
| `vw_caixa_realizado_referencia` | `semana` `DATE`, `realizado` `DECIMAL(36,2)`, `composicao` `VARCHAR(170)` |
| `vw_cliente_cpf` | `cpf` `VARCHAR(14)`, `id_pessoa` `BIGINT`, `nome` `VARCHAR(150)`, `tipo_registro` `VARCHAR(11)`, `id_registro` `BIGINT`, `data_evento` `DATETIME`, `descricao` `MEDIUMTEXT`, `valor` `DECIMAL(14,2)`, `situacao` `VARCHAR(18)` |
| `vw_fila_acoes` | `fonte` `VARCHAR(7)`, `id_referencia` `BIGINT`, `descricao` `VARCHAR(231)`, `motivo` `VARCHAR(103)`, `valor_em_risco` `DECIMAL(14,2)`, `urgencia_dias` `INT` |
| `vw_fluxos_previsao` | `camada` `VARCHAR(9)`, `data_evento` `DATE`, `valor` `DECIMAL(20,8)`, `bancario` `BIGINT`, `temperatura` `VARCHAR(17)`, `descricao` `VARCHAR(255)` |
| `vw_lead_atual` | `id_atendimento` `BIGINT`, `id_pessoa` `BIGINT`, `nome_cliente` `VARCHAR(150)`, `telefone` `VARCHAR(20)`, `id_funcionario` `BIGINT`, `tipo_interesse` `VARCHAR(6)`, `descricao_interesse` `TEXT`, `data_abertura` `DATETIME`, `situacao_atendimento` `VARCHAR(13)`, `tipo_desfecho` `VARCHAR(16)`, `motivo_desfecho` `TEXT`, `data_desfecho` `DATETIME`, `id_classificacao` `BIGINT`, `data_classificacao` `DATETIME`, `versao_regra` `VARCHAR(16)`, `temperatura_sugerida` `VARCHAR(8)`, `pontuacao` `DECIMAL(6,2)`, `temperatura_final` `VARCHAR(8)`, `revisado` `INT`, `id_revisor` `BIGINT`, `data_revisao` `DATETIME`, `justificativa_revisao` `TEXT`, `temperatura_atual` `VARCHAR(8)`, `data_ultima_interacao` `DATETIME`, `total_interacoes` `BIGINT`, `dias_sem_contato` `INT` |
| `vw_previsao_caixa` | `semana` `DATE`, `realizado` `DECIMAL(37,2)`, `obrigacoes` `DECIMAL(37,2)`, `funil_ponderado` `DECIMAL(37,2)`, `saldo_projetado` `DECIMAL(62,2)`, `composicao` `MEDIUMTEXT` |
| `vw_proposta_comparativo` | `id_proposta` `BIGINT`, `id_atendimento` `BIGINT`, `id_pessoa` `BIGINT`, `cpf` `VARCHAR(14)`, `id_entrada` `BIGINT`, `rotulo` `VARCHAR(1)`, `versao` `INT`, `data_criacao` `DATE`, `validade` `DATE`, `situacao` `VARCHAR(12)`, `valor_total` `DECIMAL(14,2)`, `caixa_d0` `DECIMAL(14,2)`, `caixa_posterior` `DECIMAL(14,2)`, `valor_em_troca` `DECIMAL(14,2)`, `margem_estimada` `DECIMAL(14,2)`, `retorno_banco` `DECIMAL(14,2)`, `margem_com_retorno` `DECIMAL(14,2)`, `parcela_simulada` `DECIMAL(14,2)`, `parcela_sobre_renda_pct` `DECIMAL(23,2)`, `dias_ate_recebimento` `BIGINT`, `prazo_caixa` `VARCHAR(13)` |
| `vw_simulacao_parcela` | `id_simulacao` `BIGINT`, `id_proposta` `BIGINT`, `instituicao` `VARCHAR(100)`, `tabela_retorno` `VARCHAR(2)`, `origem` `VARCHAR(16)`, `valor_financiado` `DECIMAL(14,2)`, `taxa_base_mensal` `DECIMAL(8,6)`, `acrescimo_taxa_mensal` `DECIMAL(8,6)`, `taxa_cliente_mensal` `DECIMAL(9,6)`, `prazo_meses` `SMALLINT`, `parcela_calculada` `DECIMAL(23,2)`, `custo_total_cliente` `DECIMAL(23,2)`, `cet_aproximado_anual` `DECIMAL(27,6)`, `retorno_loja` `DECIMAL(23,2)`, `parcela_informada` `DECIMAL(14,2)`, `renda_declarada` `DECIMAL(14,2)`, `parcela_sobre_renda_pct` `DECIMAL(23,2)`, `consentimento_renda` `TINYINT(1)`, `situacao` `VARCHAR(12)` |
| `vw_veiculo_situacao` | `id_veiculo` `BIGINT`, `marca` `VARCHAR(60)`, `modelo` `VARCHAR(80)`, `ano_modelo` `SMALLINT`, `cor` `VARCHAR(30)`, `placa` `VARCHAR(7)`, `chassi` `VARCHAR(17)`, `combustivel` `VARCHAR(20)`, `cambio` `VARCHAR(20)`, `categoria_comercial` `VARCHAR(8)`, `situacao_atual` `VARCHAR(24)` |
| `vw_venda_resumo` | `id_venda` `BIGINT`, `id_comprador` `BIGINT`, `id_funcionario` `BIGINT`, `id_entrada_principal` `BIGINT`, `id_laudo` `BIGINT`, `data_registro` `DATETIME`, `situacao_comercial` `VARCHAR(18)`, `data_conclusao` `DATETIME`, `valor_base` `DECIMAL(14,2)`, `desconto` `DECIMAL(14,2)`, `acrescimo` `DECIMAL(14,2)`, `taxas` `DECIMAL(14,2)`, `valor_total` `DECIMAL(14,2)`, `numero_contrato` `VARCHAR(40)`, `data_emissao` `DATE`, `termos_condicoes` `TEXT`, `condicao_repasse` `TINYINT(1)`, `valor_recebido` `DECIMAL(14,2)`, `data_ultimo_recebimento` `DATETIME`, `instituicao_financeira` `VARCHAR(100)`, `valor_financiado` `DECIMAL(14,2)`, `situacao_financiamento` `VARCHAR(20)`, `data_aprovacao_financiamento` `DATETIME`, `data_recebimento_financiamento` `DATETIME`, `data_scanner` `DATETIME`, `resultado_scanner` `VARCHAR(100)`, `providencias_scanner` `TEXT`, `preparacao` `TEXT`, `data_entrega` `DATETIME`, `concessao_garantia` `TINYINT(1)`, `termos_politica` `TEXT`, `data_cancelamento` `DATETIME`, `motivo_cancelamento` `TEXT`, `data_retorno_veiculo` `DATETIME`, `valor_restituido_loja` `DECIMAL(14,2)`, `data_aviso_consignante` `DATETIME`, `orientacao_bancaria` `TEXT`, `observacoes_cancelamento` `TEXT`, `total_trocas` `DECIMAL(36,2)`, `saldo` `DECIMAL(37,2)`, `total_trocas_historico` `DECIMAL(36,2)`, `saldo_historico` `DECIMAL(37,2)`, `formas_ok` `INT`, `recebimento_ok` `INT`, `contrato_ok` `INT`, `situacao_financeira` `VARCHAR(15)`, `situacao_documental` `VARCHAR(8)`, `data_inicio_garantia` `DATETIME`, `data_fim_garantia` `DATETIME`, `requisitos_rn22_ok` `INT` |
| `vw_venda_validacao` | `id_venda` `BIGINT`, `total_trocas` `DECIMAL(36,2)`, `total_trocas_historico` `DECIMAL(36,2)`, `saldo_historico` `DECIMAL(37,2)`, `saldo` `DECIMAL(37,2)`, `situacao_financeira` `VARCHAR(8)`, `financiamento_ok` `INT`, `formas_ok` `INT`, `recebimento_ok` `INT`, `contrato_ok` `INT`, `documentos_ok` `INT`, `reconhecimento_ok` `INT`, `laudo_ok` `INT` |

## 5. Triggers e rotinas

Nomes, eventos e tabelas-alvo lidos do catálogo MySQL.

| Nome | Tipo/evento | Tabela ou retorno |
|---|---|---|
| `desfecho_bd` | `BEFORE DELETE` | `atendimento_desfecho` |
| `desfecho_bu` | `BEFORE UPDATE` | `atendimento_desfecho` |
| `avaliacao_bu` | `BEFORE UPDATE` | `avaliacao` |
| `avaliacao_laudo_bi` | `BEFORE INSERT` | `avaliacao_laudo` |
| `avaliacao_laudo_bu` | `BEFORE UPDATE` | `avaliacao_laudo` |
| `fator_bd` | `BEFORE DELETE` | `classificacao_fator` |
| `fator_bu` | `BEFORE UPDATE` | `classificacao_fator` |
| `classificacao_bd` | `BEFORE DELETE` | `classificacao_lead` |
| `classificacao_bu` | `BEFORE UPDATE` | `classificacao_lead` |
| `classificacao_lead_bi` | `BEFORE INSERT` | `classificacao_lead` |
| `entrada_bd` | `BEFORE DELETE` | `entrada` |
| `entrada_bi` | `BEFORE INSERT` | `entrada` |
| `entrada_bu` | `BEFORE UPDATE` | `entrada` |
| `entrada_contrato_bi` | `BEFORE INSERT` | `entrada` |
| `entrada_contrato_bu` | `BEFORE UPDATE` | `entrada` |
| `intencao_compra_bi` | `BEFORE INSERT` | `intencao_compra` |
| `intencao_compra_bu` | `BEFORE UPDATE` | `intencao_compra` |
| `interacao_bd` | `BEFORE DELETE` | `interacao` |
| `interacao_bu` | `BEFORE UPDATE` | `interacao` |
| `laudo_bu` | `BEFORE UPDATE` | `laudo` |
| `obrigacao_imutavel_bd` | `BEFORE DELETE` | `obrigacao_financeira` |
| `obrigacao_imutavel_bu` | `BEFORE UPDATE` | `obrigacao_financeira` |
| `ocorrencia_bi` | `BEFORE INSERT` | `ocorrencia_garantia` |
| `ocorrencia_bu` | `BEFORE UPDATE` | `ocorrencia_garantia` |
| `pessoa_contrato_bu` | `BEFORE UPDATE` | `pessoa` |
| `proposta_bi` | `BEFORE INSERT` | `proposta` |
| `proposta_bu` | `BEFORE UPDATE` | `proposta` |
| `proposta_condicao_bd` | `BEFORE DELETE` | `proposta_condicao` |
| `proposta_condicao_bi` | `BEFORE INSERT` | `proposta_condicao` |
| `proposta_condicao_bu` | `BEFORE UPDATE` | `proposta_condicao` |
| `proposta_troca_bd` | `BEFORE DELETE` | `proposta_troca` |
| `proposta_troca_bi` | `BEFORE INSERT` | `proposta_troca` |
| `proposta_troca_bu` | `BEFORE UPDATE` | `proposta_troca` |
| `simulacao_imutavel_bd` | `BEFORE DELETE` | `simulacao_financiamento` |
| `simulacao_imutavel_bu` | `BEFORE UPDATE` | `simulacao_financiamento` |
| `simulacao_retorno_bi` | `BEFORE INSERT` | `simulacao_financiamento` |
| `simulacao_retorno_bu` | `BEFORE UPDATE` | `simulacao_financiamento` |
| `venda_bd` | `BEFORE DELETE` | `venda` |
| `venda_bi` | `BEFORE INSERT` | `venda` |
| `venda_bu` | `BEFORE UPDATE` | `venda` |
| `venda_contrato_bi` | `BEFORE INSERT` | `venda` |
| `venda_contrato_bu` | `BEFORE UPDATE` | `venda` |
| `venda_proposta_bi` | `BEFORE INSERT` | `venda` |
| `venda_proposta_bu` | `BEFORE UPDATE` | `venda` |
| `documento_bd` | `BEFORE DELETE` | `venda_documento` |
| `documento_bi` | `BEFORE INSERT` | `venda_documento` |
| `documento_bu` | `BEFORE UPDATE` | `venda_documento` |
| `forma_venda_bd` | `BEFORE DELETE` | `venda_forma_pagamento` |
| `forma_venda_bi` | `BEFORE INSERT` | `venda_forma_pagamento` |
| `forma_venda_bu` | `BEFORE UPDATE` | `venda_forma_pagamento` |
| `aceitar_proposta` | `PROCEDURE` | rotina do banco |
| `cancelar_venda` | `PROCEDURE` | rotina do banco |
| `concluir_venda` | `PROCEDURE` | rotina do banco |
| `criar_contraproposta` | `PROCEDURE` | rotina do banco |
| `data_referencia` | `FUNCTION` | rotina do banco |
| `fn_previsao_caixa_cenario` | `PROCEDURE` | rotina do banco |
| `pessoa_dados_contrato` | `FUNCTION` | rotina do banco |
| `registrar_classificacao_lead` | `PROCEDURE` | rotina do banco |

## 6. Totais conferidos

- Tabelas: **28**.
- Views: **11**.
- Atributos de tabela: **259**. São 258 colunas declaradas dentro dos `CREATE TABLE` mais `venda.id_proposta`, acrescentada pela extensão com `ALTER TABLE venda ADD COLUMN id_proposta` (`sql/extensao/01-ddl-propostas-caixa.sql`); por isso uma contagem feita só nos `CREATE TABLE` encontra 258.
- Restrições `CHECK`: **114**.
- Triggers: **50**.
- Procedures e functions: **8**.
- A matriz de execução e os totais de testes estão em [`docs/evidencias/mysql/paridade-testes.md`](evidencias/mysql/paridade-testes.md).
