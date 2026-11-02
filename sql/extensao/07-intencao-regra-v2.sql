-- Intencao de compra opcional e Regra V2; não altera registros históricos V1.
USE multiplikar;
create table intencao_compra (
    id_atendimento bigint primary key,
    id_entrada bigint null,
    valor_disponivel decimal(14,2) null,
    codigo_forma varchar(20) null,
    data_registro datetime not null,
    origem varchar(20) not null,
    constraint ck_intencao_valor check (valor_disponivel is null or valor_disponivel>=0),
    constraint ck_intencao_origem check (origem in ('SITE', 'VENDEDOR')),
    constraint ck_intencao_conteudo check (id_entrada is not null
        or valor_disponivel is not null
        or codigo_forma is not null),
    constraint fk_intencao_atendimento foreign key (id_atendimento) references atendimento(id_atendimento),
    constraint fk_intencao_entrada foreign key (id_entrada) references entrada(id_entrada),
    constraint fk_intencao_forma foreign key (codigo_forma) references forma_pagamento(codigo)
) engine=InnoDB default character set=utf8mb4;
CREATE INDEX ix_intencao_entrada ON intencao_compra(id_entrada);
DELIMITER $$
CREATE TRIGGER intencao_compra_bi BEFORE INSERT ON intencao_compra FOR EACH ROW
BEGIN
 DECLARE v_tipo VARCHAR(20);DECLARE v_status VARCHAR(20);DECLARE v_preco DECIMAL(14,2);
 SELECT tipo_interesse INTO v_tipo FROM atendimento WHERE id_atendimento=NEW.id_atendimento;
 IF v_tipo NOT IN('COMPRA','TROCA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN44: intencao de compra exige atendimento de COMPRA ou TROCA'; END IF;
 IF NEW.id_entrada IS NOT NULL THEN SELECT situacao,preco_anunciado INTO v_status,v_preco FROM entrada WHERE id_entrada=NEW.id_entrada; IF v_status<>'ATIVA' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN44: veiculo pretendido deve estar anunciado'; END IF; IF NEW.valor_disponivel IS NOT NULL AND v_preco IS NOT NULL AND NEW.valor_disponivel>v_preco THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN44: valor disponivel maior que o preco anunciado'; END IF; END IF;
END$$
CREATE TRIGGER intencao_compra_bu BEFORE UPDATE ON intencao_compra FOR EACH ROW
BEGIN
 DECLARE v_tipo VARCHAR(20);DECLARE v_status VARCHAR(20);DECLARE v_preco DECIMAL(14,2);
 SELECT tipo_interesse INTO v_tipo FROM atendimento WHERE id_atendimento=NEW.id_atendimento;
 IF v_tipo NOT IN('COMPRA','TROCA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN44: intencao de compra exige atendimento de COMPRA ou TROCA'; END IF;
 IF NEW.id_entrada IS NOT NULL THEN SELECT situacao,preco_anunciado INTO v_status,v_preco FROM entrada WHERE id_entrada=NEW.id_entrada; IF v_status<>'ATIVA' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN44: veiculo pretendido deve estar anunciado'; END IF; IF NEW.valor_disponivel IS NOT NULL AND v_preco IS NOT NULL AND NEW.valor_disponivel>v_preco THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN44: valor disponivel maior que o preco anunciado'; END IF; END IF;
END$$
ALTER TABLE classificacao_fator DROP CHECK ck_fator_codigo$$
ALTER TABLE classificacao_fator ADD CONSTRAINT ck_fator_codigo CHECK(codigo_fator IN('URGENCIA_CONTATO','ESTAGIO_NEGOCIACAO','INTERESSE_FINANCEIRO','VOLUME_INTERACOES','CAPACIDADE_PAGAMENTO'))$$
DROP PROCEDURE IF EXISTS registrar_classificacao_lead$$
CREATE PROCEDURE registrar_classificacao_lead(IN p_id_atendimento BIGINT,IN p_versao_regra VARCHAR(16),IN p_referencia DATETIME,OUT p_id_classificacao BIGINT)
BEGIN
 DECLARE vs VARCHAR(13);DECLARE vt VARCHAR(6);DECLARE vd DATETIME;DECLARE vu DATETIME;DECLARE vn INT;DECLARE vdays INT;DECLARE a DECIMAL(6,2);DECLARE b DECIMAL(6,2);DECLARE c DECIMAL(6,2);DECLARE d DECIMAL(6,2);DECLARE cap DECIMAL(6,2) DEFAULT 0;DECLARE sc DECIMAL(6,2);DECLARE temp VARCHAR(8);DECLARE val DECIMAL(14,2);DECLARE forma VARCHAR(20);DECLARE preco DECIMAL(14,2);DECLARE cover DECIMAL(10,4);DECLARE ev TEXT;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @mk_registrando_classificacao=NULL; RESIGNAL; END;
 IF p_versao_regra NOT IN('REGRA-V1','REGRA-V2') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Versao de regra desconhecida (use REGRA-V1 ou REGRA-V2)'; END IF;
 SELECT situacao,tipo_interesse,data INTO vs,vt,vd FROM atendimento WHERE id_atendimento=p_id_atendimento; IF vd IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Atendimento nao encontrado'; END IF;
 SELECT MAX(data_hora),COUNT(*) INTO vu,vn FROM interacao WHERE id_atendimento=p_id_atendimento AND data_hora<=p_referencia;
 SET vdays=DATEDIFF(DATE(p_referencia),DATE(COALESCE(vu,vd))); SET a=CASE WHEN vdays>=15 THEN 40 WHEN vdays>=7 THEN 20 ELSE 0 END;SET b=CASE vs WHEN 'EM_NEGOCIACAO' THEN 30 WHEN 'ABERTO' THEN 10 ELSE 0 END;SET c=CASE vt WHEN 'COMPRA' THEN 20 WHEN 'TROCA' THEN 15 ELSE 10 END;SET d=CASE WHEN vn>=3 THEN 10 WHEN vn>=1 THEN 5 ELSE 0 END;
 IF p_versao_regra='REGRA-V2' THEN
  SELECT valor_disponivel,codigo_forma INTO val,forma FROM intencao_compra WHERE id_atendimento=p_id_atendimento AND data_registro<=p_referencia;
  SELECT e.preco_anunciado INTO preco FROM intencao_compra i JOIN entrada e ON e.id_entrada=i.id_entrada WHERE i.id_atendimento=p_id_atendimento AND i.data_registro<=p_referencia;
  IF preco>0 AND val IS NOT NULL THEN SET cover=val/preco; END IF;
  SET cap=CASE WHEN cover>=0.9 AND forma IN('PIX','DINHEIRO') THEN 40 WHEN cover>=0.9 THEN 30 WHEN cover>=0.5 OR forma='FINANCIAMENTO' THEN 20 WHEN cover IS NULL AND forma IS NOT NULL THEN 10 ELSE 0 END;
  SET ev=CONCAT('valor=',COALESCE(val,'nao informado'),', forma=',COALESCE(forma,'nao informada'),', preco=',COALESCE(preco,'sem veiculo'),', cobertura=',COALESCE(CONCAT(ROUND(cover*100),'%'),'nao calculavel'));
 END IF;
 SET sc=a+b+c+d+cap;SET temp=CASE WHEN sc>=70 THEN 'QUENTE' WHEN sc>=40 THEN 'MORNO' ELSE 'FRIO' END;
 SET @mk_registrando_classificacao=1;
 INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao) VALUES(p_id_atendimento,p_referencia,'REGRA',p_versao_regra,temp,sc);
 SET @mk_registrando_classificacao=NULL;SET p_id_classificacao=LAST_INSERT_ID();
 INSERT INTO classificacao_fator VALUES(p_id_classificacao,'URGENCIA_CONTATO',a,CONCAT(vdays,' dias sem contato')),(p_id_classificacao,'ESTAGIO_NEGOCIACAO',b,CONCAT('situacao=',vs)),(p_id_classificacao,'INTERESSE_FINANCEIRO',c,CONCAT('interesse=',vt)),(p_id_classificacao,'VOLUME_INTERACOES',d,CONCAT(vn,' interacoes'));
 IF p_versao_regra='REGRA-V2' THEN INSERT INTO classificacao_fator VALUES(p_id_classificacao,'CAPACIDADE_PAGAMENTO',cap,ev);END IF;
END$$
DELIMITER ;
INSERT INTO intencao_compra VALUES(5,5,30000,'FINANCIAMENTO','2026-01-09 09:30','VENDEDOR'),(7,10,52000,'PIX','2026-02-02 12:30','VENDEDOR'),(9,5,20000,NULL,'2026-01-11 09:30','VENDEDOR');
SELECT 'PASS RN44: tres intencoes registradas para atendimentos de compra' AS resultado;
DELIMITER $$
CREATE PROCEDURE verificar_regra_v2(IN p_id BIGINT)
BEGIN
 IF (SELECT COUNT(*) FROM classificacao_fator WHERE id_classificacao=p_id)<>5 OR (SELECT temperatura_sugerida FROM classificacao_lead WHERE id_classificacao=p_id)<>'QUENTE' OR (SELECT pontuacao FROM classificacao_lead WHERE id_classificacao=p_id)<>95 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='REGRA-V2 esperava 95 pontos, QUENTE e cinco fatores'; END IF;
 SELECT 'PASS REGRA-V2: capacidade de pagamento eleva lead a 95 pontos QUENTE' AS resultado;
END$$
CREATE PROCEDURE teste_regra_v2(IN p_rotulo VARCHAR(120),IN p_sql TEXT,IN p_esperado VARCHAR(128))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 @msg=MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE; END;
  SET @v2_sql=p_sql; PREPARE v2_stmt FROM @v2_sql; EXECUTE v2_stmt; DEALLOCATE PREPARE v2_stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Regra RN44 deveria recusar ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Regra inesperada: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS RN44 ',p_rotulo,': ',p_esperado) AS resultado;
END$$
CREATE PROCEDURE confere_fator_v2(IN p_id BIGINT,IN p_esperado DECIMAL(6,2),IN p_rotulo VARCHAR(120))
BEGIN DECLARE v_err TEXT; IF (SELECT pontos FROM classificacao_fator WHERE id_classificacao=p_id AND codigo_fator='CAPACIDADE_PAGAMENTO')<>p_esperado THEN SET v_err=CONCAT('Fator de capacidade incorreto: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF; SELECT CONCAT('PASS REGRA-V2 ',p_rotulo,' = ',p_esperado,' pts') AS resultado; END$$
CREATE PROCEDURE confere_caso_v2(IN p_id BIGINT) BEGIN DECLARE v_err TEXT; IF (SELECT pontuacao FROM classificacao_lead WHERE id_classificacao=p_id)<>75 OR (SELECT temperatura_sugerida FROM classificacao_lead WHERE id_classificacao=p_id)<>'QUENTE' OR (SELECT COUNT(*) FROM classificacao_fator WHERE id_classificacao=p_id)<>5 OR (SELECT pontos FROM classificacao_fator WHERE id_classificacao=p_id AND codigo_fator='CAPACIDADE_PAGAMENTO')<>40 THEN SET v_err='REGRA-V2 esperava 75 pontos QUENTE e capacidade 40'; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF; SELECT 'PASS REGRA-V2: cobertura 97 por cento a vista resulta em 75 pontos QUENTE e cinco fatores' AS resultado; END$$
CREATE PROCEDURE confere_classificacao_v2(IN p_id BIGINT,IN p_score DECIMAL(6,2),IN p_temp VARCHAR(10),IN p_rotulo VARCHAR(160))
BEGIN DECLARE v_err TEXT; IF (SELECT pontuacao FROM classificacao_lead WHERE id_classificacao=p_id)<>p_score OR (SELECT temperatura_sugerida FROM classificacao_lead WHERE id_classificacao=p_id)<>p_temp THEN SET v_err=CONCAT('Classificacao incorreta: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF; SELECT CONCAT('PASS ',p_rotulo) AS resultado; END$$
DELIMITER ;
START TRANSACTION;
INSERT INTO pessoa(id_pessoa,nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES(9701,'Lead de teste V2','CPF','97000000001','11990009701','v2@example.invalid','Rua Teste','1','Centro','Sao Paulo','SP');
INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,data,tipo_interesse,descricao_interesse,situacao) VALUES(9701,9701,1,'2026-02-10 08:00','COMPRA','Teste dos fatores de capacidade','ABERTO');
INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9701,1,'2026-02-10 08:00','OUTRO','RECEBIDA','Teste de uma interacao no periodo');
INSERT INTO intencao_compra VALUES(9701,10,52000,'PIX','2026-02-10 08:00','SITE');
INSERT INTO pessoa(id_pessoa,nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES(9702,'Lead de teste V2 faixa 75','CPF','97000000002','11990009702','v2-75@example.invalid','Rua Teste','2','Centro','Sao Paulo','SP');
INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,data,tipo_interesse,descricao_interesse,situacao) VALUES(9702,9702,1,'2026-02-10 08:00','COMPRA','Teste de capacidade 97 por cento','ABERTO');
INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9702,1,'2026-02-10 08:00','OUTRO','RECEBIDA','Teste de uma interacao no periodo');
INSERT INTO intencao_compra VALUES(9702,11,60000,'DINHEIRO','2026-02-10 08:00','SITE');
CALL teste_regra_v2('versao de regra desconhecida','CALL registrar_classificacao_lead(9701,''REGRA-V9'',''2026-02-10 09:00'',@id_teste)','Versao de regra desconhecida');
CALL teste_regra_v2('intencao duplicada','INSERT INTO intencao_compra VALUES(9701,10,1000,''PIX'',''2026-02-10 08:00'',''SITE'')','Duplicate entry');
CALL teste_regra_v2('intencao sem conteudo','INSERT INTO intencao_compra VALUES(8,NULL,NULL,NULL,''2026-02-10 08:00'',''VENDEDOR'')','ck_intencao_conteudo');
CALL teste_regra_v2('valor negativo','INSERT INTO intencao_compra VALUES(8,NULL,-1,NULL,''2026-02-10 08:00'',''VENDEDOR'')','ck_intencao_valor');
CALL teste_regra_v2('forma nao cadastrada','INSERT INTO intencao_compra VALUES(8,NULL,1000,''BOLETO'',''2026-02-10 08:00'',''VENDEDOR'')','fk_intencao_forma');
CALL teste_regra_v2('veiculo pretendido inativo','INSERT INTO intencao_compra VALUES(8,1,1000,''PIX'',''2026-02-10 08:00'',''VENDEDOR'')','veiculo pretendido deve estar anunciado');
CALL teste_regra_v2('atendimento de venda nao aceita intencao de compra','INSERT INTO intencao_compra VALUES(6,NULL,1000,''PIX'',''2026-02-10 08:00'',''VENDEDOR'')','RN44: intencao de compra exige atendimento de COMPRA ou TROCA');
CALL teste_regra_v2('valor disponivel acima do preco anunciado','INSERT INTO intencao_compra VALUES(8,10,55001,''PIX'',''2026-02-10 08:00'',''SITE'')','RN44: valor disponivel maior que o preco anunciado');
CALL teste_regra_v2('codigo de fator fora do dominio','INSERT INTO classificacao_fator(id_classificacao,codigo_fator,pontos,evidencia) SELECT MIN(id_classificacao),''INVALIDO'',0,''teste'' FROM classificacao_lead','ck_fator_codigo');
SET @id_fator=NULL; CALL registrar_classificacao_lead(9701,'REGRA-V2','2026-02-10 09:00',@id_fator); CALL confere_fator_v2(@id_fator,40,'cobertura >= 90% e pagamento a vista');
UPDATE intencao_compra SET codigo_forma='CARTAO' WHERE id_atendimento=9701; SET @id_fator=NULL; CALL registrar_classificacao_lead(9701,'REGRA-V2','2026-02-10 09:00',@id_fator); CALL confere_fator_v2(@id_fator,30,'cobertura >= 90% sem pagamento a vista');
UPDATE intencao_compra SET valor_disponivel=30000,codigo_forma='PIX' WHERE id_atendimento=9701; SET @id_fator=NULL; CALL registrar_classificacao_lead(9701,'REGRA-V2','2026-02-10 09:00',@id_fator); CALL confere_fator_v2(@id_fator,20,'cobertura >= 50%');
UPDATE intencao_compra SET valor_disponivel=10000,codigo_forma='FINANCIAMENTO' WHERE id_atendimento=9701; SET @id_fator=NULL; CALL registrar_classificacao_lead(9701,'REGRA-V2','2026-02-10 09:00',@id_fator); CALL confere_fator_v2(@id_fator,20,'financiamento com cobertura baixa');
UPDATE intencao_compra SET valor_disponivel=10000,codigo_forma='PIX' WHERE id_atendimento=9701; SET @id_fator=NULL; CALL registrar_classificacao_lead(9701,'REGRA-V2','2026-02-10 09:00',@id_fator); CALL confere_fator_v2(@id_fator,0,'cobertura menor que 50%');
UPDATE intencao_compra SET id_entrada=NULL,valor_disponivel=NULL,codigo_forma='PIX' WHERE id_atendimento=9701; SET @id_fator=NULL; CALL registrar_classificacao_lead(9701,'REGRA-V2','2026-02-10 09:00',@id_fator); CALL confere_fator_v2(@id_fator,10,'sem veiculo selecionado, forma PIX');
SET @id_fator=NULL; CALL registrar_classificacao_lead(9701,'REGRA-V1','2026-02-10 09:00',@id_fator);
CALL confere_classificacao_v2(@id_fator,35,'FRIO','REGRA-V1 permanece em 35 pontos FRIO apos introduzir V2');
SET @id_fator=NULL; CALL registrar_classificacao_lead(9702,'REGRA-V2','2026-02-10 09:00',@id_fator); CALL confere_caso_v2(@id_fator);
SET @id_fator=NULL; CALL registrar_classificacao_lead(9,'REGRA-V2','2026-02-10 09:00',@id_fator);
CALL confere_fator_v2(@id_fator,0,'intencao sem forma e 22% de cobertura do atendimento 9');
SET @id_fator=NULL; CALL registrar_classificacao_lead(8,'REGRA-V2','2026-02-10 09:00',@id_fator);
CALL confere_fator_v2(@id_fator,0,'atendimento sem intencao: fator zero com evidencia');
SET @id_fator=NULL; CALL registrar_classificacao_lead(5,'REGRA-V2','2026-02-10 09:00',@id_fator);
UPDATE intencao_compra SET id_entrada=15,valor_disponivel=5000,codigo_forma='PIX' WHERE id_atendimento=9701;
SET @id_fator=NULL; CALL registrar_classificacao_lead(9701,'REGRA-V2','2026-02-10 09:00',@id_fator);
CALL confere_classificacao_v2(@id_fator,35,'FRIO','oferta de 5000 sobre preco 135900 preserva lead FRIO em 35 pontos');
CALL confere_fator_v2(@id_fator,0,'oferta baixa nao pontua capacidade de pagamento');
SET @id_v2=NULL;CALL registrar_classificacao_lead(7,'REGRA-V2','2026-02-10 16:00',@id_v2);
CALL verificar_regra_v2(@id_v2);
ROLLBACK;
DROP PROCEDURE verificar_regra_v2;
DROP PROCEDURE teste_regra_v2;
DROP PROCEDURE confere_fator_v2;
DROP PROCEDURE confere_classificacao_v2;
DROP PROCEDURE confere_caso_v2;



