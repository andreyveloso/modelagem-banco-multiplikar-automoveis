-- MySQL 8.4. Segunda migração de 01/11/2026: formato do e-mail de PESSOA.
-- Aplicar depois de 2026-11-01-revisao-dominios.sql, num banco multiplikar já existente.
-- Confere os e-mails atuais antes de criar a regra e não altera nada se algum estiver fora do formato.
-- Se a conferência interromper, o procedimento auxiliar migracao_conferir_email fica no banco; remova com
-- DROP PROCEDURE multiplikar.migracao_conferir_email; (a próxima execução também o remove no início).
USE multiplikar;

DROP PROCEDURE IF EXISTS migracao_conferir_email;
DELIMITER $$
CREATE PROCEDURE migracao_conferir_email()
BEGIN
 DECLARE v_qtd INT;
 IF NOT EXISTS(SELECT 1 FROM information_schema.check_constraints
   WHERE constraint_schema='multiplikar' AND constraint_name='ck_pessoa_endereco') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Aplique antes 2026-11-01-revisao-dominios.sql';
 END IF;
 IF EXISTS(SELECT 1 FROM information_schema.check_constraints
   WHERE constraint_schema='multiplikar' AND constraint_name='ck_pessoa_email') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Migracao ja aplicada neste banco; nada a fazer';
 END IF;
 SELECT COUNT(*) INTO v_qtd FROM pessoa
  WHERE NOT regexp_like(email, '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$');
 IF v_qtd > 0 THEN
  SET @msg = CONCAT('Migracao interrompida: ', v_qtd, ' pessoa(s) com e-mail fora do formato; corrija antes');
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=@msg;
 END IF;
 SELECT 'OK: e-mails atuais atendem ao formato' AS conferencia;
END$$
DELIMITER ;
CALL migracao_conferir_email();
DROP PROCEDURE migracao_conferir_email;

ALTER TABLE pessoa
    ADD constraint ck_pessoa_email check (regexp_like(email, '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'));
SELECT 'OK: validacao de e-mail aplicada' AS resultado;
