-- MySQL 8.4. Quarta migração de 01/11/2026: aliases explícitos em vw_fluxos_previsao.
-- Nos ramos do UNION ALL, expressões sem alias recebiam nomes automáticos com mais de 64 caracteres;
-- com isso o mysqldump não conseguia recriar a view ao restaurar um backup (erro 1166) e SHOW FIELDS
-- podia falhar. O resultado da view não muda: o UNION usa os nomes do primeiro ramo.
-- CREATE OR REPLACE mantém as views dependentes (vw_previsao_caixa) e pode ser reaplicada sem efeito.
USE multiplikar;
CREATE OR REPLACE VIEW vw_fluxos_previsao AS
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
SELECT 'OK: vw_fluxos_previsao recriada com aliases explicitos' AS resultado;
