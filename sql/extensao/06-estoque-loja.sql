-- Estoque anunciado da loja; valores de aquisicao sao hipótese (85% do preco).
USE multiplikar;
-- Temporárias duram a conexão: no Workbench a mesma aba pode rodar o script de novo.
DROP TEMPORARY TABLE IF EXISTS estoque_loja, antes, carga, laudos, avaliacoes;
START TRANSACTION;
CREATE TEMPORARY TABLE estoque_loja(ordem INT PRIMARY KEY,marca VARCHAR(80),modelo VARCHAR(120),ano_modelo SMALLINT,cor VARCHAR(30),combustivel VARCHAR(20),cambio VARCHAR(30),categoria VARCHAR(20),quilometragem INT,preco DECIMAL(14,2));
INSERT INTO estoque_loja VALUES (1, 'Renault', 'Kwid Zen', 2026, 'Cinza', 'Flex', 'Manual', 'SEMINOVO', 32678, 61900), (2, 'Volkswagen', 'Tera High 1.0 TSI', 2026, 'Prata', 'Flex', 'Automatico', 'SEMINOVO', 1000, 149900), (3, 'Fiat', 'Argo Drive 1.0', 2026, 'Preto', 'Flex', 'Automatico', 'SEMINOVO', 38000, 75900), (4, 'Chevrolet', 'Onix Plus Premier 1.0 Turbo', 2025, 'Prata', 'Flex', 'Automatico', 'SEMINOVO', 45680, 99900), (5, 'Hyundai', 'Creta Comfort 1.0 Turbo', 2025, 'Branco', 'Flex', 'Automatico', 'SEMINOVO', 27163, 135900), (6, 'Jeep', 'Compass Longitude T270', 2025, 'Azul', 'Flex', 'Automatico', 'SEMINOVO', 49900, 141900), (7, 'Chevrolet', 'Equinox Premier', 2024, 'Preto', 'Gasolina', 'Manual', 'SEMINOVO', 44150, 145900), (8, 'Nissan', 'Frontier Pro-4X', 2024, 'Cinza', 'Diesel', 'Automatico', 'SEMINOVO', 34400, 225900), (9, 'Chevrolet', 'Onix LTZ 1.0 Turbo', 2024, 'Preto', 'Flex', 'Automatico', 'SEMINOVO', 15224, 89900), (10, 'Chevrolet', 'Onix Plus Premier 1.0 Turbo', 2023, 'Preto', 'Flex', 'Automatico', 'SEMINOVO', 28900, 77900), (11, 'Toyota', 'Corolla GLi', 2023, 'Preto', 'Flex', 'Automatico', 'SEMINOVO', 84085, 119900), (12, 'Toyota', 'Corolla Cross XRX Hybrid', 2023, 'Preto', 'Flex', 'Automatico', 'SEMINOVO', 60126, 149900), (13, 'Volkswagen', 'T-Cross Sense TSI', 2021, 'Prata', 'Flex', 'Automatico', 'USADO', 79275, 89900), (14, 'Jeep', 'Compass Longitude Diesel', 2021, 'Preto', 'Diesel', 'Automatico', 'USADO', 113485, 109000), (15, 'Fiat', 'Toro Freedom Turbo Diesel', 2019, 'Prata', 'Diesel', 'Automatico', 'USADO', 107000, 102900), (16, 'Ford', 'Ka Sedan SE 1.5', 2018, 'Branco', 'Flex', 'Manual', 'USADO', 103667, 45900), (17, 'Mercedes-Benz', 'C 180', 2015, 'Prata', 'Gasolina', 'Automatico', 'USADO', 80000, 102900), (18, 'Toyota', 'Corolla XEi 2.0', 2015, 'Preto', 'Flex', 'Automatico', 'USADO', 126185, 86900), (19, 'Ford', 'Fiesta Sedan 1.6', 2014, 'Prata', 'Flex', 'Manual', 'USADO', 121118, 40900), (20, 'Honda', 'Civic LXR', 2014, 'Cinza', 'Flex', 'Automatico', 'USADO', 105000, 69900), (21, 'Volkswagen', 'Tiguan 2.0 TSI', 2014, 'Branco', 'Gasolina', 'Automatico', 'USADO', 152178, 64900), (22, 'Chevrolet', 'Agile LTZ', 2013, 'Vermelho', 'Flex', 'Manual', 'USADO', 160500, 35900), (23, 'Fiat', 'Idea Attractive 1.4', 2013, 'Prata', 'Flex', 'Manual', 'USADO', 115693, 39900), (24, 'Fiat', '500 Cult Dualogic', 2013, 'Prata', 'Flex', 'Semiautomatico', 'USADO', 55000, 45900), (25, 'Dodge', 'Journey R/T', 2012, 'Preto', 'Gasolina', 'Automatico', 'USADO', 150000, 55900), (26, 'Renault', 'Sandero Expression 1.6', 2011, 'Vermelho', 'Flex', 'Manual', 'USADO', 144783, 25900), (27, 'Volkswagen', 'Polo 1.6', 2010, 'Preto', 'Flex', 'Manual', 'USADO', 129988, 39900);
CREATE TEMPORARY TABLE antes AS SELECT (SELECT COUNT(*) FROM vw_fila_acoes) AS fila,(SELECT GROUP_CONCAT(CONCAT(semana,'=',saldo_projetado) ORDER BY semana SEPARATOR ';') FROM vw_previsao_caixa) AS previsao,(SELECT GROUP_CONCAT(CONCAT(rotulo,'=',caixa_d0) ORDER BY rotulo SEPARATOR ';') FROM vw_proposta_comparativo) AS propostas,(SELECT COUNT(*) FROM vw_veiculo_situacao WHERE situacao_atual='DISPONIVEL') AS disponiveis;
-- IDs 12..38 sao fixos para que a carga do estoque não dependa do consumo de AUTO_INCREMENT em testes revertidos.
-- Placa e chassi são SINTÉTICOS (padrão Mercosul LLLNLNN e 17 caracteres), como os TST1A../9TEST.. da massa
-- principal: o anúncio público não traz esses dados, mas um veículo em estoque ativo, com laudo cautelar e
-- contrato de compra, tem placa e chassi conhecidos. Sem eles a auditoria Q7 acusaria a própria massa.
INSERT INTO veiculo(id_veiculo,marca,modelo,ano_modelo,cor,placa,chassi,combustivel,cambio,categoria_comercial) SELECT 11+ordem,marca,modelo,ano_modelo,cor,CONCAT('LJA1B',LPAD(ordem,2,'0')),CONCAT('9LJAB',LPAD(ordem,12,'0')),combustivel,cambio,categoria FROM estoque_loja ORDER BY ordem;
CREATE TEMPORARY TABLE carga AS SELECT s.ordem,v.id_veiculo FROM estoque_loja s JOIN veiculo v ON v.marca=s.marca AND v.modelo=s.modelo AND v.ano_modelo=s.ano_modelo AND v.cor=s.cor;
INSERT INTO laudo(id_veiculo,referencia_documental,data_emissao,situacao,resultado) SELECT id_veiculo,CONCAT('LAUDO-LOJA-',ordem),'2026-01-16','EMITIDO','Laudo cautelar aprovado; sem restricoes estruturais ou documentais.' FROM carga ORDER BY ordem;
CREATE TEMPORARY TABLE laudos AS SELECT c.ordem,l.id_laudo,c.id_veiculo FROM carga c JOIN laudo l ON l.id_veiculo=c.id_veiculo AND l.referencia_documental=CONCAT('LAUDO-LOJA-',c.ordem);
INSERT INTO avaliacao(id_veiculo,id_avaliador,data,finalidade,quilometragem,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) SELECT c.id_veiculo,3,'2026-01-19 10:00','COMPRA_PROPRIA',e.quilometragem,'Conservada','Conservada','Revisada','Sem avarias','Regular','APROVADA','SIM','Aprovado para compra e revenda no estoque da loja' FROM carga c JOIN estoque_loja e USING(ordem) ORDER BY c.ordem;
CREATE TEMPORARY TABLE avaliacoes AS SELECT c.ordem,c.id_veiculo,a.id_avaliacao FROM carga c JOIN avaliacao a ON a.id_veiculo=c.id_veiculo AND a.data='2026-01-19 10:00' AND a.finalidade='COMPRA_PROPRIA';
INSERT INTO avaliacao_laudo(id_avaliacao,id_laudo) SELECT a.id_avaliacao,l.id_laudo FROM avaliacoes a JOIN laudos l USING(id_veiculo);
INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) SELECT c.id_veiculo,5,a.id_avaliacao,'COMPRA_PROPRIA','2026-01-20 10:00',ROUND(e.preco*0.85,-2),e.preco,CONCAT('CE-LOJA-',c.ordem),'2026-01-20','Compra para estoque proprio; custo estimado (hipotese 85% do preco anunciado).' FROM carga c JOIN estoque_loja e USING(ordem) JOIN avaliacoes a USING(id_veiculo) ORDER BY c.ordem;
-- Dois casos de demonstração recusados permanecem fora do estoque.
-- 39 fica reservado ao caso PENDENTE revertido; os veículos recusados usam 40/41.
INSERT INTO veiculo(id_veiculo,marca,modelo,ano_modelo,cor,combustivel,cambio,categoria_comercial) VALUES(40,'Chevrolet','Celta 1.0',2008,'Prata','Flex','Manual','USADO'),(41,'Peugeot','206 1.4',2009,'Azul','Flex','Manual','USADO');
INSERT INTO laudo(id_veiculo,referencia_documental,data_emissao,situacao,resultado) SELECT id_veiculo,'LAUDO-RECUSA','2026-01-26','EMITIDO','Laudo de demonstracao.' FROM veiculo WHERE modelo IN('Celta 1.0','206 1.4');
INSERT INTO avaliacao(id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) SELECT id_veiculo,3,'2026-01-27 10:00','COMPRA_PROPRIA',CASE modelo WHEN 'Celta 1.0' THEN 198000 ELSE 142000 END,3,'Desgastada','Desgastada','Revisar embreagem',CASE modelo WHEN 'Celta 1.0' THEN 'Reparo estrutural' ELSE 'Sem avarias' END,'Regular',CASE modelo WHEN 'Celta 1.0' THEN 'REPROVADA' ELSE 'APROVADA' END,'NAO','Demonstracao: reprovado ou sem interesse comercial.' FROM veiculo WHERE modelo IN('Celta 1.0','206 1.4');
INSERT INTO avaliacao_laudo(id_avaliacao,id_laudo) SELECT a.id_avaliacao,l.id_laudo FROM avaliacao a JOIN laudo l ON l.id_veiculo=a.id_veiculo AND l.referencia_documental='LAUDO-RECUSA' WHERE a.id_veiculo IN(SELECT id_veiculo FROM veiculo WHERE modelo IN('Celta 1.0','206 1.4'));
DELIMITER $$
CREATE PROCEDURE verificar_estoque_loja()
BEGIN
 DECLARE v_novos INT; DECLARE v_antes INT; DECLARE v_fila INT; DECLARE v_previsao TEXT; DECLARE v_propostas TEXT;
 SELECT COUNT(*) INTO v_novos FROM carga c JOIN vw_veiculo_situacao s USING(id_veiculo) WHERE s.situacao_atual='DISPONIVEL';
 IF v_novos<>27 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Esperados 27 veiculos disponiveis'; END IF;
 SELECT disponiveis,fila,previsao,propostas INTO v_antes,v_fila,v_previsao,v_propostas FROM antes;
 IF v_antes+27<>(SELECT COUNT(*) FROM vw_veiculo_situacao WHERE situacao_atual='DISPONIVEL') OR v_fila<>(SELECT COUNT(*) FROM vw_fila_acoes) OR v_previsao<>(SELECT GROUP_CONCAT(CONCAT(semana,'=',saldo_projetado) ORDER BY semana SEPARATOR ';') FROM vw_previsao_caixa) OR v_propostas<>(SELECT GROUP_CONCAT(CONCAT(rotulo,'=',caixa_d0) ORDER BY rotulo SEPARATOR ';') FROM vw_proposta_comparativo) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Estoque alterou fila, previsao ou comparativo'; END IF;
 SELECT 'PASS estoque: 27 veiculos anunciados disponiveis' AS resultado;
 SELECT 'PASS estoque: disponiveis aumentaram exatamente em 27' AS resultado;
 SELECT 'PASS estoque: fila, previsao e propostas inalterados' AS resultado;
 SELECT 'PASS estoque: previsao e comparativo conferidos contra captura anterior' AS resultado;
 IF EXISTS(SELECT 1 FROM veiculo v JOIN avaliacao a USING(id_veiculo) JOIN vw_veiculo_situacao s USING(id_veiculo) WHERE v.modelo IN('Celta 1.0','206 1.4') AND s.situacao_atual<>'FORA_DO_ESTOQUE') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Veiculo recusado apareceu no estoque'; END IF;
 SELECT 'PASS estoque: casos reprovados fora do estoque' AS resultado;
END$$
DELIMITER ;
CALL verificar_estoque_loja(); DROP PROCEDURE verificar_estoque_loja;
COMMIT;
DROP PROCEDURE IF EXISTS estoque_rejeitar;
DELIMITER $$
CREATE PROCEDURE estoque_rejeitar(IN p_nome VARCHAR(120),IN p_sql TEXT,IN p_esperado VARCHAR(128))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 @msg=MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE; END;
  SET @estoque_sql=p_sql; PREPARE estoque_stmt FROM @estoque_sql; EXECUTE estoque_stmt; DEALLOCATE PREPARE estoque_stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Entrada de estoque aceita: ',p_nome); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Motivo incorreto: ',p_nome,': ',LEFT(COALESCE(v_msg,'<vazia>'),70)); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS estoque rejeita ',p_nome,': ',p_esperado) AS resultado;
END$$
DELIMITER ;
START TRANSACTION;
CALL estoque_rejeitar('avaliacao reprovada fora do estoque',"INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado) SELECT a.id_veiculo,5,a.id_avaliacao,'COMPRA_PROPRIA','2026-01-28 10:00:00',10000,12000 FROM avaliacao a JOIN veiculo v USING(id_veiculo) WHERE v.modelo='Celta 1.0' AND a.data='2026-01-27 10:00:00'",'RN06/RN07');
CALL estoque_rejeitar('avaliacao sem interesse fora do estoque',"INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado) SELECT a.id_veiculo,5,a.id_avaliacao,'COMPRA_PROPRIA','2026-01-28 10:00:00',10000,12000 FROM avaliacao a JOIN veiculo v USING(id_veiculo) WHERE v.modelo='206 1.4' AND a.data='2026-01-27 10:00:00'",'RN06/RN07');
CALL estoque_rejeitar('avaliacao ja usada em entrada',"INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) SELECT a.id_veiculo,5,a.id_avaliacao,'COMPRA_PROPRIA','2026-01-28 10:00:00',10000,12000,'TESTE-DUP','2026-01-28','teste' FROM avaliacao a JOIN entrada e USING(id_avaliacao) WHERE e.modalidade='COMPRA_PROPRIA' LIMIT 1",'Duplicate entry');
ROLLBACK;
DROP PROCEDURE estoque_rejeitar;
DROP TEMPORARY TABLE IF EXISTS estoque_loja, antes, carga, laudos, avaliacoes;
