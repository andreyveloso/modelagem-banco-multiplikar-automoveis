-- Massa-base MySQL 8.4.13; dados fictícios. Os ciclos compostos usam procedures atomicas.
-- O MySQL Workbench liga o modo Safe Updates por padrão, que recusa UPDATE/DELETE sem coluna-chave
-- no WHERE. Este script faz essas operações de proposito (inclusive dentro dos testes), entao o modo
-- e desligado só durante a execução e o valor anterior e restaurado no fim.
SET @mk_safe_updates = @@SESSION.sql_safe_updates;
SET SQL_SAFE_UPDATES = 0;
USE multiplikar;
INSERT INTO pessoa (id_pessoa, nome, tipo_documento, numero_documento, telefone, email, logradouro, numero, bairro, cidade, estado_uf, possui_cnh) SELECT id, nome, 'CPF', LPAD(CAST(id AS CHAR), 11, '0'), CONCAT('1190000', LPAD(CAST(id AS CHAR), 4, '0')), CONCAT('pessoa', id, '@example.invalid'), 'Rua de Teste', CAST(id AS CHAR), 'Vila Sao Geraldo', 'Sao Paulo', 'SP', TRUE FROM (SELECT 1 AS id, 'Ana Comercial' AS nome UNION ALL SELECT 2, 'Bruno Administrativo' UNION ALL SELECT 3, 'Caio Avaliador' UNION ALL SELECT 4, 'Dora Mecanica' UNION ALL SELECT 5, 'Eva Fornecedora' UNION ALL SELECT 6, 'Fabio Comprador' UNION ALL SELECT 7, 'Gabi Compradora' UNION ALL SELECT 8, 'Hugo Consignante' UNION ALL SELECT 9, 'Iara Compradora' UNION ALL SELECT 10, 'Joao Comprador' UNION ALL SELECT 11, 'Lia Compradora' UNION ALL SELECT 12, 'Mario Comprador') AS p;

INSERT INTO funcionario (id_funcionario, id_pessoa, cargo, data_admissao, situacao) VALUES (1, 1, 'Vendas', '2025-01-10', 'ATIVO'), (2, 2, 'Administrativo', '2025-02-01', 'ATIVO');

INSERT INTO veiculo (id_veiculo, marca, modelo, ano_modelo, cor, placa, chassi, combustivel, cambio, categoria_comercial) VALUES (1, 'Fiat', 'Argo', 2022, 'Branco', 'TST1A01', '9TEST000000000001', 'Flex', 'Manual', 'USADO'), (2, 'Toyota', 'Corolla', 2021, 'Prata', 'TST1A02', '9TEST000000000002', 'Flex', 'Automatico', 'USADO'), (3, 'Honda', 'City', 2023, 'Cinza', 'TST1A03', '9TEST000000000003', 'Flex', 'Automatico', 'SEMINOVO'), (4, 'Hyundai', 'HB20', 2022, 'Azul', 'TST1A04', '9TEST000000000004', 'Flex', 'Manual', 'USADO'), (5, 'Chevrolet', 'Tracker', 2023, 'Preto', 'TST1A05', '9TEST000000000005', 'Flex', 'Automatico', 'SEMINOVO'), (6, 'Fiat', 'Uno', 2015, 'Branco', 'TST1A06', '9TEST000000000006', 'Flex', 'Manual', 'USADO'), (7, 'Ford', 'Ka', 2013, 'Vermelho', 'TST1A07', '9TEST000000000007', 'Flex', 'Manual', 'USADO'), (8, 'Volkswagen', 'Gol', 2017, 'Prata', 'TST1A08', '9TEST000000000008', 'Flex', 'Manual', 'USADO'), (9, 'Renault', 'Kwid', 2024, 'Branco', 'TST1A09', '9TEST000000000009', 'Flex', 'Manual', 'SEMINOVO');

INSERT INTO atendimento (id_atendimento, id_pessoa, id_funcionario, data, tipo_interesse, descricao_interesse, situacao) VALUES (1, 6, 1, '2026-01-05 09:00', 'COMPRA', 'Busca por Argo', 'CONVERTIDO'), (2, 7, 1, '2026-01-05 09:00', 'TROCA', 'Corolla com Uno e Ka de entrada', 'CONVERTIDO'), (3, 9, 2, '2026-01-07 09:00', 'COMPRA', 'City com financiamento', 'CONVERTIDO'), (4, 10, 1, '2026-01-07 09:00', 'TROCA', 'HB20 com Gol de entrada', 'CONVERTIDO'), (5, 12, 1, '2026-01-09 09:00', 'COMPRA', 'Tracker aguardando banco', 'EM_NEGOCIACAO'), (6, 8, 2, '2026-01-02 09:00', 'VENDA', 'Consignacao City e Kwid', 'CONVERTIDO');

INSERT INTO laudo (id_laudo, id_veiculo, referencia_documental, data_emissao, situacao, resultado) SELECT id_veiculo, id_veiculo, CONCAT('LAUDO-TESTE-', id_veiculo), CASE WHEN id_veiculo IN (6, 7) THEN CAST('2026-01-06' AS DATE) WHEN id_veiculo = 8 THEN CAST('2026-01-08' AS DATE) ELSE CAST('2026-01-02' AS DATE) END, 'EMITIDO', 'Documento cautelar realizado; resultado registrado para analise.' FROM veiculo;

INSERT INTO avaliacao (id_avaliacao, id_veiculo, id_avaliador, data, finalidade, quilometragem, quantidade_proprietarios, condicao_externa, condicao_interna, condicao_mecanica, condicao_estrutural, condicao_documental, decisao_tecnica, interesse_comercial, justificativa) SELECT id, id_veiculo, 3, CASE WHEN id_veiculo IN (6, 7) THEN CAST('2026-01-06 10:00' AS DATETIME) WHEN id_veiculo = 8 THEN CAST('2026-01-08 10:00' AS DATETIME) ELSE CAST('2026-01-03 10:00' AS DATETIME) END, modalidade, km, 2, 'Conservada', 'Conservada', 'Vistoriada', 'Verificada', 'Conferida', 'APROVADA', 'SIM', 'Vistoria aprovada e interesse comercial confirmado.' FROM (SELECT 1 AS id, 1 AS id_veiculo, 'COMPRA_PROPRIA' AS modalidade, 40000 AS km UNION ALL SELECT 2, 2, 'COMPRA_PROPRIA', 50000 UNION ALL SELECT 3, 3, 'CONSIGNACAO', 30000 UNION ALL SELECT 4, 4, 'COMPRA_PROPRIA', 45000 UNION ALL SELECT 5, 5, 'COMPRA_PROPRIA', 25000 UNION ALL SELECT 6, 6, 'TROCA', 100000 UNION ALL SELECT 7, 7, 'TROCA', 120000 UNION ALL SELECT 8, 8, 'TROCA', 80000 UNION ALL SELECT 10, 9, 'CONSIGNACAO', 20000) AS a;

INSERT INTO avaliacao_laudo (id_avaliacao, id_laudo) SELECT id_avaliacao, id_veiculo FROM avaliacao;

INSERT INTO entrada (id_entrada, id_veiculo, id_contraparte, id_avaliacao, modalidade, data_entrada, valor_acordado, preco_anunciado, numero_contrato, data_emissao, termos_ajustes, reconhecimento_firma, valor_repasse_acordado, prazo_repasse, criterio_repasse) SELECT id, id, contraparte, id_avaliacao, modalidade, '2026-01-04 10:00', custo, preco, CONCAT('CE-', id), '2026-01-04', 'Condicoes individualizadas de entrada.', 'REALIZADO', repasse, CASE WHEN modalidade = 'CONSIGNACAO' THEN 'Apos confirmacao da venda' END, CASE WHEN modalidade = 'CONSIGNACAO' THEN 'Valor fixo acordado com o consignante' END FROM (SELECT 1 AS id, 5 AS contraparte, 1 AS id_avaliacao, 'COMPRA_PROPRIA' AS modalidade, 50000 AS custo, 60000 AS preco, CAST(NULL AS DECIMAL) AS repasse UNION ALL SELECT 2, 5, 2, 'COMPRA_PROPRIA', 85000, 100000, NULL UNION ALL SELECT 3, 8, 3, 'CONSIGNACAO', 80000, 80000, 74000 UNION ALL SELECT 4, 5, 4, 'COMPRA_PROPRIA', 58000, 70000, NULL UNION ALL SELECT 5, 5, 5, 'COMPRA_PROPRIA', 78000, 90000, NULL) AS e;

INSERT INTO entrada (id_entrada, id_veiculo, id_contraparte, id_avaliacao, modalidade, data_entrada, valor_acordado, preco_anunciado, numero_contrato, data_emissao, termos_ajustes, reconhecimento_firma, valor_repasse_acordado, prazo_repasse, criterio_repasse) VALUES (10, 9, 8, 10, 'CONSIGNACAO', '2026-01-04 11:00', 55000, 55000, 'CE-10', '2026-01-04', 'Consignacao com prazo ate 15/11/2026.', 'REALIZADO', 50000, 'Apos a venda', 'Repasse fixo');

UPDATE entrada SET prazo_consignacao = '2026-04-04' WHERE id_entrada = 3;

UPDATE entrada SET prazo_consignacao = '2026-11-15' WHERE id_entrada = 10;

INSERT INTO venda (id_venda, id_comprador, id_funcionario, id_entrada_principal, id_laudo, data_registro, valor_base, numero_contrato, data_emissao, termos_condicoes, valor_recebido, data_ultimo_recebimento, concessao_garantia, termos_politica) VALUES (1, 6, 1, 1, 1, '2026-01-05 10:00', 60000, 'CV-1', '2026-01-05', 'Venda normal via Pix.', 60000, '2026-01-06 10:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.'), (2, 7, 1, 2, 2, '2026-01-06 10:00', 100000, 'CV-2', '2026-01-06', 'Uno: 25000; Ka: 15000; Pix: 60000.', 60000, '2026-01-07 10:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.'), (3, 9, 2, 3, 3, '2026-01-07 10:00', 80000, 'CV-3', '2026-01-07', 'Pix 20000 e banco 60000; consignado.', 80000, '2026-01-08 10:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.'), (4, 10, 1, 4, 4, '2026-01-08 10:00', 70000, 'CV-4', '2026-01-08', 'Gol: 30000; Pix: 40000.', 40000, '2026-01-09 10:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.'), (6, 12, 1, 5, 5, '2026-01-09 10:00', 90000, 'CV-6', '2026-01-09', 'Pix 10000; banco 80000 ainda nao recebido.', 10000, '2026-01-09 11:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.');

UPDATE venda SET instituicao_financeira = 'Banco Exemplo', valor_financiado = 60000, situacao_financiamento = 'RECEBIDO', data_aprovacao_financiamento = '2026-01-07 15:00', data_recebimento_financiamento = '2026-01-08 10:00' WHERE id_venda = 3;

UPDATE venda SET instituicao_financeira = 'Banco Demonstracao', valor_financiado = 80000, situacao_financiamento = 'APROVADO_A_RECEBER', data_aprovacao_financiamento = '2026-01-10 10:00' WHERE id_venda = 6;

INSERT INTO entrada (id_entrada, id_veiculo, id_contraparte, id_avaliacao, id_venda_origem, modalidade, data_entrada, valor_acordado, preco_anunciado) VALUES (6, 6, 7, 6, 2, 'TROCA', '2026-01-06 11:00', 25000, 30000), (7, 7, 7, 7, 2, 'TROCA', '2026-01-06 11:00', 15000, 20000), (8, 8, 10, 8, 4, 'TROCA', '2026-01-08 11:00', 30000, 35000);

INSERT INTO forma_pagamento VALUES ('PIX', 'Pix'), ('DINHEIRO', 'Dinheiro'), ('CARTAO', 'Cartao'), ('FINANCIAMENTO', 'Financiamento'), ('TROCA', 'Veiculo recebido em troca');

INSERT INTO venda_forma_pagamento VALUES (1, 'PIX'), (2, 'PIX'), (2, 'TROCA'), (3, 'PIX'), (3, 'FINANCIAMENTO'), (4, 'PIX'), (4, 'TROCA'), (6, 'PIX'), (6, 'FINANCIAMENTO');

INSERT INTO venda_documento (id_venda, tipo_documento, data_conferencia, reconhecimento_aplicavel, data_reconhecimento) SELECT v.id_venda, d.tipo, '2026-01-10 12:00', d.tipo IN ('ATPV', 'CONTRATO'), CASE WHEN d.tipo IN ('ATPV', 'CONTRATO') THEN CAST('2026-01-10 13:00' AS DATETIME) END FROM venda AS v CROSS JOIN (SELECT 'CNH' AS tipo UNION ALL SELECT 'LAUDO_CAUTELAR' UNION ALL SELECT 'CRLV' UNION ALL SELECT 'ATPV' UNION ALL SELECT 'COMPROVANTE_RESIDENCIA' UNION ALL SELECT 'CONTRATO') AS d;

CALL concluir_venda(1,'2026-01-11 10:00','2026-01-11 11:00','Leitura realizada sem falhas.','Nenhuma intervencao indicada.','Limpeza e conferencia de entrega.','2026-01-12 10:00');

CALL concluir_venda(2,'2026-01-11 10:00','2026-01-11 11:00','Leitura realizada sem falhas.','Nenhuma intervencao indicada.','Limpeza e conferencia de entrega.','2026-01-12 10:00');

CALL concluir_venda(3,'2026-01-11 10:00','2026-01-11 11:00','Leitura realizada sem falhas.','Nenhuma intervencao indicada.','Limpeza e conferencia de entrega.','2026-01-12 10:00');

CALL concluir_venda(4,'2026-01-11 10:00','2026-01-11 11:00','Leitura realizada sem falhas.','Nenhuma intervencao indicada.','Limpeza e conferencia de entrega.','2026-01-12 10:00');

UPDATE venda SET situacao_comercial = 'EM_DESFAZIMENTO' WHERE id_venda = 4;

UPDATE entrada SET situacao = 'ENCERRADA', motivo_encerramento = 'DESFAZIMENTO' WHERE id_entrada = 4;

UPDATE entrada SET situacao = 'DEVOLVIDA', data_devolucao = '2026-01-20 12:00', data_encerramento = '2026-01-20 12:00', motivo_encerramento = 'DEVOLUCAO_TROCA' WHERE id_entrada = 8;

INSERT INTO avaliacao (id_avaliacao, id_veiculo, id_avaliador, data, finalidade, quilometragem, quantidade_proprietarios, condicao_externa, condicao_interna, condicao_mecanica, condicao_estrutural, condicao_documental, decisao_tecnica, interesse_comercial, justificativa) VALUES (9, 4, 3, '2026-01-20 13:00', 'COMPRA_PROPRIA', 45300, 2, 'Conservada', 'Conservada', 'Reavaliada apos retorno', 'Verificada', 'Em regularizacao administrativa', 'APROVADA', 'SIM', 'Nova avaliacao de aceitacao; liberacao comercial aguarda regularizacao do distrato.');

INSERT INTO avaliacao_laudo VALUES (9, 4);

INSERT INTO entrada (id_entrada, id_veiculo, id_contraparte, id_avaliacao, id_entrada_anterior, modalidade, data_entrada, situacao, valor_acordado, preco_anunciado, numero_contrato, data_emissao, termos_ajustes) VALUES (9, 4, 10, 9, 4, 'COMPRA_PROPRIA', '2026-01-20 14:00', 'EM_REGULARIZACAO', 58000, 68000, 'DISTRATO-CV-4', '2026-01-20', 'Reintegracao por distrato; valor de referencia do ciclo, sem nova compra paga.');

CALL cancelar_venda(4,'2026-01-20 15:00','Desfazimento acordado entre as partes.','2026-01-20 10:00',40000,'HB20 recebido; Gol devolvido; 40000 restituidos; novo ciclo 9 em regularizacao.');

UPDATE entrada SET situacao = 'ATIVA', data_regularizacao = '2026-01-22 09:00', observacoes_regularizacao = 'Distrato, retorno e restituicoes conferidos; liberado para nova venda.' WHERE id_entrada = 9;

INSERT INTO venda (id_venda, id_comprador, id_funcionario, id_entrada_principal, id_laudo, data_registro, valor_base, numero_contrato, data_emissao, termos_condicoes, valor_recebido, data_ultimo_recebimento, concessao_garantia, termos_politica) VALUES (5, 11, 1, 9, 4, '2026-01-23 10:00', 68000, 'CV-5', '2026-01-23', 'Revenda apos regularizacao; banco recusou; quitacao integral via Pix.', 68000, '2026-01-23 11:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.');

UPDATE venda SET instituicao_financeira = 'Banco Demonstracao', valor_financiado = 50000, situacao_financiamento = 'NAO_APROVADO' WHERE id_venda = 5;

INSERT INTO venda_forma_pagamento VALUES (5, 'PIX');

INSERT INTO venda_documento (id_venda, tipo_documento, data_conferencia, reconhecimento_aplicavel, data_reconhecimento) SELECT 5, tipo, '2026-01-23 12:00', tipo IN ('ATPV', 'CONTRATO'), CASE WHEN tipo IN ('ATPV', 'CONTRATO') THEN CAST('2026-01-23 13:00' AS DATETIME) END FROM (SELECT 'CNH' AS tipo UNION ALL SELECT 'LAUDO_CAUTELAR' UNION ALL SELECT 'CRLV' UNION ALL SELECT 'ATPV' UNION ALL SELECT 'COMPROVANTE_RESIDENCIA' UNION ALL SELECT 'CONTRATO') AS d;

CALL concluir_venda(5,'2026-01-24 10:00','2026-01-24 11:00','Sem falhas',NULL,NULL,'2026-01-25 10:00');

INSERT INTO ocorrencia_garantia (id_ocorrencia, id_venda, id_mecanico, data_abertura, problema_relatado, atendimento_externo_informado, diagnostico, responsabilidade_apurada, servico_realizado, solucao, situacao, data_encerramento) VALUES (1, 1, 4, '2026-02-01 09:00', 'Falha de partida', 'NAO', 'Bateria com falha', 'LOJA', 'Substituicao de bateria', 'Problema resolvido', 'ENCERRADA', '2026-02-02 15:00'), (2, 3, 4, '2026-02-03 09:00', 'Ruido na suspensao', 'NAO', 'Em diagnostico', 'EM_ANALISE', NULL, NULL, 'EM_ANALISE', NULL);

INSERT INTO despesa (id_despesa, id_veiculo, data, categoria, descricao, valor) VALUES (1, 1, '2026-02-02', 'GARANTIA', 'Bateria e instalacao', 650), (2, 3, '2026-02-03', 'DIAGNOSTICO', 'Inspecao de suspensao', 150), (3, 2, '2026-01-10', 'PREPARACAO', 'Higienizacao', 250), (4, 4, '2026-01-22', 'PREPARACAO', 'Revisao apos devolucao', 400);

DELIMITER $$
CREATE PROCEDURE verificar_massa_nucleo()
BEGIN
 IF (SELECT COUNT(*) FROM venda)<>6 OR (SELECT COUNT(*) FROM entrada)<>10 OR (SELECT COUNT(*) FROM ocorrencia_garantia)<>2 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Contagens finais inesperadas na massa do nucleo'; END IF;
 SELECT 'PASS massa: 6 vendas, 10 entradas e 2 ocorrencias' AS resultado;
 IF EXISTS(SELECT 1 FROM vw_venda_resumo WHERE data_conclusao IS NOT NULL AND requisitos_rn22_ok<>TRUE) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Venda concluida com RN22 pendente'; END IF;
 SELECT 'PASS RN22: vendas concluidas atendem aos requisitos' AS resultado;
 IF (SELECT total_trocas FROM vw_venda_resumo WHERE id_venda=2)<>40000 OR (SELECT saldo FROM vw_venda_resumo WHERE id_venda=2)<>0 OR (SELECT saldo FROM vw_venda_resumo WHERE id_venda=6)<>80000 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Composicao financeira incorreta'; END IF;
 SELECT 'PASS composicao: troca, saldo quitado e financiamento pendente' AS resultado;
 IF NOT EXISTS(SELECT 1 FROM entrada n JOIN entrada a ON a.id_entrada=n.id_entrada_anterior JOIN venda antiga ON antiga.id_entrada_principal=a.id_entrada JOIN venda nova ON nova.id_entrada_principal=n.id_entrada WHERE a.id_veiculo=4 AND n.id_veiculo=4 AND antiga.situacao_comercial='CANCELADA' AND nova.situacao_comercial='CONCLUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Historico RN13 incompleto'; END IF;
 SELECT 'PASS RN13: distrato e novo ciclo do HB20 preservados' AS resultado;
END$$
DELIMITER ;
CALL verificar_massa_nucleo();
DROP PROCEDURE verificar_massa_nucleo;

-- Regressao RN do núcleo: os DML abaixo sao executados e precisam falhar pela regra esperada.
DROP PROCEDURE IF EXISTS massa_rejeitar;
DELIMITER $$
CREATE PROCEDURE massa_rejeitar(IN p_nome VARCHAR(120),IN p_sql TEXT,IN p_esperado VARCHAR(128))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 @msg=MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE; END;
  SET @massa_sql=p_sql; PREPARE massa_stmt FROM @massa_sql; EXECUTE massa_stmt; DEALLOCATE PREPARE massa_stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Operacao aceita indevidamente: ',p_nome); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Regra inesperada em ',p_nome,': ',LEFT(COALESCE(v_msg,'<vazia>'),64)); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS massa ',p_nome,': ',p_esperado) AS resultado;
END$$
DELIMITER ;
START TRANSACTION;
CALL massa_rejeitar('vinculo avaliacao-laudo de outro veiculo','UPDATE avaliacao_laudo SET id_laudo=2 WHERE id_avaliacao=1','RN08');
CALL massa_rejeitar('laudo usado nao muda de veiculo','UPDATE laudo SET id_veiculo=2 WHERE id_laudo=1','RN08');
CALL massa_rejeitar('avaliacao de entrada nao pode reprovar','UPDATE avaliacao SET decisao_tecnica=''REPROVADA'' WHERE id_avaliacao=1','RN06/RN07');
CALL massa_rejeitar('identidade de entrada imutavel','UPDATE entrada SET id_veiculo=2 WHERE id_entrada=1','Identidade e origem');
CALL massa_rejeitar('entrada historica nao apaga','DELETE FROM entrada WHERE id_entrada=1','nunca apagado');
CALL massa_rejeitar('venda historica nao apaga','DELETE FROM venda WHERE id_venda=1','nunca apagado');
CALL massa_rejeitar('recebimento da venda concluida e imutavel','UPDATE venda SET valor_recebido=0 WHERE id_venda=1','RN22');
CALL massa_rejeitar('documento concluido nao apaga','DELETE FROM venda_documento WHERE id_venda=1 LIMIT 1','RN22');
CALL massa_rejeitar('documento concluido nao altera','UPDATE venda_documento SET data_reconhecimento=NULL WHERE id_venda=1 AND tipo_documento=''ATPV''','RN22');
CALL massa_rejeitar('despesa sem veiculo','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES(99999,''2026-02-01'',''PREPARACAO'',''x'',100)','fk_despesa');
CALL massa_rejeitar('despesa negativa','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES(1,''2026-02-01'',''PREPARACAO'',''x'',-1)','ck_despesa_valor');
CALL massa_rejeitar('pessoa sem nome','INSERT INTO pessoa(nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES(NULL,''CPF'',''99887766554'',''1'',''x@invalid'',''R'',''1'',''B'',''C'',''SP'')','nome');
CALL massa_rejeitar('data de recebimento posterior a conclusao','UPDATE venda SET data_ultimo_recebimento=''2026-03-01'' WHERE id_venda=1','RN22');
CALL massa_rejeitar('tipo de documento desconhecido','INSERT INTO venda_documento(id_venda,tipo_documento,reconhecimento_aplicavel) VALUES(6,''OUTRO'',FALSE)','ck_documento_tipo');
CALL massa_rejeitar('categoria de despesa desconhecida','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES(1,''2026-02-01'',''QUALQUER'',''x'',1)','ck_despesa_categoria');
CALL massa_rejeitar('status de atendimento desconhecido','UPDATE atendimento SET situacao=''PENDENTE'' WHERE id_atendimento=1','ck_atendimento_situacao');
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES(100,6,3,'2026-02-01 10:00:00','COMPRA_PROPRIA',101000,2,'ok','ok','ok','ok','ok','APROVADA','SIM','Teste de ciclo ativo');
SET @massa_avaliacao=100;
CALL massa_rejeitar('entrada duplica ciclo ativo do veiculo','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(6,5,@massa_avaliacao,''COMPRA_PROPRIA'',''2026-02-02'',25000,30000,''TESTE-CICLO'',''2026-02-02'',''teste'')','Duplicate entry');
CALL massa_rejeitar('concluir venda com financiamento pendente','CALL concluir_venda(6,''2026-02-01 10:00:00'',''2026-02-01 11:00:00'',''x'',''x'',''x'',''2026-02-02 10:00:00'')','RN22');
CALL massa_rejeitar('cancelar venda sem ciclo de retorno','CALL cancelar_venda(1,''2026-02-10 10:00:00'',''Teste'',''2026-02-09 10:00:00'',60000,''Teste'')','RN13/RN28-RN31');
CALL massa_rejeitar('forma de venda duplicada','INSERT INTO venda_forma_pagamento VALUES(6,''PIX'')','Duplicate entry');
CALL massa_rejeitar('estado final irregular de venda','UPDATE venda SET situacao_comercial=''CONCLUIDA'' WHERE id_venda=6','Use concluir_venda');
CALL massa_rejeitar('forma de pagamento de venda concluida nao apaga','DELETE FROM venda_forma_pagamento WHERE id_venda=1 AND codigo_forma=''PIX''','RN22');
CALL massa_rejeitar('financiamento de venda concluida nao apaga','DELETE FROM venda_forma_pagamento WHERE id_venda=3 AND codigo_forma=''FINANCIAMENTO''','RN22');
CALL massa_rejeitar('garantia historica da venda concluida','UPDATE venda SET concessao_garantia=FALSE WHERE id_venda=1','RN22');
CALL massa_rejeitar('garantia historica da venda 5','UPDATE venda SET concessao_garantia=FALSE WHERE id_venda=5','RN22');
CALL massa_rejeitar('recebimento de venda 5 concluida e imutavel','UPDATE venda SET valor_recebido=1 WHERE id_venda=5','RN22');
CALL massa_rejeitar('situacao de funcionario fora do dominio','UPDATE funcionario SET situacao=''INVALIDO''','ck_funcionario_situacao');
CALL massa_rejeitar('situacao de laudo fora do dominio','UPDATE laudo SET situacao=''INVALIDO''','ck_laudo_situacao');
CALL massa_rejeitar('situacao de ocorrencia fora do dominio','UPDATE ocorrencia_garantia SET situacao=''INVALIDO''','ck_ocorrencia_situacao');
CALL massa_rejeitar('responsabilidade de ocorrencia fora do dominio','UPDATE ocorrencia_garantia SET responsabilidade_apurada=''INVALIDO''','ck_ocorrencia_responsabilidade');
CALL massa_rejeitar('ano de veiculo abaixo do limite','UPDATE veiculo SET ano_modelo=1885 WHERE id_veiculo=1','ck_veiculo_ano');
CALL massa_rejeitar('ano de veiculo acima do limite','UPDATE veiculo SET ano_modelo=2101 WHERE id_veiculo=1','ck_veiculo_ano');
ROLLBACK;
-- InnoDB consome AUTO_INCREMENT em INSERT que falha; reverta o contador para a carga seguinte.
ALTER TABLE entrada AUTO_INCREMENT=11;
ALTER TABLE avaliacao AUTO_INCREMENT=11;
DROP PROCEDURE massa_rejeitar;

-- Restaura o modo Safe Updates da sessao.
SET SQL_SAFE_UPDATES = @mk_safe_updates;
