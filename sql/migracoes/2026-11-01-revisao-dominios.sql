-- MySQL 8.4. Migração da revisão de domínios (01/11/2026) para um banco multiplikar já existente.
-- Use este arquivo quando o banco tem dados que não podem ser recriados (servidor do site).
-- Para uma instalação nova, basta executar a cadeia normal (executar-tudo-workbench.sql).
-- Primeiro confere se os dados atuais atendem às regras novas; se algum não atender,
-- para com a lista de pendências antes de alterar qualquer tabela. Nesse caso o procedimento auxiliar
-- migracao_conferir fica no banco; remova com DROP PROCEDURE multiplikar.migracao_conferir;
-- (a próxima execução também o remove no início).
USE multiplikar;

DROP PROCEDURE IF EXISTS migracao_conferir;
DELIMITER $$
CREATE PROCEDURE migracao_conferir()
BEGIN
 DECLARE v_msg TEXT DEFAULT '';
 DECLARE v_ja_aplicada BOOLEAN;
 SET v_ja_aplicada = EXISTS(SELECT 1 FROM information_schema.check_constraints
  WHERE constraint_schema='multiplikar' AND constraint_name='ck_pessoa_endereco');
 IF v_ja_aplicada THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Migracao ja aplicada neste banco; nada a fazer'; END IF;
 IF EXISTS(SELECT 1 FROM pessoa WHERE estado_uf COLLATE utf8mb4_bin NOT IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO'))
  THEN SET v_msg=CONCAT(v_msg,' pessoa com UF invalida;'); END IF;
 IF EXISTS(SELECT 1 FROM pessoa WHERE TRIM(telefone)='' OR TRIM(email)='' OR TRIM(logradouro)='' OR TRIM(numero)='' OR TRIM(bairro)='' OR TRIM(cidade)='')
  THEN SET v_msg=CONCAT(v_msg,' pessoa com texto vazio;'); END IF;
 IF EXISTS(SELECT 1 FROM pessoa WHERE possui_cnh NOT IN (0,1)) THEN SET v_msg=CONCAT(v_msg,' possui_cnh fora de 0/1;'); END IF;
 IF EXISTS(SELECT 1 FROM funcionario WHERE TRIM(cargo)='') THEN SET v_msg=CONCAT(v_msg,' cargo vazio;'); END IF;
 IF EXISTS(SELECT 1 FROM veiculo WHERE TRIM(marca)='' OR TRIM(modelo)='' OR TRIM(cor)='' OR TRIM(combustivel)='' OR TRIM(cambio)='')
  THEN SET v_msg=CONCAT(v_msg,' veiculo com texto vazio;'); END IF;
 IF EXISTS(SELECT 1 FROM atendimento WHERE TRIM(descricao_interesse)='') THEN SET v_msg=CONCAT(v_msg,' atendimento sem descricao;'); END IF;
 IF EXISTS(SELECT 1 FROM laudo WHERE TRIM(referencia_documental)=''
   OR (situacao='PENDENTE' AND (data_emissao IS NOT NULL OR resultado IS NOT NULL))
   OR (situacao='EMITIDO' AND TRIM(resultado)='') OR (situacao='CANCELADO' AND TRIM(resultado)=''))
  THEN SET v_msg=CONCAT(v_msg,' laudo incompativel com ck_laudo_emissao;'); END IF;
 IF EXISTS(SELECT 1 FROM avaliacao WHERE decisao_tecnica<>'PENDENTE' AND TRIM(justificativa)='')
  THEN SET v_msg=CONCAT(v_msg,' avaliacao concluida sem justificativa;'); END IF;
 IF EXISTS(SELECT 1 FROM venda WHERE condicao_repasse NOT IN (0,1) OR concessao_garantia NOT IN (0,1))
  THEN SET v_msg=CONCAT(v_msg,' venda com booleano fora de 0/1;'); END IF;
 IF EXISTS(SELECT 1 FROM forma_pagamento WHERE TRIM(codigo)='' OR TRIM(descricao)='') THEN SET v_msg=CONCAT(v_msg,' forma de pagamento vazia;'); END IF;
 IF EXISTS(SELECT 1 FROM venda_documento WHERE reconhecimento_aplicavel NOT IN (0,1)) THEN SET v_msg=CONCAT(v_msg,' documento com booleano fora de 0/1;'); END IF;
 IF EXISTS(SELECT 1 FROM ocorrencia_garantia WHERE TRIM(problema_relatado)=''
   OR (situacao='ENCERRADA' AND (data_encerramento IS NULL OR data_encerramento<data_abertura OR solucao IS NULL OR TRIM(solucao)=''))
   OR (situacao IN ('ABERTA','EM_ANALISE','EM_ATENDIMENTO') AND data_encerramento IS NOT NULL))
  THEN SET v_msg=CONCAT(v_msg,' ocorrencia incompativel com ck_ocorrencia_encerramento;'); END IF;
 IF EXISTS(SELECT 1 FROM despesa WHERE TRIM(descricao)='') THEN SET v_msg=CONCAT(v_msg,' despesa sem descricao;'); END IF;
 IF EXISTS(SELECT 1 FROM parametro_retorno WHERE TRIM(instituicao)='') THEN SET v_msg=CONCAT(v_msg,' parametro_retorno sem instituicao;'); END IF;
 IF EXISTS(SELECT 1 FROM simulacao_financiamento WHERE TRIM(instituicao)='' OR consentimento_renda NOT IN (0,1))
  THEN SET v_msg=CONCAT(v_msg,' simulacao incompativel;'); END IF;
 IF EXISTS(SELECT 1 FROM obrigacao_financeira WHERE TRIM(categoria)='' OR TRIM(contraparte)='') THEN SET v_msg=CONCAT(v_msg,' obrigacao com texto vazio;'); END IF;
 IF EXISTS(SELECT 1 FROM parametro_prazo WHERE TRIM(banco)='') THEN SET v_msg=CONCAT(v_msg,' parametro_prazo sem banco;'); END IF;
 IF v_msg<>'' THEN SET v_msg=CONCAT('Migracao interrompida, corrija antes:',v_msg); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_msg; END IF;
 SELECT 'OK: dados atuais atendem as regras novas' AS conferencia;
END$$
DELIMITER ;
CALL migracao_conferir();
DROP PROCEDURE migracao_conferir;

-- PESSOA: e-mail e endereço opcionais até o contrato; UF por lista; textos e booleano.
ALTER TABLE pessoa
    MODIFY email varchar(254),
    MODIFY logradouro varchar(150),
    MODIFY numero varchar(10),
    MODIFY bairro varchar(80),
    MODIFY cidade varchar(80),
    MODIFY estado_uf char(2),
    DROP CHECK ck_pessoa_uf;
ALTER TABLE pessoa
    ADD constraint ck_pessoa_textos check (trim(telefone) <> '' and trim(email) <> '' and trim(logradouro) <> ''
        and trim(numero) <> '' and trim(bairro) <> '' and trim(cidade) <> ''),
    ADD constraint ck_pessoa_endereco check ((logradouro is null and numero is null and complemento is null and bairro is null and cidade is null and estado_uf is null)
        or (logradouro is not null and numero is not null and bairro is not null and cidade is not null and estado_uf is not null)),
    ADD constraint ck_pessoa_uf check (estado_uf collate utf8mb4_bin in ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
        'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO')),
    ADD constraint ck_pessoa_cnh check (possui_cnh in (0, 1));

ALTER TABLE funcionario ADD constraint ck_funcionario_cargo check (trim(cargo) <> '');
ALTER TABLE veiculo ADD constraint ck_veiculo_textos check (trim(marca) <> '' and trim(modelo) <> '' and trim(cor) <> ''
        and trim(combustivel) <> '' and trim(cambio) <> '');
ALTER TABLE atendimento ADD constraint ck_atendimento_descricao check (trim(descricao_interesse) <> '');

-- LAUDO: data e resultado só a partir da emissão.
ALTER TABLE laudo
    MODIFY data_emissao date,
    MODIFY resultado text,
    ADD constraint ck_laudo_referencia check (trim(referencia_documental) <> ''),
    ADD constraint ck_laudo_emissao check ((situacao <> 'PENDENTE' or (data_emissao is null and resultado is null))
        and (situacao <> 'EMITIDO' or (data_emissao is not null and resultado is not null and trim(resultado) <> ''))
        and (situacao <> 'CANCELADO' or resultado is null or trim(resultado) <> ''));

ALTER TABLE avaliacao DROP CHECK ck_avaliacao_concluida;
ALTER TABLE avaliacao ADD constraint ck_avaliacao_concluida check (decisao_tecnica = 'PENDENTE'
        or (condicao_externa is not null and condicao_interna is not null and condicao_mecanica is not null and condicao_estrutural is not null and condicao_documental is not null and justificativa is not null and trim(justificativa) <> ''));

ALTER TABLE venda ADD constraint ck_venda_booleanos check (condicao_repasse in (0, 1) and concessao_garantia in (0, 1));
ALTER TABLE forma_pagamento ADD constraint ck_forma_pagamento_textos check (trim(codigo) <> '' and trim(descricao) <> '');
ALTER TABLE venda_documento ADD constraint ck_documento_aplicavel check (reconhecimento_aplicavel in (0, 1));

-- OCORRÊNCIA: ENCERRADA exige data coerente e solução; em andamento, data nula.
ALTER TABLE ocorrencia_garantia DROP CHECK ck_ocorrencia_encerramento;
ALTER TABLE ocorrencia_garantia
    ADD constraint ck_ocorrencia_encerramento check ((situacao <> 'ENCERRADA' or (data_encerramento is not null and data_encerramento >= data_abertura
            and solucao is not null and trim(solucao) <> ''))
        and (situacao not in ('ABERTA', 'EM_ANALISE', 'EM_ATENDIMENTO') or data_encerramento is null)),
    ADD constraint ck_ocorrencia_problema check (trim(problema_relatado) <> '');

ALTER TABLE despesa ADD constraint ck_despesa_descricao check (trim(descricao) <> '');

-- Extensão de propostas e caixa.
ALTER TABLE parametro_retorno ADD constraint ck_parametro_retorno_instituicao check (trim(instituicao) <> '');
ALTER TABLE simulacao_financiamento
    ADD constraint ck_simulacao_instituicao check (trim(instituicao) <> ''),
    ADD constraint ck_simulacao_consentimento_dominio check (consentimento_renda in (0, 1));
ALTER TABLE obrigacao_financeira ADD constraint ck_obrigacao_textos check (trim(categoria) <> '' and trim(contraparte) <> '');
ALTER TABLE parametro_prazo ADD constraint ck_parametro_prazo_banco check (trim(banco) <> '');

-- RO02: e-mail e endereço exigidos quando a pessoa assina contrato.
DROP FUNCTION IF EXISTS pessoa_dados_contrato;
DELIMITER $$
CREATE FUNCTION pessoa_dados_contrato(p_id BIGINT) RETURNS BOOLEAN READS SQL DATA
BEGIN
 -- id nulo ou inexistente fica para o NOT NULL e a FK, que dão a mensagem certa.
 RETURN NOT EXISTS(SELECT 1 FROM pessoa WHERE id_pessoa=p_id AND (email IS NULL OR logradouro IS NULL));
END$$
CREATE TRIGGER entrada_contrato_bi BEFORE INSERT ON entrada FOR EACH ROW
BEGIN IF NEW.numero_contrato IS NOT NULL AND NOT pessoa_dados_contrato(NEW.id_contraparte) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: contrato exige e-mail e endereco completo da contraparte'; END IF; END$$
CREATE TRIGGER entrada_contrato_bu BEFORE UPDATE ON entrada FOR EACH ROW
BEGIN IF NEW.numero_contrato IS NOT NULL AND OLD.numero_contrato IS NULL AND NOT pessoa_dados_contrato(NEW.id_contraparte) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: contrato exige e-mail e endereco completo da contraparte'; END IF; END$$
-- PRECEDES mantém a mesma ordem de disparo da instalação nova (núcleo antes da extensão).
CREATE TRIGGER venda_contrato_bi BEFORE INSERT ON venda FOR EACH ROW PRECEDES venda_proposta_bi
BEGIN IF NEW.numero_contrato IS NOT NULL AND NOT pessoa_dados_contrato(NEW.id_comprador) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: contrato exige e-mail e endereco completo do comprador'; END IF; END$$
CREATE TRIGGER venda_contrato_bu BEFORE UPDATE ON venda FOR EACH ROW PRECEDES venda_proposta_bu
BEGIN IF NEW.numero_contrato IS NOT NULL AND OLD.numero_contrato IS NULL AND NOT pessoa_dados_contrato(NEW.id_comprador) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: contrato exige e-mail e endereco completo do comprador'; END IF; END$$
CREATE TRIGGER pessoa_contrato_bu BEFORE UPDATE ON pessoa FOR EACH ROW
BEGIN
 IF (NEW.email IS NULL OR NEW.logradouro IS NULL)
  AND (EXISTS(SELECT 1 FROM entrada WHERE id_contraparte=OLD.id_pessoa AND numero_contrato IS NOT NULL)
   OR EXISTS(SELECT 1 FROM venda WHERE id_comprador=OLD.id_pessoa AND numero_contrato IS NOT NULL)) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: pessoa com contrato deve manter e-mail e endereco completo'; END IF;
END$$
DELIMITER ;
SELECT 'OK: migracao da revisao de dominios aplicada' AS resultado;
