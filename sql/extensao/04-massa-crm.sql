-- Dados fictícios do CRM. A referência única é definida na massa do arquivo 02.
USE multiplikar;
INSERT INTO parametro_temperatura VALUES('FRIO',0.0500,'HIPOTESE','2026-01-01'),('MORNO',0.3000,'HIPOTESE','2026-01-01'),('QUENTE',0.6500,'HIPOTESE','2026-01-01');
INSERT INTO pessoa(id_pessoa,nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf,possui_cnh) VALUES(14,'Oto Desistente','CPF','00000000014','11900000014','pessoa14@example.invalid','Rua de Teste','14','Vila Sao Geraldo','Sao Paulo','SP',TRUE),(15,'Paula Morna','CPF','00000000015','11900000015','pessoa15@example.invalid','Rua de Teste','15','Vila Sao Geraldo','Sao Paulo','SP',TRUE);
INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,data,tipo_interesse,descricao_interesse,situacao) VALUES(8,14,2,'2026-01-20 08:45','COMPRA','HB20 usado, avaliando opcoes','EM_NEGOCIACAO'),(9,15,1,'2026-01-11 09:00','COMPRA','Tracker, ainda sem decisao','ABERTO');
INSERT INTO interacao(id_interacao,id_atendimento,id_funcionario,data_hora,canal,direcao,resumo,proximo_passo,data_proximo_passo) VALUES(1,5,1,'2026-01-09 09:15','TELEFONE','ENVIADA','Primeiro contato sobre o Tracker.','Aguardar resposta','2026-01-12 09:00'),(2,5,1,'2026-01-10 11:00','WHATSAPP','RECEBIDA','Cliente perguntou prazo do financiamento.','Retornar','2026-01-13 11:00');
SET @id_classificacao=NULL; CALL registrar_classificacao_lead(5,'REGRA-V1','2026-01-26 11:00',@id_classificacao);
UPDATE classificacao_lead SET temperatura_final='QUENTE',id_revisor=1,data_revisao='2026-01-26 15:00' WHERE id_classificacao=@id_classificacao;
INSERT INTO interacao VALUES(3,7,1,'2026-02-03 09:00','PRESENCIAL','RECEBIDA','Cliente recebeu tres propostas Kwid e pediu tempo.','Confirmar escolha','2026-02-06 09:00');
CALL registrar_classificacao_lead(7,'REGRA-V1','2026-02-10 09:00',@id_classificacao);
UPDATE classificacao_lead SET temperatura_final='QUENTE',id_revisor=1,data_revisao='2026-02-10 15:00',justificativa_revisao='Urgencia informada pelo vendedor; cliente aguarda assinatura.' WHERE id_classificacao=@id_classificacao;
INSERT INTO interacao VALUES(4,8,2,'2026-01-20 09:00','TELEFONE','ENVIADA','Contato inicial sobre HB20.','Aguardar retorno','2026-01-25 09:00');
CALL registrar_classificacao_lead(8,'REGRA-V1','2026-01-22 09:00',@id_classificacao);
INSERT INTO interacao(id_interacao,id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(5,8,2,'2026-01-28 14:00','WHATSAPP','RECEBIDA','Cliente fechou em outra revenda.');
UPDATE atendimento SET situacao='ENCERRADO' WHERE id_atendimento=8;
INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,data_hora,tipo_desfecho,motivo,detalhe) VALUES(8,2,'2026-01-28 14:30','PERDA','Cliente fechou negocio em outra revenda','Informado por WhatsApp.');
INSERT INTO interacao(id_interacao,id_atendimento,id_funcionario,data_hora,canal,direcao,resumo,proximo_passo,data_proximo_passo) VALUES(6,9,1,'2026-01-11 09:00','EMAIL','ENVIADA','Catalogo do Tracker enviado.','Aguardar manifestacao','2026-01-20 09:00');
CALL registrar_classificacao_lead(9,'REGRA-V1','2026-01-12 09:00',@id_classificacao);
DELIMITER $$
CREATE PROCEDURE verificar_massa_crm()
BEGIN
 IF data_referencia()<>'2026-02-10' OR (SELECT COUNT(*) FROM classificacao_lead)<>4 OR (SELECT temperatura_sugerida FROM vw_lead_atual WHERE id_atendimento=7)<>'MORNO' OR (SELECT temperatura_atual FROM vw_lead_atual WHERE id_atendimento=7)<>'QUENTE' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Massa CRM incoerente'; END IF;
 SELECT 'PASS CRM: quatro classificacoes e referencia 2026-02-10 conferidas' AS resultado;
 SELECT 'PASS CRM: atendimento 7 MORNO sugerido e QUENTE revisado' AS resultado;
 IF EXISTS(SELECT 1 FROM vw_lead_atual WHERE id_atendimento=8 AND tipo_desfecho<>'PERDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Desfecho CRM incorreto'; END IF;
 SELECT 'PASS CRM: atendimento 8 encerrado com desfecho de perda' AS resultado;
END$$
DELIMITER ;
CALL verificar_massa_crm();
DROP PROCEDURE verificar_massa_crm;

-- Testes de regras CRM com operações reais; TRUNCATE e tratado na paridade documental.
DROP PROCEDURE IF EXISTS teste_regra_crm;
DELIMITER $$
CREATE PROCEDURE teste_regra_crm(IN p_rotulo VARCHAR(120), IN p_sql TEXT, IN p_esperado VARCHAR(160))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN GET DIAGNOSTICS CONDITION 1 @msg=MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE; IF p_sql NOT LIKE 'CALL registrar_classificacao_lead%' THEN SET @mk_registrando_classificacao=NULL; END IF;
  END;
  IF p_sql LIKE 'INSERT INTO classificacao_lead%' THEN SET @mk_registrando_classificacao=1; END IF;
  SET @teste_crm_sql=p_sql; PREPARE teste_crm_stmt FROM @teste_crm_sql; EXECUTE teste_crm_stmt; DEALLOCATE PREPARE teste_crm_stmt;
  IF p_sql NOT LIKE 'CALL registrar_classificacao_lead%' THEN SET @mk_registrando_classificacao=NULL; END IF;
 END;
 IF p_sql LIKE 'CALL registrar_classificacao_lead%' AND @mk_registrando_classificacao IS NOT NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='R37: procedure nao limpou a marca apos erro'; END IF;
 SET @mk_registrando_classificacao=NULL;
 IF NOT v_falhou THEN SET v_err=CONCAT('Operacao CRM deveria ser recusada: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Mensagem CRM inesperada em ',p_rotulo,': ',COALESCE(v_msg,'<vazia>')); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS CRM ',p_rotulo,': ',p_esperado) AS resultado;
END$$
DELIMITER ;
START TRANSACTION;
CALL teste_regra_crm('interacao somente insercao update','UPDATE interacao SET resumo=''alterado'' WHERE id_interacao=1','somente insercao');
CALL teste_regra_crm('interacao somente insercao delete','DELETE FROM interacao WHERE id_interacao=1','somente insercao');
CALL teste_regra_crm('desfecho somente insercao update','UPDATE atendimento_desfecho SET motivo=''alterado'' WHERE id_atendimento=8','somente insercao');
CALL teste_regra_crm('desfecho somente insercao delete','DELETE FROM atendimento_desfecho WHERE id_atendimento=8','somente insercao');
CALL teste_regra_crm('fator somente insercao update','UPDATE classificacao_fator SET pontos=pontos+1 WHERE id_classificacao=1 LIMIT 1','somente insercao');
CALL teste_regra_crm('fator somente insercao delete','DELETE FROM classificacao_fator WHERE id_classificacao=1 LIMIT 1','somente insercao');
CALL teste_regra_crm('classificacao revisada imutavel','UPDATE classificacao_lead SET temperatura_final=''FRIO'' WHERE id_classificacao=1','Apenas revisao humana ausente');
CALL teste_regra_crm('classificacao historica nao apaga','DELETE FROM classificacao_lead WHERE id_classificacao=1','historico; nunca e apagada');
CALL teste_regra_crm('temperatura fora do dominio','INSERT INTO parametro_temperatura VALUES(''QUENTEX'',0.5,''HIPOTESE'',''2026-01-01'')','ck_parametro_temperatura');
CALL teste_regra_crm('probabilidade fora do intervalo','INSERT INTO parametro_temperatura VALUES(''FRIO'',1.5,''HIPOTESE'',''2026-01-01'')','ck_parametro_probabilidade');
CALL teste_regra_crm('fator fora do dominio','INSERT INTO classificacao_fator VALUES(1,''FATOR_INVALIDO'',1,''x'')','ck_fator_codigo');
CALL teste_regra_crm('classificacao sem atendimento','INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao) VALUES(9999,''2026-02-10 10:00:00'',''REGRA'',''REGRA-V1'',''FRIO'',0)','fk_classificacao_lead_id_atendimento');
CALL teste_regra_crm('desfecho duplicado','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,data_hora,tipo_desfecho,motivo) VALUES(8,2,''2026-01-29 10:00:00'',''PERDA'',''Duplicado'')','Duplicate entry');
CALL teste_regra_crm('tipo de desfecho fora do dominio','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,data_hora,tipo_desfecho,motivo) VALUES(9,1,''2026-02-10 10:00:00'',''PENDENTE'',''x'')','ck_desfecho_tipo');
CALL teste_regra_crm('interacao com atendimento inexistente','INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9999,1,''2026-02-10 10:00:00'',''TELEFONE'',''ENVIADA'',''x'')','fk_interacao_id_atendimento');
CALL teste_regra_crm('proximo passo antes da interacao','INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo,proximo_passo,data_proximo_passo) VALUES(9,1,''2026-02-10 10:00:00'',''TELEFONE'',''ENVIADA'',''x'',''Retornar'',''2026-02-09 10:00:00'')','ck_interacao_proximo_passo');
CALL teste_regra_crm('interacao sem resumo','INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9,1,''2026-02-10 10:00:00'',''TELEFONE'',''ENVIADA'','''')','ck_interacao_resumo');
CALL teste_regra_crm('parametro temperatura duplicado','INSERT INTO parametro_temperatura SELECT temperatura,probabilidade,origem,vigencia FROM parametro_temperatura WHERE temperatura=''MORNO''','Duplicate entry');
CALL teste_regra_crm('revisao divergente exige justificativa','INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao,temperatura_final) VALUES(9,''2026-02-10 10:00:00'',''REGRA'',''REGRA-V1'',''FRIO'',0,''QUENTE'')','ck_classificacao_justificativa');
CALL teste_regra_crm('procedure limpa marca da sessao apos INSERT falho','CALL registrar_classificacao_lead(9,''REGRA-V1'',NULL,@classificacao_falha)','data_hora');
ROLLBACK;
DROP PROCEDURE teste_regra_crm;
