-- Verificações ponta a ponta das regras no MySQL 8.4; todas as mutações de teste sofrem ROLLBACK.
-- O MySQL Workbench liga o modo Safe Updates por padrão, que recusa UPDATE/DELETE sem coluna-chave
-- no WHERE. Este script faz essas operações de proposito (inclusive dentro dos testes), entao o modo
-- e desligado só durante a execução e o valor anterior e restaurado no fim.
SET @mk_safe_updates = @@SESSION.sql_safe_updates;
SET SQL_SAFE_UPDATES = 0;
USE multiplikar;
DROP PROCEDURE IF EXISTS fluxo_rejeicao;
DROP PROCEDURE IF EXISTS fluxo_confere;
DROP PROCEDURE IF EXISTS fluxo_recusa_regra;
DELIMITER $$
CREATE PROCEDURE fluxo_rejeicao(IN p_nome VARCHAR(120),IN p_sql TEXT)
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE;
 BEGIN DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_falhou=TRUE; SET @sql_fluxo=p_sql; PREPARE s FROM @sql_fluxo; EXECUTE s; DEALLOCATE PREPARE s; END;
 IF NOT v_falhou THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Fluxo invalido foi aceito'; END IF;
 SELECT CONCAT('PASS fluxo desvio ',p_nome,': operacao recusada') AS resultado;
END$$
CREATE PROCEDURE fluxo_confere(IN p_nome VARCHAR(120),IN p_ok BOOLEAN)
BEGIN IF p_ok IS NULL OR NOT p_ok THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Verificacao de fluxo falhou'; END IF; SELECT CONCAT('PASS fluxo ',p_nome) AS resultado; END$$
CREATE PROCEDURE fluxo_recusa_regra(IN p_nome VARCHAR(120),IN p_sql TEXT,IN p_esperado VARCHAR(128))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 @msg=MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE; END;
  SET @sql_fluxo=p_sql; PREPARE fluxo_stmt FROM @sql_fluxo; EXECUTE fluxo_stmt; DEALLOCATE PREPARE fluxo_stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Desvio foi aceito: ',p_nome); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Regra incorreta: ',p_nome); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS fluxo desvio ',p_nome,': ',p_esperado) AS resultado;
END$$
DELIMITER ;
START TRANSACTION;
CALL fluxo_confere('demonstracao tem alternativas A/B/C', (SELECT COUNT(*)=3 FROM proposta WHERE id_atendimento=7 AND versao=1 AND situacao='APRESENTADA'));
CALL fluxo_confere('R0 e R4 estao disponiveis para a simulacao', (SELECT COUNT(*)=2 FROM vw_simulacao_parcela WHERE id_proposta=2));
CALL fluxo_confere('margem estimada igual nas tres alternativas', (SELECT COUNT(DISTINCT margem_estimada)=1 FROM vw_proposta_comparativo WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('valor de troca nao aparece como caixa D0', (SELECT caixa_d0=25000 FROM vw_proposta_comparativo WHERE id_proposta=3));
CALL fluxo_confere('saldo de entrada da semana incorpora 6 mil liquidos', (SELECT obrigacoes=6000 FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('recebimento vencido da venda 6 compoe explicacao', (SELECT composicao LIKE '%80000%' FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('CRM exclui atendimento convertido', (SELECT COUNT(*)=0 FROM vw_fila_acoes f JOIN atendimento a ON f.id_referencia=a.id_atendimento WHERE f.fonte='CRM' AND a.situacao='CONVERTIDO'));
CALL fluxo_confere('simulacao R4 aumenta parcela e retorno da loja', ((SELECT parcela_calculada FROM vw_simulacao_parcela WHERE id_simulacao=2)>(SELECT parcela_calculada FROM vw_simulacao_parcela WHERE id_simulacao=1)) AND (SELECT retorno_loja=1760 FROM vw_simulacao_parcela WHERE id_simulacao=2));
CALL fluxo_confere('PMT, total pago e CET preservam centavos e escala', (SELECT parcela_calculada=1402.56 AND custo_total_cliente=67322.88 AND cet_aproximado_anual=0.251926 FROM vw_simulacao_parcela WHERE id_simulacao=1) AND (SELECT parcela_calculada=1490.50 AND custo_total_cliente=71544.00 AND cet_aproximado_anual=0.296883 FROM vw_simulacao_parcela WHERE id_simulacao=2));
CALL fluxo_confere('parcelas e retorno do banco identificados como movimento bancario para o cenario de atraso',(SELECT COUNT(*)=2 FROM vw_fluxos_previsao WHERE camada='FUNIL' AND bancario=TRUE AND descricao LIKE '%FINANCIAMENTO%' OR camada='FUNIL' AND bancario=TRUE AND descricao LIKE '%RETORNO BANCO%'));
CALL fluxo_rejeicao('venda proposta para outro cliente','UPDATE venda SET id_proposta=1 WHERE id_venda=6');
CALL fluxo_rejeicao('delete historico de interacao','DELETE FROM interacao WHERE id_interacao=1');
CALL fluxo_rejeicao('troca consumida','INSERT INTO proposta_troca VALUES(1,1,10000)');
CALL fluxo_rejeicao('arco administrativo preenchido','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ADMINISTRATIVA'',6,''ADMIN'',''Teste'',100,''2026-02-10'',''2026-02-10'',''2026-02-10'')');
CALL fluxo_rejeicao('obrigacao terminal imutavel','DELETE FROM obrigacao_financeira WHERE id_obrigacao=1');
CALL fluxo_rejeicao('simulacao nao pode ser apagada','DELETE FROM simulacao_financiamento WHERE id_simulacao=1');
CALL fluxo_rejeicao('simulacao exige tabela vigente','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,situacao,data_simulacao) VALUES(2,''Banco Demonstracao'',''R5'',''ACADEMICA'',10000,0.02,12,''EM_ANALISE'',''2026-02-10'')');
INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,valor_base) VALUES(7,10,1,'Z',1,'2026-02-03',100);
CALL fluxo_confere('validade omitida ancora em data_referencia', (SELECT validade='2026-02-17' FROM proposta WHERE rotulo='Z'));
CALL fluxo_recusa_regra('proposta rascunho nao aceita direto','UPDATE proposta SET situacao=''ACEITA'',data_decisao=''2026-02-04 10:00:00'' WHERE rotulo=''Z''','apresentada antes da decisao');
CALL fluxo_recusa_regra('proposta nao apresenta sem condicoes','UPDATE proposta SET situacao=''APRESENTADA'' WHERE rotulo=''Z''','Composicao da proposta deve igualar');
CALL fluxo_recusa_regra('nova venda nao vincula proposta apresentada','UPDATE venda SET id_proposta=1 WHERE id_venda=6','Venda exige proposta aceita');
INSERT INTO obrigacao_financeira(natureza,origem,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual,situacao,origem_estimativa) VALUES('PAGAR','ADMINISTRATIVA','TESTE','Fornecedor',100,'2026-02-10','2026-02-10','2026-02-10','PREVISTA','HIPOTESE');
UPDATE obrigacao_financeira SET situacao='ABERTA' WHERE id_obrigacao=LAST_INSERT_ID();
CALL fluxo_confere('obrigacao prevista abre no fluxo permitido',(SELECT COUNT(*)=1 FROM obrigacao_financeira WHERE origem='ADMINISTRATIVA' AND categoria='TESTE' AND situacao='ABERTA'));
CALL fluxo_recusa_regra('transicao invalida de obrigacao','UPDATE obrigacao_financeira SET situacao=''PREVISTA'' WHERE categoria=''TESTE''','Transicao de situacao da obrigacao financeira invalida');
UPDATE simulacao_financiamento SET situacao='RECUSADA',data_resposta='2026-02-04 10:00:00' WHERE id_simulacao=1;
CALL fluxo_recusa_regra('simulacao depois da resposta nao edita parcela','UPDATE simulacao_financiamento SET parcela_informada=1 WHERE id_simulacao=1','imutavel apos EM_ANALISE');
SET @multiplikar_aceitar_proposta=1;
UPDATE proposta SET situacao='ACEITA',data_decisao='2026-02-04 10:00:00' WHERE id_proposta=1;
SET @multiplikar_aceitar_proposta=NULL;
CALL fluxo_recusa_regra('situacao terminal da proposta','UPDATE proposta SET situacao=''RECUSADA'',motivo_recusa=''Teste'',data_decisao=''2026-02-04 10:00:00'' WHERE id_proposta=1','Situacao terminal da proposta e imutavel');
-- Cobertura adicional dos fluxos 01-09: consultas reais e transições contra a massa.
CALL fluxo_confere('09 alternativas A/B/C usam a entrada 10', (SELECT COUNT(*)=3 AND COUNT(DISTINCT id_entrada)=1 FROM proposta WHERE id_atendimento=7 AND id_entrada=10 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 cada alternativa comeca como versao raiz', (SELECT MIN(versao)=1 AND MAX(versao)=1 AND COUNT(DISTINCT rotulo)=3 FROM proposta WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 proposta A e PIX integral', (SELECT COUNT(*)=1 AND SUM(valor)=55000 FROM proposta_condicao WHERE id_proposta=1 AND codigo_forma='PIX'));
CALL fluxo_confere('09 proposta B combina entrada PIX de 20 por cento', (SELECT COUNT(*)=1 AND SUM(valor)=11000 FROM proposta_condicao WHERE id_proposta=2 AND codigo_forma='PIX'));
CALL fluxo_confere('09 proposta B financia o saldo de 80 por cento', (SELECT COUNT(*)=1 AND SUM(valor)=44000 FROM proposta_condicao WHERE id_proposta=2 AND codigo_forma='FINANCIAMENTO'));
CALL fluxo_confere('09 proposta C registra a entrada PIX em dinheiro', (SELECT COUNT(*)=1 AND SUM(valor)=25000 FROM proposta_condicao WHERE id_proposta=3 AND codigo_forma='PIX'));
CALL fluxo_confere('09 proposta C registra o Gol avaliado como troca', (SELECT COUNT(*)=1 AND SUM(valor_oferecido)=30000 FROM proposta_troca WHERE id_proposta=3));
CALL fluxo_confere('09 as condicoes e a troca fecham o total de cada proposta', NOT EXISTS(SELECT 1 FROM proposta p WHERE p.id_atendimento=7 AND p.rotulo IN('A','B','C') AND p.valor_total<>(SELECT COALESCE(SUM(c.valor),0) FROM proposta_condicao c WHERE c.id_proposta=p.id_proposta)+(SELECT COALESCE(SUM(t.valor_oferecido),0) FROM proposta_troca t WHERE t.id_proposta=p.id_proposta)));
CALL fluxo_confere('09 comparador usa o CPF do cliente do atendimento', (SELECT COUNT(DISTINCT cpf)=1 AND MIN(cpf)='00000000010' FROM vw_proposta_comparativo WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 recebimento no ato varia por alternativa', (SELECT COUNT(*)=3 AND MIN(caixa_d0)=11000 AND MAX(caixa_d0)=55000 FROM vw_proposta_comparativo WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 valor recebido depois do ato e separado do caixa D0', (SELECT caixa_posterior=45760 FROM vw_proposta_comparativo WHERE id_proposta=2));
CALL fluxo_confere('09 troca nao e receita em dinheiro nem altera caixa D0', (SELECT valor_em_troca=30000 AND caixa_d0=25000 FROM vw_proposta_comparativo WHERE id_proposta=3));
CALL fluxo_confere('09 margem de veiculo permanece igual nas tres opcoes', (SELECT COUNT(DISTINCT margem_estimada)=1 FROM vw_proposta_comparativo WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 retorno do banco soma apenas a margem da proposta financiada', (SELECT retorno_banco=1760 AND margem_com_retorno=margem_estimada+retorno_banco FROM vw_proposta_comparativo WHERE id_proposta=2));
CALL fluxo_confere('09 simulacao R0 usa a taxa base mensal', (SELECT parcela_calculada=1402.56 AND taxa_cliente_mensal=0.0189 FROM vw_simulacao_parcela WHERE id_simulacao=1));
CALL fluxo_confere('09 simulacao R0 apresenta CET anual aproximado', (SELECT cet_aproximado_anual=0.251926 FROM vw_simulacao_parcela WHERE id_simulacao=1));
CALL fluxo_confere('09 simulacao R4 soma acrescimo a taxa base', (SELECT taxa_cliente_mensal=0.0219 FROM vw_simulacao_parcela WHERE id_simulacao=2));
CALL fluxo_confere('09 simulacao R4 mostra CET anual aproximado maior', (SELECT cet_aproximado_anual=0.296883 FROM vw_simulacao_parcela WHERE id_simulacao=2));
CALL fluxo_confere('09 simulacao R0 nao remunera retorno a loja', (SELECT retorno_loja=0 FROM vw_simulacao_parcela WHERE id_simulacao=1));
CALL fluxo_confere('09 simulacao aprovada mantem consentimento de renda', (SELECT COUNT(*)=2 AND MIN(consentimento_renda)=1 FROM simulacao_financiamento WHERE id_proposta=2));
CALL fluxo_confere('01 atendimento 7 preserva a data de abertura do contato', (SELECT data_abertura='2026-02-02 12:00:00' FROM vw_lead_atual WHERE id_atendimento=7));
CALL fluxo_confere('01 lead final esta revisado por funcionario ativo', (SELECT revisado=1 AND id_revisor=1 AND temperatura_atual='QUENTE' FROM vw_lead_atual WHERE id_atendimento=7));
CALL fluxo_confere('01 classificacao humana preserva sugestao MORNO', (SELECT temperatura_sugerida='MORNO' AND temperatura_final='QUENTE' FROM vw_lead_atual WHERE id_atendimento=7));
CALL fluxo_confere('01 lead mantem uma interacao no historico', (SELECT total_interacoes=1 AND data_ultima_interacao='2026-02-03 09:00:00' FROM vw_lead_atual WHERE id_atendimento=7));
CALL fluxo_confere('01 fila CRM prioriza o lead quente de 55 mil', (SELECT COUNT(*)=1 AND MAX(valor_em_risco)=55000 FROM vw_fila_acoes WHERE fonte='CRM' AND id_referencia=7));
CALL fluxo_confere('08 fila de caixa identifica a obrigacao da venda 6', (SELECT COUNT(*)=1 AND MAX(valor_em_risco)=80000 FROM vw_fila_acoes WHERE fonte='CAIXA' AND id_referencia=1));
CALL fluxo_confere('08 saldo de venda 6 permanece a receber', (SELECT situacao_financiamento='APROVADO_A_RECEBER' AND valor_recebido=10000 FROM venda WHERE id_venda=6));
CALL fluxo_confere('08 obrigacao da venda 6 preserva vencimento original', (SELECT vencimento_original='2026-01-25' AND situacao='ATRASADA' FROM obrigacao_financeira WHERE id_obrigacao=1));
CALL fluxo_confere('05 previsao inclui semana atual e semanas futuras', (SELECT COUNT(*)=4 AND MIN(semana)='2026-02-09' FROM vw_previsao_caixa));
CALL fluxo_confere('05 previsao parte do saldo inicial hipotetico documentado', (SELECT composicao LIKE '%Saldo inicial HIPOTESE R$ 25000%' FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('05 camada realizado e recebimentos historicos ate a referencia', (SELECT SUM(realizado)=0 FROM vw_previsao_caixa));
CALL fluxo_confere('05 primeira semana explica obrigacao vencida da venda 6', (SELECT composicao LIKE '%Obrigacao 1 RECEBER 80000.00%' FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('05 recebimento vencido de 80 mil entra na semana inicial com aviso', (SELECT composicao LIKE '%vencida antes da referencia; incluida na primeira semana%' AND composicao LIKE '%80000.00%' FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('05 semana do financiamento inclui caixa liquido ponderado', (SELECT funil_ponderado>0 AND composicao LIKE '%RETORNO BANCO%' FROM vw_previsao_caixa WHERE semana='2026-02-23'));
CALL fluxo_confere('05 semana do repasse registra saida do consignante ponderada', (SELECT funil_ponderado<0 AND composicao LIKE '%PAGAR consignante na proposta 2%' FROM vw_previsao_caixa WHERE semana='2026-03-02'));
CALL fluxo_recusa_regra('09 proposta apresentada nao permite alterar preco','UPDATE proposta SET valor_base=1 WHERE id_proposta=1','Proposta apresentada e imutavel');
CALL fluxo_recusa_regra('09 proposta apresentada nao permite incluir condicao','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(1,''DINHEIRO'',1)','Proposta apresentada e imutavel');
CALL fluxo_recusa_regra('09 aceite direto sem aceitar_proposta e bloqueado','UPDATE proposta SET situacao=''ACEITA'',data_decisao=''2026-02-04 10:00:00'' WHERE id_proposta=1','Use aceitar_proposta');
CALL fluxo_recusa_regra('09 avaliacao de troca duplicada na mesma proposta e bloqueada','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(3,11,30000)','Troca exige avaliacao');
CALL fluxo_recusa_regra('08 vencimento original da obrigacao e imutavel','UPDATE obrigacao_financeira SET vencimento_original=''2026-02-20'' WHERE id_obrigacao=1','so permite alterar vencimento_atual');
CALL fluxo_recusa_regra('05 parametros de simulacao respondida sao imutaveis','UPDATE simulacao_financiamento SET tabela_retorno=''R0'' WHERE id_simulacao=2','so permite alterar situacao, data_resposta e parcela_informada');
-- P9: cancelamento de venda financiada sem orientacao bancaria (RN13/RN28-RN31), condicao isolada.
-- Estado inicial: venda 6 EM_FORMALIZACAO, financiada (Banco Demonstracao, APROVADO_A_RECEBER), sem trocas,
-- sem orientacao bancaria. Preparacao: todas as demais exigencias do cancelamento ficam atendidas
-- (entrada principal 5 encerrada por DESFAZIMENTO e novo ciclo 9601 aberto), de modo que a unica pendencia
-- restante e a orientacao bancaria. O UPDATE abaixo e o mesmo que cancelar_venda executa; a procedure nao e
-- chamada porque ela faz COMMIT e encerraria a transacao deste teste.
CALL fluxo_confere('P9 estado inicial: venda 6 financiada, em formalizacao e sem orientacao bancaria',(SELECT situacao_comercial='EM_FORMALIZACAO' AND instituicao_financeira IS NOT NULL AND orientacao_bancaria IS NULL FROM venda WHERE id_venda=6));
UPDATE entrada SET situacao='ENCERRADA',motivo_encerramento='DESFAZIMENTO',data_encerramento='2026-02-21 09:00' WHERE id_entrada=5;
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa)
 VALUES(9601,5,3,'2026-02-21 10:00','COMPRA_PROPRIA',40100,'Conservada','Conservada','Reavaliada apos retorno','Verificada','Em regularizacao','APROVADA','SIM','Reavaliacao apos distrato da venda 6.');
INSERT INTO entrada(id_entrada,id_veiculo,id_contraparte,id_avaliacao,id_entrada_anterior,modalidade,data_entrada,situacao,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes)
 VALUES(9601,5,12,9601,5,'COMPRA_PROPRIA','2026-02-21 11:00','EM_REGULARIZACAO',1,1,'DISTRATO-CV-6','2026-02-21','Reintegracao por distrato da venda 6.');
SET @multiplikar_operacao_venda=6;
CALL fluxo_recusa_regra('P9 cancelar venda financiada sem orientacao bancaria',
 'UPDATE venda SET situacao_comercial=''CANCELADA'',data_cancelamento=''2026-02-21 15:00'',motivo_cancelamento=''Desistencia do comprador'',data_retorno_veiculo=''2026-02-21 10:00'',valor_restituido_loja=0,observacoes_cancelamento=''Teste P9'' WHERE id_venda=6',
 'RN13/RN28-RN31: cancelamento pendente: orientacao bancaria;');
CALL fluxo_confere('P9 recusa preserva a venda: situacao, cancelamento e financiamento inalterados',(SELECT situacao_comercial='EM_FORMALIZACAO' AND data_cancelamento IS NULL AND motivo_cancelamento IS NULL AND situacao_financiamento='APROVADO_A_RECEBER' FROM venda WHERE id_venda=6));
UPDATE venda SET orientacao_bancaria='Banco informado do distrato; contrato de financiamento cancelado.' WHERE id_venda=6;
UPDATE venda SET situacao_comercial='CANCELADA',data_cancelamento='2026-02-21 15:00',motivo_cancelamento='Desistencia do comprador',data_retorno_veiculo='2026-02-21 10:00',valor_restituido_loja=0,observacoes_cancelamento='Teste P9' WHERE id_venda=6;
SET @multiplikar_operacao_venda=NULL;
CALL fluxo_confere('P9 controle positivo: com orientacao bancaria o mesmo cancelamento e aceito',(SELECT situacao_comercial='CANCELADA' FROM venda WHERE id_venda=6));
SELECT 'PASS fluxos MySQL: verificacoes reais encerradas em transacao' AS resultado;
ROLLBACK;
-- O ROLLBACK nao devolve os contadores AUTO_INCREMENT; com valor 1 o MySQL volta ao maior id + 1.
ALTER TABLE avaliacao AUTO_INCREMENT=1; ALTER TABLE entrada AUTO_INCREMENT=1;
DROP PROCEDURE fluxo_confere;
DROP PROCEDURE fluxo_rejeicao;
DROP PROCEDURE fluxo_recusa_regra;

-- Restaura o modo Safe Updates da sessao.
SET SQL_SAFE_UPDATES = @mk_safe_updates;
