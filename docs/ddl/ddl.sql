-- Multiplikar Automóveis — recorte para a atividade de DDL
-- Dialeto: SQLite 3.37+ (STRICT tables)
PRAGMA foreign_keys = ON;

CREATE TABLE pessoa (
    id_pessoa       INTEGER PRIMARY KEY,
    nome            TEXT NOT NULL CHECK (length(trim(nome)) > 0),
    tipo_documento  TEXT NOT NULL CHECK (tipo_documento IN ('CPF', 'CNPJ')),
    numero_documento TEXT NOT NULL UNIQUE CHECK (length(trim(numero_documento)) > 0),
    telefone        TEXT NOT NULL CHECK (length(trim(telefone)) > 0),
    email           TEXT NOT NULL CHECK (length(trim(email)) > 0)
) STRICT;

CREATE TABLE funcionario (
    id_funcionario INTEGER PRIMARY KEY,
    id_pessoa      INTEGER NOT NULL UNIQUE,
    cargo          TEXT NOT NULL CHECK (length(trim(cargo)) > 0),
    data_admissao  TEXT NOT NULL,
    situacao       TEXT NOT NULL CHECK (situacao IN ('ativo', 'inativo')),
    FOREIGN KEY (id_pessoa) REFERENCES pessoa(id_pessoa)
) STRICT;

CREATE TABLE veiculo (
    id_veiculo INTEGER PRIMARY KEY,
    marca      TEXT NOT NULL CHECK (length(trim(marca)) > 0),
    modelo     TEXT NOT NULL CHECK (length(trim(modelo)) > 0),
    ano_modelo INTEGER NOT NULL CHECK (ano_modelo BETWEEN 1900 AND 2100),
    cor        TEXT NOT NULL CHECK (length(trim(cor)) > 0),
    placa      TEXT UNIQUE,
    chassi     TEXT UNIQUE,
    combustivel TEXT NOT NULL CHECK (length(trim(combustivel)) > 0),
    cambio     TEXT NOT NULL CHECK (cambio IN ('manual', 'automatico', 'automatizado', 'CVT', 'outro'))
) STRICT;

CREATE TABLE avaliacao (
    id_avaliacao INTEGER PRIMARY KEY,
    id_veiculo   INTEGER NOT NULL,
    id_avaliador INTEGER NOT NULL,
    data         TEXT NOT NULL,
    finalidade   TEXT NOT NULL CHECK (finalidade IN ('compra_propria', 'consignacao', 'troca')),
    quilometragem INTEGER NOT NULL CHECK (quilometragem >= 0),
    decisao_tecnica TEXT NOT NULL CHECK (decisao_tecnica IN ('aprovada', 'reprovada', 'pendente')),
    interesse_comercial TEXT NOT NULL CHECK (interesse_comercial IN ('sim', 'nao', 'em_analise')),
    FOREIGN KEY (id_veiculo) REFERENCES veiculo(id_veiculo),
    FOREIGN KEY (id_avaliador) REFERENCES pessoa(id_pessoa)
) STRICT;

CREATE TABLE entrada (
    id_entrada INTEGER PRIMARY KEY,
    id_veiculo INTEGER NOT NULL,
    id_contraparte INTEGER NOT NULL,
    id_avaliacao INTEGER NOT NULL UNIQUE,
    modalidade TEXT NOT NULL CHECK (modalidade IN ('compra_propria', 'consignacao', 'troca')),
    data_entrada TEXT NOT NULL,
    situacao TEXT NOT NULL CHECK (situacao IN ('ativa', 'comercializada', 'em_regularizacao', 'retirada', 'devolvida')),
    valor_acordado REAL NOT NULL CHECK (valor_acordado >= 0),
    FOREIGN KEY (id_veiculo) REFERENCES veiculo(id_veiculo),
    FOREIGN KEY (id_contraparte) REFERENCES pessoa(id_pessoa),
    FOREIGN KEY (id_avaliacao) REFERENCES avaliacao(id_avaliacao)
) STRICT;

CREATE TABLE venda (
    id_venda INTEGER PRIMARY KEY,
    id_entrada_principal INTEGER NOT NULL UNIQUE,
    id_comprador INTEGER NOT NULL,
    id_funcionario INTEGER NOT NULL,
    data_registro TEXT NOT NULL,
    situacao_comercial TEXT NOT NULL CHECK (situacao_comercial IN ('em_formalizacao', 'concluida', 'em_desfazimento', 'cancelada')),
    valor_base REAL NOT NULL CHECK (valor_base >= 0),
    desconto REAL NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    acrescimo REAL NOT NULL DEFAULT 0 CHECK (acrescimo >= 0),
    taxas REAL NOT NULL DEFAULT 0 CHECK (taxas >= 0),
    valor_total REAL GENERATED ALWAYS AS (valor_base - desconto + acrescimo + taxas) STORED,
    valor_recebido REAL NOT NULL DEFAULT 0 CHECK (valor_recebido >= 0),
    data_ultimo_recebimento TEXT,
    situacao_financeira TEXT NOT NULL CHECK (situacao_financeira IN ('pendente', 'parcial', 'integral')),
    FOREIGN KEY (id_entrada_principal) REFERENCES entrada(id_entrada),
    FOREIGN KEY (id_comprador) REFERENCES pessoa(id_pessoa),
    FOREIGN KEY (id_funcionario) REFERENCES funcionario(id_funcionario),
    CHECK (desconto <= valor_base),
    CHECK ((valor_recebido = 0 AND data_ultimo_recebimento IS NULL) OR
           (valor_recebido > 0 AND data_ultimo_recebimento IS NOT NULL))
) STRICT;

-- Resolve a relação N:N entre VENDA e ENTRADA recebida em troca.
CREATE TABLE venda_entrada_troca (
    id_venda   INTEGER NOT NULL,
    id_entrada INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (id_venda, id_entrada),
    FOREIGN KEY (id_venda) REFERENCES venda(id_venda),
    FOREIGN KEY (id_entrada) REFERENCES entrada(id_entrada)
) STRICT;

-- Triggers garantem regras entre tabelas que CHECK não consegue expressar.
CREATE TRIGGER entrada_avaliacao_coerente
BEFORE INSERT ON entrada
WHEN NOT EXISTS (
    SELECT 1 FROM avaliacao a
    WHERE a.id_avaliacao = NEW.id_avaliacao
      AND a.id_veiculo = NEW.id_veiculo
      AND a.decisao_tecnica = 'aprovada'
      AND a.interesse_comercial = 'sim'
      AND a.finalidade = NEW.modalidade
)
BEGIN
    SELECT RAISE(ABORT, 'entrada exige avaliacao aprovada e coerente para o mesmo veiculo e modalidade');
END;

CREATE TRIGGER venda_entrada_principal_valida
BEFORE INSERT ON venda
WHEN NOT EXISTS (
    SELECT 1 FROM entrada e
    WHERE e.id_entrada = NEW.id_entrada_principal
      AND e.modalidade IN ('compra_propria', 'consignacao')
      AND e.situacao = 'ativa'
)
BEGIN
    SELECT RAISE(ABORT, 'venda exige entrada principal ativa de compra propria ou consignacao');
END;

CREATE TRIGGER troca_entrada_valida
BEFORE INSERT ON venda_entrada_troca
WHEN NOT EXISTS (
    SELECT 1 FROM entrada e
    JOIN venda v ON v.id_venda = NEW.id_venda
    WHERE e.id_entrada = NEW.id_entrada
      AND e.modalidade = 'troca'
      AND e.situacao = 'ativa'
      AND e.id_veiculo <> (SELECT id_veiculo FROM entrada WHERE id_entrada = v.id_entrada_principal)
      AND e.id_contraparte = v.id_comprador
)
BEGIN
    SELECT RAISE(ABORT, 'entrada de troca deve pertencer ao comprador e ser veiculo diferente do principal');
END;

CREATE TRIGGER venda_consume_entrada_principal
AFTER INSERT ON venda
BEGIN
    UPDATE entrada SET situacao = 'comercializada' WHERE id_entrada = NEW.id_entrada_principal;
END;

CREATE TRIGGER venda_consume_entrada_troca
AFTER INSERT ON venda_entrada_troca
BEGIN
    UPDATE entrada SET situacao = 'comercializada' WHERE id_entrada = NEW.id_entrada;
END;
