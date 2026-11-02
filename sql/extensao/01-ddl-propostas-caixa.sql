-- Propostas, simulações e obrigações financeiras. MySQL 8.4 / InnoDB / utf8mb4.
-- No MySQL, a validação ocorre no ponto em que a proposta é apresentada ou aceita.
-- A substituição e a recusa das alternativas são atômicas por procedures.
USE multiplikar;
-- MySQL 8.4; constraints de referência declaradas no nível da tabela.
create table parametro_referencia (
    chave boolean primary key default true,
    data_referencia date not null,
    origem varchar(12) not null,
    constraint ck_parametro_referencia_chave check (chave=true),
    constraint ck_parametro_referencia_origem check (origem in ('DEMONSTRACAO', 'OPERACAO'))
) engine=InnoDB default character set=utf8mb4;
DROP FUNCTION IF EXISTS data_referencia;
DELIMITER $$
CREATE FUNCTION data_referencia() RETURNS DATE READS SQL DATA BEGIN DECLARE v DATE; SELECT MAX(data_referencia) INTO v FROM parametro_referencia WHERE chave=TRUE; RETURN COALESCE(v,CURRENT_DATE()); END$$
DELIMITER ;
create table proposta (
    id_proposta bigint not null auto_increment primary key,
    id_atendimento bigint not null,
    id_entrada bigint not null,
    id_funcionario bigint not null,
    id_proposta_anterior bigint unique,
    rotulo varchar(1) not null,
    versao int not null,
    data_criacao date not null default (current_date),
    validade date not null default (current_date + interval 7 day),
    valor_base decimal(14,2) not null,
    desconto decimal(14,2) not null default 0,
    acrescimo decimal(14,2) not null default 0,
    taxas decimal(14,2) not null default 0,
    valor_total decimal(14,2) generated always as (valor_base - desconto + acrescimo + taxas) stored,
    id_entrada_aceita bigint generated always as (case when situacao='ACEITA' then id_entrada else null end) stored,
    situacao varchar(12) not null default 'RASCUNHO',
    data_decisao datetime,
    motivo_recusa text,
    constraint ck_proposta_versao check (versao > 0),
    constraint ck_proposta_rotulo check (trim(rotulo) <> ''),
    constraint ck_proposta_raiz_versao check ((id_proposta_anterior is null and versao=1)
        or (id_proposta_anterior is not null and versao>1)),
    constraint ck_proposta_valores check (valor_base >= 0
        and desconto >= 0
        and acrescimo >= 0
        and taxas >= 0
        and valor_total > 0
        and desconto <= valor_base),
    constraint ck_proposta_datas check (validade >= data_criacao),
    constraint ck_proposta_situacao check (situacao in ('RASCUNHO', 'APRESENTADA', 'ACEITA', 'RECUSADA', 'EXPIRADA', 'SUBSTITUIDA')),
    constraint ck_proposta_data_decisao check ((situacao in ('ACEITA', 'RECUSADA', 'EXPIRADA', 'SUBSTITUIDA') and data_decisao is not null)
        or (situacao in ('RASCUNHO', 'APRESENTADA') and data_decisao is null)),
    constraint ck_proposta_recusa check ((situacao = 'RECUSADA' and motivo_recusa is not null)
        or (situacao <> 'RECUSADA' and motivo_recusa is null)),
    constraint uq_proposta_alternativa_versao unique (id_atendimento, id_entrada, rotulo, versao),
    constraint fk_proposta_id_atendimento foreign key (id_atendimento) references atendimento(id_atendimento),
    constraint fk_proposta_id_entrada foreign key (id_entrada) references entrada(id_entrada),
    constraint fk_proposta_id_funcionario foreign key (id_funcionario) references funcionario(id_funcionario),
    constraint fk_proposta_id_proposta_anterior foreign key (id_proposta_anterior) references proposta(id_proposta)
) engine=InnoDB default character set=utf8mb4;
create table proposta_condicao (
    id_proposta bigint not null,
    codigo_forma varchar(20) not null,
    valor decimal(14,2) not null,
    prazo_previsto_dias int not null default 0,
    primary key (id_proposta, codigo_forma),
    constraint ck_proposta_condicao_valor check (valor > 0),
    constraint ck_proposta_condicao_prazo check (prazo_previsto_dias >= 0),
    constraint fk_proposta_condicao_id_proposta foreign key (id_proposta) references proposta(id_proposta),
    constraint fk_proposta_condicao_codigo_forma foreign key (codigo_forma) references forma_pagamento(codigo)
) engine=InnoDB default character set=utf8mb4;
create table proposta_troca (
    id_proposta bigint not null,
    id_avaliacao bigint not null,
    valor_oferecido decimal(14,2) not null,
    primary key (id_proposta, id_avaliacao),
    constraint ck_proposta_troca_valor check (valor_oferecido > 0),
    constraint fk_proposta_troca_id_proposta foreign key (id_proposta) references proposta(id_proposta),
    constraint fk_proposta_troca_id_avaliacao foreign key (id_avaliacao) references avaliacao(id_avaliacao)
) engine=InnoDB default character set=utf8mb4;
create table parametro_retorno (
    instituicao varchar(100) not null,
    tabela_retorno varchar(2) not null,
    acrescimo_taxa_mensal decimal(8,6) not null default 0,
    retorno_pct decimal(5,4) not null default 0,
    origem varchar(10) not null default 'HIPOTESE',
    vigencia date not null default (current_date),
    primary key (instituicao, tabela_retorno, vigencia),
    constraint ck_parametro_retorno_tabela check (tabela_retorno in ('R0', 'R1', 'R2', 'R3', 'R4', 'R5')),
    constraint ck_parametro_retorno_instituicao check (trim(instituicao) <> ''),
    constraint ck_parametro_retorno_acrescimo check (acrescimo_taxa_mensal >= 0),
    constraint ck_parametro_retorno_pct check (retorno_pct between 0 and 0.10),
    constraint ck_parametro_retorno_origem check (origem in ('HIPOTESE', 'CALIBRADA'))
) engine=InnoDB default character set=utf8mb4;
create table simulacao_financiamento (
    id_simulacao bigint not null auto_increment primary key,
    id_proposta bigint not null,
    instituicao varchar(100) not null,
    tabela_retorno varchar(2) not null default 'R0',
    origem varchar(16) not null,
    valor_financiado decimal(14,2) not null,
    taxa_mensal decimal(8,6) not null,
    prazo_meses smallint not null,
    parcela_informada decimal(14,2),
    renda_declarada decimal(14,2),
    consentimento_renda boolean not null default false,
    situacao varchar(12) not null default 'EM_ANALISE',
    id_proposta_aprovada bigint generated always as (case when situacao='APROVADA' then id_proposta else null end) stored,
    data_simulacao datetime not null default current_timestamp,
    data_resposta datetime,
    constraint ck_simulacao_origem check (origem in ('ACADEMICA', 'INFORMADA_BANCO', 'INTEGRACAO')),
    constraint ck_simulacao_tabela_retorno check (tabela_retorno in ('R0', 'R1', 'R2', 'R3', 'R4', 'R5')),
    constraint ck_simulacao_instituicao check (trim(instituicao) <> ''),
    constraint ck_simulacao_consentimento_dominio check (consentimento_renda in (0, 1)),
    constraint ck_simulacao_valores check (valor_financiado > 0
        and taxa_mensal > 0
        and taxa_mensal < 1
        and prazo_meses > 0
        and parcela_informada > 0
        and renda_declarada > 0),
    constraint ck_simulacao_situacao check (situacao in ('EM_ANALISE', 'APROVADA', 'RECUSADA', 'CANCELADA')),
    constraint ck_simulacao_datas check (data_resposta is null or data_resposta >= data_simulacao),
    constraint ck_simulacao_consentimento_renda check (renda_declarada is null
        or consentimento_renda),
    constraint fk_simulacao_financiamento_id_proposta foreign key (id_proposta) references proposta(id_proposta)
) engine=InnoDB default character set=utf8mb4;
create table obrigacao_financeira (
    id_obrigacao bigint not null auto_increment primary key,
    natureza varchar(8) not null,
    origem varchar(16) not null,
    id_venda bigint,
    id_entrada bigint,
    id_despesa bigint,
    categoria varchar(40) not null,
    contraparte varchar(150) not null,
    valor decimal(14,2) not null,
    data_competencia date not null,
    vencimento_original date not null,
    vencimento_atual date not null,
    situacao varchar(10) not null default 'PREVISTA',
    origem_estimativa varchar(10) not null default 'FATO',
    constraint ck_obrigacao_natureza check (natureza in ('RECEBER', 'PAGAR')),
    constraint ck_obrigacao_origem check (origem in ('VENDA', 'ENTRADA', 'DESPESA_VEICULO', 'ADMINISTRATIVA')),
    constraint ck_obrigacao_arco check ((origem = 'VENDA' and id_venda is not null and id_entrada is null and id_despesa is null and natureza='RECEBER')
        or (origem = 'ENTRADA' and id_venda is null and id_entrada is not null and id_despesa is null and natureza='PAGAR')
        or (origem = 'DESPESA_VEICULO' and id_venda is null and id_entrada is null and id_despesa is not null and natureza='PAGAR')
        or (origem = 'ADMINISTRATIVA' and id_venda is null and id_entrada is null and id_despesa is null and natureza='PAGAR')),
    constraint ck_obrigacao_valores check (valor > 0),
    constraint ck_obrigacao_textos check (trim(categoria) <> '' and trim(contraparte) <> ''),
    constraint ck_obrigacao_datas check (vencimento_original >= data_competencia
        and vencimento_atual >= data_competencia),
    constraint ck_obrigacao_situacao check (situacao in ('PREVISTA', 'ABERTA', 'QUITADA', 'CANCELADA', 'ATRASADA')),
    constraint ck_obrigacao_estimativa check (origem_estimativa in ('FATO', 'HIPOTESE', 'SIMULADO')),
    constraint fk_obrigacao_financeira_id_venda foreign key (id_venda) references venda(id_venda),
    constraint fk_obrigacao_financeira_id_entrada foreign key (id_entrada) references entrada(id_entrada),
    constraint fk_obrigacao_financeira_id_despesa foreign key (id_despesa) references despesa(id_despesa)
) engine=InnoDB default character set=utf8mb4;
create table parametro_prazo (
    banco varchar(100) not null,
    tipo_obrigacao varchar(32) not null,
    dias_previstos int not null,
    origem varchar(10) not null default 'HIPOTESE',
    vigencia date not null default (current_date),
    primary key (banco, tipo_obrigacao, vigencia),
    constraint ck_parametro_prazo_tipo check (tipo_obrigacao in ('FINANCIAMENTO_RECEBER', 'CONSIGNANTE_PAGAR', 'COMPRA_PROPRIA_PAGAR')),
    constraint ck_parametro_prazo_dias check (dias_previstos >= 0),
    constraint ck_parametro_prazo_banco check (trim(banco) <> ''),
    constraint ck_parametro_prazo_origem check (origem in ('HIPOTESE', 'CALIBRADA'))
) engine=InnoDB default character set=utf8mb4;
ALTER TABLE venda ADD COLUMN id_proposta BIGINT UNIQUE;
ALTER TABLE venda ADD CONSTRAINT fk_venda_id_proposta FOREIGN KEY (id_proposta) REFERENCES proposta(id_proposta);
CREATE UNIQUE INDEX uq_proposta_aceita_entrada ON proposta(id_entrada_aceita);
CREATE UNIQUE INDEX uq_simulacao_aprovada_proposta ON simulacao_financiamento(id_proposta_aprovada);
CREATE INDEX ix_proposta_atendimento_data ON proposta(id_atendimento,data_criacao);
CREATE INDEX ix_proposta_condicao_proposta ON proposta_condicao(id_proposta);
CREATE INDEX ix_proposta_troca_avaliacao ON proposta_troca(id_avaliacao);
CREATE INDEX ix_simulacao_proposta ON simulacao_financiamento(id_proposta,data_simulacao);
CREATE INDEX ix_obrigacao_vencimento ON obrigacao_financeira(situacao,vencimento_atual);

-- A validação de composição que era adiada ao COMMIT ocorre no instante de APRESENTADA.
DELIMITER $$
CREATE TRIGGER proposta_bi BEFORE INSERT ON proposta FOR EACH ROW
BEGIN
 DECLARE v_atd BIGINT; DECLARE v_ent BIGINT; DECLARE v_ver INT; DECLARE v_rot VARCHAR(1); DECLARE v_sit VARCHAR(12);
 IF NEW.id_proposta_anterior IS NULL THEN
  IF NEW.versao<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta raiz deve iniciar na versao 1'; END IF;
 ELSE
  SELECT id_atendimento,id_entrada,versao,rotulo,situacao INTO v_atd,v_ent,v_ver,v_rot,v_sit FROM proposta WHERE id_proposta=NEW.id_proposta_anterior;
  IF v_atd IS NULL OR v_atd<>NEW.id_atendimento OR v_ent<>NEW.id_entrada OR v_ver+1<>NEW.versao OR v_rot<>NEW.rotulo OR v_sit<>'SUBSTITUIDA' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Contraproposta deve suceder a mesma alternativa e herdar o rotulo'; END IF;
 END IF;
 IF NEW.validade=DATE_ADD(CURRENT_DATE(),INTERVAL 7 DAY) THEN SET NEW.validade=DATE_ADD(data_referencia(),INTERVAL 7 DAY); END IF;
END$$
CREATE TRIGGER proposta_bu BEFORE UPDATE ON proposta FOR EACH ROW
BEGIN
 DECLARE v_sum DECIMAL(14,2); DECLARE v_ativa INT;
 IF OLD.situacao<>'RASCUNHO' AND (NOT(NEW.id_atendimento<=>OLD.id_atendimento) OR NOT(NEW.id_entrada<=>OLD.id_entrada) OR NOT(NEW.id_funcionario<=>OLD.id_funcionario) OR NOT(NEW.id_proposta_anterior<=>OLD.id_proposta_anterior) OR NOT(NEW.rotulo<=>OLD.rotulo) OR NOT(NEW.versao<=>OLD.versao) OR NOT(NEW.data_criacao<=>OLD.data_criacao) OR NOT(NEW.validade<=>OLD.validade) OR NOT(NEW.valor_base<=>OLD.valor_base) OR NOT(NEW.desconto<=>OLD.desconto) OR NOT(NEW.acrescimo<=>OLD.acrescimo) OR NOT(NEW.taxas<=>OLD.taxas)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta apresentada e imutavel; crie nova versao'; END IF;
 IF OLD.situacao IN ('ACEITA','RECUSADA','EXPIRADA','SUBSTITUIDA') AND NEW.situacao<>OLD.situacao THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Situacao terminal da proposta e imutavel'; END IF;
 IF OLD.situacao='RASCUNHO' AND NEW.situacao NOT IN ('RASCUNHO','APRESENTADA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta deve ser apresentada antes da decisao'; END IF;
 IF OLD.situacao='APRESENTADA' AND NEW.situacao NOT IN ('APRESENTADA','ACEITA','RECUSADA','EXPIRADA','SUBSTITUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Transicao de situacao da proposta invalida'; END IF;
 IF NEW.situacao='APRESENTADA' AND OLD.situacao='RASCUNHO' THEN
  SELECT COALESCE((SELECT SUM(valor) FROM proposta_condicao WHERE id_proposta=NEW.id_proposta),0)+COALESCE((SELECT SUM(valor_oferecido) FROM proposta_troca WHERE id_proposta=NEW.id_proposta),0) INTO v_sum;
  IF v_sum<>NEW.valor_total THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Composicao da proposta deve igualar o valor total'; END IF;
  SELECT COUNT(*) INTO v_ativa FROM entrada WHERE id_entrada=NEW.id_entrada AND situacao='ATIVA';
  IF v_ativa=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta apresentada exige entrada ativa'; END IF;
 END IF;
 IF NEW.situacao='ACEITA' THEN
  IF COALESCE(@multiplikar_aceitar_proposta,0)<>NEW.id_proposta THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use aceitar_proposta para registrar escolha e recusar alternativas'; END IF;
  IF NEW.data_decisao IS NULL OR DATE(NEW.data_decisao)>NEW.validade OR NOT EXISTS(SELECT 1 FROM entrada WHERE id_entrada=NEW.id_entrada AND situacao='ATIVA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta aceita exige entrada ativa e decisao ate a validade'; END IF;
 END IF;
END$$
CREATE PROCEDURE aceitar_proposta(IN p_id BIGINT, IN p_quando DATETIME)
BEGIN
 DECLARE v_atd BIGINT; DECLARE v_ent BIGINT;
 START TRANSACTION;
 SELECT id_atendimento,id_entrada INTO v_atd,v_ent FROM proposta WHERE id_proposta=p_id AND situacao='APRESENTADA' FOR UPDATE;
 SET @multiplikar_aceitar_proposta=p_id;
 UPDATE proposta SET situacao='ACEITA',data_decisao=p_quando WHERE id_proposta=p_id;
 SET @multiplikar_aceitar_proposta=NULL;
 UPDATE proposta SET situacao='RECUSADA',motivo_recusa=CONCAT('Alternativa nao escolhida: proposta ',p_id,' aceita'),data_decisao=p_quando WHERE id_atendimento=v_atd AND id_entrada=v_ent AND id_proposta<>p_id AND situacao='APRESENTADA';
 COMMIT;
END$$
CREATE PROCEDURE criar_contraproposta(IN p_anterior BIGINT,IN p_data DATE,IN p_desconto DECIMAL(14,2),IN p_acrescimo DECIMAL(14,2),IN p_taxas DECIMAL(14,2),OUT p_nova BIGINT)
BEGIN
 DECLARE v_atd BIGINT; DECLARE v_ent BIGINT; DECLARE v_func BIGINT; DECLARE v_rot VARCHAR(1); DECLARE v_ver INT; DECLARE v_base DECIMAL(14,2);
 START TRANSACTION;
 SELECT id_atendimento,id_entrada,id_funcionario,rotulo,versao,valor_base INTO v_atd,v_ent,v_func,v_rot,v_ver,v_base FROM proposta WHERE id_proposta=p_anterior AND situacao='APRESENTADA' FOR UPDATE;
 UPDATE proposta SET situacao='SUBSTITUIDA',data_decisao=TIMESTAMP(data_referencia()) WHERE id_proposta=p_anterior;
 INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base,desconto,acrescimo,taxas,situacao) VALUES(v_atd,v_ent,v_func,p_anterior,v_rot,v_ver+1,p_data,DATE_ADD(data_referencia(),INTERVAL 7 DAY),v_base,p_desconto,p_acrescimo,p_taxas,'RASCUNHO');
 SET p_nova=LAST_INSERT_ID(); COMMIT;
END$$
CREATE TRIGGER proposta_condicao_bi BEFORE INSERT ON proposta_condicao FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM proposta WHERE id_proposta=NEW.id_proposta AND situacao='RASCUNHO') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta apresentada e imutavel; crie nova versao'; END IF; END$$
CREATE TRIGGER proposta_condicao_bu BEFORE UPDATE ON proposta_condicao FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM proposta WHERE id_proposta=OLD.id_proposta AND situacao='RASCUNHO') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta apresentada e imutavel; crie nova versao'; END IF; END$$
CREATE TRIGGER proposta_condicao_bd BEFORE DELETE ON proposta_condicao FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM proposta WHERE id_proposta=OLD.id_proposta AND situacao='RASCUNHO') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta apresentada e imutavel; crie nova versao'; END IF; END$$
CREATE TRIGGER proposta_troca_bi BEFORE INSERT ON proposta_troca FOR EACH ROW
BEGIN
 DECLARE v_data DATE; DECLARE v_veic BIGINT;
 SELECT data_criacao INTO v_data FROM proposta WHERE id_proposta=NEW.id_proposta AND situacao='RASCUNHO';
 SELECT id_veiculo INTO v_veic FROM entrada WHERE id_entrada=(SELECT id_entrada FROM proposta WHERE id_proposta=NEW.id_proposta);
 IF v_data IS NULL OR NOT EXISTS(SELECT 1 FROM avaliacao a WHERE a.id_avaliacao=NEW.id_avaliacao AND a.finalidade='TROCA' AND a.decisao_tecnica='APROVADA' AND a.interesse_comercial='SIM' AND a.id_veiculo<>v_veic AND DATE(a.data)<=v_data AND NOT EXISTS(SELECT 1 FROM entrada e WHERE e.id_avaliacao=a.id_avaliacao)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Troca exige avaliacao aprovada, anterior e ainda nao consumida'; END IF;
END$$
CREATE TRIGGER proposta_troca_bu BEFORE UPDATE ON proposta_troca FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM proposta WHERE id_proposta=OLD.id_proposta AND situacao='RASCUNHO') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta apresentada e imutavel; crie nova versao'; END IF; END$$
CREATE TRIGGER proposta_troca_bd BEFORE DELETE ON proposta_troca FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM proposta WHERE id_proposta=OLD.id_proposta AND situacao='RASCUNHO') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Proposta apresentada e imutavel; crie nova versao'; END IF; END$$
CREATE TRIGGER simulacao_retorno_bi BEFORE INSERT ON simulacao_financiamento FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM parametro_retorno WHERE instituicao=NEW.instituicao AND tabela_retorno=NEW.tabela_retorno AND vigencia<=DATE(NEW.data_simulacao)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Parametro_retorno vigente nao encontrado para instituicao/tabela/data da simulacao'; END IF; END$$
CREATE TRIGGER simulacao_retorno_bu BEFORE UPDATE ON simulacao_financiamento FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM parametro_retorno WHERE instituicao=NEW.instituicao AND tabela_retorno=NEW.tabela_retorno AND vigencia<=DATE(NEW.data_simulacao)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Parametro_retorno vigente nao encontrado para instituicao/tabela/data da simulacao'; END IF; END$$
CREATE TRIGGER simulacao_imutavel_bu BEFORE UPDATE ON simulacao_financiamento FOR EACH ROW
BEGIN
 IF OLD.situacao<>'EM_ANALISE' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Simulacao financeira imutavel apos EM_ANALISE'; END IF;
 IF NOT(NEW.id_simulacao<=>OLD.id_simulacao) OR NOT(NEW.id_proposta<=>OLD.id_proposta) OR NOT(NEW.instituicao<=>OLD.instituicao) OR NOT(NEW.tabela_retorno<=>OLD.tabela_retorno) OR NOT(NEW.origem<=>OLD.origem) OR NOT(NEW.valor_financiado<=>OLD.valor_financiado) OR NOT(NEW.taxa_mensal<=>OLD.taxa_mensal) OR NOT(NEW.prazo_meses<=>OLD.prazo_meses) OR NOT(NEW.renda_declarada<=>OLD.renda_declarada) OR NOT(NEW.consentimento_renda<=>OLD.consentimento_renda) OR NOT(NEW.data_simulacao<=>OLD.data_simulacao) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Simulacao em analise so permite alterar situacao, data_resposta e parcela_informada'; END IF;
END$$
CREATE TRIGGER simulacao_imutavel_bd BEFORE DELETE ON simulacao_financiamento FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Simulacao financeira nao pode ser removida'; END$$
CREATE TRIGGER obrigacao_imutavel_bu BEFORE UPDATE ON obrigacao_financeira FOR EACH ROW
BEGIN
 IF NOT(NEW.id_obrigacao<=>OLD.id_obrigacao) OR NOT(NEW.natureza<=>OLD.natureza) OR NOT(NEW.origem<=>OLD.origem) OR NOT(NEW.id_venda<=>OLD.id_venda) OR NOT(NEW.id_entrada<=>OLD.id_entrada) OR NOT(NEW.id_despesa<=>OLD.id_despesa) OR NOT(NEW.categoria<=>OLD.categoria) OR NOT(NEW.contraparte<=>OLD.contraparte) OR NOT(NEW.valor<=>OLD.valor) OR NOT(NEW.data_competencia<=>OLD.data_competencia) OR NOT(NEW.vencimento_original<=>OLD.vencimento_original) OR NOT(NEW.origem_estimativa<=>OLD.origem_estimativa) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Obrigacao financeira so permite alterar vencimento_atual e situacao'; END IF;
 IF OLD.situacao IN ('QUITADA','CANCELADA') AND NEW.situacao<>OLD.situacao THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Situacao terminal da obrigacao financeira e imutavel'; END IF;
 IF NEW.situacao<>OLD.situacao AND NOT((OLD.situacao='PREVISTA' AND NEW.situacao IN('ABERTA','CANCELADA')) OR (OLD.situacao='ABERTA' AND NEW.situacao IN('QUITADA','ATRASADA','CANCELADA')) OR (OLD.situacao='ATRASADA' AND NEW.situacao IN('QUITADA','CANCELADA'))) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Transicao de situacao da obrigacao financeira invalida'; END IF;
END$$
CREATE TRIGGER obrigacao_imutavel_bd BEFORE DELETE ON obrigacao_financeira FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Obrigacao financeira nao pode ser removida'; END$$
CREATE TRIGGER venda_proposta_bi BEFORE INSERT ON venda FOR EACH ROW
BEGIN
 IF NEW.id_proposta IS NOT NULL AND NOT EXISTS(SELECT 1 FROM proposta p JOIN atendimento a ON a.id_atendimento=p.id_atendimento JOIN entrada e ON e.id_entrada=NEW.id_entrada_principal WHERE p.id_proposta=NEW.id_proposta AND p.situacao='ACEITA' AND p.id_entrada=NEW.id_entrada_principal AND a.id_pessoa=NEW.id_comprador AND e.id_veiculo=(SELECT id_veiculo FROM entrada WHERE id_entrada=p.id_entrada)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Venda exige proposta aceita para o mesmo cliente e veiculo'; END IF;
END$$
CREATE TRIGGER venda_proposta_bu BEFORE UPDATE ON venda FOR EACH ROW
BEGIN
 IF NEW.id_proposta IS NOT NULL AND NOT EXISTS(SELECT 1 FROM proposta p JOIN atendimento a ON a.id_atendimento=p.id_atendimento WHERE p.id_proposta=NEW.id_proposta AND p.situacao='ACEITA' AND p.id_entrada=NEW.id_entrada_principal AND a.id_pessoa=NEW.id_comprador) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Venda exige proposta aceita para o mesmo cliente e veiculo'; END IF;
END$$
DELIMITER ;

CREATE VIEW vw_cliente_cpf AS SELECT p.numero_documento AS cpf, p.id_pessoa, p.nome, CAST('ATENDIMENTO' AS CHAR) AS tipo_registro, a.id_atendimento AS id_registro, a.data AS data_evento, a.descricao_interesse AS descricao, CAST(NULL AS DECIMAL(14, 2)) AS valor, a.situacao FROM pessoa AS p JOIN atendimento AS a ON a.id_pessoa = p.id_pessoa WHERE p.tipo_documento = 'CPF' UNION ALL SELECT p.numero_documento, p.id_pessoa, p.nome, 'PROPOSTA', pr.id_proposta, pr.data_criacao, CONCAT('Proposta para entrada ', pr.id_entrada), pr.valor_total, pr.situacao FROM pessoa AS p JOIN atendimento AS a ON a.id_pessoa = p.id_pessoa JOIN proposta AS pr ON pr.id_atendimento = a.id_atendimento WHERE p.tipo_documento = 'CPF' UNION ALL SELECT p.numero_documento, p.id_pessoa, p.nome, 'VENDA', v.id_venda, CAST(v.data_registro AS DATE), CONCAT('Venda para entrada ', v.id_entrada_principal), v.valor_total, v.situacao_comercial FROM pessoa AS p JOIN venda AS v ON v.id_comprador = p.id_pessoa WHERE p.tipo_documento = 'CPF';
CREATE VIEW vw_simulacao_parcela AS SELECT s.id_simulacao, s.id_proposta, s.instituicao, s.tabela_retorno, s.origem, s.valor_financiado, s.taxa_mensal AS taxa_base_mensal, r.acrescimo_taxa_mensal, (s.taxa_mensal + r.acrescimo_taxa_mensal) AS taxa_cliente_mensal, s.prazo_meses, p.parcela_calculada, ROUND(CAST((p.parcela_calculada * s.prazo_meses) AS DECIMAL(30,10)), 2) AS custo_total_cliente, ROUND(CAST((POWER(1 + s.taxa_mensal + r.acrescimo_taxa_mensal, 12) - 1) AS DECIMAL(30,10)), 6) AS cet_aproximado_anual, ROUND(CAST((s.valor_financiado * r.retorno_pct) AS DECIMAL(30,10)), 2) AS retorno_loja, s.parcela_informada, s.renda_declarada, CASE WHEN s.renda_declarada IS NULL THEN NULL ELSE ROUND(CAST((p.parcela_calculada / s.renda_declarada * 100) AS DECIMAL(30,10)), 2) END AS parcela_sobre_renda_pct, s.consentimento_renda, s.situacao FROM simulacao_financiamento AS s JOIN LATERAL (SELECT pr.acrescimo_taxa_mensal, pr.retorno_pct FROM parametro_retorno AS pr WHERE pr.instituicao = s.instituicao AND pr.tabela_retorno = s.tabela_retorno AND pr.vigencia <= CAST(s.data_simulacao AS DATE) ORDER BY CASE WHEN pr.vigencia IS NULL THEN 1 ELSE 0 END DESC, pr.vigencia DESC LIMIT 1) AS r ON TRUE CROSS JOIN LATERAL (SELECT ROUND(CAST((s.valor_financiado * (s.taxa_mensal + r.acrescimo_taxa_mensal) / (1 - POWER(1 + s.taxa_mensal + r.acrescimo_taxa_mensal, -s.prazo_meses))) AS DECIMAL(30,10)), 2) AS parcela_calculada) AS p;
CREATE VIEW vw_proposta_comparativo AS SELECT p.id_proposta, p.id_atendimento, at.id_pessoa, pessoa.numero_documento AS cpf, p.id_entrada, p.rotulo, p.versao, p.data_criacao, p.validade, p.situacao, p.valor_total, CAST(COALESCE(c.caixa_d0, 0) AS DECIMAL(14, 2)) AS caixa_d0, CAST((COALESCE(c.caixa_posterior, 0) + COALESCE(s.retorno_loja, 0)) AS DECIMAL(14, 2)) AS caixa_posterior, CAST(COALESCE(t.valor_trocas, 0) AS DECIMAL(14, 2)) AS valor_em_troca, CAST((p.valor_total - CASE WHEN e.modalidade = 'CONSIGNACAO' THEN e.valor_repasse_acordado ELSE e.valor_acordado END - COALESCE(d.despesas_preparacao, 0) - COALESCE(d.despesas_garantia, 0)) AS DECIMAL(14, 2)) AS margem_estimada, CAST(COALESCE(s.retorno_loja, 0) AS DECIMAL(14, 2)) AS retorno_banco, CAST((p.valor_total - CASE WHEN e.modalidade = 'CONSIGNACAO' THEN e.valor_repasse_acordado ELSE e.valor_acordado END - COALESCE(d.despesas_preparacao, 0) - COALESCE(d.despesas_garantia, 0) + COALESCE(s.retorno_loja, 0)) AS DECIMAL(14, 2)) AS margem_com_retorno, CAST(COALESCE(s.parcela_calculada, 0) AS DECIMAL(14, 2)) AS parcela_simulada, s.parcela_sobre_renda_pct, GREATEST(COALESCE(c.prazo_maximo, 0), COALESCE(pr.dias_previstos, 0)) AS dias_ate_recebimento, CASE WHEN GREATEST(COALESCE(c.prazo_maximo, 0), COALESCE(pr.dias_previstos, 0)) = 0 THEN 'D+0' ELSE CONCAT('D+', CAST(GREATEST(COALESCE(c.prazo_maximo, 0), COALESCE(pr.dias_previstos, 0)) AS CHAR)) END AS prazo_caixa FROM proposta AS p JOIN atendimento AS at ON at.id_atendimento = p.id_atendimento JOIN pessoa ON pessoa.id_pessoa = at.id_pessoa JOIN entrada AS e ON e.id_entrada = p.id_entrada LEFT JOIN LATERAL (SELECT SUM(CASE WHEN prazo_previsto_dias = 0 AND codigo_forma IN ('PIX', 'DINHEIRO') THEN valor ELSE NULL END) AS caixa_d0, SUM(CASE WHEN prazo_previsto_dias > 0 THEN valor ELSE NULL END) AS caixa_posterior, MAX(prazo_previsto_dias) AS prazo_maximo FROM proposta_condicao WHERE id_proposta = p.id_proposta) AS c ON TRUE LEFT JOIN LATERAL (SELECT SUM(valor_oferecido) AS valor_trocas FROM proposta_troca WHERE id_proposta = p.id_proposta) AS t ON TRUE /* A margem segue a consulta #8 de gerenciais.sql: preparacao do ciclo da entrada */ /* e garantia/diagnostico da venda vinculada, sem multiplicar registros. */ LEFT JOIN LATERAL (SELECT (SELECT SUM(d.valor) FROM despesa AS d WHERE d.id_veiculo = e.id_veiculo AND LOWER(d.categoria) NOT LIKE LOWER('%garantia%') AND LOWER(d.categoria) NOT LIKE LOWER('%diagnostico%') AND d.data >= CAST(e.data_entrada AS DATE) AND d.data <= COALESCE(CAST(e.data_encerramento AS DATE), p.data_criacao)) AS despesas_preparacao, (SELECT SUM(d.valor) FROM venda AS v JOIN vw_venda_resumo AS vr ON vr.id_venda = v.id_venda JOIN despesa AS d ON d.id_veiculo = e.id_veiculo WHERE v.id_entrada_principal = e.id_entrada AND v.data_entrega IS NOT NULL AND v.situacao_comercial = 'CONCLUIDA' AND (LOWER(d.categoria) LIKE LOWER('%garantia%') OR LOWER(d.categoria) LIKE LOWER('%diagnostico%')) AND d.data >= CAST(v.data_entrega AS DATE) AND d.data <= CAST(vr.data_fim_garantia AS DATE)) AS despesas_garantia) AS d ON TRUE LEFT JOIN LATERAL (SELECT sp.instituicao, sp.parcela_calculada, sp.parcela_sobre_renda_pct, sp.retorno_loja, sp.tabela_retorno FROM vw_simulacao_parcela AS sp WHERE sp.id_proposta = p.id_proposta ORDER BY CASE WHEN sp.id_simulacao IS NULL THEN 1 ELSE 0 END DESC, sp.id_simulacao DESC LIMIT 1) AS s ON TRUE LEFT JOIN LATERAL (SELECT pp.dias_previstos FROM parametro_prazo AS pp WHERE pp.tipo_obrigacao = 'FINANCIAMENTO_RECEBER' AND EXISTS(SELECT 1 FROM proposta_condicao AS pc WHERE pc.id_proposta = p.id_proposta AND pc.codigo_forma = 'FINANCIAMENTO') AND pp.vigencia <= p.data_criacao AND (s.instituicao IS NULL OR pp.banco = s.instituicao) ORDER BY CASE WHEN pp.vigencia IS NULL THEN 1 ELSE 0 END DESC, pp.vigencia DESC, CASE WHEN pp.banco IS NULL THEN 1 ELSE 0 END, pp.banco LIMIT 1) AS pr ON TRUE;



