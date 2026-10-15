"""Testes de restrições do recorte DDL; executa com Python 3 + SQLite 3.37+."""
import pathlib
import sqlite3
import unittest

DDL = pathlib.Path(__file__).with_name("ddl.sql").read_text(encoding="utf-8")


class DDLTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(":memory:")
        self.db.executescript(DDL)
        self.db.execute("INSERT INTO pessoa VALUES (1,'Comprador','CPF','111','11999990000','a@b.com')")
        self.db.execute("INSERT INTO pessoa VALUES (2,'Vendedor','CPF','222','11999990001','c@d.com')")
        self.db.execute("INSERT INTO funcionario VALUES (1,2,'vendedor','2025-01-01','ativo')")
        self.db.execute("INSERT INTO veiculo VALUES (1,'Fiat','Argo',2022,'Prata','ABC1D23','CHASSI1','flex','manual')")
        self.db.execute("INSERT INTO avaliacao VALUES (1,1,2,'2026-10-01','compra_propria',30000,'aprovada','sim')")
        self.db.execute("INSERT INTO entrada VALUES (1,1,1,1,'compra_propria','2026-10-02','ativa',50000)")
        self.db.execute("INSERT INTO veiculo VALUES (2,'Ford','Ka',2020,'Branco','DEF4G56','CHASSI2','flex','manual')")
        self.db.execute("INSERT INTO avaliacao VALUES (2,2,2,'2026-10-01','troca',45000,'aprovada','sim')")
        self.db.execute("INSERT INTO entrada VALUES (2,2,1,2,'troca','2026-10-02','ativa',25000)")
        self.db.execute("INSERT INTO avaliacao VALUES (3,1,2,'2026-10-02','compra_propria',30000,'reprovada','sim')")
        self.db.commit()

    def tearDown(self):
        self.db.close()

    def test_pk_unique_documento(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO pessoa VALUES (3,'Duplicado','CPF','111','1','x@y.com')")

    def test_fk_funcionario_pessoa_inexistente(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO funcionario VALUES (2,999,'vendedor','2026-01-01','ativo')")

    def test_not_null_ou_check(self):
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.execute("INSERT INTO funcionario VALUES (2,1,'','2026-01-01','ativo')")

    def test_regra_erp_entrada_sem_avaliacao_aprovada(self):
        with self.assertRaisesRegex(sqlite3.IntegrityError, 'entrada exige avaliacao aprovada'):
            self.db.execute("INSERT INTO entrada VALUES (3,1,1,3,'compra_propria','2026-10-03','ativa',100)")

    def test_regra_erp_venda_exige_entrada_principal_qualificada(self):
        with self.assertRaisesRegex(sqlite3.IntegrityError, 'venda exige entrada principal ativa'):
            self.db.execute("INSERT INTO venda (id_venda,id_entrada_principal,id_comprador,id_funcionario,data_registro,situacao_comercial,valor_base,situacao_financeira) VALUES (1,2,1,1,'2026-10-03','em_formalizacao',50000,'pendente')")

    def test_regra_erp_troca_nao_pode_ser_veiculo_principal(self):
        self.db.execute("INSERT INTO venda (id_venda,id_entrada_principal,id_comprador,id_funcionario,data_registro,situacao_comercial,valor_base,situacao_financeira) VALUES (1,1,1,1,'2026-10-03','em_formalizacao',50000,'pendente')")
        with self.assertRaisesRegex(sqlite3.IntegrityError, 'entrada de troca deve pertencer'):
            self.db.execute("INSERT INTO venda_entrada_troca VALUES (1,1)")

    def test_n_n_resolvido_e_entrada_marcada_comercializada(self):
        self.db.execute("INSERT INTO venda (id_venda,id_entrada_principal,id_comprador,id_funcionario,data_registro,situacao_comercial,valor_base,situacao_financeira) VALUES (1,1,1,1,'2026-10-03','em_formalizacao',80000,'pendente')")
        self.db.execute("INSERT INTO venda_entrada_troca VALUES (1,2)")
        state = self.db.execute("SELECT situacao FROM entrada WHERE id_entrada=2").fetchone()[0]
        self.assertEqual(state, "comercializada")


if __name__ == "__main__":
    unittest.main(verbosity=2)
