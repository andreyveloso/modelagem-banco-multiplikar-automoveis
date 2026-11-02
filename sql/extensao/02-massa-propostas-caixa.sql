-- Massa fixa para a extensão financeira; executada depois do 01.
USE multiplikar;
INSERT INTO parametro_referencia(chave,data_referencia,origem) VALUES(TRUE,'2026-02-10','DEMONSTRACAO');
INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,data,tipo_interesse,descricao_interesse,situacao) VALUES(7,10,1,'2026-02-02 12:00','COMPRA','Propostas para o Kwid consignado; comparacao de pagamento.','ABERTO');
INSERT INTO veiculo(id_veiculo,marca,modelo,ano_modelo,cor,placa,chassi,combustivel,cambio,categoria_comercial) VALUES(11,'Volkswagen','Gol',2018,'Prata','TST1A11','9TEST000000000011','Flex','Manual','USADO');
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES(11,11,3,'2026-02-02 10:00','TROCA',80000,2,'Conservada','Conservada','Vistoriada','Verificada','Conferida','APROVADA','SIM','Avaliacao especifica para a proposta do cliente 10.');
-- A posse do Gol não é modelada; a avaliação registra apenas a oferta para a proposta.
INSERT INTO parametro_prazo(banco,tipo_obrigacao,dias_previstos,origem,vigencia) SELECT instituicao_financeira,'FINANCIAMENTO_RECEBER',15,'HIPOTESE','2026-01-01' FROM venda WHERE id_venda=6;
INSERT INTO parametro_prazo VALUES('Consignante Demonstracao','CONSIGNANTE_PAGAR',5,'HIPOTESE','2026-01-01'),('Fornecedor Demonstracao','COMPRA_PROPRIA_PAGAR',3,'HIPOTESE','2026-01-01');
INSERT INTO parametro_retorno(instituicao,tabela_retorno,acrescimo_taxa_mensal,retorno_pct,origem,vigencia) SELECT instituicao_financeira,'R0',0,0,'HIPOTESE','2026-01-01' FROM venda WHERE id_venda=6;
INSERT INTO parametro_retorno(instituicao,tabela_retorno,acrescimo_taxa_mensal,retorno_pct,origem,vigencia) SELECT instituicao_financeira,'R4',0.0030,0.04,'HIPOTESE','2026-01-01' FROM venda WHERE id_venda=6;
INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base,desconto,acrescimo,taxas,situacao) VALUES(7,10,1,'A',1,'2026-02-03','2026-02-10',55000,0,0,0,'RASCUNHO'),(7,10,1,'B',1,'2026-02-03','2026-02-10',55000,0,0,0,'RASCUNHO'),(7,10,1,'C',1,'2026-02-03','2026-02-10',55000,0,0,0,'RASCUNHO');
INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor,prazo_previsto_dias) VALUES(1,'PIX',55000,0),(2,'PIX',11000,0),(2,'FINANCIAMENTO',44000,15),(3,'PIX',25000,0);
INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(3,11,30000);
UPDATE proposta SET situacao='APRESENTADA' WHERE id_atendimento=7;
INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,parcela_informada,renda_declarada,consentimento_renda,situacao,data_simulacao) SELECT 2,instituicao_financeira,'R0','ACADEMICA',44000,0.018900,48,1402.56,6500,TRUE,'EM_ANALISE','2026-02-03 10:00' FROM venda WHERE id_venda=6;
INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) SELECT 2,instituicao_financeira,'R4','ACADEMICA',44000,0.018900,48,6500,TRUE,'EM_ANALISE','2026-02-03 11:00' FROM venda WHERE id_venda=6;
INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual,situacao,origem_estimativa) SELECT 'RECEBER','VENDA',v.id_venda,'FINANCIAMENTO',v.instituicao_financeira,v.valor_financiado,DATE(v.data_aprovacao_financiamento),DATE_ADD(DATE(v.data_aprovacao_financiamento),INTERVAL pp.dias_previstos DAY),DATE_ADD(DATE(v.data_aprovacao_financiamento),INTERVAL pp.dias_previstos DAY),'ATRASADA','HIPOTESE' FROM venda v JOIN parametro_prazo pp ON pp.banco=v.instituicao_financeira AND pp.tipo_obrigacao='FINANCIAMENTO_RECEBER' AND pp.vigencia=(SELECT MAX(p2.vigencia) FROM parametro_prazo p2 WHERE p2.banco=v.instituicao_financeira AND p2.tipo_obrigacao='FINANCIAMENTO_RECEBER' AND p2.vigencia<=DATE(v.data_aprovacao_financiamento)) WHERE v.id_venda=6;
DELIMITER $$
CREATE PROCEDURE verificar_massa_propostas()
BEGIN
 IF (SELECT COUNT(*) FROM vw_proposta_comparativo WHERE id_atendimento=7)<>3 OR (SELECT COUNT(DISTINCT margem_estimada) FROM vw_proposta_comparativo WHERE id_atendimento=7)<>1 OR (SELECT COUNT(DISTINCT caixa_d0) FROM vw_proposta_comparativo WHERE id_atendimento=7)<>3 OR (SELECT valor_em_troca FROM vw_proposta_comparativo WHERE id_proposta=3)<>30000 OR (SELECT COUNT(*) FROM vw_simulacao_parcela WHERE id_proposta=2 AND consentimento_renda AND parcela_calculada>0)<>2 OR (SELECT parcela_calculada FROM vw_simulacao_parcela WHERE id_simulacao=2)<=(SELECT parcela_calculada FROM vw_simulacao_parcela WHERE id_simulacao=1) OR (SELECT retorno_loja FROM vw_simulacao_parcela WHERE id_simulacao=2)<>1760 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Demonstracao de propostas Kwid incoerente'; END IF;
 SELECT 'PASS demonstracao: alternativas A/B/C e trade-off R0/R4 conferidos' AS resultado;
 SELECT 'PASS massa proposta: condicoes, troca e simulacoes conferidas' AS resultado;
END$$
DELIMITER ;
CALL verificar_massa_propostas();
DROP PROCEDURE verificar_massa_propostas;

-- Casos de comportamento: cada chamada executa DML e válida o texto retornado pelo banco.
DROP PROCEDURE IF EXISTS teste_regra_ext02;
DELIMITER $$
CREATE PROCEDURE teste_regra_ext02(IN p_rotulo VARCHAR(120), IN p_sql TEXT, IN p_esperado VARCHAR(160))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN GET DIAGNOSTICS CONDITION 1 @msg = MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE;
  END;
  SET @teste_ext02_sql=p_sql; PREPARE teste_ext02_stmt FROM @teste_ext02_sql; EXECUTE teste_ext02_stmt; DEALLOCATE PREPARE teste_ext02_stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Operacao deveria ser recusada: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Regra inesperada em ',p_rotulo,': ',COALESCE(v_msg,'<vazia>')); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS ext02 ',p_rotulo,': ',p_esperado) AS resultado;
END$$
CREATE PROCEDURE confere_ext02(IN p_ok BOOLEAN, IN p_rotulo VARCHAR(160))
BEGIN DECLARE v_err TEXT; IF p_ok IS NULL OR NOT p_ok THEN SET v_err=CONCAT('Verificacao falhou: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF; SELECT CONCAT('PASS ext02 ',p_rotulo) AS resultado; END$$
DELIMITER ;
START TRANSACTION;
INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base) VALUES(7,10,1,'D',1,'2026-02-03','2026-02-10',100);
INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(4,'PIX',100);
CALL teste_regra_ext02('condicao duplicada na proposta','INSERT INTO proposta_condicao VALUES(4,''PIX'',100,0)','Duplicate entry');
CALL teste_regra_ext02('valor da condicao deve ser positivo','INSERT INTO proposta_condicao VALUES(4,''DINHEIRO'',0,0)','ck_proposta_condicao_valor');
CALL teste_regra_ext02('apresentada imutavel','UPDATE proposta SET valor_base=54000 WHERE id_proposta=1','Proposta apresentada e imutavel');
CALL teste_regra_ext02('condicao de proposta apresentada imutavel','UPDATE proposta_condicao SET valor=1 WHERE id_proposta=1 AND codigo_forma=''PIX''','Proposta apresentada e imutavel');
CALL teste_regra_ext02('ACEITA exige funcao atomica','UPDATE proposta SET situacao=''ACEITA'',data_decisao=''2026-02-04 10:00:00'' WHERE id_proposta=1','Use aceitar_proposta');
CALL teste_regra_ext02('consentimento de renda obrigatorio','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) SELECT 1,instituicao_financeira,''R0'',''ACADEMICA'',10000,0.02,12,5000,FALSE,''EM_ANALISE'',''2026-02-04 10:00:00'' FROM venda WHERE id_venda=6','ck_simulacao_consentimento_renda');
CALL teste_regra_ext02('retorno sem vigencia','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) VALUES(2,''Banco Demonstracao'',''R5'',''ACADEMICA'',10000,0.02,12,5000,TRUE,''EM_ANALISE'',''2026-02-04 10:00:00'')','Parametro_retorno vigente');
CALL teste_regra_ext02('simulacao nao pode ser apagada','DELETE FROM simulacao_financiamento WHERE id_simulacao=1','nao pode ser removida');
CALL teste_regra_ext02('simulacao em analise nao altera dados-base','UPDATE simulacao_financiamento SET tabela_retorno=''R4'' WHERE id_simulacao=1','so permite alterar situacao');
CALL teste_regra_ext02('obrigacao nao pode ser apagada','DELETE FROM obrigacao_financeira WHERE id_obrigacao=1','nao pode ser removida');
CALL teste_regra_ext02('vencimento original e imutavel','UPDATE obrigacao_financeira SET vencimento_original=''2026-03-01'' WHERE id_obrigacao=1','so permite alterar vencimento_atual');
CALL teste_regra_ext02('arco administrativo sem FK','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ADMINISTRATIVA'',6,''ADMIN'',''Teste'',100,''2026-02-10'',''2026-02-10'',''2026-02-10'')','ck_obrigacao_arco');
CALL teste_regra_ext02('troca ja consumida','INSERT INTO proposta_troca VALUES(1,8,10000)','Troca exige avaliacao aprovada');
CALL teste_regra_ext02('troca ligada a proposta apresentada','INSERT INTO proposta_troca VALUES(3,11,30000)','Troca exige avaliacao aprovada');
CALL teste_regra_ext02('percentual de retorno limitado','INSERT INTO parametro_retorno(instituicao,tabela_retorno,acrescimo_taxa_mensal,retorno_pct,origem,vigencia) VALUES(''Banco Teste'',''R4'',0.003,0.11,''HIPOTESE'',''2026-01-01'')','ck_parametro_retorno_pct');
CALL teste_regra_ext02('instituicao e tabela unicas por vigencia','INSERT INTO parametro_retorno SELECT instituicao,tabela_retorno,acrescimo_taxa_mensal,retorno_pct,origem,vigencia FROM parametro_retorno WHERE tabela_retorno=''R4'' LIMIT 1','Duplicate entry');
CALL teste_regra_ext02('obrigacao so permite campos de previsao','UPDATE obrigacao_financeira SET valor=valor+1 WHERE id_obrigacao=1','so permite alterar vencimento_atual');
CALL teste_regra_ext02('simulacao sem taxa tabela valida','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) VALUES(2,''Banco Demonstracao'',''R9'',''ACADEMICA'',10000,0.02,12,5000,TRUE,''EM_ANALISE'',''2026-02-04 10:00:00'')','Parametro_retorno vigente');
CALL teste_regra_ext02('venda referencia proposta nao aceita','UPDATE venda SET id_proposta=2 WHERE id_venda=6','Venda exige proposta aceita');
CALL teste_regra_ext02('datas da obrigacao em ordem','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''RECEBER'',''VENDA'',6,''FINANCIAMENTO'',''Banco'',100,''2026-02-10'',''2026-02-09'',''2026-02-09'')','ck_obrigacao_datas');
CALL teste_regra_ext02('raiz exige versao 1','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,valor_base) VALUES(7,10,1,''E'',2,''2026-02-03'',100)','Proposta raiz deve iniciar');
CALL teste_regra_ext02('alternativa raiz rotulo e versao unicos','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,valor_base) VALUES(7,10,1,''A'',1,''2026-02-03'',55000)','Duplicate entry');
CALL teste_regra_ext02('sucessora exige predecessora substituida','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base) VALUES(7,10,1,2,''B'',2,''2026-02-04'',''2026-02-17'',100)','Contraproposta deve suceder');
CALL teste_regra_ext02('decisao nula antes da decisao','UPDATE proposta SET data_decisao=''2026-02-04 10:00:00'' WHERE id_proposta=2','ck_proposta_data_decisao');
SET @multiplikar_aceitar_proposta=1;
CALL teste_regra_ext02('ACEITA depois da validade','UPDATE proposta SET situacao=''ACEITA'',data_decisao=''2026-02-11 10:00:00'' WHERE id_proposta=1','Proposta aceita exige entrada ativa');
SET @multiplikar_aceitar_proposta=NULL;
UPDATE obrigacao_financeira SET situacao='QUITADA' WHERE id_obrigacao=1;
CALL teste_regra_ext02('situacao terminal da obrigacao','UPDATE obrigacao_financeira SET situacao=''ATRASADA'' WHERE id_obrigacao=1','Situacao terminal da obrigacao financeira');
CALL teste_regra_ext02('transicao atrasada para aberta proibida','UPDATE obrigacao_financeira SET situacao=''ABERTA'' WHERE id_obrigacao=1','Situacao terminal da obrigacao financeira');
UPDATE simulacao_financiamento SET situacao='APROVADA',data_resposta='2026-02-04 12:00:00' WHERE id_simulacao=1;
CALL teste_regra_ext02('segunda simulacao aprovada para proposta','UPDATE simulacao_financiamento SET situacao=''APROVADA'',data_resposta=''2026-02-04 12:00:00'' WHERE id_simulacao=2','Duplicate entry');
CALL teste_regra_ext02('data resposta anterior a simulacao','UPDATE simulacao_financiamento SET data_resposta=''2026-02-02 10:00:00'' WHERE id_simulacao=2','ck_simulacao_datas');
CALL teste_regra_ext02('simulacao R4 em analise nao altera tabela','UPDATE simulacao_financiamento SET tabela_retorno=''R0'' WHERE id_simulacao=2','so permite alterar situacao');
UPDATE proposta SET situacao='SUBSTITUIDA',data_decisao='2026-02-04 10:00:00' WHERE id_proposta=1;
INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base,desconto,situacao)
SELECT id_atendimento,id_entrada,id_funcionario,id_proposta,'A',2,'2026-02-04','2026-02-17',55000,500,'RASCUNHO' FROM proposta WHERE id_proposta=1;
CALL confere_ext02((SELECT COUNT(*)=1 FROM proposta WHERE id_proposta_anterior=1 AND rotulo='A' AND versao=2 AND desconto=500),'substituicao positiva: alternativa A sucede para versao 2 e aplica desconto');
CALL teste_regra_ext02('sucessora herda rotulo','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base,situacao) SELECT id_atendimento,id_entrada,id_funcionario,id_proposta,''B'',3,''2026-02-04'',''2026-02-17'',55000,''RASCUNHO'' FROM proposta WHERE id_proposta=1','Contraproposta deve suceder a mesma alternativa');
ROLLBACK;
DROP PROCEDURE teste_regra_ext02;
DROP PROCEDURE confere_ext02;
