-- Testes de restricoes no MySQL 8.4. As violacoes sao executadas via SQL dinamico.
USE multiplikar;
DROP PROCEDURE IF EXISTS teste_rejeicao;
DELIMITER $$
CREATE PROCEDURE teste_rejeicao(IN p_rotulo VARCHAR(120),IN p_sql TEXT,IN p_trecho VARCHAR(120))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE;
 DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
   GET DIAGNOSTICS CONDITION 1 @msg = MESSAGE_TEXT;
   SET v_msg=@msg;
   SET v_falhou=TRUE;
  END;
  SET @teste_sql=p_sql; PREPARE stmt FROM @teste_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Falha: operacao invalida foi aceita: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_trecho,'%') THEN SET v_err=CONCAT('Mensagem inesperada para ',p_rotulo,': ',COALESCE(v_msg,'<vazia>')); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS rejeicao ',p_rotulo,': ',p_trecho) AS resultado;
END$$
DROP PROCEDURE IF EXISTS teste_aceita$$
CREATE PROCEDURE teste_aceita(IN p_rotulo VARCHAR(120),IN p_sql TEXT)
BEGIN
 SET @teste_sql=p_sql; PREPARE stmt FROM @teste_sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
 SELECT CONCAT('PASS aceita ',p_rotulo) AS resultado;
END$$
DELIMITER ;
START TRANSACTION;
CALL teste_rejeicao('PK forma','INSERT INTO forma_pagamento VALUES (''PIX'',''Pix repetido'')','forma_pagamento');
CALL teste_rejeicao('UNIQUE documento','INSERT INTO pessoa(nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES(''Outra Pessoa'',''CPF'',''00000000001'',''11999990000'',''outra@example.invalid'',''Rua A'',''1'',''Centro'',''Sao Paulo'',''SP'')','uq_pessoa_documento');
CALL teste_rejeicao('FK pessoa','INSERT INTO atendimento(id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES(9999,1,''COMPRA'',''Teste'',''ABERTO'')','fk_atendimento_id_pessoa');
CALL teste_rejeicao('FK funcionario','INSERT INTO atendimento(id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES(1,999,''COMPRA'',''Teste'',''ABERTO'')','fk_atendimento_id_funcionario');
CALL teste_rejeicao('CHECK CPF','INSERT INTO pessoa(nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES(''CPF Curto'',''CPF'',''123'',''11999990000'',''curto@example.invalid'',''Rua A'',''1'',''Centro'',''Sao Paulo'',''SP'')','ck_pessoa_documento');
CALL teste_rejeicao('CHECK atendimento','INSERT INTO atendimento(id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES(1,1,''COMPRA'',''Teste'',''PENDENTE'')','ck_atendimento_situacao');
CALL teste_rejeicao('NOT NULL pessoa.nome','INSERT INTO pessoa(nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES(NULL,''CPF'',''99999999999'',''11999990000'',''nulo@example.invalid'',''Rua A'',''1'',''Centro'',''Sao Paulo'',''SP'')','nome');
CALL teste_rejeicao('UNIQUE pessoa-funcionario','INSERT INTO funcionario(id_pessoa,cargo,data_admissao,situacao) SELECT id_pessoa,''Vendedor'',''2026-01-01'',''ATIVO'' FROM funcionario WHERE id_funcionario=1','Duplicate entry');
CALL teste_rejeicao('PK associativa','INSERT INTO venda_forma_pagamento VALUES(6,''PIX'')','Duplicate entry');
CALL teste_rejeicao('FK associativa','INSERT INTO venda_forma_pagamento VALUES(999,''PIX'')','fk_venda_forma_pagamento_id_venda');
CALL teste_rejeicao('DELETE pessoa referenciada','DELETE FROM pessoa WHERE id_pessoa=1','fk_');
-- Revisao de dominios: encerramento de ocorrencia, booleanos, UF, textos vazios e etapa do cadastro.
-- Encerramento de ocorrencia (ocorrencia 1 esta ENCERRADA; ocorrencia 2 esta EM_ANALISE).
CALL teste_rejeicao('ocorrencia ENCERRADA sem data','UPDATE ocorrencia_garantia SET data_encerramento=NULL WHERE id_ocorrencia=1','ck_ocorrencia_encerramento');
CALL teste_rejeicao('ocorrencia encerrada antes da abertura','UPDATE ocorrencia_garantia SET data_encerramento=''2026-01-31 09:00'' WHERE id_ocorrencia=1','ck_ocorrencia_encerramento');
CALL teste_rejeicao('ocorrencia ENCERRADA sem solucao','UPDATE ocorrencia_garantia SET solucao=NULL WHERE id_ocorrencia=1','ck_ocorrencia_encerramento');
CALL teste_rejeicao('ocorrencia ENCERRADA com solucao so de espacos','UPDATE ocorrencia_garantia SET solucao=''   '' WHERE id_ocorrencia=1','ck_ocorrencia_encerramento');
CALL teste_rejeicao('ocorrencia em andamento com data de encerramento','UPDATE ocorrencia_garantia SET data_encerramento=''2026-02-04 10:00'' WHERE id_ocorrencia=2','ck_ocorrencia_encerramento');
CALL teste_rejeicao('ocorrencia encerrada sem data ao mudar situacao','UPDATE ocorrencia_garantia SET situacao=''ENCERRADA'',solucao=''Ajuste feito'' WHERE id_ocorrencia=2','ck_ocorrencia_encerramento');
CALL teste_aceita('ocorrencia encerrada no mesmo instante da abertura','UPDATE ocorrencia_garantia SET situacao=''ENCERRADA'',solucao=''Ajuste feito'',data_encerramento=data_abertura WHERE id_ocorrencia=2');
-- Booleanos limitados a 0 e 1; possui_cnh aceita NULL (nao informado).
CALL teste_rejeicao('possui_cnh = 2','UPDATE pessoa SET possui_cnh=2 WHERE id_pessoa=1','ck_pessoa_cnh');
CALL teste_rejeicao('possui_cnh = -1','UPDATE pessoa SET possui_cnh=-1 WHERE id_pessoa=1','ck_pessoa_cnh');
CALL teste_rejeicao('condicao_repasse = 2','UPDATE venda SET condicao_repasse=2 WHERE id_venda=6','ck_venda_booleanos');
CALL teste_rejeicao('concessao_garantia = 5','UPDATE venda SET concessao_garantia=5 WHERE id_venda=6','ck_venda_booleanos');
CALL teste_rejeicao('reconhecimento_aplicavel = 3','UPDATE venda_documento SET reconhecimento_aplicavel=3 WHERE id_venda=6 AND tipo_documento=''ATPV''','ck_documento_aplicavel');
CALL teste_aceita('possui_cnh NULL (nao informado)','UPDATE pessoa SET possui_cnh=NULL WHERE id_pessoa=1');
-- UF: lista das 27 unidades federativas, em maiusculas.
CALL teste_rejeicao('UF inexistente XX','UPDATE pessoa SET estado_uf=''XX'' WHERE id_pessoa=1','ck_pessoa_uf');
CALL teste_rejeicao('UF em minusculas','UPDATE pessoa SET estado_uf=''sp'' WHERE id_pessoa=1','ck_pessoa_uf');
CALL teste_rejeicao('UF com espaco','UPDATE pessoa SET estado_uf='' S'' WHERE id_pessoa=1','ck_pessoa_uf');
CALL teste_aceita('UF valida DF','UPDATE pessoa SET estado_uf=''DF'' WHERE id_pessoa=1');
-- Textos obrigatorios: NOT NULL barra a ausencia; CHECK com TRIM barra texto vazio ou so de espacos.
CALL teste_rejeicao('telefone so de espacos','UPDATE pessoa SET telefone=''   '' WHERE id_pessoa=1','ck_pessoa_textos');
CALL teste_rejeicao('e-mail vazio','UPDATE pessoa SET email='''' WHERE id_pessoa=1','ck_pessoa_email');
CALL teste_rejeicao('e-mail sem arroba','UPDATE pessoa SET email=''cliente.example.com'' WHERE id_pessoa=1','ck_pessoa_email');
CALL teste_rejeicao('e-mail sem dominio','UPDATE pessoa SET email=''cliente@exemplo'' WHERE id_pessoa=1','ck_pessoa_email');
CALL teste_rejeicao('e-mail com espaco','UPDATE pessoa SET email=''cli ente@example.com'' WHERE id_pessoa=1','ck_pessoa_email');
CALL teste_aceita('e-mail valido','UPDATE pessoa SET email=''cliente.novo@example.com.br'' WHERE id_pessoa=1');
CALL teste_rejeicao('cidade so de espacos','UPDATE pessoa SET cidade=''  '' WHERE id_pessoa=1','ck_pessoa_textos');
CALL teste_rejeicao('cargo vazio','UPDATE funcionario SET cargo='' '' WHERE id_funcionario=1','ck_funcionario_cargo');
CALL teste_rejeicao('marca vazia','UPDATE veiculo SET marca='''' WHERE id_veiculo=1','ck_veiculo_textos');
CALL teste_rejeicao('descricao de interesse vazia','UPDATE atendimento SET descricao_interesse=''  '' WHERE id_atendimento=1','ck_atendimento_descricao');
CALL teste_rejeicao('descricao de despesa vazia','UPDATE despesa SET descricao='' '' WHERE id_despesa=1','ck_despesa_descricao');
CALL teste_rejeicao('problema relatado vazio','UPDATE ocorrencia_garantia SET problema_relatado='' '' WHERE id_ocorrencia=1','ck_ocorrencia_problema');
CALL teste_rejeicao('NOT NULL telefone','INSERT INTO pessoa(nome,tipo_documento,numero_documento,telefone) VALUES(''Sem Telefone'',''CPF'',''98765432199'',NULL)','telefone');
-- Etapa do cadastro: primeiro contato sem e-mail e endereco; endereco parcial nao.
CALL teste_aceita('pessoa no primeiro contato sem e-mail e endereco','INSERT INTO pessoa(id_pessoa,nome,tipo_documento,numero_documento,telefone) VALUES(9901,''Contato Inicial'',''CPF'',''98765432100'',''11988887777'')');
CALL teste_rejeicao('endereco parcial','INSERT INTO pessoa(nome,tipo_documento,numero_documento,telefone,logradouro,numero) VALUES(''Endereco Parcial'',''CPF'',''98765432101'',''11988887777'',''Rua A'',''1'')','ck_pessoa_endereco');
CALL teste_aceita('endereco completo sem complemento','INSERT INTO pessoa(nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES(''Endereco Completo'',''CPF'',''98765432102'',''11988887777'',''ok@example.invalid'',''Rua A'',''1'',''Centro'',''Sao Paulo'',''SP'')');
CALL teste_rejeicao('apagar e-mail de pessoa com contrato','UPDATE pessoa SET email=NULL WHERE id_pessoa=6','RO02');
CALL teste_aceita('veiculo para entrada com contrato','INSERT INTO veiculo(id_veiculo,marca,modelo,ano_modelo,cor,combustivel,cambio,categoria_comercial) VALUES(9901,''Fiat'',''Uno'',2015,''Branco'',''Flex'',''Manual'',''USADO'')');
CALL teste_aceita('placa e chassi ainda nulos em segundo veiculo (UNIQUE admite varios NULL)','INSERT INTO veiculo(marca,modelo,ano_modelo,cor,combustivel,cambio,categoria_comercial) VALUES(''Fiat'',''Mobi'',2018,''Prata'',''Flex'',''Manual'',''USADO'')');
CALL teste_aceita('avaliacao aprovada do veiculo 9901','INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES(9901,9901,1,''2026-03-01 10:00'',''COMPRA_PROPRIA'',90000,''Boa'',''Boa'',''Boa'',''Boa'',''Regular'',''APROVADA'',''SIM'',''Sem restricoes'')');
CALL teste_rejeicao('contrato de entrada com contraparte sem e-mail e endereco','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9901,9901,9901,''COMPRA_PROPRIA'',''2026-03-02 10:00'',20000,25000,''CT-9901'',''2026-03-02'',''Compra a vista'')','RO02');
CALL teste_aceita('cadastro completado antes do contrato','UPDATE pessoa SET email=''contato@example.invalid'',logradouro=''Rua B'',numero=''10'',bairro=''Centro'',cidade=''Sao Paulo'',estado_uf=''SP'' WHERE id_pessoa=9901');
CALL teste_aceita('contrato de entrada apos completar o cadastro','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9901,9901,9901,''COMPRA_PROPRIA'',''2026-03-02 10:00'',20000,25000,''CT-9901'',''2026-03-02'',''Compra a vista'')');
-- Cardinalidade RN13: no maximo uma entrada vigente (nao encerrada) por veiculo.
CALL teste_aceita('nova avaliacao aprovada do veiculo 9901','INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES(9902,9901,1,''2026-03-03 10:00'',''COMPRA_PROPRIA'',90010,''Boa'',''Boa'',''Boa'',''Boa'',''Regular'',''APROVADA'',''SIM'',''Reavaliacao'')');
CALL teste_rejeicao('segundo ciclo vigente do mesmo veiculo','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9901,9901,9902,''COMPRA_PROPRIA'',''2026-03-04 10:00'',20000,25000,''CT-9902'',''2026-03-04'',''Compra a vista'')','uq_entrada_veiculo_vigente');
-- Laudo: data de emissao e resultado so sao exigidos quando EMITIDO.
CALL teste_aceita('laudo PENDENTE sem data e resultado','INSERT INTO laudo(id_laudo,id_veiculo,referencia_documental,situacao) VALUES(9901,9901,''LAU-9901'',''PENDENTE'')');
CALL teste_rejeicao('laudo PENDENTE nao vincula avaliacao','INSERT INTO avaliacao_laudo VALUES(9901,9901)','RN08');
CALL teste_rejeicao('laudo EMITIDO sem data','UPDATE laudo SET situacao=''EMITIDO'',resultado=''Aprovado'' WHERE id_laudo=9901','ck_laudo_emissao');
CALL teste_rejeicao('laudo EMITIDO com resultado so de espacos','UPDATE laudo SET situacao=''EMITIDO'',data_emissao=''2026-02-28'',resultado=''  '' WHERE id_laudo=9901','ck_laudo_emissao');
CALL teste_rejeicao('laudo PENDENTE com data de emissao','UPDATE laudo SET data_emissao=''2026-02-28'' WHERE id_laudo=9901','ck_laudo_emissao');
CALL teste_rejeicao('referencia documental vazia','UPDATE laudo SET referencia_documental='' '' WHERE id_laudo=9901','ck_laudo_referencia');
CALL teste_aceita('laudo emitido com data e resultado','UPDATE laudo SET situacao=''EMITIDO'',data_emissao=''2026-02-28'',resultado=''Aprovado'' WHERE id_laudo=9901');
SELECT 'PASS restricoes: 11 violacoes originais e 49 casos da revisao de dominios; DML isolado em transacao' AS resultado;
ROLLBACK;
-- O ROLLBACK nao devolve os contadores AUTO_INCREMENT; com valor 1 o MySQL volta ao maior id + 1.
ALTER TABLE pessoa AUTO_INCREMENT=1; ALTER TABLE veiculo AUTO_INCREMENT=1; ALTER TABLE avaliacao AUTO_INCREMENT=1;
ALTER TABLE entrada AUTO_INCREMENT=1; ALTER TABLE laudo AUTO_INCREMENT=1;
DROP PROCEDURE teste_rejeicao;
DROP PROCEDURE teste_aceita;
