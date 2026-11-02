-- MySQL 8.4. Terceira migração de 01/11/2026: mensagens detalhadas do gatilho venda_bu.
-- Aplicar depois de 2026-11-01-revisao-dominios.sql e 2026-11-01-validacao-email.sql num banco existente.
-- As condições de RN22 (conclusão) e RN13/RN28-RN31 (cancelamento) não mudam; a mensagem de recusa passa a
-- listar quais condições estão pendentes, mantendo os prefixos 'RN22' e 'RN13/RN28-RN31'.
-- O gatilho é recriado na mesma posição de disparo (antes de venda_contrato_bu), como na instalação nova.
-- Entre o DROP e o CREATE o gatilho não existe por um instante: aplique fora do horário de uso.
-- Se a conferência interromper, remova o auxiliar com DROP PROCEDURE multiplikar.migracao_conferir_mensagens;
USE multiplikar;
DROP PROCEDURE IF EXISTS migracao_conferir_mensagens;
DELIMITER $$
CREATE PROCEDURE migracao_conferir_mensagens()
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.triggers WHERE trigger_schema='multiplikar' AND trigger_name='venda_contrato_bu') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Aplique antes 2026-11-01-revisao-dominios.sql';
 END IF;
 IF EXISTS(SELECT 1 FROM information_schema.triggers WHERE trigger_schema='multiplikar' AND trigger_name='venda_bu' AND action_statement LIKE '%RN22: pendente:%') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Migracao ja aplicada neste banco; nada a fazer';
 END IF;
 SELECT 'OK: banco pronto para atualizar venda_bu' AS conferencia;
END$$
DELIMITER ;
CALL migracao_conferir_mensagens();
DROP PROCEDURE migracao_conferir_mensagens;
DROP TRIGGER IF EXISTS venda_bu;
DELIMITER $$
CREATE TRIGGER venda_bu BEFORE UPDATE ON venda FOR EACH ROW PRECEDES venda_contrato_bu
BEGIN
 DECLARE v_status VARCHAR(18); DECLARE v_fim DATETIME; DECLARE v_trocas DECIMAL(14,2); DECLARE v_total DECIMAL(14,2); DECLARE v_docs INT; DECLARE v_firma INT; DECLARE v_formas INT; DECLARE v_fin_ok BOOLEAN; DECLARE v_pend VARCHAR(300) DEFAULT '';
 IF NOT(NEW.id_venda<=>OLD.id_venda) OR NOT(NEW.id_entrada_principal<=>OLD.id_entrada_principal) OR NOT(NEW.id_comprador<=>OLD.id_comprador) OR NOT(NEW.data_registro<=>OLD.data_registro) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identidade da venda e imutavel'; END IF;
 IF OLD.data_conclusao IS NOT NULL AND NOT(NEW.data_conclusao<=>OLD.data_conclusao) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Preserve o marco de conclusao'; END IF;
 IF OLD.situacao_comercial='CANCELADA' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Venda cancelada e historica; crie novo ciclo'; END IF;
 IF OLD.situacao_comercial='CONCLUIDA' AND OLD.concessao_garantia=TRUE AND NEW.concessao_garantia=FALSE THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN22: concessao de garantia da venda concluida e historica'; END IF;
 IF NEW.situacao_comercial='CONCLUIDA' AND OLD.situacao_comercial<>'CONCLUIDA' AND NOT(@multiplikar_operacao_venda<=>NEW.id_venda) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use concluir_venda para concluir com RN22'; END IF;
 IF NEW.situacao_comercial='CANCELADA' AND OLD.situacao_comercial<>'CANCELADA' THEN
  IF NOT(@multiplikar_operacao_venda<=>NEW.id_venda) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use cancelar_venda para registrar o desfazimento'; END IF;
  -- Mesmas quatro condições de antes; a mensagem passa a listar quais estão pendentes.
  IF NOT EXISTS(SELECT 1 FROM entrada WHERE id_entrada=NEW.id_entrada_principal AND situacao='ENCERRADA' AND motivo_encerramento='DESFAZIMENTO') THEN SET v_pend=CONCAT(v_pend,' encerrar entrada por DESFAZIMENTO;'); END IF;
  IF NOT EXISTS(SELECT 1 FROM entrada WHERE id_entrada_anterior=NEW.id_entrada_principal) THEN SET v_pend=CONCAT(v_pend,' novo ciclo;'); END IF;
  IF NEW.instituicao_financeira IS NOT NULL AND NEW.orientacao_bancaria IS NULL THEN SET v_pend=CONCAT(v_pend,' orientacao bancaria;'); END IF;
  IF (SELECT COUNT(*) FROM entrada WHERE id_venda_origem=NEW.id_venda AND (situacao<>'DEVOLVIDA' OR data_devolucao IS NULL))>0 THEN SET v_pend=CONCAT(v_pend,' devolver trocas;'); END IF;
  IF v_pend<>'' THEN SET v_pend=LEFT(CONCAT('RN13/RN28-RN31: cancelamento pendente:',v_pend),128); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_pend; END IF;
 END IF;
 IF NEW.situacao_comercial='CONCLUIDA' OR (NEW.data_conclusao IS NOT NULL AND NEW.situacao_comercial NOT IN('CANCELADA','EM_DESFAZIMENTO')) THEN
  SET v_total=NEW.valor_base-NEW.desconto+NEW.acrescimo+NEW.taxas;
  SELECT situacao,data_encerramento INTO v_status,v_fim FROM entrada WHERE id_entrada=NEW.id_entrada_principal;
  SELECT COALESCE(SUM(CASE WHEN data_devolucao IS NULL AND situacao NOT IN('EM_REGULARIZACAO','DEVOLVIDA','RETIRADA','ENCERRADA') THEN valor_acordado ELSE 0 END),0) INTO v_trocas FROM entrada WHERE id_venda_origem=NEW.id_venda;
  SELECT COUNT(*) INTO v_docs FROM venda_documento WHERE id_venda=NEW.id_venda AND data_conferencia IS NOT NULL AND (NEW.data_conclusao IS NULL OR data_conferencia<=NEW.data_conclusao) AND tipo_documento IN('CNH','LAUDO_CAUTELAR','CRLV','ATPV','COMPROVANTE_RESIDENCIA','CONTRATO');
  SELECT COUNT(*) INTO v_firma FROM venda_documento WHERE id_venda=NEW.id_venda AND tipo_documento IN('ATPV','CONTRATO') AND (NOT reconhecimento_aplicavel OR data_reconhecimento IS NOT NULL) AND (data_reconhecimento IS NULL OR NEW.data_conclusao IS NULL OR data_reconhecimento<=NEW.data_conclusao);
  SELECT COUNT(*) INTO v_formas FROM venda_forma_pagamento WHERE id_venda=NEW.id_venda;
  SET v_fin_ok=(NEW.instituicao_financeira IS NULL OR (NEW.situacao_financiamento='NAO_APROVADO' AND NEW.valor_recebido+v_trocas>=v_total) OR (NEW.situacao_financiamento='RECEBIDO' AND NEW.data_recebimento_financiamento IS NOT NULL));
  -- RN22: as mesmas condições, avaliadas em conjunto; a mensagem lista todas as pendências encontradas.
  IF NEW.data_conclusao IS NULL THEN SET v_pend=CONCAT(v_pend,' conclusao;'); END IF;
  IF NEW.numero_contrato IS NULL OR NEW.data_emissao IS NULL OR NEW.termos_condicoes IS NULL THEN SET v_pend=CONCAT(v_pend,' contrato;'); END IF;
  IF v_status<>'COMERCIALIZADA' OR NOT(v_fim<=>NEW.data_conclusao) THEN SET v_pend=CONCAT(v_pend,' entrada;'); END IF;
  IF NEW.valor_recebido+v_trocas<v_total THEN SET v_pend=CONCAT(v_pend,' pagamento;'); END IF;
  IF NOT v_fin_ok THEN SET v_pend=CONCAT(v_pend,' financiamento;'); END IF;
  IF v_formas=0 OR (NEW.instituicao_financeira IS NOT NULL AND NEW.situacao_financiamento<>'NAO_APROVADO' AND NOT EXISTS(SELECT 1 FROM venda_forma_pagamento WHERE id_venda=NEW.id_venda AND codigo_forma='FINANCIAMENTO')) THEN SET v_pend=CONCAT(v_pend,' formas;'); END IF;
  IF NEW.data_ultimo_recebimento IS NOT NULL AND NEW.data_ultimo_recebimento>NEW.data_conclusao THEN SET v_pend=CONCAT(v_pend,' recebimento posterior;'); END IF;
  IF v_docs<6 THEN SET v_pend=CONCAT(v_pend,' documentos;'); END IF;
  IF v_firma<2 THEN SET v_pend=CONCAT(v_pend,' firma;'); END IF;
  IF NEW.id_laudo IS NULL OR NOT EXISTS(SELECT 1 FROM laudo l JOIN entrada e ON e.id_entrada=NEW.id_entrada_principal WHERE l.id_laudo=NEW.id_laudo AND l.id_veiculo=e.id_veiculo AND l.data_emissao<=DATE(NEW.data_conclusao)) THEN SET v_pend=CONCAT(v_pend,' laudo;'); END IF;
  IF v_pend<>'' THEN SET v_pend=LEFT(CONCAT('RN22: pendente:',v_pend),128); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_pend; END IF;
 END IF;
END$$
DELIMITER ;
SELECT 'OK: mensagens de venda_bu atualizadas' AS resultado;
