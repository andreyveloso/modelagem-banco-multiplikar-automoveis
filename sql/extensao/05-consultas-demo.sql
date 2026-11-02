-- Previsão de caixa semanal e roteiros do painel (MySQL 8.4).
USE multiplikar;
DROP VIEW IF EXISTS vw_previsao_caixa;
DROP VIEW IF EXISTS vw_fluxos_previsao;
DROP VIEW IF EXISTS vw_caixa_realizado_referencia;
DROP PROCEDURE IF EXISTS fn_previsao_caixa_cenario;
DROP PROCEDURE IF EXISTS verificar_previsao_caixa;
CREATE VIEW vw_caixa_realizado_referencia AS
SELECT DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY) AS semana,
 COALESCE(SUM(v.valor_recebido),0) AS realizado,
 CONCAT('Recebimentos de vendas com data_ultimo_recebimento entre segunda-feira e ',data_referencia(),'; entradas historicas apenas; saidas historicas nao registradas, saldo inicial HIPOTESE') AS composicao
FROM venda v WHERE v.valor_recebido>0 AND DATE(v.data_ultimo_recebimento)>=DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY) AND DATE(v.data_ultimo_recebimento)<=data_referencia();
CREATE VIEW vw_fluxos_previsao AS
WITH propostas AS (
 SELECT p.id_proposta,p.id_atendimento,p.id_entrada,p.valor_total,e.modalidade,e.valor_repasse_acordado,
 COUNT(*) OVER(PARTITION BY p.id_atendimento,p.id_entrada) AS alternativas,
 COALESCE((SELECT pt.probabilidade FROM parametro_temperatura pt WHERE pt.temperatura=COALESCE(l.temperatura_final,l.temperatura_sugerida) AND pt.vigencia<=data_referencia() ORDER BY pt.vigencia DESC LIMIT 1),0) AS prob_lead,
 COALESCE((SELECT sp.retorno_loja FROM vw_simulacao_parcela sp WHERE sp.id_proposta=p.id_proposta ORDER BY sp.id_simulacao DESC LIMIT 1),0) AS retorno_banco,
 COALESCE((SELECT sp.instituicao FROM vw_simulacao_parcela sp WHERE sp.id_proposta=p.id_proposta ORDER BY sp.id_simulacao DESC LIMIT 1),NULL) AS banco,
 COALESCE((SELECT MAX(pc.prazo_previsto_dias) FROM proposta_condicao pc WHERE pc.id_proposta=p.id_proposta),0) AS prazo_max,
 COALESCE((SELECT MAX(pp.dias_previstos) FROM parametro_prazo pp WHERE pp.tipo_obrigacao='CONSIGNANTE_PAGAR' AND pp.vigencia<=data_referencia() ORDER BY pp.vigencia DESC LIMIT 1),0) AS dias_repasse
 FROM proposta p LEFT JOIN vw_lead_atual l ON l.id_atendimento=p.id_atendimento JOIN entrada e ON e.id_entrada=p.id_entrada
 WHERE p.situacao='APRESENTADA' AND p.validade>=data_referencia()
), fluxo AS (
 SELECT 'REALIZADO' AS camada, r.semana AS data_evento,CAST(r.realizado AS DECIMAL(20,8)) AS valor,FALSE AS bancario,NULL AS temperatura,r.composicao AS descricao FROM vw_caixa_realizado_referencia r
 UNION ALL
 SELECT 'OBRIGACAO' AS camada,GREATEST(o.vencimento_atual,data_referencia()) AS data_evento,CAST(CASE o.natureza WHEN 'RECEBER' THEN o.valor ELSE -o.valor END AS DECIMAL(20,8)) AS valor,(o.natureza='RECEBER' AND o.categoria='FINANCIAMENTO') AS bancario,NULL AS temperatura,CONCAT('Obrigacao ',o.id_obrigacao,' ',o.natureza,' ',o.valor,' vencimento ',o.vencimento_atual,IF(o.vencimento_atual<data_referencia(),' (vencida antes da referencia; incluida na primeira semana)','')) AS descricao FROM obrigacao_financeira o WHERE o.situacao NOT IN('QUITADA','CANCELADA')
 UNION ALL
 SELECT 'OBRIGACAO' AS camada,GREATEST(DATE_ADD(COALESCE(DATE(v.data_conclusao),DATE(v.data_registro)),INTERVAL COALESCE((SELECT MAX(pp.dias_previstos) FROM parametro_prazo pp WHERE pp.tipo_obrigacao='CONSIGNANTE_PAGAR' AND pp.vigencia<=data_referencia()),0) DAY),data_referencia()) AS data_evento,CAST(-e.valor_repasse_acordado AS DECIMAL(20,8)) AS valor,FALSE AS bancario,NULL AS temperatura,CONCAT('PAGAR consignante da venda ',v.id_venda,': -',e.valor_repasse_acordado,', vencimento estimado ',DATE_ADD(COALESCE(DATE(v.data_conclusao),DATE(v.data_registro)),INTERVAL COALESCE((SELECT MAX(pp.dias_previstos) FROM parametro_prazo pp WHERE pp.tipo_obrigacao='CONSIGNANTE_PAGAR' AND pp.vigencia<=data_referencia()),0) DAY),' (HIPOTESE)',IF(DATE_ADD(COALESCE(DATE(v.data_conclusao),DATE(v.data_registro)),INTERVAL COALESCE((SELECT MAX(pp.dias_previstos) FROM parametro_prazo pp WHERE pp.tipo_obrigacao='CONSIGNANTE_PAGAR' AND pp.vigencia<=data_referencia()),0) DAY)<data_referencia(),'; vencida antes da referencia, incluida na primeira semana','')) AS descricao
 FROM venda v JOIN entrada e ON e.id_entrada=v.id_entrada_principal WHERE e.modalidade='CONSIGNACAO' AND v.situacao_comercial IN('EM_FORMALIZACAO','CONCLUIDA') AND NOT EXISTS(SELECT 1 FROM obrigacao_financeira o WHERE o.origem='ENTRADA' AND o.id_entrada=e.id_entrada)
 UNION ALL
 SELECT 'FUNIL' AS camada,DATE_ADD(data_referencia(),INTERVAL pc.prazo_previsto_dias DAY) AS data_evento,CAST(pc.valor*p.prob_lead/p.alternativas AS DECIMAL(20,8)) AS valor,(pc.codigo_forma='FINANCIAMENTO') AS bancario,COALESCE(l.temperatura_atual,'SEM_CLASSIFICACAO') AS temperatura,CONCAT('Proposta ',p.id_proposta,' condicao ',pc.codigo_forma,': ',pc.valor,' x P(lead) ',p.prob_lead,' / ',p.alternativas,' alternativas (hipotese de escolha uniforme), D+',pc.prazo_previsto_dias,IF(t.trocas>0,CONCAT('; troca ',t.trocas,' entra em estoque e nao e caixa'),'')) AS descricao
 FROM propostas p JOIN proposta_condicao pc ON pc.id_proposta=p.id_proposta LEFT JOIN vw_lead_atual l ON l.id_atendimento=p.id_atendimento LEFT JOIN (SELECT id_proposta,SUM(valor_oferecido) AS trocas FROM proposta_troca GROUP BY id_proposta) t ON t.id_proposta=p.id_proposta WHERE pc.codigo_forma<>'TROCA'
 UNION ALL
 SELECT 'FUNIL' AS camada,DATE_ADD(data_referencia(),INTERVAL p.prazo_max+p.dias_repasse DAY) AS data_evento,CAST(-p.valor_repasse_acordado*p.prob_lead/p.alternativas AS DECIMAL(20,8)) AS valor,(p.prazo_max>0) AS bancario,COALESCE(l.temperatura_atual,'SEM_CLASSIFICACAO') AS temperatura,CONCAT('PAGAR consignante na proposta ',p.id_proposta,': -',p.valor_repasse_acordado,' x P(lead) ',p.prob_lead,' / ',p.alternativas,' alternativas; caixa liquido do repasse') AS descricao FROM propostas p JOIN vw_lead_atual l ON l.id_atendimento=p.id_atendimento WHERE p.modalidade='CONSIGNACAO' AND p.valor_repasse_acordado>0
 UNION ALL
 SELECT 'FUNIL' AS camada,DATE_ADD(data_referencia(),INTERVAL p.prazo_max DAY) AS data_evento,CAST(p.retorno_banco*p.prob_lead/p.alternativas AS DECIMAL(20,8)) AS valor,TRUE AS bancario,COALESCE(l.temperatura_atual,'SEM_CLASSIFICACAO') AS temperatura,CONCAT('RETORNO BANCO ',p.banco,': ',p.retorno_banco,' x P(lead) ',p.prob_lead,' / ',p.alternativas,' alternativas; receita da loja na liberacao, nao comissao de vendedor') AS descricao FROM propostas p JOIN vw_lead_atual l ON l.id_atendimento=p.id_atendimento JOIN proposta_condicao pc ON pc.id_proposta=p.id_proposta AND pc.codigo_forma='FINANCIAMENTO' WHERE p.retorno_banco>0
)
SELECT camada,data_evento,valor,bancario,temperatura,descricao FROM fluxo;
CREATE VIEW vw_previsao_caixa AS
WITH RECURSIVE limites AS(SELECT DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY) AS inicio,COALESCE(MAX(DATE_SUB(data_evento,INTERVAL WEEKDAY(data_evento) DAY)),DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY)) AS fim FROM vw_fluxos_previsao), semanas AS(SELECT inicio AS semana,fim FROM limites UNION ALL SELECT DATE_ADD(semana,INTERVAL 7 DAY),fim FROM semanas WHERE semana<fim), semanal AS(SELECT s.semana,ROUND(COALESCE(SUM(CASE WHEN f.camada='REALIZADO' THEN f.valor ELSE 0 END),0),2) AS realizado,ROUND(COALESCE(SUM(CASE WHEN f.camada='OBRIGACAO' THEN f.valor ELSE 0 END),0),2) AS obrigacoes,ROUND(COALESCE(SUM(CASE WHEN f.camada='FUNIL' THEN f.valor ELSE 0 END),0),2) AS funil_ponderado,GROUP_CONCAT(f.descricao ORDER BY f.descricao SEPARATOR ' | ') AS detalhes FROM semanas s LEFT JOIN vw_fluxos_previsao f ON DATE_SUB(f.data_evento,INTERVAL WEEKDAY(f.data_evento) DAY)=s.semana GROUP BY s.semana), acumulado AS(SELECT semanal.*,25000+SUM(realizado+obrigacoes+funil_ponderado) OVER(ORDER BY semana ROWS UNBOUNDED PRECEDING) AS saldo_projetado FROM semanal)
SELECT semana,realizado,obrigacoes,funil_ponderado,saldo_projetado,CONCAT(IF(semana=(SELECT MIN(semana) FROM semanal),'Saldo inicial HIPOTESE R$ 25000; ','(semana futura); '),COALESCE(detalhes,'sem outros movimentos'),'; funil dividido igualmente entre alternativas da mesma entrada; repasse ao consignante e retorno do banco ponderados') AS composicao FROM acumulado;
DELIMITER $$
CREATE PROCEDURE fn_previsao_caixa_cenario(IN p_cenario VARCHAR(40),IN p_saldo_inicial DECIMAL(14,2))
BEGIN
 IF p_cenario NOT IN('BASE','BANCO_ATRA_15_DIAS','LEADS_QUENTES_NAO_FECHAM') OR p_saldo_inicial IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cenario invalido ou saldo inicial ausente'; END IF;
 WITH RECURSIVE cen AS(SELECT camada,CASE WHEN p_cenario='BANCO_ATRA_15_DIAS' AND bancario THEN DATE_ADD(data_evento,INTERVAL 15 DAY) ELSE data_evento END AS data_evento,valor,bancario,temperatura,descricao FROM vw_fluxos_previsao WHERE NOT(p_cenario='LEADS_QUENTES_NAO_FECHAM' AND camada='FUNIL' AND temperatura='QUENTE')), limites AS(SELECT DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY) AS inicio,COALESCE(MAX(DATE_SUB(data_evento,INTERVAL WEEKDAY(data_evento) DAY)),DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY)) AS fim FROM cen), semanas AS(SELECT inicio AS semana,fim FROM limites UNION ALL SELECT DATE_ADD(semana,INTERVAL 7 DAY),fim FROM semanas WHERE semana<fim), semanal AS(SELECT s.semana,ROUND(COALESCE(SUM(CASE WHEN f.camada='REALIZADO' THEN f.valor ELSE 0 END),0),2) realizado,ROUND(COALESCE(SUM(CASE WHEN f.camada='OBRIGACAO' THEN f.valor ELSE 0 END),0),2) obrigacoes,ROUND(COALESCE(SUM(CASE WHEN f.camada='FUNIL' THEN f.valor ELSE 0 END),0),2) funil_ponderado,GROUP_CONCAT(f.descricao ORDER BY f.descricao SEPARATOR ' | ') detalhes FROM semanas s LEFT JOIN cen f ON DATE_SUB(f.data_evento,INTERVAL WEEKDAY(f.data_evento) DAY)=s.semana GROUP BY s.semana), saldo AS(SELECT semanal.*,p_saldo_inicial+SUM(realizado+obrigacoes+funil_ponderado) OVER(ORDER BY semana ROWS UNBOUNDED PRECEDING) saldo_projetado FROM semanal) SELECT semana,realizado,obrigacoes,funil_ponderado,saldo_projetado,CONCAT('Cenario ',p_cenario,'; saldo inicial HIPOTESE ',p_saldo_inicial,'; ',COALESCE(detalhes,'sem outros movimentos')) composicao FROM saldo ORDER BY semana;
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE verificar_previsao_caixa()
BEGIN
 IF (SELECT COUNT(*) FROM vw_previsao_caixa)=0 OR EXISTS(SELECT 1 FROM vw_previsao_caixa WHERE realizado IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Previsao semanal sem realizado/referencia'; END IF;
 SELECT 'PASS previsao: semanas e realizado ate a referencia' AS resultado;
 IF (SELECT COUNT(*) FROM vw_fluxos_previsao WHERE camada='FUNIL')=0 OR NOT EXISTS(SELECT 1 FROM vw_fluxos_previsao WHERE camada='FUNIL' AND descricao LIKE '%PAGAR consignante%') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Funil deve incluir entradas e repasse ponderado'; END IF;
 SELECT 'PASS previsao: funil limitado a alternativas e liquido de repasse' AS resultado;
END$$
DELIMITER ;
CALL verificar_previsao_caixa(); DROP PROCEDURE verificar_previsao_caixa;
