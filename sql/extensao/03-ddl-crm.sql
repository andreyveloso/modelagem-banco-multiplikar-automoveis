-- MySQL 8.4 / InnoDB. Histórico somente por inserção; TRUNCATE não dispara trigger no MySQL.
USE multiplikar;
create table interacao (
    id_interacao bigint not null auto_increment primary key,
    id_atendimento bigint not null,
    id_funcionario bigint not null,
    data_hora datetime not null default current_timestamp,
    canal varchar(16) not null,
    direcao varchar(10) not null,
    resumo text not null,
    proximo_passo text,
    data_proximo_passo datetime,
    constraint ck_interacao_canal check (canal in ('TELEFONE', 'WHATSAPP', 'EMAIL', 'PRESENCIAL', 'OUTRO')),
    constraint ck_interacao_direcao check (direcao in ('RECEBIDA', 'ENVIADA')),
    constraint ck_interacao_resumo check (trim(resumo) <> ''),
    constraint ck_interacao_proximo_passo check ((data_proximo_passo is null)
        or (proximo_passo is not null and data_proximo_passo >= data_hora)),
    constraint fk_interacao_id_atendimento foreign key (id_atendimento) references atendimento(id_atendimento),
    constraint fk_interacao_id_funcionario foreign key (id_funcionario) references funcionario(id_funcionario)
) engine=InnoDB default character set=utf8mb4;
create table atendimento_desfecho (
    id_atendimento bigint primary key,
    id_funcionario bigint not null,
    data_hora datetime not null default current_timestamp,
    tipo_desfecho varchar(16) not null,
    motivo text not null,
    detalhe text,
    constraint ck_desfecho_tipo check (tipo_desfecho in ('GANHO', 'PERDA')),
    constraint ck_desfecho_motivo check (trim(motivo) <> ''),
    constraint fk_atendimento_desfecho_id_atendimento foreign key (id_atendimento) references atendimento(id_atendimento),
    constraint fk_atendimento_desfecho_id_funcionario foreign key (id_funcionario) references funcionario(id_funcionario)
) engine=InnoDB default character set=utf8mb4;
create table classificacao_lead (
    id_classificacao bigint not null auto_increment primary key,
    id_atendimento bigint not null,
    data_hora datetime not null,
    origem varchar(10) not null,
    versao_regra varchar(16) not null,
    temperatura_sugerida varchar(8) not null,
    pontuacao decimal(6,2) not null,
    temperatura_final varchar(8),
    id_revisor bigint,
    data_revisao datetime,
    justificativa_revisao text,
    constraint ck_classificacao_origem check (origem in ('REGRA', 'IA')),
    constraint ck_classificacao_temp_sugerida check (temperatura_sugerida in ('FRIO', 'MORNO', 'QUENTE')),
    constraint ck_classificacao_temp_final check (temperatura_final is null
        or temperatura_final in ('FRIO', 'MORNO', 'QUENTE')),
    constraint ck_classificacao_pontuacao check (pontuacao >= 0),
    constraint ck_classificacao_revisao check ((temperatura_final is null and id_revisor is null and data_revisao is null and justificativa_revisao is null)
        or (temperatura_final is not null and id_revisor is not null and data_revisao is not null)),
    constraint ck_classificacao_justificativa check (temperatura_final is null
        or temperatura_final = temperatura_sugerida
        or justificativa_revisao is not null),
    constraint fk_classificacao_lead_id_atendimento foreign key (id_atendimento) references atendimento(id_atendimento),
    constraint fk_classificacao_lead_id_revisor foreign key (id_revisor) references funcionario(id_funcionario)
) engine=InnoDB default character set=utf8mb4;
create table classificacao_fator (
    id_classificacao bigint not null,
    codigo_fator varchar(32) not null,
    pontos decimal(6,2) not null,
    evidencia text not null,
    primary key (id_classificacao, codigo_fator),
    constraint ck_fator_codigo check (codigo_fator in ('URGENCIA_CONTATO', 'ESTAGIO_NEGOCIACAO', 'INTERESSE_FINANCEIRO', 'VOLUME_INTERACOES')),
    constraint ck_fator_evidencia check (trim(evidencia) <> ''),
    constraint fk_classificacao_fator_id_classificacao foreign key (id_classificacao) references classificacao_lead(id_classificacao)
) engine=InnoDB default character set=utf8mb4;
create table parametro_temperatura (
    temperatura varchar(8) primary key,
    probabilidade decimal(5,4) not null,
    origem varchar(10) not null,
    vigencia date not null,
    constraint ck_parametro_temperatura check (temperatura in ('FRIO', 'MORNO', 'QUENTE')),
    constraint ck_parametro_probabilidade check (probabilidade between 0 and 1),
    constraint ck_parametro_origem check (origem in ('HIPOTESE', 'CALIBRADA'))
) engine=InnoDB default character set=utf8mb4;

CREATE INDEX ix_interacao_atendimento ON interacao(id_atendimento,data_hora);
CREATE INDEX ix_classificacao_atendimento ON classificacao_lead(id_atendimento,data_hora);
CREATE INDEX ix_atendimento_desfecho_funcionario ON atendimento_desfecho(id_funcionario);
DELIMITER $$
-- O gatilho força o INSERT da classificação pelo procedimento, que também grava fatores.
CREATE TRIGGER classificacao_lead_bi BEFORE INSERT ON classificacao_lead FOR EACH ROW
BEGIN
 IF NOT (@mk_registrando_classificacao <=> 1) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='R37: classificacao de lead exige ao menos um fator explicativo; use registrar_classificacao_lead';
 END IF;
END$$
CREATE TRIGGER interacao_bu BEFORE UPDATE ON interacao FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Registro de interacao e somente insercao'; END$$
CREATE TRIGGER interacao_bd BEFORE DELETE ON interacao FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Registro de interacao e somente insercao'; END$$
CREATE TRIGGER desfecho_bu BEFORE UPDATE ON atendimento_desfecho FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Registro de desfecho e somente insercao'; END$$
CREATE TRIGGER desfecho_bd BEFORE DELETE ON atendimento_desfecho FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Registro de desfecho e somente insercao'; END$$
CREATE TRIGGER fator_bu BEFORE UPDATE ON classificacao_fator FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Registro de fator e somente insercao'; END$$
CREATE TRIGGER fator_bd BEFORE DELETE ON classificacao_fator FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Registro de fator e somente insercao'; END$$
CREATE TRIGGER classificacao_bu BEFORE UPDATE ON classificacao_lead FOR EACH ROW
BEGIN
 IF OLD.temperatura_final IS NOT NULL OR NEW.temperatura_final IS NULL OR NOT(NEW.id_atendimento<=>OLD.id_atendimento) OR NOT(NEW.data_hora<=>OLD.data_hora) OR NOT(NEW.origem<=>OLD.origem) OR NOT(NEW.versao_regra<=>OLD.versao_regra) OR NOT(NEW.temperatura_sugerida<=>OLD.temperatura_sugerida) OR NOT(NEW.pontuacao<=>OLD.pontuacao) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Apenas revisao humana ausente pode ser preenchida'; END IF;
END$$
CREATE TRIGGER classificacao_bd BEFORE DELETE ON classificacao_lead FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Classificacao de lead e historico; nunca e apagada'; END$$
CREATE PROCEDURE registrar_classificacao_lead(IN p_id_atendimento BIGINT,IN p_versao_regra VARCHAR(16),IN p_referencia DATETIME,OUT p_id_classificacao BIGINT)
BEGIN
 DECLARE v_sit VARCHAR(13); DECLARE v_tipo VARCHAR(6); DECLARE v_data DATETIME; DECLARE v_ultima DATETIME; DECLARE v_n INT; DECLARE v_dias INT; DECLARE a DECIMAL(6,2); DECLARE b DECIMAL(6,2); DECLARE c DECIMAL(6,2); DECLARE d DECIMAL(6,2); DECLARE total DECIMAL(6,2); DECLARE temp VARCHAR(8);
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @mk_registrando_classificacao=NULL; RESIGNAL; END;
 SELECT situacao,tipo_interesse,data INTO v_sit,v_tipo,v_data FROM atendimento WHERE id_atendimento=p_id_atendimento;
 IF v_data IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Atendimento nao encontrado'; END IF;
 SELECT MAX(data_hora),COUNT(*) INTO v_ultima,v_n FROM interacao WHERE id_atendimento=p_id_atendimento AND data_hora<=p_referencia;
 SET v_dias=DATEDIFF(DATE(p_referencia),DATE(COALESCE(v_ultima,v_data)));
 SET a=CASE WHEN v_dias>=15 THEN 40 WHEN v_dias>=7 THEN 20 ELSE 0 END; SET b=CASE v_sit WHEN 'EM_NEGOCIACAO' THEN 30 WHEN 'ABERTO' THEN 10 ELSE 0 END; SET c=CASE v_tipo WHEN 'COMPRA' THEN 20 WHEN 'TROCA' THEN 15 ELSE 10 END; SET d=CASE WHEN v_n>=3 THEN 10 WHEN v_n>=1 THEN 5 ELSE 0 END; SET total=a+b+c+d; SET temp=CASE WHEN total>=70 THEN 'QUENTE' WHEN total>=40 THEN 'MORNO' ELSE 'FRIO' END;
 SET @mk_registrando_classificacao=1;
 INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao) VALUES(p_id_atendimento,p_referencia,'REGRA',p_versao_regra,temp,total);
 SET @mk_registrando_classificacao=NULL; SET p_id_classificacao=LAST_INSERT_ID();
 INSERT INTO classificacao_fator VALUES(p_id_classificacao,'URGENCIA_CONTATO',a,CONCAT(v_dias,' dias sem contato')), (p_id_classificacao,'ESTAGIO_NEGOCIACAO',b,CONCAT('situacao=',v_sit)), (p_id_classificacao,'INTERESSE_FINANCEIRO',c,CONCAT('interesse=',v_tipo)),(p_id_classificacao,'VOLUME_INTERACOES',d,CONCAT(v_n,' interacoes'));
END$$
DELIMITER ;

CREATE VIEW vw_lead_atual AS WITH ultima_classificacao AS (SELECT * FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY id_atendimento ORDER BY data_hora DESC,id_classificacao DESC) AS _row_number FROM classificacao_lead) AS _t WHERE _row_number = 1), contato AS (SELECT id_atendimento, MAX(data_hora) AS data_ultima_interacao, COUNT(*) AS total_interacoes FROM interacao GROUP BY id_atendimento) SELECT a.id_atendimento, a.id_pessoa, p.nome AS nome_cliente, p.telefone, a.id_funcionario, a.tipo_interesse, a.descricao_interesse, a.data AS data_abertura, a.situacao AS situacao_atendimento, d.tipo_desfecho, d.motivo AS motivo_desfecho, d.data_hora AS data_desfecho, c.id_classificacao, c.data_hora AS data_classificacao, c.versao_regra, c.temperatura_sugerida, c.pontuacao, c.temperatura_final, (c.temperatura_final IS NOT NULL) AS revisado, c.id_revisor, c.data_revisao, c.justificativa_revisao, COALESCE(c.temperatura_final, c.temperatura_sugerida) AS temperatura_atual, ct.data_ultima_interacao, COALESCE(ct.total_interacoes, 0) AS total_interacoes, DATEDIFF(data_referencia(), COALESCE(DATE(ct.data_ultima_interacao), DATE(a.data))) AS dias_sem_contato FROM atendimento AS a JOIN pessoa AS p ON p.id_pessoa = a.id_pessoa LEFT JOIN atendimento_desfecho AS d ON d.id_atendimento = a.id_atendimento LEFT JOIN ultima_classificacao AS c ON c.id_atendimento = a.id_atendimento LEFT JOIN contato AS ct ON ct.id_atendimento = a.id_atendimento;

CREATE VIEW vw_fila_acoes AS
WITH propostas_validas AS (
 SELECT pr.id_atendimento,pr.id_proposta,pr.valor_total,ROW_NUMBER() OVER(PARTITION BY pr.id_atendimento ORDER BY pr.valor_total DESC,pr.data_criacao DESC,pr.id_proposta DESC) AS rn
 FROM proposta pr WHERE pr.situacao IN('RASCUNHO','APRESENTADA') AND pr.validade>=data_referencia()
), veiculo_lead AS (
 SELECT a.id_atendimento,e.preco_anunciado,ROW_NUMBER() OVER(PARTITION BY a.id_atendimento ORDER BY e.data_entrada DESC,e.id_entrada DESC) AS rn
 FROM atendimento a JOIN entrada e ON e.situacao='ATIVA' JOIN veiculo v ON v.id_veiculo=e.id_veiculo WHERE a.descricao_interesse LIKE CONCAT('%',v.modelo,'%')
), fila_crm AS (
 SELECT 'CRM' AS fonte,l.id_atendimento AS id_referencia,
 CONCAT('Lead ',l.nome_cliente,' (atendimento ',l.id_atendimento,') ',LOWER(l.temperatura_atual),' sem contato ha ',l.dias_sem_contato,' dias') AS descricao,
 CONCAT('temperatura=',l.temperatura_atual,', pontuacao=',COALESCE(l.pontuacao,0),', sem contato=',l.dias_sem_contato,' dias; valor em risco=',COALESCE(p.valor_total,v.preco_anunciado,0)) AS motivo,
 COALESCE(p.valor_total,v.preco_anunciado,0) AS valor_em_risco,l.dias_sem_contato AS urgencia_dias
 FROM vw_lead_atual l LEFT JOIN propostas_validas p ON p.id_atendimento=l.id_atendimento AND p.rn=1 LEFT JOIN veiculo_lead v ON v.id_atendimento=l.id_atendimento AND v.rn=1
 WHERE l.situacao_atendimento IN('ABERTO','EM_NEGOCIACAO') AND l.tipo_desfecho IS NULL AND l.temperatura_atual IN('QUENTE','MORNO') AND l.dias_sem_contato>=CASE l.temperatura_atual WHEN 'QUENTE' THEN 3 ELSE 7 END
 AND NOT EXISTS(SELECT 1 FROM venda vv WHERE vv.situacao_comercial<>'CANCELADA' AND (vv.id_proposta IN(SELECT id_proposta FROM proposta WHERE id_atendimento=l.id_atendimento) OR (vv.id_proposta IS NULL AND vv.id_comprador=l.id_pessoa AND vv.data_registro>=l.data_abertura)))
), fila_caixa AS (
 SELECT 'CAIXA' AS fonte,o.id_obrigacao AS id_referencia,CONCAT('Obrigacao ',o.id_obrigacao,' venda ',COALESCE(o.id_venda,0),': ',LOWER(o.natureza),' ',o.valor,' vencida ha ',DATEDIFF(data_referencia(),o.vencimento_atual),' dias') AS descricao,
 CONCAT('situacao=',o.situacao,', vencimento_original=',o.vencimento_original,', vencimento_atual=',o.vencimento_atual) AS motivo,o.valor AS valor_em_risco,DATEDIFF(data_referencia(),o.vencimento_atual) AS urgencia_dias
 FROM obrigacao_financeira o WHERE o.natureza='RECEBER' AND o.situacao NOT IN('QUITADA','CANCELADA') AND o.vencimento_atual<data_referencia()
), fila_estoque AS (
 SELECT 'ESTOQUE' AS fonte,e.id_entrada AS id_referencia,CONCAT('Veiculo ',v.marca,' ',v.modelo,' parado ha ',DATEDIFF(data_referencia(),DATE(e.data_entrada)),' dias') AS descricao,
 CONCAT('entrada ativa sem venda nem proposta aberta; capital=',e.valor_acordado) AS motivo,e.valor_acordado AS valor_em_risco,DATEDIFF(data_referencia(),DATE(e.data_entrada)) AS urgencia_dias
 FROM entrada e JOIN veiculo v ON v.id_veiculo=e.id_veiculo WHERE e.situacao='ATIVA' AND DATEDIFF(data_referencia(),DATE(e.data_entrada))>=30
 AND NOT EXISTS(SELECT 1 FROM venda vv WHERE vv.id_entrada_principal=e.id_entrada)
 AND NOT EXISTS(SELECT 1 FROM proposta pr WHERE pr.id_entrada=e.id_entrada AND pr.situacao IN('RASCUNHO','APRESENTADA') AND pr.validade>=data_referencia())
)
SELECT * FROM fila_crm UNION ALL SELECT * FROM fila_caixa UNION ALL SELECT * FROM fila_estoque;



