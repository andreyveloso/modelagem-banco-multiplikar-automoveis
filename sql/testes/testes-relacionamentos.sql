-- Verificacoes estruturais dos relacionamentos R01 a R41 no MySQL 8.4.
-- O lado pai tem mínimo zero quando o relacionamento permite ausência.
-- O MySQL Workbench liga o modo Safe Updates por padrão, que recusa UPDATE/DELETE sem coluna-chave
-- no WHERE. Este script faz essas operações de proposito (inclusive dentro dos testes), entao o modo
-- e desligado só durante a execução e o valor anterior e restaurado no fim.
SET @mk_safe_updates = @@SESSION.sql_safe_updates;
SET SQL_SAFE_UPDATES = 0;
USE multiplikar;
DROP PROCEDURE IF EXISTS verificar_relacionamentos;
-- Temporárias duram a conexão; remove sobras de uma execução interrompida na mesma aba do Workbench.
DROP TEMPORARY TABLE IF EXISTS rel_esperados, rel_resultado, rel_ai_before;
CREATE TEMPORARY TABLE rel_esperados(codigo VARCHAR(4),tabela_filha VARCHAR(64),coluna_filha VARCHAR(64),tabela_pai VARCHAR(64),coluna_pai VARCHAR(64),unica TINYINT,nullable TINYINT);
INSERT INTO rel_esperados VALUES
('R01','funcionario','id_pessoa','pessoa','id_pessoa',1,0),
('R02','atendimento','id_pessoa','pessoa','id_pessoa',0,0),
('R03','atendimento','id_funcionario','funcionario','id_funcionario',0,0),
('R04','avaliacao','id_veiculo','veiculo','id_veiculo',0,0),
('R05','avaliacao','id_avaliador','pessoa','id_pessoa',0,0),
('R06','laudo','id_veiculo','veiculo','id_veiculo',0,0),
('R07','avaliacao_laudo','id_avaliacao','avaliacao','id_avaliacao',1,0),
('R07','avaliacao_laudo','id_laudo','laudo','id_laudo',0,0),
('R08','entrada','id_veiculo','veiculo','id_veiculo',0,0),
('R09','entrada','id_contraparte','pessoa','id_pessoa',0,0),
('R10','entrada','id_avaliacao','avaliacao','id_avaliacao',1,0),
('R11','venda','id_comprador','pessoa','id_pessoa',0,0),
('R12','venda','id_funcionario','funcionario','id_funcionario',0,0),
('R13','venda','id_entrada_principal','entrada','id_entrada',1,0),
('R14','entrada','id_venda_origem','venda','id_venda',0,1),
('R15','venda','id_laudo','laudo','id_laudo',0,1),
('R16','ocorrencia_garantia','id_venda','venda','id_venda',0,0),
('R17','ocorrencia_garantia','id_mecanico','pessoa','id_pessoa',0,1),
('R18','despesa','id_veiculo','veiculo','id_veiculo',0,0),
('R19','entrada','id_entrada_anterior','entrada','id_entrada',1,1),
('R20','proposta','id_atendimento','atendimento','id_atendimento',0,0),
('R21','proposta','id_entrada','entrada','id_entrada',0,0),
('R22','proposta','id_funcionario','funcionario','id_funcionario',0,0),
('R23','proposta','id_proposta_anterior','proposta','id_proposta',1,1),
('R24','venda','id_proposta','proposta','id_proposta',1,1),
('R25','proposta_condicao','id_proposta','proposta','id_proposta',0,0),
('R25','proposta_condicao','codigo_forma','forma_pagamento','codigo',0,0),
('R26','proposta_troca','id_proposta','proposta','id_proposta',0,0),
('R26','proposta_troca','id_avaliacao','avaliacao','id_avaliacao',0,0),
('R27','simulacao_financiamento','id_proposta','proposta','id_proposta',0,0),
('R29','obrigacao_financeira','id_venda','venda','id_venda',0,1),
('R30','obrigacao_financeira','id_entrada','entrada','id_entrada',0,1),
('R31','obrigacao_financeira','id_despesa','despesa','id_despesa',0,1),
('R32','interacao','id_atendimento','atendimento','id_atendimento',0,0),
('R33','interacao','id_funcionario','funcionario','id_funcionario',0,0),
('R34','atendimento_desfecho','id_atendimento','atendimento','id_atendimento',1,0),
('R35','classificacao_lead','id_atendimento','atendimento','id_atendimento',0,0),
('R36','classificacao_lead','id_revisor','funcionario','id_funcionario',0,1),
('R37','classificacao_fator','id_classificacao','classificacao_lead','id_classificacao',0,0),
('R38','atendimento_desfecho','id_funcionario','funcionario','id_funcionario',0,0),
('R39','intencao_compra','id_atendimento','atendimento','id_atendimento',1,0),
('R40','intencao_compra','id_entrada','entrada','id_entrada',0,1),
('R41','intencao_compra','codigo_forma','forma_pagamento','codigo',0,1);
DELIMITER $$
CREATE PROCEDURE verificar_relacionamentos()
BEGIN
 DECLARE feito INT DEFAULT 0; DECLARE v_cod VARCHAR(4); DECLARE v_tab VARCHAR(64); DECLARE v_col VARCHAR(64); DECLARE v_pai VARCHAR(64); DECLARE v_pcol VARCHAR(64); DECLARE v_uni TINYINT; DECLARE v_null TINYINT; DECLARE n INT; DECLARE un INT; DECLARE nul VARCHAR(3);
 DECLARE c CURSOR FOR SELECT codigo,tabela_filha,coluna_filha,tabela_pai,coluna_pai,unica,nullable FROM rel_esperados ORDER BY codigo,tabela_filha,coluna_filha;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET feito=1;
 OPEN c; ciclo: LOOP FETCH c INTO v_cod,v_tab,v_col,v_pai,v_pcol,v_uni,v_null; IF feito=1 THEN LEAVE ciclo; END IF;
  SELECT COUNT(*) INTO n FROM information_schema.key_column_usage WHERE table_schema=DATABASE() AND table_name=v_tab AND column_name=v_col AND referenced_table_name=v_pai AND referenced_column_name=v_pcol;
  SELECT is_nullable INTO nul FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name=v_tab AND column_name=v_col;
  SELECT COUNT(*) INTO un FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name=v_tab AND column_name=v_col AND non_unique=0;
  IF n<>1 OR ((v_uni=1) AND un=0) OR ((v_null=1)<>(nul='YES')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Metadados de relacionamento divergentes'; END IF;
  SELECT CONCAT('PASS ',v_cod,' ',v_tab,'.',v_col,' -> ',v_pai,'.',v_pcol,'; FK, nulidade e unicidade conferidas') AS resultado;
 END LOOP; CLOSE c;
 IF NOT EXISTS(SELECT 1 FROM information_schema.triggers WHERE trigger_schema=DATABASE() AND trigger_name='simulacao_retorno_bi') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='R28: validacao do parametro de retorno ausente'; END IF;
 SELECT 'PASS R28 simulacao_parametro_retorno: gatilho de vigencia instalado' AS resultado;
END$$
DELIMITER ;
CALL verificar_relacionamentos();
DROP PROCEDURE verificar_relacionamentos;
DROP TEMPORARY TABLE rel_esperados;

-- Ensaios comportamentais adicionais: DML real dentro de transação revertida.
-- Procedures criadas antes de START TRANSACTION porque CREATE PROCEDURE confirma DDL.
DROP PROCEDURE IF EXISTS rel_rejeita;
DROP PROCEDURE IF EXISTS rel_aceita;
DROP PROCEDURE IF EXISTS rel_volta_obrigatoria;
DROP PROCEDURE IF EXISTS rel_confere;
DROP PROCEDURE IF EXISTS rel_restaurar_auto_increment;
CREATE TEMPORARY TABLE rel_resultado(ok TINYINT NOT NULL);
CREATE TEMPORARY TABLE rel_ai_before(table_name VARCHAR(64) PRIMARY KEY, next_value BIGINT UNSIGNED NOT NULL);
DELIMITER $$
CREATE PROCEDURE rel_rejeita(IN p_rotulo VARCHAR(180),IN p_sql TEXT,IN p_trecho VARCHAR(160))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
BEGIN DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 @rel_msg=MESSAGE_TEXT; SET v_msg=@rel_msg; SET v_falhou=TRUE; SET @mk_registrando_classificacao=NULL; END;
  IF p_rotulo LIKE 'R35 Volta%' THEN SET @mk_registrando_classificacao=1; END IF;
  SET @rel_sql=p_sql; PREPARE rel_stmt FROM @rel_sql; EXECUTE rel_stmt; DEALLOCATE PREPARE rel_stmt;
  SET @mk_registrando_classificacao=NULL;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Operacao aceita indevidamente: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_trecho,'%') THEN SET v_err=CONCAT('Regra inesperada: ',p_rotulo,' / ',LEFT(COALESCE(v_msg,''),64)); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS ',p_rotulo,': recusado (',p_trecho,')') AS resultado;
END$$
CREATE PROCEDURE rel_aceita(IN p_rotulo VARCHAR(180),IN p_sql TEXT)
BEGIN
 SAVEPOINT rel_aceita_sp;
 SET @rel_sql=p_sql; PREPARE rel_stmt FROM @rel_sql; EXECUTE rel_stmt; DEALLOCATE PREPARE rel_stmt;
 ROLLBACK TO SAVEPOINT rel_aceita_sp; RELEASE SAVEPOINT rel_aceita_sp;
 SELECT CONCAT('PASS ',p_rotulo,': aceito') AS resultado;
END$$
CREATE PROCEDURE rel_volta_obrigatoria(IN p_rotulo VARCHAR(140),IN p_modelo TEXT,IN p_coluna VARCHAR(64),IN p_fk VARCHAR(128))
BEGIN
 CALL rel_rejeita(CONCAT(p_rotulo,' (minimo 1)'),REPLACE(p_modelo,'{fk}','NULL'),p_coluna);
 CALL rel_rejeita(CONCAT(p_rotulo,' (pai inexistente)'),REPLACE(p_modelo,'{fk}','999999999'),p_fk);
END$$
CREATE PROCEDURE rel_confere(IN p_rotulo VARCHAR(180),IN p_condicao TEXT)
BEGIN
 DELETE FROM rel_resultado; SET @rel_sql=CONCAT('INSERT INTO rel_resultado SELECT IF((',p_condicao,'),1,0)');
 PREPARE rel_stmt FROM @rel_sql; EXECUTE rel_stmt; DEALLOCATE PREPARE rel_stmt;
 IF (SELECT ok FROM rel_resultado LIMIT 1)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Verificacao relacional falhou'; END IF;
 SELECT CONCAT('PASS ',p_rotulo) AS resultado;
END$$
CREATE PROCEDURE rel_restaurar_auto_increment()
BEGIN
 DECLARE v_done BOOLEAN DEFAULT FALSE; DECLARE v_table VARCHAR(64); DECLARE v_next BIGINT UNSIGNED;
 DECLARE c CURSOR FOR SELECT table_name,next_value FROM rel_ai_before ORDER BY table_name;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=TRUE;
 OPEN c; ciclo: LOOP FETCH c INTO v_table,v_next; IF v_done THEN LEAVE ciclo; END IF;
  SET @rel_sql=CONCAT('ALTER TABLE ',v_table,' AUTO_INCREMENT=',v_next);
  PREPARE rel_stmt FROM @rel_sql; EXECUTE rel_stmt; DEALLOCATE PREPARE rel_stmt;
 END LOOP; CLOSE c;
END$$
DELIMITER ;
INSERT INTO rel_ai_before SELECT table_name,auto_increment FROM information_schema.tables WHERE table_schema=DATABASE() AND auto_increment IS NOT NULL;
START TRANSACTION;
INSERT INTO pessoa(id_pessoa,nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES
(9201,'Pessoa 9201','CPF','00000009201','11999201','p9201@example.invalid','Rua','1','Centro','Sao Paulo','SP'),
(9202,'Pessoa 9202','CPF','00000009202','11999202','p9202@example.invalid','Rua','1','Centro','Sao Paulo','SP'),
(9203,'Pessoa 9203','CPF','00000009203','11999203','p9203@example.invalid','Rua','1','Centro','Sao Paulo','SP'),
(9204,'Pessoa 9204','CPF','00000009204','11999204','p9204@example.invalid','Rua','1','Centro','Sao Paulo','SP');
INSERT INTO funcionario(id_funcionario,id_pessoa,cargo,data_admissao,situacao) VALUES(9201,9203,'Vendas','2025-01-01','ATIVO');
INSERT INTO veiculo(id_veiculo,marca,modelo,ano_modelo,cor,combustivel,cambio,categoria_comercial) VALUES
(9201,'Marca','Modelo 9201',2018,'Prata','Flex','Manual','USADO'),(9202,'Marca','Modelo 9202',2018,'Prata','Flex','Manual','USADO'),
(9203,'Marca','Modelo 9203',2018,'Prata','Flex','Manual','USADO'),(9204,'Marca','Modelo 9204',2018,'Prata','Flex','Manual','USADO'),
(9205,'Marca','Modelo 9205',2018,'Prata','Flex','Manual','USADO'),(9206,'Marca','Modelo 9206',2018,'Prata','Flex','Manual','USADO'),
(9207,'Marca','Modelo 9207',2018,'Prata','Flex','Manual','USADO');
INSERT INTO laudo(id_laudo,id_veiculo,referencia_documental,data_emissao,situacao,resultado) VALUES
(9201,9201,'L9201','2026-01-10','EMITIDO','ok'),(9202,9202,'L9202','2026-01-10','EMITIDO','ok');
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES
(9201,9201,9203,'2026-01-11 10:00','COMPRA_PROPRIA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9202,9202,9203,'2026-01-11 10:00','COMPRA_PROPRIA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9203,9203,9203,'2026-01-13 10:00','TROCA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9204,9204,9203,'2026-01-13 10:00','TROCA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9205,9205,9203,'2026-01-20 10:00','TROCA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9206,9206,9203,'2026-01-20 10:00','TROCA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9207,9207,9203,'2026-01-11 10:00','COMPRA_PROPRIA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok');
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES
(9293,9201,9204,'2026-01-11 13:00','COMPRA_PROPRIA',50100,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','laudo adicional'),
(9294,9201,9204,'2026-01-11 14:00','COMPRA_PROPRIA',50200,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','laudo mismatch test');
INSERT INTO avaliacao_laudo VALUES(9201,9201),(9202,9202);
INSERT INTO entrada(id_entrada,id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES
(9201,9201,9202,9201,'COMPRA_PROPRIA','2026-01-12 10:00',50000,60000,'CE9201','2026-01-12','ok'),
(9202,9202,9202,9202,'COMPRA_PROPRIA','2026-01-12 10:00',50000,60000,'CE9202','2026-01-12','ok'),
(9207,9207,9202,9207,'COMPRA_PROPRIA','2026-01-12 10:00',50000,60000,'CE9207','2026-01-12','ok');
INSERT INTO venda(id_venda,id_comprador,id_funcionario,id_entrada_principal,id_laudo,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,9201,9201,9201,'2026-01-14 10:00',60000,FALSE);
INSERT INTO entrada(id_entrada,id_veiculo,id_contraparte,id_avaliacao,id_venda_origem,modalidade,data_entrada,valor_acordado,preco_anunciado) VALUES
(9203,9203,9201,9203,9201,'TROCA','2026-01-14 11:00',20000,24000),(9204,9204,9201,9204,9201,'TROCA','2026-01-14 11:00',10000,12000);
INSERT INTO despesa(id_despesa,id_veiculo,data,categoria,descricao,valor) VALUES(9201,9201,'2026-01-15','PREPARACAO','ok',100);
INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,data,tipo_interesse,descricao_interesse,situacao) VALUES
(9201,9201,9201,'2026-01-05 09:00','COMPRA','ok','ABERTO'),(9202,9204,9201,'2026-01-05 09:00','COMPRA','ok','ABERTO');
INSERT INTO proposta(id_proposta,id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base,situacao) VALUES
(9201,9201,9202,9201,'A',1,'2026-02-05','2026-02-12',60000,'RASCUNHO'),
(9202,9201,9202,9201,'B',1,'2026-02-05','2026-02-12',60000,'RASCUNHO'),
(9203,9202,9202,9201,'A',1,'2026-02-05','2026-02-12',60000,'RASCUNHO');
INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(9201,'PIX',60000),(9202,'PIX',60000),(9203,'PIX',60000);
INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9201,9201,'2026-02-05 09:00','TELEFONE','ENVIADA','ok');
CALL registrar_classificacao_lead(9201,'REGRA-V1','2026-02-06 09:00',@classificacao_9201);
-- R01 a R10: minimos, existência e cardinalidades executados no banco.
CALL rel_volta_obrigatoria('R01 Volta','INSERT INTO funcionario(id_pessoa,cargo,data_admissao,situacao) VALUES({fk},''Vendas'',''2025-01-01'',''ATIVO'')','id_pessoa','fk_funcionario_id_pessoa');
CALL rel_rejeita('R01 Ida (maximo 1)','INSERT INTO funcionario(id_pessoa,cargo,data_admissao,situacao) VALUES(9203,''Vendas'',''2025-01-01'',''ATIVO'')','Duplicate entry');
CALL rel_confere('R01 Ida (minimo 0): pessoa sem funcionario','NOT EXISTS(SELECT 1 FROM funcionario WHERE id_pessoa=9201)');
CALL rel_volta_obrigatoria('R02 Volta','INSERT INTO atendimento(id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES({fk},9201,''COMPRA'',''x'',''ABERTO'')','id_pessoa','fk_atendimento_id_pessoa');
CALL rel_aceita('R02 Ida (maximo N): segunda interacao da mesma pessoa','INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES(9290,9201,9201,''VENDA'',''x'',''ABERTO'')');
CALL rel_volta_obrigatoria('R03 Volta','INSERT INTO atendimento(id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES(9201,{fk},''COMPRA'',''x'',''ABERTO'')','id_funcionario','fk_atendimento_id_funcionario');
CALL rel_confere('R03 Ida (maximo N): funcionario com dois atendimentos','(SELECT COUNT(*) FROM atendimento WHERE id_funcionario=9201)=2');
CALL rel_volta_obrigatoria('R04 Volta','INSERT INTO avaliacao(id_veiculo,id_avaliador,data,finalidade,quilometragem) VALUES({fk},9203,''2026-01-11 10:00:00'',''COMPRA_PROPRIA'',1)','id_veiculo','fk_avaliacao_id_veiculo');
CALL rel_aceita('R04 Ida (maximo N): reavaliacao do mesmo veiculo','INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem) VALUES(9290,9201,9203,''2026-01-11 12:00:00'',''COMPRA_PROPRIA'',50100)');
CALL rel_volta_obrigatoria('R05 Volta','INSERT INTO avaliacao(id_veiculo,id_avaliador,data,finalidade,quilometragem) VALUES(9201,{fk},''2026-01-11 10:00:00'',''COMPRA_PROPRIA'',1)','id_avaliador','fk_avaliacao_id_avaliador');
CALL rel_confere('R05 Ida (maximo N): avaliador com varias avaliacoes','(SELECT COUNT(*) FROM avaliacao WHERE id_avaliador=9203)=7');
CALL rel_volta_obrigatoria('R06 Volta','INSERT INTO laudo(id_veiculo,referencia_documental,data_emissao,situacao,resultado) VALUES({fk},''x'',''2026-01-10'',''EMITIDO'',''x'')','id_veiculo','fk_laudo_id_veiculo');
CALL rel_aceita('R06 Ida (maximo N): segundo laudo historico do mesmo veiculo','INSERT INTO laudo(id_laudo,id_veiculo,referencia_documental,data_emissao,situacao,resultado) VALUES(9290,9201,''L9201-B'',''2026-01-09'',''EMITIDO'',''x'')');
CALL rel_rejeita('R07 Ida (maximo 1)','INSERT INTO avaliacao_laudo VALUES(9201,9201)','Duplicate entry');
CALL rel_confere('R07 Ida (minimo 0): avaliacao sem laudo','NOT EXISTS(SELECT 1 FROM avaliacao_laudo WHERE id_avaliacao=9203)');
CALL rel_aceita('R07 Volta (maximo N): mesmo laudo pode subsidiar varias avaliacoes','INSERT INTO avaliacao_laudo VALUES(9293,9201)');
CALL rel_rejeita('R07 Volta (laudo de outro veiculo, RN08)','INSERT INTO avaliacao_laudo VALUES(9294,9202)','RN08');
CALL rel_rejeita('R07 Volta (laudo inexistente barrado pela regra de laudo)','INSERT INTO avaliacao_laudo VALUES(9203,999999999)','RN08');
CALL rel_volta_obrigatoria('R08 Volta','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES({fk},9202,9293,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','id_veiculo','entrada exige avaliacao aprovada, interesse e veiculo');
CALL rel_confere('R08 Ida (maximo N): HB20 tem ciclos de entrada anteriores e atual','(SELECT COUNT(*) FROM entrada WHERE id_veiculo=4)=2');
CALL rel_confere('R08 Ida (minimo 0): veiculo preliminar sem entrada','NOT EXISTS(SELECT 1 FROM entrada WHERE id_veiculo=9205)');
CALL rel_volta_obrigatoria('R09 Volta','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,{fk},9293,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','id_contraparte','fk_entrada_id_contraparte');
CALL rel_confere('R09 Ida (maximo N): fornecedor com tres entradas','(SELECT COUNT(*) FROM entrada WHERE id_contraparte=9202)=3');
-- The evaluation lookup yields NULL on a missing row, so the FK is the first rejecting constraint.
CALL rel_rejeita('R10 Volta (pai inexistente)','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,9202,999999999,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','fk_entrada_id_avaliacao');
CALL rel_rejeita('R10 Volta (minimo 1)','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,9202,NULL,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','id_avaliacao');
CALL rel_rejeita('R10 Ida (maximo 1): mesma avaliacao nao fundamenta duas entradas','INSERT INTO entrada(id_entrada,id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9290,9201,9202,9294,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','Duplicate entry');
CALL rel_confere('R10 Ida (minimo 0): avaliacao sem entrada','NOT EXISTS(SELECT 1 FROM entrada WHERE id_avaliacao=9205)');
-- R11-R19: demais relacionamentos do núcleo sobre o fixture transacional.
CALL rel_volta_obrigatoria('R11 Volta','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES({fk},9201,9202,''2026-02-06 10:00:00'',1,FALSE)','id_comprador','fk_venda_id_comprador');
CALL rel_aceita('R11/R12 Ida (maximo N): comprador e funcionario podem ter outra venda','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,9202,''2026-02-06 10:00:00'',1,FALSE)');
CALL rel_volta_obrigatoria('R12 Volta','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9201,{fk},9202,''2026-02-06 10:00:00'',1,FALSE)','id_funcionario','fk_venda_id_funcionario');
CALL rel_rejeita('R13 Volta (minimo 1)','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,NULL,''2026-02-06 10:00:00'',1,FALSE)','Venda exige entrada disponivel');
CALL rel_rejeita('R13 Volta (referencia inexistente interceptada por regra de disponibilidade)','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,999999999,''2026-02-06 10:00:00'',1,FALSE)','Venda exige entrada disponivel');
CALL rel_rejeita('R13 Ida (maximo 1): entrada ja vinculada a venda','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9201,''2026-02-06 10:00:00'',1,FALSE)','Duplicate entry');
CALL rel_confere('R13 Ida (minimo 0): entrada sem venda','NOT EXISTS(SELECT 1 FROM venda WHERE id_entrada_principal=9202)');
CALL rel_confere('R14 Ida (maximo N): venda aceita varias entradas de troca','(SELECT COUNT(*)=2 FROM entrada WHERE id_venda_origem=9201)');
CALL rel_confere('R14 Volta (minimo 0): compra propria nao aponta venda de origem','(SELECT id_venda_origem IS NULL FROM entrada WHERE id_entrada=9202)');
CALL rel_rejeita('R14 Volta (venda de origem inexistente)','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,id_venda_origem,modalidade,data_entrada,valor_acordado,preco_anunciado) VALUES(9205,9201,9205,999999999,''TROCA'',''2026-01-21 10:00:00'',1,1)','foreign key constraint fails');
CALL rel_aceita('R15 Volta (minimo 0): venda ainda sem laudo','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9202,''2026-02-06 10:00:00'',1,FALSE)');
CALL rel_rejeita('R15 Volta (laudo inexistente interceptado pela regra)','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,id_laudo,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9202,999999999,''2026-02-06 10:00:00'',1,FALSE)','Laudo deve corresponder');
CALL rel_confere('R15 Ida (maximo N): laudo 4 documenta duas vendas','(SELECT COUNT(*)=2 FROM venda WHERE id_laudo=4)');
CALL rel_rejeita('R16 Volta (minimo 1)','INSERT INTO ocorrencia_garantia(id_venda,data_abertura,problema_relatado,situacao) VALUES(NULL,''2026-02-05 10:00:00'',''x'',''ABERTA'')','Ocorrencia de garantia exige concessao e entrega anterior');
CALL rel_rejeita('R16 Volta (venda inexistente barrada pela regra de garantia)','INSERT INTO ocorrencia_garantia(id_venda,data_abertura,problema_relatado,situacao) VALUES(999999999,''2026-02-05 10:00:00'',''x'',''ABERTA'')','Ocorrencia de garantia exige concessao e entrega anterior');
INSERT INTO ocorrencia_garantia(id_venda,id_mecanico,data_abertura,problema_relatado,situacao) VALUES(1,NULL,'2026-02-05 10:00:00','fixture R16','ABERTA');
CALL rel_aceita('R16 Ida (maximo N) e R17 Volta (minimo 0): outra ocorrencia sem mecanico','INSERT INTO ocorrencia_garantia(id_venda,data_abertura,problema_relatado,situacao) VALUES(1,''2026-02-06 10:00:00'',''segunda ocorrencia'',''ABERTA'')');
CALL rel_rejeita('R17 Volta (mecanico inexistente)','INSERT INTO ocorrencia_garantia(id_venda,id_mecanico,data_abertura,problema_relatado,situacao) VALUES(1,999999999,''2026-02-06 10:00:00'',''x'',''ABERTA'')','fk_ocorrencia_garantia_id_mecanico');
CALL rel_confere('R17 Ida (maximo N): mecanico 4 esta em duas ocorrencias','(SELECT COUNT(*)=2 FROM ocorrencia_garantia WHERE id_mecanico=4)');
CALL rel_volta_obrigatoria('R18 Volta','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES({fk},''2026-01-15'',''PREPARACAO'',''x'',1)','id_veiculo','fk_despesa_id_veiculo');
CALL rel_aceita('R18 Ida (maximo N): segunda despesa do veiculo','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES(9201,''2026-01-16'',''DIAGNOSTICO'',''x'',50)');
CALL rel_rejeita('R19 Ida (maximo 1): entrada 4 ja tem sucessora','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,id_entrada_anterior,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,9202,9293,4,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''C-19'',''2026-01-21'',''ok'')','Duplicate entry');
CALL rel_rejeita('R19 Volta (anterior inexistente)','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,id_entrada_anterior,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,9202,9293,999999999,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''C-19B'',''2026-01-21'',''ok'')','foreign key constraint fails');
CALL rel_confere('R19 minimo 0: primeira entrada sem anterior nem sucessora','(SELECT id_entrada_anterior IS NULL FROM entrada WHERE id_entrada=9202) AND NOT EXISTS(SELECT 1 FROM entrada WHERE id_entrada_anterior=9202)');
-- R20-R22: atendimento, entrada e funcionario sustentam várias propostas.
CALL rel_volta_obrigatoria('R20 Volta','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base) VALUES({fk},9202,9201,''Z'',1,''2026-02-05'',''2026-02-12'',1)','id_atendimento','fk_proposta_id_atendimento');
CALL rel_volta_obrigatoria('R21 Volta','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base) VALUES(9201,{fk},9201,''Z'',1,''2026-02-05'',''2026-02-12'',1)','id_entrada','fk_proposta_id_entrada');
CALL rel_volta_obrigatoria('R22 Volta','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base) VALUES(9201,9202,{fk},''Z'',1,''2026-02-05'',''2026-02-12'',1)','id_funcionario','fk_proposta_id_funcionario');
CALL rel_confere('R20-R22 Ida (maximo N): atendimento, entrada e funcionario associados a propostas multiplas','(SELECT COUNT(*)=2 FROM proposta WHERE id_atendimento=9201) AND (SELECT COUNT(*)=3 FROM proposta WHERE id_entrada=9202) AND (SELECT COUNT(*)=3 FROM proposta WHERE id_funcionario=9201)');
-- R23: preparar uma cadeia válida para verificar unicidade da sucessora.
UPDATE proposta SET situacao='APRESENTADA' WHERE id_proposta=9201;
UPDATE proposta SET situacao='SUBSTITUIDA',data_decisao='2026-02-06 10:00:00' WHERE id_proposta=9201;
INSERT INTO proposta(id_proposta,id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base,situacao)
VALUES(9204,9201,9202,9201,9201,'A',2,'2026-02-06','2026-02-13',60000,'RASCUNHO');
CALL rel_rejeita('R23 Ida (maximo 1): duas sucessoras da mesma proposta','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base) VALUES(9201,9202,9201,9201,''A'',2,''2026-02-06'',''2026-02-13'',60000)','Duplicate entry');
CALL rel_rejeita('R23 Volta (anterior inexistente interceptado pela cadeia)','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base) VALUES(9201,9202,9201,999999999,''Z'',2,''2026-02-06'',''2026-02-13'',60000)','Contraproposta deve suceder');
CALL rel_confere('R23 minimo 0: raiz ainda sem sucessora','NOT EXISTS(SELECT 1 FROM proposta WHERE id_proposta_anterior=9202)');
-- R24: proposta e venda sao opcionais no lado inverso; o FK da venda e validado por regra antes da restricao.
CALL rel_confere('R24 minimo 0 nos dois lados: venda sem proposta e proposta ainda sem venda','(SELECT id_proposta IS NULL FROM venda WHERE id_venda=9201) AND NOT EXISTS(SELECT 1 FROM venda WHERE id_proposta=9202)');
CALL rel_rejeita('R24 Volta (proposta inexistente preemptada por validacao de proposta)','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,id_proposta,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,9202,999999999,''2026-02-06 10:00:00'',1,FALSE)','Venda exige proposta aceita');
UPDATE proposta SET situacao='APRESENTADA' WHERE id_proposta=9203;
SET @multiplikar_aceitar_proposta=9203; UPDATE proposta SET situacao='ACEITA',data_decisao='2026-02-06 10:00:00' WHERE id_proposta=9203; SET @multiplikar_aceitar_proposta=NULL;
INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,id_proposta,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9202,9203,'2026-02-06 10:30:00',60000,FALSE);
CALL rel_rejeita('R24 Ida (maximo 1): venda da mesma proposta nao duplica','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,id_proposta,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9202,9203,''2026-02-06 11:00:00'',60000,FALSE)','Duplicate entry');
-- R25: condição sempre tem proposta e forma; cada proposta pode ter várias formas.
CALL rel_rejeita('R25 Volta condicao-proposta (minimo 1)','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(NULL,''PIX'',1)','Proposta apresentada e imutavel');
CALL rel_rejeita('R25 Volta condicao-proposta (pai inexistente)','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(999999999,''PIX'',1)','Proposta apresentada e imutavel');
CALL rel_rejeita('R25 Volta condicao-forma (minimo 1)','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(9202,NULL,1)','codigo_forma');
CALL rel_rejeita('R25 Volta condicao-forma inexistente','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(9202,''BITCOIN'',1)','fk_proposta_condicao_codigo_forma');
INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(9202,'FINANCIAMENTO',1);
CALL rel_confere('R25 Ida (maximo N): proposta possui multiplas formas de pagamento','(SELECT COUNT(*)=2 FROM proposta_condicao WHERE id_proposta=9202)');
CALL rel_confere('R25 Volta forma (maximo N): PIX reutilizado em varias propostas','(SELECT COUNT(*)=3 FROM proposta_condicao WHERE codigo_forma=''PIX'' AND id_proposta BETWEEN 9201 AND 9203)');
-- R26: trocas exigem avaliação TROCA válida e podem incluir várias avaliações distintas.
CALL rel_rejeita('R26 Volta proposta inexistente barrada pela regra de rascunho','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(999999999,9205,1)','Troca exige avaliacao');
CALL rel_rejeita('R26 Volta avaliacao inexistente barrada pela regra de avaliacao','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9202,999999999,1)','Troca exige avaliacao');
INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9202,9205,25000),(9202,9206,15000);
CALL rel_confere('R26 Ida (maximo N): proposta inclui duas avaliacoes de troca','(SELECT COUNT(*)=2 FROM proposta_troca WHERE id_proposta=9202)');
CALL rel_rejeita('R26 Ida (maximo 1): avaliacao nao duplica na mesma proposta','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9202,9205,1)','Duplicate entry');
-- R27-R28: simulações admitem histórico, mas precisam proposta e parametro vigente.
CALL rel_volta_obrigatoria('R27 Volta','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,data_simulacao) VALUES({fk},''Banco Demonstracao'',''R0'',''ACADEMICA'',1000,0.02,12,''2026-02-05'')','id_proposta','fk_simulacao_financiamento_id_proposta');
INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,data_simulacao)
VALUES(9202,'Banco Demonstracao','R0','ACADEMICA',10000,0.02,12,5000,TRUE,'2026-02-05 10:00:00'),
(9202,'Banco Demonstracao','R0','ACADEMICA',12000,0.02,18,5000,TRUE,'2026-02-05 11:00:00');
CALL rel_confere('R27 Ida (maximo N): proposta tem varias simulacoes','(SELECT COUNT(*)=2 FROM simulacao_financiamento WHERE id_proposta=9202)');
CALL rel_rejeita('R27 Ida (maximo 1 APROVADA por proposta)','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) VALUES(9202,''Banco Demonstracao'',''R0'',''ACADEMICA'',10000,0.02,12,5000,TRUE,''APROVADA'',''2026-02-05 12:00:00''),(9202,''Banco Demonstracao'',''R0'',''ACADEMICA'',12000,0.02,18,5000,TRUE,''APROVADA'',''2026-02-05 13:00:00'')','Duplicate entry');
CALL rel_rejeita('R28 Volta (parametro de retorno inexistente ou fora da vigencia)','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,data_simulacao) VALUES(9202,''Banco Sem Parametro'',''R0'',''ACADEMICA'',10000,0.02,12,''2026-02-05 10:00:00'')','Parametro_retorno vigente nao encontrado');
-- R29-R31: obrigação aceita arco vazio ou uma origem; cada origem pode gerar várias obrigações.
INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual)
VALUES('RECEBER','VENDA',9201,'PIX','Cliente fixture',10,'2026-02-05','2026-02-05','2026-02-05');
INSERT INTO obrigacao_financeira(natureza,origem,id_entrada,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual)
VALUES('PAGAR','ENTRADA',9202,'REPASSE','Fornecedor fixture',10,'2026-02-05','2026-02-10','2026-02-10');
INSERT INTO obrigacao_financeira(natureza,origem,id_despesa,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual)
VALUES('PAGAR','DESPESA_VEICULO',9201,'OFICINA','Oficina fixture',10,'2026-02-05','2026-02-10','2026-02-10');
CALL rel_aceita('R29 Ida (maximo N): venda tem outra obrigacao','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''RECEBER'',''VENDA'',9201,''FINANCIAMENTO'',''Banco'',10,''2026-02-05'',''2026-02-20'',''2026-02-20'')');
CALL rel_aceita('R30 Ida (maximo N): entrada tem outra obrigacao','INSERT INTO obrigacao_financeira(natureza,origem,id_entrada,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ENTRADA'',9202,''REPASSE'',''Fornecedor'',10,''2026-02-05'',''2026-02-20'',''2026-02-20'')');
CALL rel_aceita('R31 Ida (maximo N): despesa tem outra obrigacao','INSERT INTO obrigacao_financeira(natureza,origem,id_despesa,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''DESPESA_VEICULO'',9201,''OFICINA'',''Oficina'',10,''2026-02-05'',''2026-02-20'',''2026-02-20'')');
CALL rel_aceita('R29-R31 Volta (minimo 0): obrigacao administrativa sem arco','INSERT INTO obrigacao_financeira(natureza,origem,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ADMINISTRATIVA'',''ALUGUEL'',''Imobiliaria'',10,''2026-02-05'',''2026-02-10'',''2026-02-10'')');
CALL rel_rejeita('R29 Volta (venda inexistente)','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''RECEBER'',''VENDA'',999999999,''PIX'',''x'',10,''2026-02-05'',''2026-02-05'',''2026-02-05'')','foreign key constraint fails');
CALL rel_rejeita('R30 Volta (entrada inexistente)','INSERT INTO obrigacao_financeira(natureza,origem,id_entrada,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ENTRADA'',999999999,''REPASSE'',''x'',10,''2026-02-05'',''2026-02-05'',''2026-02-05'')','foreign key constraint fails');
CALL rel_rejeita('R31 Volta (despesa inexistente)','INSERT INTO obrigacao_financeira(natureza,origem,id_despesa,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''DESPESA_VEICULO'',999999999,''OFICINA'',''x'',10,''2026-02-05'',''2026-02-05'',''2026-02-05'')','foreign key constraint fails');
CALL rel_rejeita('R29/R30 arco exclusivo','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,id_entrada,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''RECEBER'',''VENDA'',9201,9202,''PIX'',''x'',10,''2026-02-05'',''2026-02-05'',''2026-02-05'')','ck_obrigacao_arco');
-- R32-R38: interações, desfecho, classificação e fatores.
CALL rel_volta_obrigatoria('R32 Volta','INSERT INTO interacao(id_atendimento,id_funcionario,canal,direcao,resumo) VALUES({fk},9201,''TELEFONE'',''ENVIADA'',''x'')','id_atendimento','fk_interacao_id_atendimento');
CALL rel_volta_obrigatoria('R33 Volta','INSERT INTO interacao(id_atendimento,id_funcionario,canal,direcao,resumo) VALUES(9201,{fk},''TELEFONE'',''ENVIADA'',''x'')','id_funcionario','fk_interacao_id_funcionario');
CALL rel_aceita('R32/R33 Ida (maximo N): segundo contato no mesmo atendimento','INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9201,9201,''2026-02-06 09:00:00'',''WHATSAPP'',''RECEBIDA'',''resposta adicional'')');
INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES(9201,9201,'GANHO','fixture cardinalidade');
CALL rel_volta_obrigatoria('R34 Volta','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES({fk},9201,''GANHO'',''x'')','id_atendimento','fk_atendimento_desfecho_id_atendimento');
CALL rel_volta_obrigatoria('R38 Volta','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES(9202,{fk},''GANHO'',''x'')','id_funcionario','fk_atendimento_desfecho_id_funcionario');
CALL rel_rejeita('R34 Ida (maximo 1): segundo desfecho no atendimento','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES(9201,9201,''PERDA'',''duplicado'')','Duplicate entry');
CALL rel_aceita('R38 Ida (maximo N): mesmo funcionario encerra outro atendimento','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES(9202,9201,''PERDA'',''sem interesse'')');
CALL rel_volta_obrigatoria('R35 Volta','INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao) VALUES({fk},''2026-02-06 09:00:00'',''REGRA'',''REGRA-V1'',''FRIO'',0)','id_atendimento','fk_classificacao_lead_id_atendimento');
CALL registrar_classificacao_lead(9201,'REGRA-V1','2026-02-07 09:00:00',@classificacao_rel_2);
CALL rel_confere('R35 Ida (maximo N): atendimento recebeu duas classificacoes','(SELECT COUNT(*)>=2 FROM classificacao_lead WHERE id_atendimento=9201)');
CALL rel_confere('R36 Volta (minimo 0): nova classificacao aguarda revisao','(SELECT id_revisor IS NULL FROM classificacao_lead WHERE id_classificacao=@classificacao_rel_2)');
CALL rel_rejeita('R36 Volta (revisor inexistente)','UPDATE classificacao_lead SET temperatura_final=temperatura_sugerida,id_revisor=999999999,data_revisao=''2026-02-08 10:00:00'' WHERE id_classificacao=@classificacao_rel_2','fk_classificacao_lead_id_revisor');
CALL rel_aceita('R36 Ida (maximo N): funcionario revisa classificacoes distintas','UPDATE classificacao_lead SET temperatura_final=temperatura_sugerida,id_revisor=9201,data_revisao=''2026-02-08 10:00:00'',justificativa_revisao=''Revisao de teste'' WHERE id_classificacao=@classificacao_rel_2');
CALL rel_confere('R37 Ida (maximo N): classificacao registra quatro fatores','(SELECT COUNT(*)=4 FROM classificacao_fator WHERE id_classificacao=@classificacao_9201)');
CALL rel_rejeita('R37 Ida (minimo 1 fator): INSERT direto sem fatores','INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao) VALUES(9202,''2026-02-06 10:00:00'',''REGRA'',''REGRA-V1'',''FRIO'',0)','R37: classificacao de lead exige ao menos um fator explicativo; use registrar_classificacao_lead');
CALL rel_volta_obrigatoria('R37 Volta','INSERT INTO classificacao_fator(id_classificacao,codigo_fator,pontos,evidencia) VALUES({fk},''URGENCIA_CONTATO'',0,''teste'')','id_classificacao','fk_classificacao_fator_id_classificacao');
CALL rel_rejeita('R37 Volta (maximo 1): fator repetido na mesma classificacao','INSERT INTO classificacao_fator(id_classificacao,codigo_fator,pontos,evidencia) VALUES(@classificacao_9201,''URGENCIA_CONTATO'',0,''teste'')','Duplicate entry');
-- R39-R41: intenção e seus dois relacionamentos opcionais.
INSERT INTO intencao_compra(id_atendimento,id_entrada,codigo_forma,valor_disponivel,data_registro,origem) VALUES(9201,9207,'PIX',55000,'2026-02-05 09:30:00','VENDEDOR');
CALL rel_volta_obrigatoria('R39 Volta','INSERT INTO intencao_compra(id_atendimento,valor_disponivel,data_registro,origem) VALUES({fk},1000,''2026-02-05 09:00:00'',''VENDEDOR'')','id_atendimento','foreign key constraint fails');
CALL rel_rejeita('R39 Ida (maximo 1): segunda intencao no atendimento','INSERT INTO intencao_compra(id_atendimento,valor_disponivel,data_registro,origem) VALUES(9201,1000,''2026-02-05 09:00:00'',''VENDEDOR'')','Duplicate entry');
CALL rel_confere('R39 Ida (minimo 0): atendimento sem intencao','NOT EXISTS(SELECT 1 FROM intencao_compra WHERE id_atendimento=9202)');
CALL rel_aceita('R40/R41 Volta (minimo 0): intencao sem entrada nem forma','INSERT INTO intencao_compra(id_atendimento,valor_disponivel,data_registro,origem) VALUES(9202,1000,''2026-02-05 09:00:00'',''VENDEDOR'')');
CALL rel_rejeita('R40 Volta (entrada inexistente)','INSERT INTO intencao_compra(id_atendimento,id_entrada,data_registro,origem) VALUES(9202,999999999,''2026-02-05 09:00:00'',''VENDEDOR'')','foreign key constraint fails');
CALL rel_rejeita('R41 Volta (forma inexistente)','INSERT INTO intencao_compra(id_atendimento,codigo_forma,data_registro,origem) VALUES(9202,''BOLETO'',''2026-02-05 09:00:00'',''VENDEDOR'')','foreign key constraint fails');
INSERT INTO intencao_compra(id_atendimento,id_entrada,codigo_forma,data_registro,origem) VALUES(9202,9207,'PIX','2026-02-05 10:00:00','VENDEDOR');
CALL rel_confere('R40/R41 Ida (maximo N): mesma entrada e forma aparecem em várias intenções','(SELECT COUNT(*)=2 FROM intencao_compra WHERE id_entrada=9207 AND codigo_forma=''PIX'')');
CALL rel_aceita('R26 Volta (maximo N): mesma avaliacao pode aparecer em propostas distintas','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9204,9206,14000)');
INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9204,9206,14000);
CALL rel_confere('R26 Ida e Volta: proposta 9202 possui duas trocas e avaliacao 9206 esta em duas propostas','(SELECT COUNT(*)=2 FROM proposta_troca WHERE id_proposta=9202) AND (SELECT COUNT(*)=2 FROM proposta_troca WHERE id_avaliacao=9206)');
INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,data_simulacao)
VALUES(9202,'Banco Demonstracao','R4','ACADEMICA',13000,0.02,24,5000,TRUE,'2026-02-05 12:00:00');
CALL rel_confere('R27 Ida e R28 Volta: R0 e R4 vigentes geram tres simulacoes para a proposta','(SELECT COUNT(*)=3 FROM simulacao_financiamento WHERE id_proposta=9202) AND (SELECT COUNT(*)=2 FROM parametro_retorno WHERE instituicao=''Banco Demonstracao'' AND tabela_retorno IN(''R0'',''R4'') AND vigencia<=''2026-02-05'')');
CALL rel_confere('Fixture relacional: propostas e condicoes permanecem vinculadas a pais existentes','(SELECT COUNT(*)=3 FROM proposta WHERE id_proposta IN(9201,9202,9203) AND id_atendimento IN(9201,9202) AND id_entrada=9202 AND id_funcionario=9201) AND (SELECT COUNT(*)>=3 FROM proposta_condicao WHERE id_proposta IN(9201,9202,9203))');
CALL rel_confere('Fixture relacional: troca, financiamento e obrigacoes apontam para seus pais','(SELECT COUNT(*)=2 FROM proposta_troca WHERE id_proposta=9202) AND (SELECT COUNT(*)=3 FROM simulacao_financiamento WHERE id_proposta=9202) AND (SELECT COUNT(*)=1 FROM obrigacao_financeira WHERE id_venda=9201)');
CALL rel_confere('Suite de relacionamentos conclui com cobertura R01-R41 documentada','(SELECT COUNT(*)>=40 FROM information_schema.key_column_usage WHERE table_schema=DATABASE() AND referenced_table_name IS NOT NULL) AND EXISTS(SELECT 1 FROM information_schema.triggers WHERE trigger_schema=DATABASE() AND trigger_name=''simulacao_retorno_bi'')');
ROLLBACK;
CALL rel_restaurar_auto_increment();
DROP PROCEDURE rel_restaurar_auto_increment;
DROP PROCEDURE rel_rejeita; DROP PROCEDURE rel_aceita; DROP PROCEDURE rel_volta_obrigatoria; DROP PROCEDURE rel_confere; DROP TEMPORARY TABLE rel_resultado; DROP TEMPORARY TABLE rel_ai_before;

-- Restaura o modo Safe Updates da sessao.
SET SQL_SAFE_UPDATES = @mk_safe_updates;
