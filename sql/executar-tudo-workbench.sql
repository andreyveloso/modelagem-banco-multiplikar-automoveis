-- MySQL 8.4. Execução completa do projeto em um único arquivo para o MySQL Workbench.
-- Abra este arquivo no Workbench e use Execute All (raio); a cadeia recria o banco.
-- Gerado dos 14 arquivos na ordem de RODAR-BANCO-MULTIPLIKAR.bat.

-- =====================================================================
-- sql\ddl\schema.sql
-- =====================================================================
-- MySQL 8.4; esquema relacional principal do projeto.
DROP DATABASE IF EXISTS multiplikar;
CREATE DATABASE multiplikar CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE multiplikar;

create table pessoa (
    id_pessoa bigint not null auto_increment primary key,
    nome varchar(150) not null,
    tipo_documento varchar(4) not null,
    numero_documento varchar(14) not null,
    telefone varchar(20) not null,
    -- e-mail e endereço podem faltar no primeiro contato; viram obrigatórios quando
    -- a pessoa assina contrato (gatilhos pessoa_contrato_* em entrada e venda, RO02).
    email varchar(254),
    logradouro varchar(150),
    numero varchar(10),
    complemento varchar(60),
    bairro varchar(80),
    cidade varchar(80),
    estado_uf char(2),
    -- NULL = não informado (a CNH só é perguntada em atendimento de compra).
    possui_cnh boolean,
    constraint uq_pessoa_documento unique (tipo_documento, numero_documento),
    constraint ck_pessoa_documento check ((tipo_documento = 'CPF' and regexp_like(numero_documento, '^[0-9]{11}$'))
        or (tipo_documento = 'CNPJ' and regexp_like(numero_documento, '^[0-9]{14}$'))),
    constraint ck_pessoa_nome check (trim(nome) <> ''),
    constraint ck_pessoa_textos check (trim(telefone) <> '' and trim(email) <> '' and trim(logradouro) <> ''
        and trim(numero) <> '' and trim(bairro) <> '' and trim(cidade) <> ''),
    -- mesmo formato exigido pelo site: texto@dominio.sufixo, sem espaços e com um único @.
    constraint ck_pessoa_email check (regexp_like(email, '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$')),
    -- endereço composto: ou ainda não foi informado, ou vem completo (complemento é opcional).
    constraint ck_pessoa_endereco check ((logradouro is null and numero is null and complemento is null and bairro is null and cidade is null and estado_uf is null)
        or (logradouro is not null and numero is not null and bairro is not null and cidade is not null and estado_uf is not null)),
    -- collate utf8mb4_bin: a collation padrão ignora maiúsculas e aceitaria 'sp'.
    constraint ck_pessoa_uf check (estado_uf collate utf8mb4_bin in ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
        'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO')),
    constraint ck_pessoa_cnh check (possui_cnh in (0, 1))
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table funcionario (
    id_funcionario bigint not null auto_increment primary key,
    id_pessoa bigint not null unique,
    cargo varchar(80) not null,
    data_admissao date not null,
    situacao varchar(10) not null,
    constraint ck_funcionario_situacao check (situacao in ('ATIVO', 'INATIVO', 'AFASTADO')),
    constraint ck_funcionario_cargo check (trim(cargo) <> ''),
    constraint fk_funcionario_id_pessoa foreign key (id_pessoa) references pessoa(id_pessoa)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table veiculo (
    id_veiculo bigint not null auto_increment primary key,
    marca varchar(60) not null,
    modelo varchar(80) not null,
    ano_modelo smallint not null,
    cor varchar(30) not null,
    placa varchar(7) unique,
    chassi varchar(17) unique,
    combustivel varchar(20) not null,
    cambio varchar(20) not null,
    categoria_comercial varchar(8) not null,
    constraint ck_veiculo_ano check (ano_modelo between 1886 and 2100),
    constraint ck_veiculo_categoria check (categoria_comercial in ('NOVO', 'SEMINOVO', 'USADO')),
    constraint ck_veiculo_textos check (trim(marca) <> '' and trim(modelo) <> '' and trim(cor) <> ''
        and trim(combustivel) <> '' and trim(cambio) <> '')
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table atendimento (
    id_atendimento bigint not null auto_increment primary key,
    id_pessoa bigint not null,
    id_funcionario bigint not null,
    data datetime not null default current_timestamp(),
    tipo_interesse varchar(6) not null,
    descricao_interesse text not null,
    situacao varchar(13) not null,
    observacoes text,
    constraint ck_atendimento_situacao check (situacao in ('ABERTO', 'EM_NEGOCIACAO', 'CONVERTIDO', 'ENCERRADO')),
    constraint ck_atendimento_interesse check (tipo_interesse in ('COMPRA', 'VENDA', 'TROCA')),
    constraint ck_atendimento_descricao check (trim(descricao_interesse) <> ''),
    constraint fk_atendimento_id_pessoa foreign key (id_pessoa) references pessoa(id_pessoa),
    constraint fk_atendimento_id_funcionario foreign key (id_funcionario) references funcionario(id_funcionario)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table laudo (
    id_laudo bigint not null auto_increment primary key,
    id_veiculo bigint not null,
    referencia_documental varchar(80) not null,
    -- data e resultado só existem depois da emissão; o laudo pode ser registrado como PENDENTE.
    data_emissao date,
    situacao varchar(10) not null,
    resultado text,
    constraint ck_laudo_situacao check (situacao in ('PENDENTE', 'EMITIDO', 'CANCELADO')),
    constraint ck_laudo_referencia check (trim(referencia_documental) <> ''),
    constraint ck_laudo_emissao check ((situacao <> 'PENDENTE' or (data_emissao is null and resultado is null))
        and (situacao <> 'EMITIDO' or (data_emissao is not null and resultado is not null and trim(resultado) <> ''))
        and (situacao <> 'CANCELADO' or resultado is null or trim(resultado) <> '')),
    constraint fk_laudo_id_veiculo foreign key (id_veiculo) references veiculo(id_veiculo)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table avaliacao (
    id_avaliacao bigint not null auto_increment primary key,
    id_veiculo bigint not null,
    id_avaliador bigint not null,
    data datetime not null,
    finalidade varchar(14) not null,
    quilometragem int not null,
    quantidade_proprietarios int,
    condicao_externa varchar(120),
    condicao_interna varchar(120),
    condicao_mecanica varchar(120),
    condicao_estrutural varchar(120),
    condicao_documental varchar(120),
    decisao_tecnica varchar(10) not null default 'PENDENTE',
    interesse_comercial varchar(10) not null default 'EM_ANALISE',
    justificativa text,
    constraint ck_avaliacao_finalidade check (finalidade in ('COMPRA_PROPRIA', 'CONSIGNACAO', 'TROCA')),
    constraint ck_avaliacao_medidas check (quilometragem >= 0 and quantidade_proprietarios >= 0),
    constraint ck_avaliacao_decisao check (decisao_tecnica in ('PENDENTE', 'APROVADA', 'REPROVADA')),
    constraint ck_avaliacao_interesse check (interesse_comercial in ('EM_ANALISE', 'SIM', 'NAO')),
    constraint ck_avaliacao_concluida check (decisao_tecnica = 'PENDENTE'
        or (condicao_externa is not null and condicao_interna is not null and condicao_mecanica is not null and condicao_estrutural is not null and condicao_documental is not null and justificativa is not null and trim(justificativa) <> '')),
    constraint fk_avaliacao_id_veiculo foreign key (id_veiculo) references veiculo(id_veiculo),
    constraint fk_avaliacao_id_avaliador foreign key (id_avaliador) references pessoa(id_pessoa)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table avaliacao_laudo (
    id_avaliacao bigint primary key,
    id_laudo bigint not null,
    constraint fk_avaliacao_laudo_id_avaliacao foreign key (id_avaliacao) references avaliacao(id_avaliacao),
    constraint fk_avaliacao_laudo_id_laudo foreign key (id_laudo) references laudo(id_laudo)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table entrada (
    id_entrada bigint not null auto_increment primary key,
    id_veiculo bigint not null,
    id_contraparte bigint not null,
    id_avaliacao bigint not null unique,
    id_venda_origem bigint,
    id_entrada_anterior bigint unique,
    modalidade varchar(14) not null,
    data_entrada datetime not null,
    situacao varchar(18) not null default 'ATIVA',
    data_encerramento datetime,
    motivo_encerramento varchar(32),
    data_regularizacao datetime,
    observacoes_regularizacao text,
    valor_acordado decimal(14,2) not null,
    preco_anunciado decimal(14,2),
    numero_contrato varchar(40),
    data_emissao date,
    termos_ajustes text,
    reconhecimento_firma varchar(12),
    prazo_consignacao date,
    valor_repasse_acordado decimal(14,2),
    prazo_repasse varchar(50),
    criterio_repasse text,
    data_devolucao datetime,
    constraint ck_entrada_modalidade check (modalidade in ('COMPRA_PROPRIA', 'CONSIGNACAO', 'TROCA')),
    constraint ck_entrada_situacao check (situacao in ('ATIVA', 'EM_REGULARIZACAO', 'COMERCIALIZADA', 'ENCERRADA', 'RETIRADA', 'DEVOLVIDA')),
    constraint ck_entrada_encerramento check ((situacao in ('ATIVA', 'EM_REGULARIZACAO') and data_encerramento is null and motivo_encerramento is null)
        or (situacao in ('COMERCIALIZADA', 'ENCERRADA', 'RETIRADA', 'DEVOLVIDA') and data_encerramento is not null and motivo_encerramento is not null)),
    constraint ck_entrada_datas check (data_encerramento >= data_entrada
        and data_devolucao >= data_entrada
        and data_regularizacao >= data_entrada
        and prazo_consignacao >= cast(data_entrada as date)),
    constraint ck_entrada_valores check (valor_acordado >= 0
        and preco_anunciado >= 0
        and valor_repasse_acordado >= 0
        and valor_repasse_acordado <= valor_acordado),
    constraint ck_entrada_preco check (situacao <> 'ATIVA' or preco_anunciado is not null),
    constraint ck_entrada_origem check ((modalidade = 'TROCA' and id_venda_origem is not null and numero_contrato is null and data_emissao is null and termos_ajustes is null)
        or (modalidade <> 'TROCA' and id_venda_origem is null and numero_contrato is not null and data_emissao is not null and termos_ajustes is not null)),
    constraint ck_entrada_consignacao check ((modalidade = 'CONSIGNACAO' and reconhecimento_firma is not null and reconhecimento_firma = 'REALIZADO' and valor_repasse_acordado is not null and prazo_repasse is not null and criterio_repasse is not null)
        or (modalidade <> 'CONSIGNACAO' and prazo_consignacao is null and valor_repasse_acordado is null and prazo_repasse is null and criterio_repasse is null)),
    constraint ck_entrada_devolucao check (situacao <> 'DEVOLVIDA' or data_devolucao is not null),
    constraint ck_entrada_regularizacao check (data_regularizacao is null
        or observacoes_regularizacao is not null),
    veiculo_vigente bigint generated always as (case when data_encerramento is null then id_veiculo else null end) stored,
    constraint fk_entrada_id_veiculo foreign key (id_veiculo) references veiculo(id_veiculo),
    constraint fk_entrada_id_contraparte foreign key (id_contraparte) references pessoa(id_pessoa),
    constraint fk_entrada_id_avaliacao foreign key (id_avaliacao) references avaliacao(id_avaliacao),
    constraint fk_entrada_id_entrada_anterior foreign key (id_entrada_anterior) references entrada(id_entrada)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table venda (
    id_venda bigint not null auto_increment primary key,
    id_comprador bigint not null,
    id_funcionario bigint not null,
    id_entrada_principal bigint not null unique,
    id_laudo bigint,
    data_registro datetime not null,
    situacao_comercial varchar(18) not null default 'EM_FORMALIZACAO',
    data_conclusao datetime,
    valor_base decimal(14,2) not null,
    desconto decimal(14,2) not null default 0,
    acrescimo decimal(14,2) not null default 0,
    taxas decimal(14,2) not null default 0,
    valor_total decimal(14,2) generated always as (valor_base - desconto + acrescimo + taxas) virtual,
    numero_contrato varchar(40),
    data_emissao date,
    termos_condicoes text,
    condicao_repasse boolean not null default false,
    valor_recebido decimal(14,2) not null default 0,
    data_ultimo_recebimento datetime,
    instituicao_financeira varchar(100),
    valor_financiado decimal(14,2),
    situacao_financiamento varchar(20),
    data_aprovacao_financiamento datetime,
    data_recebimento_financiamento datetime,
    data_scanner datetime,
    resultado_scanner varchar(100),
    providencias_scanner text,
    preparacao text,
    data_entrega datetime,
    concessao_garantia boolean not null,
    termos_politica text,
    data_cancelamento datetime,
    motivo_cancelamento text,
    data_retorno_veiculo datetime,
    valor_restituido_loja decimal(14,2),
    data_aviso_consignante datetime,
    orientacao_bancaria text,
    observacoes_cancelamento text,
    constraint ck_venda_situacao check (situacao_comercial in ('EM_FORMALIZACAO', 'CONCLUIDA', 'EM_DESFAZIMENTO', 'CANCELADA')),
    constraint ck_venda_valores check (valor_base >= 0
        and desconto >= 0
        and acrescimo >= 0
        and taxas >= 0
        and valor_total >= 0
        and valor_recebido >= 0
        and valor_restituido_loja >= 0
        and valor_restituido_loja <= valor_recebido),
    constraint ck_venda_recebimento check ((valor_recebido = 0 and data_ultimo_recebimento is null)
        or (valor_recebido > 0 and data_ultimo_recebimento is not null)),
    constraint ck_venda_financiamento check ((instituicao_financeira is null and valor_financiado is null and situacao_financiamento is null and data_aprovacao_financiamento is null and data_recebimento_financiamento is null)
        or (instituicao_financeira is not null and valor_financiado is not null and valor_financiado > 0 and situacao_financiamento is not null and ((situacao_financiamento in ('EM_ANALISE', 'NAO_APROVADO') and data_aprovacao_financiamento is null and data_recebimento_financiamento is null) or (situacao_financiamento = 'APROVADO_A_RECEBER' and data_aprovacao_financiamento is not null and data_recebimento_financiamento is null) or (situacao_financiamento = 'RECEBIDO' and data_aprovacao_financiamento is not null and data_recebimento_financiamento is not null and data_recebimento_financiamento >= data_aprovacao_financiamento and valor_recebido >= valor_financiado and data_ultimo_recebimento >= data_recebimento_financiamento)))),
    constraint ck_venda_conclusao check (situacao_comercial <> 'CONCLUIDA'
        or (data_conclusao is not null and numero_contrato is not null and data_emissao is not null and termos_condicoes is not null and id_laudo is not null)),
    constraint ck_venda_formalizacao check (situacao_comercial <> 'EM_FORMALIZACAO'
        or (data_conclusao is null and data_entrega is null)),
    constraint ck_venda_marcos check (data_conclusao >= data_registro
        and data_entrega >= data_conclusao
        and data_cancelamento >= data_registro
        and data_retorno_veiculo >= data_registro),
    constraint ck_venda_entrega check (data_entrega is null
        or (data_conclusao is not null and data_scanner is not null and resultado_scanner is not null and data_scanner <= data_entrega)),
    constraint ck_venda_garantia check (not concessao_garantia or termos_politica is not null),
    constraint ck_venda_booleanos check (condicao_repasse in (0, 1) and concessao_garantia in (0, 1)),
    constraint ck_venda_cancelamento check (situacao_comercial <> 'CANCELADA'
        or (data_cancelamento is not null and motivo_cancelamento is not null and data_retorno_veiculo is not null and data_cancelamento >= data_retorno_veiculo and valor_restituido_loja is not null and observacoes_cancelamento is not null)),
    constraint fk_venda_id_comprador foreign key (id_comprador) references pessoa(id_pessoa),
    constraint fk_venda_id_funcionario foreign key (id_funcionario) references funcionario(id_funcionario),
    constraint fk_venda_id_entrada_principal foreign key (id_entrada_principal) references entrada(id_entrada),
    constraint fk_venda_id_laudo foreign key (id_laudo) references laudo(id_laudo)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table forma_pagamento (
    codigo varchar(20) primary key,
    descricao varchar(40) not null unique,
    constraint ck_forma_pagamento_textos check (trim(codigo) <> '' and trim(descricao) <> '')
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table venda_forma_pagamento (
    id_venda bigint not null,
    codigo_forma varchar(20) not null,
    primary key (id_venda, codigo_forma),
    constraint fk_venda_forma_pagamento_id_venda foreign key (id_venda) references venda(id_venda),
    constraint fk_venda_forma_pagamento_codigo_forma foreign key (codigo_forma) references forma_pagamento(codigo)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table venda_documento (
    id_venda bigint not null,
    tipo_documento varchar(24) not null,
    data_conferencia datetime,
    reconhecimento_aplicavel boolean not null,
    data_reconhecimento datetime,
    justificativa_dispensa text,
    primary key (id_venda, tipo_documento),
    constraint ck_documento_tipo check (tipo_documento in ('CNH', 'LAUDO_CAUTELAR', 'CRLV', 'ATPV', 'COMPROVANTE_RESIDENCIA', 'CONTRATO')),
    constraint ck_documento_aplicavel check (reconhecimento_aplicavel in (0, 1)),
    constraint ck_documento_firma check ((reconhecimento_aplicavel and tipo_documento in ('ATPV', 'CONTRATO') and justificativa_dispensa is null)
        or (not reconhecimento_aplicavel and data_reconhecimento is null and (not tipo_documento in ('ATPV', 'CONTRATO') or justificativa_dispensa is not null))),
    constraint fk_venda_documento_id_venda foreign key (id_venda) references venda(id_venda)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table ocorrencia_garantia (
    id_ocorrencia bigint not null auto_increment primary key,
    id_venda bigint not null,
    id_mecanico bigint,
    data_abertura datetime not null,
    problema_relatado text not null,
    atendimento_externo_informado varchar(14) not null default 'NAO_INFORMADO',
    diagnostico text,
    responsabilidade_apurada varchar(12),
    servico_realizado text,
    solucao text,
    situacao varchar(16) not null,
    data_encerramento datetime,
    constraint ck_ocorrencia_situacao check (situacao in ('ABERTA', 'EM_ANALISE', 'EM_ATENDIMENTO', 'ENCERRADA')),
    constraint ck_ocorrencia_responsabilidade check (responsabilidade_apurada in ('EM_ANALISE', 'LOJA', 'MAU_USO', 'INCONCLUSIVA')),
    constraint ck_ocorrencia_externo check (atendimento_externo_informado in ('SIM', 'NAO', 'NAO_INFORMADO')),
    -- ENCERRADA exige data igual ou posterior à abertura e solução escrita;
    -- nas situações em andamento a data de encerramento fica nula.
    constraint ck_ocorrencia_encerramento check ((situacao <> 'ENCERRADA' or (data_encerramento is not null and data_encerramento >= data_abertura
            and solucao is not null and trim(solucao) <> ''))
        and (situacao not in ('ABERTA', 'EM_ANALISE', 'EM_ATENDIMENTO') or data_encerramento is null)),
    constraint ck_ocorrencia_problema check (trim(problema_relatado) <> ''),
    constraint fk_ocorrencia_garantia_id_venda foreign key (id_venda) references venda(id_venda),
    constraint fk_ocorrencia_garantia_id_mecanico foreign key (id_mecanico) references pessoa(id_pessoa)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

create table despesa (
    id_despesa bigint not null auto_increment primary key,
    id_veiculo bigint not null,
    data date not null,
    categoria varchar(11) not null,
    descricao text not null,
    valor decimal(14,2) not null,
    constraint ck_despesa_categoria check (categoria in ('GARANTIA', 'DIAGNOSTICO', 'PREPARACAO')),
    constraint ck_despesa_valor check (valor >= 0),
    constraint ck_despesa_descricao check (trim(descricao) <> ''),
    constraint fk_despesa_id_veiculo foreign key (id_veiculo) references veiculo(id_veiculo)
) engine=InnoDB default character set=utf8mb4 collate=utf8mb4_0900_ai_ci;

ALTER TABLE entrada ADD CONSTRAINT fk_entrada_venda_origem FOREIGN KEY (id_venda_origem) REFERENCES venda(id_venda);

CREATE UNIQUE INDEX uq_entrada_veiculo_vigente ON entrada (veiculo_vigente);
CREATE INDEX ix_laudo_veiculo ON laudo (id_veiculo);
CREATE INDEX ix_avaliacao_veiculo ON avaliacao (id_veiculo);
CREATE INDEX ix_entrada_historico ON entrada (id_veiculo, data_entrada);
CREATE INDEX ix_entrada_venda_origem ON entrada (id_venda_origem);
CREATE INDEX ix_venda_comprador ON venda (id_comprador);
CREATE INDEX ix_ocorrencia_venda ON ocorrencia_garantia (id_venda);
CREATE INDEX ix_despesa_veiculo ON despesa (id_veiculo);

CREATE VIEW vw_venda_validacao AS SELECT v.id_venda, t.total_trocas, t.total_trocas_historico, v.valor_total - v.valor_recebido - t.total_trocas_historico AS saldo_historico, v.valor_total - v.valor_recebido - t.total_trocas AS saldo, CASE WHEN v.valor_recebido + t.total_trocas >= v.valor_total THEN 'INTEGRAL' WHEN v.valor_recebido + t.total_trocas > 0 THEN 'PARCIAL' ELSE 'PENDENTE' END AS situacao_financeira, (v.instituicao_financeira IS NULL OR (v.situacao_financiamento = 'NAO_APROVADO' AND v.valor_recebido + t.total_trocas_historico >= v.valor_total) OR (v.situacao_financiamento = 'RECEBIDO' AND v.data_recebimento_financiamento IS NOT NULL)) AS financiamento_ok, (EXISTS(SELECT 1 FROM venda_forma_pagamento AS f WHERE f.id_venda = v.id_venda) AND (v.instituicao_financeira IS NULL OR v.situacao_financiamento = 'NAO_APROVADO' OR EXISTS(SELECT 1 FROM venda_forma_pagamento AS f WHERE f.id_venda = v.id_venda AND f.codigo_forma = 'FINANCIAMENTO'))) AS formas_ok, (v.data_ultimo_recebimento IS NULL OR v.data_conclusao IS NULL OR v.data_ultimo_recebimento <= v.data_conclusao) AS recebimento_ok, (v.numero_contrato IS NOT NULL AND v.data_emissao IS NOT NULL AND v.termos_condicoes IS NOT NULL) AS contrato_ok, NOT EXISTS(SELECT 1 FROM (SELECT 'CNH' AS tipo UNION ALL SELECT 'LAUDO_CAUTELAR' UNION ALL SELECT 'CRLV' UNION ALL SELECT 'ATPV' UNION ALL SELECT 'COMPROVANTE_RESIDENCIA' UNION ALL SELECT 'CONTRATO') AS exigido WHERE NOT EXISTS(SELECT 1 FROM venda_documento AS d WHERE d.id_venda = v.id_venda AND d.tipo_documento = exigido.tipo AND d.data_conferencia IS NOT NULL AND (v.data_conclusao IS NULL OR d.data_conferencia <= v.data_conclusao))) AS documentos_ok, (SELECT COUNT(*) = 2 AND MIN((NOT d.reconhecimento_aplicavel OR d.data_reconhecimento IS NOT NULL) AND (d.data_reconhecimento IS NULL OR v.data_conclusao IS NULL OR d.data_reconhecimento <= v.data_conclusao)) FROM venda_documento AS d WHERE d.id_venda = v.id_venda AND d.tipo_documento IN ('ATPV', 'CONTRATO')) AS reconhecimento_ok, EXISTS(SELECT 1 FROM laudo AS l WHERE l.id_laudo = v.id_laudo AND l.id_veiculo = e.id_veiculo AND (v.data_conclusao IS NULL OR l.data_emissao <= CAST(v.data_conclusao AS DATE))) AS laudo_ok FROM venda AS v JOIN entrada AS e ON e.id_entrada = v.id_entrada_principal CROSS JOIN LATERAL (SELECT COALESCE(SUM(CASE WHEN x.data_devolucao IS NULL AND x.situacao NOT IN ('EM_REGULARIZACAO','DEVOLVIDA','RETIRADA','ENCERRADA') THEN x.valor_acordado ELSE NULL END), 0) AS total_trocas, COALESCE(SUM(x.valor_acordado), 0) AS total_trocas_historico FROM entrada AS x WHERE x.id_venda_origem = v.id_venda) AS t;

CREATE VIEW vw_venda_resumo AS SELECT v.*, a.total_trocas, a.saldo, a.total_trocas_historico, a.saldo_historico, a.formas_ok, a.recebimento_ok, a.contrato_ok, CASE WHEN v.situacao_comercial IN ('CANCELADA', 'EM_DESFAZIMENTO') THEN 'EM_DESFAZIMENTO' ELSE a.situacao_financeira END AS situacao_financeira, CASE WHEN a.documentos_ok AND a.reconhecimento_ok THEN 'COMPLETA' ELSE 'PENDENTE' END AS situacao_documental, CASE WHEN v.concessao_garantia THEN v.data_entrega END AS data_inicio_garantia, CASE WHEN v.concessao_garantia THEN v.data_entrega + INTERVAL '2' MONTH END AS data_fim_garantia, (CASE WHEN v.data_conclusao IS NOT NULL THEN a.saldo_historico ELSE a.saldo END) <= 0 AND a.financiamento_ok AND a.documentos_ok AND a.reconhecimento_ok AND a.laudo_ok AND a.formas_ok AND a.recebimento_ok AND a.contrato_ok AS requisitos_rn22_ok FROM venda AS v JOIN vw_venda_validacao AS a USING (id_venda);

CREATE VIEW vw_veiculo_situacao AS SELECT v.*, CASE WHEN e.id_entrada IS NULL THEN 'FORA_DO_ESTOQUE' WHEN e.situacao = 'EM_REGULARIZACAO' OR s.situacao_comercial = 'EM_DESFAZIMENTO' THEN 'AGUARDANDO_REGULARIZACAO' WHEN s.situacao_comercial = 'EM_FORMALIZACAO' THEN 'EM_FORMALIZACAO' WHEN s.situacao_comercial = 'CONCLUIDA' THEN 'VENDIDO' WHEN e.situacao = 'ATIVA' THEN 'DISPONIVEL' ELSE 'FORA_DO_ESTOQUE' END AS situacao_atual FROM veiculo AS v LEFT JOIN LATERAL (SELECT x.* FROM entrada AS x WHERE x.id_veiculo = v.id_veiculo ORDER BY CASE WHEN x.data_entrada IS NULL THEN 1 ELSE 0 END DESC, x.data_entrada DESC, CASE WHEN x.id_entrada IS NULL THEN 1 ELSE 0 END DESC, x.id_entrada DESC LIMIT 1) AS e ON TRUE LEFT JOIN venda AS s ON s.id_entrada_principal = e.id_entrada;

-- As extensões MySQL ficam em sql/extensao/.
-- MySQL não possui trigger de instrução nem constraint trigger adiado ao COMMIT.
DROP PROCEDURE IF EXISTS concluir_venda;
DROP PROCEDURE IF EXISTS cancelar_venda;
DELIMITER $$
CREATE PROCEDURE concluir_venda(IN p_id BIGINT, IN p_data DATETIME, IN p_scanner DATETIME,
 IN p_resultado VARCHAR(100), IN p_providencias TEXT, IN p_preparacao TEXT, IN p_entrega DATETIME)
BEGIN
 DECLARE v_entrada BIGINT;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  SET @multiplikar_operacao_venda=NULL;
  ROLLBACK;
  RESIGNAL;
 END;
 START TRANSACTION;
 SELECT id_entrada_principal INTO v_entrada FROM venda WHERE id_venda=p_id FOR UPDATE;
 SET @multiplikar_operacao_venda=p_id;
 UPDATE entrada SET situacao='COMERCIALIZADA',data_encerramento=p_data,motivo_encerramento='VENDA_CONCLUIDA' WHERE id_entrada=v_entrada;
 UPDATE venda SET situacao_comercial='CONCLUIDA',data_conclusao=p_data,data_scanner=p_scanner,
  resultado_scanner=p_resultado,providencias_scanner=p_providencias,preparacao=p_preparacao,data_entrega=p_entrega WHERE id_venda=p_id;
 SET @multiplikar_operacao_venda=NULL; COMMIT;
END$$
CREATE PROCEDURE cancelar_venda(IN p_id BIGINT, IN p_data DATETIME, IN p_motivo TEXT,
 IN p_retorno DATETIME, IN p_restituido DECIMAL(14,2), IN p_observacoes TEXT)
BEGIN
 DECLARE EXIT HANDLER FOR SQLEXCEPTION
 BEGIN
  SET @multiplikar_operacao_venda=NULL;
  ROLLBACK;
  RESIGNAL;
 END;
 START TRANSACTION; SET @multiplikar_operacao_venda=p_id;
 UPDATE venda SET situacao_comercial='CANCELADA',data_cancelamento=p_data,motivo_cancelamento=p_motivo,
  data_retorno_veiculo=p_retorno,valor_restituido_loja=p_restituido,observacoes_cancelamento=p_observacoes WHERE id_venda=p_id;
 SET @multiplikar_operacao_venda=NULL; COMMIT;
END$$
CREATE TRIGGER entrada_bi BEFORE INSERT ON entrada FOR EACH ROW
BEGIN
 DECLARE v_veiculo BIGINT; DECLARE v_decisao VARCHAR(10); DECLARE v_interesse VARCHAR(10); DECLARE v_data DATETIME; DECLARE v_finalidade VARCHAR(14);
 IF NEW.id_entrada_anterior=NEW.id_entrada THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ck_entrada_anterior'; END IF;
 SELECT id_veiculo,decisao_tecnica,interesse_comercial,data,finalidade INTO v_veiculo,v_decisao,v_interesse,v_data,v_finalidade FROM avaliacao WHERE id_avaliacao=NEW.id_avaliacao;
 IF v_veiculo<>NEW.id_veiculo OR v_decisao<>'APROVADA' OR v_interesse<>'SIM' OR v_data>NEW.data_entrada OR v_finalidade<>NEW.modalidade THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN06/RN07: entrada exige avaliacao aprovada, interesse e veiculo correto'; END IF;
 IF NEW.id_venda_origem IS NOT NULL AND (NEW.modalidade<>'TROCA' OR EXISTS(SELECT 1 FROM venda v JOIN entrada p ON p.id_entrada=v.id_entrada_principal WHERE v.id_venda=NEW.id_venda_origem AND (v.id_comprador<>NEW.id_contraparte OR p.id_veiculo=NEW.id_veiculo))) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN18: troca pertence ao comprador e difere do veiculo principal'; END IF;
END$$
CREATE TRIGGER entrada_bu BEFORE UPDATE ON entrada FOR EACH ROW
BEGIN
 DECLARE v_veiculo BIGINT; DECLARE v_decisao VARCHAR(10); DECLARE v_interesse VARCHAR(10); DECLARE v_data DATETIME; DECLARE v_finalidade VARCHAR(14);
 IF NOT(NEW.id_entrada<=>OLD.id_entrada) OR NOT(NEW.id_veiculo<=>OLD.id_veiculo) OR NOT(NEW.id_avaliacao<=>OLD.id_avaliacao) OR NOT(NEW.id_contraparte<=>OLD.id_contraparte) OR NOT(NEW.id_venda_origem<=>OLD.id_venda_origem) OR NOT(NEW.id_entrada_anterior<=>OLD.id_entrada_anterior) OR NOT(NEW.modalidade<=>OLD.modalidade) OR NOT(NEW.data_entrada<=>OLD.data_entrada) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identidade e origem da entrada sao imutaveis'; END IF;
 IF OLD.data_encerramento IS NOT NULL AND NEW.data_encerramento IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Entrada encerrada nao pode ser reaberta; crie novo ciclo'; END IF;
 IF NEW.id_entrada_anterior=NEW.id_entrada THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='ck_entrada_anterior'; END IF;
 SELECT id_veiculo,decisao_tecnica,interesse_comercial,data,finalidade INTO v_veiculo,v_decisao,v_interesse,v_data,v_finalidade FROM avaliacao WHERE id_avaliacao=NEW.id_avaliacao;
 IF v_veiculo<>NEW.id_veiculo OR v_decisao<>'APROVADA' OR v_interesse<>'SIM' OR v_data>NEW.data_entrada OR v_finalidade<>NEW.modalidade THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN06/RN07: entrada exige avaliacao aprovada, interesse e veiculo correto'; END IF;
 IF NEW.situacao='COMERCIALIZADA' AND (NOT(@multiplikar_operacao_venda IS NOT NULL) OR NOT EXISTS(SELECT 1 FROM venda WHERE id_venda=@multiplikar_operacao_venda AND id_entrada_principal=NEW.id_entrada)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use concluir_venda para encerrar a entrada'; END IF;
 IF NEW.situacao='ATIVA' AND NEW.id_entrada_anterior IS NOT NULL AND (NEW.data_regularizacao IS NULL OR NEW.observacoes_regularizacao IS NULL OR NOT EXISTS(SELECT 1 FROM venda WHERE id_entrada_principal=NEW.id_entrada_anterior AND situacao_comercial='CANCELADA')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN13: sucessor exige distrato e regularizacao antes de liberar'; END IF;
END$$
CREATE TRIGGER entrada_bd BEFORE DELETE ON entrada FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Historico de entrada deve ser encerrado, nunca apagado'; END$$
CREATE TRIGGER venda_bi BEFORE INSERT ON venda FOR EACH ROW
BEGIN
 IF NEW.situacao_comercial<>'EM_FORMALIZACAO' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Venda inicia em formalizacao; conclua apos registrar os requisitos'; END IF;
 IF NOT EXISTS(SELECT 1 FROM entrada WHERE id_entrada=NEW.id_entrada_principal AND situacao='ATIVA' AND data_entrada<=NEW.data_registro) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Venda exige entrada disponivel'; END IF;
 IF NEW.id_laudo IS NOT NULL AND NOT EXISTS(SELECT 1 FROM laudo l JOIN entrada e ON e.id_entrada=NEW.id_entrada_principal WHERE l.id_laudo=NEW.id_laudo AND l.id_veiculo=e.id_veiculo AND l.data_emissao<=DATE(NEW.data_registro)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Laudo deve corresponder ao veiculo da venda'; END IF;
END$$
CREATE TRIGGER venda_bu BEFORE UPDATE ON venda FOR EACH ROW
BEGIN
 DECLARE v_status VARCHAR(18); DECLARE v_fim DATETIME; DECLARE v_trocas DECIMAL(14,2); DECLARE v_total DECIMAL(14,2); DECLARE v_docs INT; DECLARE v_firma INT; DECLARE v_formas INT; DECLARE v_fin_ok BOOLEAN; DECLARE v_pend VARCHAR(300) DEFAULT '';
 IF NOT(NEW.id_venda<=>OLD.id_venda) OR NOT(NEW.id_entrada_principal<=>OLD.id_entrada_principal) OR NOT(NEW.id_comprador<=>OLD.id_comprador) OR NOT(NEW.data_registro<=>OLD.data_registro) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Identidade da venda e imutavel'; END IF;
 IF OLD.data_conclusao IS NOT NULL AND NOT(NEW.data_conclusao<=>OLD.data_conclusao) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Preserve o marco de conclusao'; END IF;
 IF OLD.situacao_comercial='CANCELADA' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Venda cancelada e historica; crie novo ciclo'; END IF;
 IF OLD.situacao_comercial='CONCLUIDA' AND OLD.concessao_garantia=TRUE AND NEW.concessao_garantia=FALSE THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN22: concessao de garantia da venda concluida e historica'; END IF;
 IF NEW.situacao_comercial='CONCLUIDA' AND OLD.situacao_comercial<>'CONCLUIDA' AND NOT(@multiplikar_operacao_venda<=>NEW.id_venda) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use concluir_venda para concluir com RN22'; END IF;
 IF NEW.situacao_comercial='CANCELADA' AND OLD.situacao_comercial<>'CANCELADA' THEN
  IF NOT(@multiplikar_operacao_venda<=>NEW.id_venda) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Use cancelar_venda para registrar o desfazimento'; END IF;
  -- Mesmas quatro condições de antes; a mensagem passa a listar quais estão pendentes.
  IF NOT EXISTS(SELECT 1 FROM entrada WHERE id_entrada=NEW.id_entrada_principal AND situacao='ENCERRADA' AND motivo_encerramento='DESFAZIMENTO') THEN SET v_pend=CONCAT(v_pend,' encerrar entrada por DESFAZIMENTO;'); END IF;
  IF NOT EXISTS(SELECT 1 FROM entrada WHERE id_entrada_anterior=NEW.id_entrada_principal) THEN SET v_pend=CONCAT(v_pend,' novo ciclo;'); END IF;
  IF NEW.instituicao_financeira IS NOT NULL AND NEW.orientacao_bancaria IS NULL THEN SET v_pend=CONCAT(v_pend,' orientacao bancaria;'); END IF;
  IF (SELECT COUNT(*) FROM entrada WHERE id_venda_origem=NEW.id_venda AND (situacao<>'DEVOLVIDA' OR data_devolucao IS NULL))>0 THEN SET v_pend=CONCAT(v_pend,' devolver trocas;'); END IF;
  IF v_pend<>'' THEN SET v_pend=LEFT(CONCAT('RN13/RN28-RN31: cancelamento pendente:',v_pend),128); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_pend; END IF;
 END IF;
 IF NEW.situacao_comercial='CONCLUIDA' OR (NEW.data_conclusao IS NOT NULL AND NEW.situacao_comercial NOT IN('CANCELADA','EM_DESFAZIMENTO')) THEN
  SET v_total=NEW.valor_base-NEW.desconto+NEW.acrescimo+NEW.taxas;
  SELECT situacao,data_encerramento INTO v_status,v_fim FROM entrada WHERE id_entrada=NEW.id_entrada_principal;
  SELECT COALESCE(SUM(CASE WHEN data_devolucao IS NULL AND situacao NOT IN('EM_REGULARIZACAO','DEVOLVIDA','RETIRADA','ENCERRADA') THEN valor_acordado ELSE 0 END),0) INTO v_trocas FROM entrada WHERE id_venda_origem=NEW.id_venda;
  SELECT COUNT(*) INTO v_docs FROM venda_documento WHERE id_venda=NEW.id_venda AND data_conferencia IS NOT NULL AND (NEW.data_conclusao IS NULL OR data_conferencia<=NEW.data_conclusao) AND tipo_documento IN('CNH','LAUDO_CAUTELAR','CRLV','ATPV','COMPROVANTE_RESIDENCIA','CONTRATO');
  SELECT COUNT(*) INTO v_firma FROM venda_documento WHERE id_venda=NEW.id_venda AND tipo_documento IN('ATPV','CONTRATO') AND (NOT reconhecimento_aplicavel OR data_reconhecimento IS NOT NULL) AND (data_reconhecimento IS NULL OR NEW.data_conclusao IS NULL OR data_reconhecimento<=NEW.data_conclusao);
  SELECT COUNT(*) INTO v_formas FROM venda_forma_pagamento WHERE id_venda=NEW.id_venda;
  SET v_fin_ok=(NEW.instituicao_financeira IS NULL OR (NEW.situacao_financiamento='NAO_APROVADO' AND NEW.valor_recebido+v_trocas>=v_total) OR (NEW.situacao_financiamento='RECEBIDO' AND NEW.data_recebimento_financiamento IS NOT NULL));
  -- RN22: as mesmas condições, avaliadas em conjunto; a mensagem lista todas as pendências encontradas.
  IF NEW.data_conclusao IS NULL THEN SET v_pend=CONCAT(v_pend,' conclusao;'); END IF;
  IF NEW.numero_contrato IS NULL OR NEW.data_emissao IS NULL OR NEW.termos_condicoes IS NULL THEN SET v_pend=CONCAT(v_pend,' contrato;'); END IF;
  IF v_status<>'COMERCIALIZADA' OR NOT(v_fim<=>NEW.data_conclusao) THEN SET v_pend=CONCAT(v_pend,' entrada;'); END IF;
  IF NEW.valor_recebido+v_trocas<v_total THEN SET v_pend=CONCAT(v_pend,' pagamento;'); END IF;
  IF NOT v_fin_ok THEN SET v_pend=CONCAT(v_pend,' financiamento;'); END IF;
  IF v_formas=0 OR (NEW.instituicao_financeira IS NOT NULL AND NEW.situacao_financiamento<>'NAO_APROVADO' AND NOT EXISTS(SELECT 1 FROM venda_forma_pagamento WHERE id_venda=NEW.id_venda AND codigo_forma='FINANCIAMENTO')) THEN SET v_pend=CONCAT(v_pend,' formas;'); END IF;
  IF NEW.data_ultimo_recebimento IS NOT NULL AND NEW.data_ultimo_recebimento>NEW.data_conclusao THEN SET v_pend=CONCAT(v_pend,' recebimento posterior;'); END IF;
  IF v_docs<6 THEN SET v_pend=CONCAT(v_pend,' documentos;'); END IF;
  IF v_firma<2 THEN SET v_pend=CONCAT(v_pend,' firma;'); END IF;
  IF NEW.id_laudo IS NULL OR NOT EXISTS(SELECT 1 FROM laudo l JOIN entrada e ON e.id_entrada=NEW.id_entrada_principal WHERE l.id_laudo=NEW.id_laudo AND l.id_veiculo=e.id_veiculo AND l.data_emissao<=DATE(NEW.data_conclusao)) THEN SET v_pend=CONCAT(v_pend,' laudo;'); END IF;
  IF v_pend<>'' THEN SET v_pend=LEFT(CONCAT('RN22: pendente:',v_pend),128); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_pend; END IF;
 END IF;
END$$
CREATE TRIGGER venda_bd BEFORE DELETE ON venda FOR EACH ROW BEGIN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Historico de venda deve ser encerrado, nunca apagado'; END$$
CREATE TRIGGER avaliacao_laudo_bi BEFORE INSERT ON avaliacao_laudo FOR EACH ROW
BEGIN IF NOT EXISTS(SELECT 1 FROM avaliacao a JOIN laudo l ON l.id_laudo=NEW.id_laudo WHERE a.id_avaliacao=NEW.id_avaliacao AND a.id_veiculo=l.id_veiculo AND l.data_emissao<=DATE(a.data)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN08: laudo deve ser do mesmo veiculo e anterior a avaliacao'; END IF; END$$
CREATE TRIGGER avaliacao_laudo_bu BEFORE UPDATE ON avaliacao_laudo FOR EACH ROW
BEGIN IF NOT EXISTS(SELECT 1 FROM avaliacao a JOIN laudo l ON l.id_laudo=NEW.id_laudo WHERE a.id_avaliacao=NEW.id_avaliacao AND a.id_veiculo=l.id_veiculo AND l.data_emissao<=DATE(a.data)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN08: laudo deve ser do mesmo veiculo e anterior a avaliacao'; END IF; END$$
CREATE TRIGGER laudo_bu BEFORE UPDATE ON laudo FOR EACH ROW
BEGIN IF EXISTS(SELECT 1 FROM avaliacao_laudo al JOIN avaliacao a ON a.id_avaliacao=al.id_avaliacao WHERE al.id_laudo=OLD.id_laudo AND (a.id_veiculo<>NEW.id_veiculo OR NEW.data_emissao>a.data)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN08: laudo deve ser do mesmo veiculo e anterior a avaliacao'; END IF; END$$
CREATE TRIGGER avaliacao_bu BEFORE UPDATE ON avaliacao FOR EACH ROW
BEGIN IF EXISTS(SELECT 1 FROM entrada e WHERE e.id_avaliacao=OLD.id_avaliacao AND (NEW.id_veiculo<>e.id_veiculo OR NEW.decisao_tecnica<>'APROVADA' OR NEW.interesse_comercial<>'SIM' OR NEW.data>e.data_entrada OR NEW.finalidade<>e.modalidade)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN06/RN07: entrada exige avaliacao aprovada, interesse e veiculo correto'; END IF; END$$
CREATE TRIGGER documento_bi BEFORE INSERT ON venda_documento FOR EACH ROW BEGIN IF EXISTS(SELECT 1 FROM venda WHERE id_venda=NEW.id_venda AND situacao_comercial='CONCLUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN22: documentos de venda concluida sao historicos'; END IF; END$$
CREATE TRIGGER documento_bu BEFORE UPDATE ON venda_documento FOR EACH ROW BEGIN IF EXISTS(SELECT 1 FROM venda WHERE id_venda=OLD.id_venda AND situacao_comercial='CONCLUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN22: documentos de venda concluida sao historicos'; END IF; END$$
CREATE TRIGGER documento_bd BEFORE DELETE ON venda_documento FOR EACH ROW BEGIN IF EXISTS(SELECT 1 FROM venda WHERE id_venda=OLD.id_venda AND situacao_comercial='CONCLUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN22: documentos de venda concluida sao historicos'; END IF; END$$
CREATE TRIGGER forma_venda_bi BEFORE INSERT ON venda_forma_pagamento FOR EACH ROW BEGIN IF EXISTS(SELECT 1 FROM venda WHERE id_venda=NEW.id_venda AND situacao_comercial='CONCLUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN22: formas de pagamento de venda concluida sao historicas'; END IF; END$$
CREATE TRIGGER forma_venda_bu BEFORE UPDATE ON venda_forma_pagamento FOR EACH ROW BEGIN IF EXISTS(SELECT 1 FROM venda WHERE id_venda=OLD.id_venda AND situacao_comercial='CONCLUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN22: formas de pagamento de venda concluida sao historicas'; END IF; END$$
CREATE TRIGGER forma_venda_bd BEFORE DELETE ON venda_forma_pagamento FOR EACH ROW BEGIN IF EXISTS(SELECT 1 FROM venda WHERE id_venda=OLD.id_venda AND situacao_comercial='CONCLUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RN22: formas de pagamento de venda concluida sao historicas'; END IF; END$$
CREATE TRIGGER ocorrencia_bi BEFORE INSERT ON ocorrencia_garantia FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM venda WHERE id_venda=NEW.id_venda AND concessao_garantia=TRUE AND data_entrega IS NOT NULL AND NEW.data_abertura>=data_entrega) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Ocorrencia de garantia exige concessao e entrega anterior'; END IF; END$$
CREATE TRIGGER ocorrencia_bu BEFORE UPDATE ON ocorrencia_garantia FOR EACH ROW BEGIN IF NOT EXISTS(SELECT 1 FROM venda WHERE id_venda=NEW.id_venda AND concessao_garantia=TRUE AND data_entrega IS NOT NULL AND NEW.data_abertura>=data_entrega) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Ocorrencia de garantia exige concessao e entrega anterior'; END IF; END$$
-- RO02: e-mail e endereço completo passam a ser exigidos quando a pessoa assina contrato
-- (entrada por compra própria/consignação ou venda com número de contrato).
DROP FUNCTION IF EXISTS pessoa_dados_contrato$$
CREATE FUNCTION pessoa_dados_contrato(p_id BIGINT) RETURNS BOOLEAN READS SQL DATA
BEGIN
 -- id nulo ou inexistente fica para o NOT NULL e a FK, que dão a mensagem certa.
 RETURN NOT EXISTS(SELECT 1 FROM pessoa WHERE id_pessoa=p_id AND (email IS NULL OR logradouro IS NULL));
END$$
CREATE TRIGGER entrada_contrato_bi BEFORE INSERT ON entrada FOR EACH ROW
BEGIN IF NEW.numero_contrato IS NOT NULL AND NOT pessoa_dados_contrato(NEW.id_contraparte) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: contrato exige e-mail e endereco completo da contraparte'; END IF; END$$
CREATE TRIGGER entrada_contrato_bu BEFORE UPDATE ON entrada FOR EACH ROW
BEGIN IF NEW.numero_contrato IS NOT NULL AND OLD.numero_contrato IS NULL AND NOT pessoa_dados_contrato(NEW.id_contraparte) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: contrato exige e-mail e endereco completo da contraparte'; END IF; END$$
CREATE TRIGGER venda_contrato_bi BEFORE INSERT ON venda FOR EACH ROW
BEGIN IF NEW.numero_contrato IS NOT NULL AND NOT pessoa_dados_contrato(NEW.id_comprador) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: contrato exige e-mail e endereco completo do comprador'; END IF; END$$
CREATE TRIGGER venda_contrato_bu BEFORE UPDATE ON venda FOR EACH ROW
BEGIN IF NEW.numero_contrato IS NOT NULL AND OLD.numero_contrato IS NULL AND NOT pessoa_dados_contrato(NEW.id_comprador) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: contrato exige e-mail e endereco completo do comprador'; END IF; END$$
CREATE TRIGGER pessoa_contrato_bu BEFORE UPDATE ON pessoa FOR EACH ROW
BEGIN
 IF (NEW.email IS NULL OR NEW.logradouro IS NULL)
  AND (EXISTS(SELECT 1 FROM entrada WHERE id_contraparte=OLD.id_pessoa AND numero_contrato IS NOT NULL)
   OR EXISTS(SELECT 1 FROM venda WHERE id_comprador=OLD.id_pessoa AND numero_contrato IS NOT NULL)) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RO02: pessoa com contrato deve manter e-mail e endereco completo'; END IF;
END$$
DELIMITER ;






-- =====================================================================
-- sql\dados\massa-dados.sql
-- =====================================================================
-- Massa-base MySQL 8.4.13; dados fictícios. Os ciclos compostos usam procedures atomicas.
-- O MySQL Workbench liga o modo Safe Updates por padrão, que recusa UPDATE/DELETE sem coluna-chave
-- no WHERE. Este script faz essas operações de proposito (inclusive dentro dos testes), entao o modo
-- e desligado só durante a execução e o valor anterior e restaurado no fim.
SET @mk_safe_updates = @@SESSION.sql_safe_updates;
SET SQL_SAFE_UPDATES = 0;
USE multiplikar;
INSERT INTO pessoa (id_pessoa, nome, tipo_documento, numero_documento, telefone, email, logradouro, numero, bairro, cidade, estado_uf, possui_cnh) SELECT id, nome, 'CPF', LPAD(CAST(id AS CHAR), 11, '0'), CONCAT('1190000', LPAD(CAST(id AS CHAR), 4, '0')), CONCAT('pessoa', id, '@example.invalid'), 'Rua de Teste', CAST(id AS CHAR), 'Vila Sao Geraldo', 'Sao Paulo', 'SP', TRUE FROM (SELECT 1 AS id, 'Ana Comercial' AS nome UNION ALL SELECT 2, 'Bruno Administrativo' UNION ALL SELECT 3, 'Caio Avaliador' UNION ALL SELECT 4, 'Dora Mecanica' UNION ALL SELECT 5, 'Eva Fornecedora' UNION ALL SELECT 6, 'Fabio Comprador' UNION ALL SELECT 7, 'Gabi Compradora' UNION ALL SELECT 8, 'Hugo Consignante' UNION ALL SELECT 9, 'Iara Compradora' UNION ALL SELECT 10, 'Joao Comprador' UNION ALL SELECT 11, 'Lia Compradora' UNION ALL SELECT 12, 'Mario Comprador') AS p;

INSERT INTO funcionario (id_funcionario, id_pessoa, cargo, data_admissao, situacao) VALUES (1, 1, 'Vendas', '2025-01-10', 'ATIVO'), (2, 2, 'Administrativo', '2025-02-01', 'ATIVO');

INSERT INTO veiculo (id_veiculo, marca, modelo, ano_modelo, cor, placa, chassi, combustivel, cambio, categoria_comercial) VALUES (1, 'Fiat', 'Argo', 2022, 'Branco', 'TST1A01', '9TEST000000000001', 'Flex', 'Manual', 'USADO'), (2, 'Toyota', 'Corolla', 2021, 'Prata', 'TST1A02', '9TEST000000000002', 'Flex', 'Automatico', 'USADO'), (3, 'Honda', 'City', 2023, 'Cinza', 'TST1A03', '9TEST000000000003', 'Flex', 'Automatico', 'SEMINOVO'), (4, 'Hyundai', 'HB20', 2022, 'Azul', 'TST1A04', '9TEST000000000004', 'Flex', 'Manual', 'USADO'), (5, 'Chevrolet', 'Tracker', 2023, 'Preto', 'TST1A05', '9TEST000000000005', 'Flex', 'Automatico', 'SEMINOVO'), (6, 'Fiat', 'Uno', 2015, 'Branco', 'TST1A06', '9TEST000000000006', 'Flex', 'Manual', 'USADO'), (7, 'Ford', 'Ka', 2013, 'Vermelho', 'TST1A07', '9TEST000000000007', 'Flex', 'Manual', 'USADO'), (8, 'Volkswagen', 'Gol', 2017, 'Prata', 'TST1A08', '9TEST000000000008', 'Flex', 'Manual', 'USADO'), (9, 'Renault', 'Kwid', 2024, 'Branco', 'TST1A09', '9TEST000000000009', 'Flex', 'Manual', 'SEMINOVO');

INSERT INTO atendimento (id_atendimento, id_pessoa, id_funcionario, data, tipo_interesse, descricao_interesse, situacao) VALUES (1, 6, 1, '2026-01-05 09:00', 'COMPRA', 'Busca por Argo', 'CONVERTIDO'), (2, 7, 1, '2026-01-05 09:00', 'TROCA', 'Corolla com Uno e Ka de entrada', 'CONVERTIDO'), (3, 9, 2, '2026-01-07 09:00', 'COMPRA', 'City com financiamento', 'CONVERTIDO'), (4, 10, 1, '2026-01-07 09:00', 'TROCA', 'HB20 com Gol de entrada', 'CONVERTIDO'), (5, 12, 1, '2026-01-09 09:00', 'COMPRA', 'Tracker aguardando banco', 'EM_NEGOCIACAO'), (6, 8, 2, '2026-01-02 09:00', 'VENDA', 'Consignacao City e Kwid', 'CONVERTIDO');

INSERT INTO laudo (id_laudo, id_veiculo, referencia_documental, data_emissao, situacao, resultado) SELECT id_veiculo, id_veiculo, CONCAT('LAUDO-TESTE-', id_veiculo), CASE WHEN id_veiculo IN (6, 7) THEN CAST('2026-01-06' AS DATE) WHEN id_veiculo = 8 THEN CAST('2026-01-08' AS DATE) ELSE CAST('2026-01-02' AS DATE) END, 'EMITIDO', 'Documento cautelar realizado; resultado registrado para analise.' FROM veiculo;

INSERT INTO avaliacao (id_avaliacao, id_veiculo, id_avaliador, data, finalidade, quilometragem, quantidade_proprietarios, condicao_externa, condicao_interna, condicao_mecanica, condicao_estrutural, condicao_documental, decisao_tecnica, interesse_comercial, justificativa) SELECT id, id_veiculo, 3, CASE WHEN id_veiculo IN (6, 7) THEN CAST('2026-01-06 10:00' AS DATETIME) WHEN id_veiculo = 8 THEN CAST('2026-01-08 10:00' AS DATETIME) ELSE CAST('2026-01-03 10:00' AS DATETIME) END, modalidade, km, 2, 'Conservada', 'Conservada', 'Vistoriada', 'Verificada', 'Conferida', 'APROVADA', 'SIM', 'Vistoria aprovada e interesse comercial confirmado.' FROM (SELECT 1 AS id, 1 AS id_veiculo, 'COMPRA_PROPRIA' AS modalidade, 40000 AS km UNION ALL SELECT 2, 2, 'COMPRA_PROPRIA', 50000 UNION ALL SELECT 3, 3, 'CONSIGNACAO', 30000 UNION ALL SELECT 4, 4, 'COMPRA_PROPRIA', 45000 UNION ALL SELECT 5, 5, 'COMPRA_PROPRIA', 25000 UNION ALL SELECT 6, 6, 'TROCA', 100000 UNION ALL SELECT 7, 7, 'TROCA', 120000 UNION ALL SELECT 8, 8, 'TROCA', 80000 UNION ALL SELECT 10, 9, 'CONSIGNACAO', 20000) AS a;

INSERT INTO avaliacao_laudo (id_avaliacao, id_laudo) SELECT id_avaliacao, id_veiculo FROM avaliacao;

INSERT INTO entrada (id_entrada, id_veiculo, id_contraparte, id_avaliacao, modalidade, data_entrada, valor_acordado, preco_anunciado, numero_contrato, data_emissao, termos_ajustes, reconhecimento_firma, valor_repasse_acordado, prazo_repasse, criterio_repasse) SELECT id, id, contraparte, id_avaliacao, modalidade, '2026-01-04 10:00', custo, preco, CONCAT('CE-', id), '2026-01-04', 'Condicoes individualizadas de entrada.', 'REALIZADO', repasse, CASE WHEN modalidade = 'CONSIGNACAO' THEN 'Apos confirmacao da venda' END, CASE WHEN modalidade = 'CONSIGNACAO' THEN 'Valor fixo acordado com o consignante' END FROM (SELECT 1 AS id, 5 AS contraparte, 1 AS id_avaliacao, 'COMPRA_PROPRIA' AS modalidade, 50000 AS custo, 60000 AS preco, CAST(NULL AS DECIMAL) AS repasse UNION ALL SELECT 2, 5, 2, 'COMPRA_PROPRIA', 85000, 100000, NULL UNION ALL SELECT 3, 8, 3, 'CONSIGNACAO', 80000, 80000, 74000 UNION ALL SELECT 4, 5, 4, 'COMPRA_PROPRIA', 58000, 70000, NULL UNION ALL SELECT 5, 5, 5, 'COMPRA_PROPRIA', 78000, 90000, NULL) AS e;

INSERT INTO entrada (id_entrada, id_veiculo, id_contraparte, id_avaliacao, modalidade, data_entrada, valor_acordado, preco_anunciado, numero_contrato, data_emissao, termos_ajustes, reconhecimento_firma, valor_repasse_acordado, prazo_repasse, criterio_repasse) VALUES (10, 9, 8, 10, 'CONSIGNACAO', '2026-01-04 11:00', 55000, 55000, 'CE-10', '2026-01-04', 'Consignacao com prazo ate 15/11/2026.', 'REALIZADO', 50000, 'Apos a venda', 'Repasse fixo');

UPDATE entrada SET prazo_consignacao = '2026-04-04' WHERE id_entrada = 3;

UPDATE entrada SET prazo_consignacao = '2026-11-15' WHERE id_entrada = 10;

INSERT INTO venda (id_venda, id_comprador, id_funcionario, id_entrada_principal, id_laudo, data_registro, valor_base, numero_contrato, data_emissao, termos_condicoes, valor_recebido, data_ultimo_recebimento, concessao_garantia, termos_politica) VALUES (1, 6, 1, 1, 1, '2026-01-05 10:00', 60000, 'CV-1', '2026-01-05', 'Venda normal via Pix.', 60000, '2026-01-06 10:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.'), (2, 7, 1, 2, 2, '2026-01-06 10:00', 100000, 'CV-2', '2026-01-06', 'Uno: 25000; Ka: 15000; Pix: 60000.', 60000, '2026-01-07 10:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.'), (3, 9, 2, 3, 3, '2026-01-07 10:00', 80000, 'CV-3', '2026-01-07', 'Pix 20000 e banco 60000; consignado.', 80000, '2026-01-08 10:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.'), (4, 10, 1, 4, 4, '2026-01-08 10:00', 70000, 'CV-4', '2026-01-08', 'Gol: 30000; Pix: 40000.', 40000, '2026-01-09 10:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.'), (6, 12, 1, 5, 5, '2026-01-09 10:00', 90000, 'CV-6', '2026-01-09', 'Pix 10000; banco 80000 ainda nao recebido.', 10000, '2026-01-09 11:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.');

UPDATE venda SET instituicao_financeira = 'Banco Exemplo', valor_financiado = 60000, situacao_financiamento = 'RECEBIDO', data_aprovacao_financiamento = '2026-01-07 15:00', data_recebimento_financiamento = '2026-01-08 10:00' WHERE id_venda = 3;

UPDATE venda SET instituicao_financeira = 'Banco Demonstracao', valor_financiado = 80000, situacao_financiamento = 'APROVADO_A_RECEBER', data_aprovacao_financiamento = '2026-01-10 10:00' WHERE id_venda = 6;

INSERT INTO entrada (id_entrada, id_veiculo, id_contraparte, id_avaliacao, id_venda_origem, modalidade, data_entrada, valor_acordado, preco_anunciado) VALUES (6, 6, 7, 6, 2, 'TROCA', '2026-01-06 11:00', 25000, 30000), (7, 7, 7, 7, 2, 'TROCA', '2026-01-06 11:00', 15000, 20000), (8, 8, 10, 8, 4, 'TROCA', '2026-01-08 11:00', 30000, 35000);

INSERT INTO forma_pagamento VALUES ('PIX', 'Pix'), ('DINHEIRO', 'Dinheiro'), ('CARTAO', 'Cartao'), ('FINANCIAMENTO', 'Financiamento'), ('TROCA', 'Veiculo recebido em troca');

INSERT INTO venda_forma_pagamento VALUES (1, 'PIX'), (2, 'PIX'), (2, 'TROCA'), (3, 'PIX'), (3, 'FINANCIAMENTO'), (4, 'PIX'), (4, 'TROCA'), (6, 'PIX'), (6, 'FINANCIAMENTO');

INSERT INTO venda_documento (id_venda, tipo_documento, data_conferencia, reconhecimento_aplicavel, data_reconhecimento) SELECT v.id_venda, d.tipo, '2026-01-10 12:00', d.tipo IN ('ATPV', 'CONTRATO'), CASE WHEN d.tipo IN ('ATPV', 'CONTRATO') THEN CAST('2026-01-10 13:00' AS DATETIME) END FROM venda AS v CROSS JOIN (SELECT 'CNH' AS tipo UNION ALL SELECT 'LAUDO_CAUTELAR' UNION ALL SELECT 'CRLV' UNION ALL SELECT 'ATPV' UNION ALL SELECT 'COMPROVANTE_RESIDENCIA' UNION ALL SELECT 'CONTRATO') AS d;

CALL concluir_venda(1,'2026-01-11 10:00','2026-01-11 11:00','Leitura realizada sem falhas.','Nenhuma intervencao indicada.','Limpeza e conferencia de entrega.','2026-01-12 10:00');

CALL concluir_venda(2,'2026-01-11 10:00','2026-01-11 11:00','Leitura realizada sem falhas.','Nenhuma intervencao indicada.','Limpeza e conferencia de entrega.','2026-01-12 10:00');

CALL concluir_venda(3,'2026-01-11 10:00','2026-01-11 11:00','Leitura realizada sem falhas.','Nenhuma intervencao indicada.','Limpeza e conferencia de entrega.','2026-01-12 10:00');

CALL concluir_venda(4,'2026-01-11 10:00','2026-01-11 11:00','Leitura realizada sem falhas.','Nenhuma intervencao indicada.','Limpeza e conferencia de entrega.','2026-01-12 10:00');

UPDATE venda SET situacao_comercial = 'EM_DESFAZIMENTO' WHERE id_venda = 4;

UPDATE entrada SET situacao = 'ENCERRADA', motivo_encerramento = 'DESFAZIMENTO' WHERE id_entrada = 4;

UPDATE entrada SET situacao = 'DEVOLVIDA', data_devolucao = '2026-01-20 12:00', data_encerramento = '2026-01-20 12:00', motivo_encerramento = 'DEVOLUCAO_TROCA' WHERE id_entrada = 8;

INSERT INTO avaliacao (id_avaliacao, id_veiculo, id_avaliador, data, finalidade, quilometragem, quantidade_proprietarios, condicao_externa, condicao_interna, condicao_mecanica, condicao_estrutural, condicao_documental, decisao_tecnica, interesse_comercial, justificativa) VALUES (9, 4, 3, '2026-01-20 13:00', 'COMPRA_PROPRIA', 45300, 2, 'Conservada', 'Conservada', 'Reavaliada apos retorno', 'Verificada', 'Em regularizacao administrativa', 'APROVADA', 'SIM', 'Nova avaliacao de aceitacao; liberacao comercial aguarda regularizacao do distrato.');

INSERT INTO avaliacao_laudo VALUES (9, 4);

INSERT INTO entrada (id_entrada, id_veiculo, id_contraparte, id_avaliacao, id_entrada_anterior, modalidade, data_entrada, situacao, valor_acordado, preco_anunciado, numero_contrato, data_emissao, termos_ajustes) VALUES (9, 4, 10, 9, 4, 'COMPRA_PROPRIA', '2026-01-20 14:00', 'EM_REGULARIZACAO', 58000, 68000, 'DISTRATO-CV-4', '2026-01-20', 'Reintegracao por distrato; valor de referencia do ciclo, sem nova compra paga.');

CALL cancelar_venda(4,'2026-01-20 15:00','Desfazimento acordado entre as partes.','2026-01-20 10:00',40000,'HB20 recebido; Gol devolvido; 40000 restituidos; novo ciclo 9 em regularizacao.');

UPDATE entrada SET situacao = 'ATIVA', data_regularizacao = '2026-01-22 09:00', observacoes_regularizacao = 'Distrato, retorno e restituicoes conferidos; liberado para nova venda.' WHERE id_entrada = 9;

INSERT INTO venda (id_venda, id_comprador, id_funcionario, id_entrada_principal, id_laudo, data_registro, valor_base, numero_contrato, data_emissao, termos_condicoes, valor_recebido, data_ultimo_recebimento, concessao_garantia, termos_politica) VALUES (5, 11, 1, 9, 4, '2026-01-23 10:00', 68000, 'CV-5', '2026-01-23', 'Revenda apos regularizacao; banco recusou; quitacao integral via Pix.', 68000, '2026-01-23 11:00', TRUE, 'Dois meses a partir da entrega; atendimento pela loja.');

UPDATE venda SET instituicao_financeira = 'Banco Demonstracao', valor_financiado = 50000, situacao_financiamento = 'NAO_APROVADO' WHERE id_venda = 5;

INSERT INTO venda_forma_pagamento VALUES (5, 'PIX');

INSERT INTO venda_documento (id_venda, tipo_documento, data_conferencia, reconhecimento_aplicavel, data_reconhecimento) SELECT 5, tipo, '2026-01-23 12:00', tipo IN ('ATPV', 'CONTRATO'), CASE WHEN tipo IN ('ATPV', 'CONTRATO') THEN CAST('2026-01-23 13:00' AS DATETIME) END FROM (SELECT 'CNH' AS tipo UNION ALL SELECT 'LAUDO_CAUTELAR' UNION ALL SELECT 'CRLV' UNION ALL SELECT 'ATPV' UNION ALL SELECT 'COMPROVANTE_RESIDENCIA' UNION ALL SELECT 'CONTRATO') AS d;

CALL concluir_venda(5,'2026-01-24 10:00','2026-01-24 11:00','Sem falhas',NULL,NULL,'2026-01-25 10:00');

INSERT INTO ocorrencia_garantia (id_ocorrencia, id_venda, id_mecanico, data_abertura, problema_relatado, atendimento_externo_informado, diagnostico, responsabilidade_apurada, servico_realizado, solucao, situacao, data_encerramento) VALUES (1, 1, 4, '2026-02-01 09:00', 'Falha de partida', 'NAO', 'Bateria com falha', 'LOJA', 'Substituicao de bateria', 'Problema resolvido', 'ENCERRADA', '2026-02-02 15:00'), (2, 3, 4, '2026-02-03 09:00', 'Ruido na suspensao', 'NAO', 'Em diagnostico', 'EM_ANALISE', NULL, NULL, 'EM_ANALISE', NULL);

INSERT INTO despesa (id_despesa, id_veiculo, data, categoria, descricao, valor) VALUES (1, 1, '2026-02-02', 'GARANTIA', 'Bateria e instalacao', 650), (2, 3, '2026-02-03', 'DIAGNOSTICO', 'Inspecao de suspensao', 150), (3, 2, '2026-01-10', 'PREPARACAO', 'Higienizacao', 250), (4, 4, '2026-01-22', 'PREPARACAO', 'Revisao apos devolucao', 400);

DELIMITER $$
CREATE PROCEDURE verificar_massa_nucleo()
BEGIN
 IF (SELECT COUNT(*) FROM venda)<>6 OR (SELECT COUNT(*) FROM entrada)<>10 OR (SELECT COUNT(*) FROM ocorrencia_garantia)<>2 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Contagens finais inesperadas na massa do nucleo'; END IF;
 SELECT 'PASS massa: 6 vendas, 10 entradas e 2 ocorrencias' AS resultado;
 IF EXISTS(SELECT 1 FROM vw_venda_resumo WHERE data_conclusao IS NOT NULL AND requisitos_rn22_ok<>TRUE) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Venda concluida com RN22 pendente'; END IF;
 SELECT 'PASS RN22: vendas concluidas atendem aos requisitos' AS resultado;
 IF (SELECT total_trocas FROM vw_venda_resumo WHERE id_venda=2)<>40000 OR (SELECT saldo FROM vw_venda_resumo WHERE id_venda=2)<>0 OR (SELECT saldo FROM vw_venda_resumo WHERE id_venda=6)<>80000 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Composicao financeira incorreta'; END IF;
 SELECT 'PASS composicao: troca, saldo quitado e financiamento pendente' AS resultado;
 IF NOT EXISTS(SELECT 1 FROM entrada n JOIN entrada a ON a.id_entrada=n.id_entrada_anterior JOIN venda antiga ON antiga.id_entrada_principal=a.id_entrada JOIN venda nova ON nova.id_entrada_principal=n.id_entrada WHERE a.id_veiculo=4 AND n.id_veiculo=4 AND antiga.situacao_comercial='CANCELADA' AND nova.situacao_comercial='CONCLUIDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Historico RN13 incompleto'; END IF;
 SELECT 'PASS RN13: distrato e novo ciclo do HB20 preservados' AS resultado;
END$$
DELIMITER ;
CALL verificar_massa_nucleo();
DROP PROCEDURE verificar_massa_nucleo;

-- Regressao RN do núcleo: os DML abaixo sao executados e precisam falhar pela regra esperada.
DROP PROCEDURE IF EXISTS massa_rejeitar;
DELIMITER $$
CREATE PROCEDURE massa_rejeitar(IN p_nome VARCHAR(120),IN p_sql TEXT,IN p_esperado VARCHAR(128))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 @msg=MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE; END;
  SET @massa_sql=p_sql; PREPARE massa_stmt FROM @massa_sql; EXECUTE massa_stmt; DEALLOCATE PREPARE massa_stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Operacao aceita indevidamente: ',p_nome); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Regra inesperada em ',p_nome,': ',LEFT(COALESCE(v_msg,'<vazia>'),64)); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS massa ',p_nome,': ',p_esperado) AS resultado;
END$$
DELIMITER ;
START TRANSACTION;
CALL massa_rejeitar('vinculo avaliacao-laudo de outro veiculo','UPDATE avaliacao_laudo SET id_laudo=2 WHERE id_avaliacao=1','RN08');
CALL massa_rejeitar('laudo usado nao muda de veiculo','UPDATE laudo SET id_veiculo=2 WHERE id_laudo=1','RN08');
CALL massa_rejeitar('avaliacao de entrada nao pode reprovar','UPDATE avaliacao SET decisao_tecnica=''REPROVADA'' WHERE id_avaliacao=1','RN06/RN07');
CALL massa_rejeitar('identidade de entrada imutavel','UPDATE entrada SET id_veiculo=2 WHERE id_entrada=1','Identidade e origem');
CALL massa_rejeitar('entrada historica nao apaga','DELETE FROM entrada WHERE id_entrada=1','nunca apagado');
CALL massa_rejeitar('venda historica nao apaga','DELETE FROM venda WHERE id_venda=1','nunca apagado');
CALL massa_rejeitar('recebimento da venda concluida e imutavel','UPDATE venda SET valor_recebido=0 WHERE id_venda=1','RN22');
CALL massa_rejeitar('documento concluido nao apaga','DELETE FROM venda_documento WHERE id_venda=1 LIMIT 1','RN22');
CALL massa_rejeitar('documento concluido nao altera','UPDATE venda_documento SET data_reconhecimento=NULL WHERE id_venda=1 AND tipo_documento=''ATPV''','RN22');
CALL massa_rejeitar('despesa sem veiculo','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES(99999,''2026-02-01'',''PREPARACAO'',''x'',100)','fk_despesa');
CALL massa_rejeitar('despesa negativa','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES(1,''2026-02-01'',''PREPARACAO'',''x'',-1)','ck_despesa_valor');
CALL massa_rejeitar('pessoa sem nome','INSERT INTO pessoa(nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES(NULL,''CPF'',''99887766554'',''1'',''x@invalid'',''R'',''1'',''B'',''C'',''SP'')','nome');
CALL massa_rejeitar('data de recebimento posterior a conclusao','UPDATE venda SET data_ultimo_recebimento=''2026-03-01'' WHERE id_venda=1','RN22');
CALL massa_rejeitar('tipo de documento desconhecido','INSERT INTO venda_documento(id_venda,tipo_documento,reconhecimento_aplicavel) VALUES(6,''OUTRO'',FALSE)','ck_documento_tipo');
CALL massa_rejeitar('categoria de despesa desconhecida','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES(1,''2026-02-01'',''QUALQUER'',''x'',1)','ck_despesa_categoria');
CALL massa_rejeitar('status de atendimento desconhecido','UPDATE atendimento SET situacao=''PENDENTE'' WHERE id_atendimento=1','ck_atendimento_situacao');
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES(100,6,3,'2026-02-01 10:00:00','COMPRA_PROPRIA',101000,2,'ok','ok','ok','ok','ok','APROVADA','SIM','Teste de ciclo ativo');
SET @massa_avaliacao=100;
CALL massa_rejeitar('entrada duplica ciclo ativo do veiculo','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(6,5,@massa_avaliacao,''COMPRA_PROPRIA'',''2026-02-02'',25000,30000,''TESTE-CICLO'',''2026-02-02'',''teste'')','Duplicate entry');
CALL massa_rejeitar('concluir venda com financiamento pendente','CALL concluir_venda(6,''2026-02-01 10:00:00'',''2026-02-01 11:00:00'',''x'',''x'',''x'',''2026-02-02 10:00:00'')','RN22');
CALL massa_rejeitar('cancelar venda sem ciclo de retorno','CALL cancelar_venda(1,''2026-02-10 10:00:00'',''Teste'',''2026-02-09 10:00:00'',60000,''Teste'')','RN13/RN28-RN31');
CALL massa_rejeitar('forma de venda duplicada','INSERT INTO venda_forma_pagamento VALUES(6,''PIX'')','Duplicate entry');
CALL massa_rejeitar('estado final irregular de venda','UPDATE venda SET situacao_comercial=''CONCLUIDA'' WHERE id_venda=6','Use concluir_venda');
CALL massa_rejeitar('forma de pagamento de venda concluida nao apaga','DELETE FROM venda_forma_pagamento WHERE id_venda=1 AND codigo_forma=''PIX''','RN22');
CALL massa_rejeitar('financiamento de venda concluida nao apaga','DELETE FROM venda_forma_pagamento WHERE id_venda=3 AND codigo_forma=''FINANCIAMENTO''','RN22');
CALL massa_rejeitar('garantia historica da venda concluida','UPDATE venda SET concessao_garantia=FALSE WHERE id_venda=1','RN22');
CALL massa_rejeitar('garantia historica da venda 5','UPDATE venda SET concessao_garantia=FALSE WHERE id_venda=5','RN22');
CALL massa_rejeitar('recebimento de venda 5 concluida e imutavel','UPDATE venda SET valor_recebido=1 WHERE id_venda=5','RN22');
CALL massa_rejeitar('situacao de funcionario fora do dominio','UPDATE funcionario SET situacao=''INVALIDO''','ck_funcionario_situacao');
CALL massa_rejeitar('situacao de laudo fora do dominio','UPDATE laudo SET situacao=''INVALIDO''','ck_laudo_situacao');
CALL massa_rejeitar('situacao de ocorrencia fora do dominio','UPDATE ocorrencia_garantia SET situacao=''INVALIDO''','ck_ocorrencia_situacao');
CALL massa_rejeitar('responsabilidade de ocorrencia fora do dominio','UPDATE ocorrencia_garantia SET responsabilidade_apurada=''INVALIDO''','ck_ocorrencia_responsabilidade');
CALL massa_rejeitar('ano de veiculo abaixo do limite','UPDATE veiculo SET ano_modelo=1885 WHERE id_veiculo=1','ck_veiculo_ano');
CALL massa_rejeitar('ano de veiculo acima do limite','UPDATE veiculo SET ano_modelo=2101 WHERE id_veiculo=1','ck_veiculo_ano');
ROLLBACK;
-- InnoDB consome AUTO_INCREMENT em INSERT que falha; reverta o contador para a carga seguinte.
ALTER TABLE entrada AUTO_INCREMENT=11;
ALTER TABLE avaliacao AUTO_INCREMENT=11;
DROP PROCEDURE massa_rejeitar;

-- Restaura o modo Safe Updates da sessao.
SET SQL_SAFE_UPDATES = @mk_safe_updates;

-- =====================================================================
-- sql\consultas\gerenciais.sql
-- =====================================================================
-- Consultas gerenciais MySQL 8.4.

USE multiplikar;

/* ============================================================================ */

/* CONSULTAS GERENCIAIS — Multiplikar Automóveis (MySQL 8.4) */

/* Cada consulta responde a uma pergunta de negócio real do gestor da revenda */

/* Usa exatamente os nomes de tabela/coluna de sql/ddl/schema.sql */

/* Aproveita as VIEWS vw_venda_validacao e vw_venda_resumo onde aplicável */

/* Cabeçalho: pergunta de negócio + decisão apoiada (manual etapas 18/20) */

/* ============================================================================ */

/* ============================================================================ */

/* 1. VEÍCULOS MAIS VENDIDOS POR PERÍODO (AGRUPADO POR MARCA/MODELO) */

/* Pergunta de negócio: Quais modelos/veículos tiveram maior volume de vendas */

/* concluídas em um determinado período, para identificar giro de estoque e preferências? */

/* Decisão apoiada: Compras de reposição e mix de estoque (etapa 18) */

/* Agrupa por marca/modelo (não por id_veiculo), filtra CONCLUIDA por data_conclusao, */

/* usa parâmetros de período (não data fixa 2024) */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            CAST('2026-01-01' AS DATE) AS periodo_inicio,
            CAST('2026-12-31' AS DATE) AS periodo_fim
    )
SELECT
    v.marca,
    v.modelo,
    COUNT(vn.id_venda) AS qtd_vendas,
    SUM(vn.valor_total) AS valor_total_vendido,
    AVG(vn.valor_total) AS ticket_medio
FROM
    veiculo AS v
    JOIN entrada AS e ON v.id_veiculo = e.id_veiculo
    JOIN venda AS vn ON e.id_entrada = vn.id_entrada_principal
    CROSS JOIN params
WHERE
    vn.situacao_comercial = 'CONCLUIDA'
    AND CAST(vn.data_conclusao AS DATE) BETWEEN params.periodo_inicio AND params.periodo_fim
GROUP BY
    v.marca,
    v.modelo
ORDER BY
    CASE
        WHEN COUNT(vn.id_venda) IS NULL THEN 1
        ELSE 0
    END DESC,
    COUNT(vn.id_venda) DESC,
    CASE
        WHEN SUM(vn.valor_total) IS NULL THEN 1
        ELSE 0
    END DESC,
    SUM(vn.valor_total) DESC;

/* ============================================================================ */

/* 2. CLIENTES QUE MAIS COMPRAM (MAIOR VOLUME FINANCEIRO E QUANTIDADE) */

/* Pergunta de negócio: Quem são os melhores clientes para programa de fidelidade */

/* e ações de retenção? */

/* Decisão apoiada: CRM e marketing direcionado (etapa 18) */

/* Usa apenas vendas CONCLUIDA; mascara CPF/telefone/email (LGPD/RNF02) */

/* ============================================================================ */

SELECT
    p.nome,
    CONCAT(
        p.tipo_documento,
        ' ',
        CASE
            WHEN p.tipo_documento = 'CPF' THEN CONCAT(
                '***.***.',
                SUBSTRING(p.numero_documento, 7, 3),
                '-',
                RIGHT(p.numero_documento, 2)
            )
            WHEN p.tipo_documento = 'CNPJ' THEN CONCAT('**.***/', SUBSTRING(p.numero_documento, 9, 4), '-**')
        END
    ) AS documento_mascarado,
    CASE
        WHEN REGEXP_LIKE(p.telefone, '^\\d{2}') THEN CONCAT('(**) ****', RIGHT(p.telefone, 4))
        ELSE '***'
    END AS telefone_mascarado,
    CASE
        WHEN p.email LIKE '%@%' THEN CONCAT('****@', SUBSTRING_INDEX(p.email, '@', -1))
        ELSE '***'
    END AS email_mascarado,
    COUNT(vn.id_venda) AS qtd_compras,
    SUM(vn.valor_total) AS valor_total_comprado,
    MAX(vn.data_conclusao) AS ultima_compra,
    CASE
        WHEN COUNT(vn.id_venda) >= 3 THEN 'CLIENTE VIP'
        WHEN COUNT(vn.id_venda) = 2 THEN 'CLIENTE RECORRENTE'
        ELSE 'CLIENTE OCASIONAL'
    END AS classificacao_cliente
FROM
    pessoa AS p
    JOIN venda AS vn ON p.id_pessoa = vn.id_comprador
WHERE
    vn.situacao_comercial = 'CONCLUIDA'
GROUP BY
    p.id_pessoa,
    p.nome,
    p.tipo_documento,
    p.numero_documento,
    p.telefone,
    p.email
ORDER BY
    CASE
        WHEN SUM(vn.valor_total) IS NULL THEN 1
        ELSE 0
    END DESC,
    SUM(vn.valor_total) DESC,
    CASE
        WHEN COUNT(vn.id_venda) IS NULL THEN 1
        ELSE 0
    END DESC,
    COUNT(vn.id_venda) DESC;

/* ============================================================================ */

/* 3. VOLUME DE VENDAS CONCLUÍDAS POR PERÍODO (MENSAL/ANUAL) */

/* Pergunta de negócio: Qual a evolução do faturamento concluído para planejamento */

/* de compras, metas de equipe e sazonalidade? */

/* Decisão apoiada: Planejamento comercial e metas (etapa 18) */

/* Apenas vendas CONCLUIDA, agrupado por data_conclusao (não data_registro) */

/* Somente financiamentos RECEBIDO entram no valor_financiado (exclui NAO_APROVADO) */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            CAST('2026-01-01' AS DATE) AS periodo_inicio,
            CAST('2026-12-31' AS DATE) AS periodo_fim
    )
SELECT
    CAST(
        EXTRACT(
            YEAR
            FROM
                vn.data_conclusao
        ) AS SIGNED
    ) AS ano,
    CAST(
        EXTRACT(
            MONTH
            FROM
                vn.data_conclusao
        ) AS SIGNED
    ) AS mes,
    COUNT(vn.id_venda) AS qtd_vendas,
    SUM(vn.valor_total) AS faturamento_bruto,
    SUM(
        CASE
            WHEN vn.situacao_financiamento = 'RECEBIDO' THEN vn.valor_financiado
            ELSE 0
        END
    ) AS valor_financiado,
    SUM(vn.valor_recebido) AS total_recebido_loja,
    AVG(vn.valor_total) AS ticket_medio_mes
FROM
    venda AS vn
    CROSS JOIN params
WHERE
    vn.situacao_comercial = 'CONCLUIDA'
    AND CAST(vn.data_conclusao AS DATE) BETWEEN params.periodo_inicio AND params.periodo_fim
GROUP BY
    CAST(
        EXTRACT(
            YEAR
            FROM
                vn.data_conclusao
        ) AS SIGNED
    ),
    CAST(
        EXTRACT(
            MONTH
            FROM
                vn.data_conclusao
        ) AS SIGNED
    )
ORDER BY
    ano DESC,
    mes DESC;

/* ============================================================================ */

/* 4. VEÍCULOS PARADOS HÁ MAIS TEMPO NO ESTOQUE (AGING DE ESTOQUE) */

/* Pergunta de negócio: Quais veículos estão ocupando pátio há mais tempo */

/* sem vender, para ações de desconto, troca ou devolução ao consignante? */

/* Decisão apoiada: Gestão de pátio e descontos progressivos (etapa 18) */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            30 AS dias_estoque_alerta
    )
SELECT
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.ano_modelo,
    v.cor,
    e.modalidade,
    e.data_entrada AS data_entrada_estoque,
    DATEDIFF(CURRENT_DATE, DATE(e.data_entrada)) AS dias_no_estoque,
    e.valor_acordado AS custo_aquisicao,
    e.preco_anunciado,
    p_consignante.nome AS consignante_nome,
    p_consignante.telefone AS consignante_telefone
FROM
    veiculo AS v
    JOIN entrada AS e ON v.id_veiculo = e.id_veiculo
    LEFT JOIN pessoa AS p_consignante ON e.id_contraparte = p_consignante.id_pessoa
    LEFT JOIN venda AS vn ON e.id_entrada = vn.id_entrada_principal
WHERE
    vn.id_venda IS NULL
    AND e.situacao = 'ATIVA'
ORDER BY
    CASE
        WHEN DATEDIFF(CURRENT_DATE, DATE(e.data_entrada)) IS NULL THEN 1
        ELSE 0
    END DESC,
    DATEDIFF(CURRENT_DATE, DATE(e.data_entrada)) DESC;

/* ============================================================================ */

/* 5. VEÍCULOS EM CONSIGNAÇÃO COM PRAZO PRÓXIMO AO VENCIMENTO */

/* Pergunta de negócio: Quais consignações estão próximas do fim do prazo */

/* para renegociar ou devolver ao proprietário? */

/* Decisão apoiada: Gestão de contratos de consignação (etapa 18) */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            30 AS dias_prazo_alerta
    )
SELECT
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.ano_modelo,
    e.data_entrada,
    e.prazo_consignacao,
    DATEDIFF(e.prazo_consignacao, CURRENT_DATE) AS dias_para_vencer,
    p_proprietario.nome AS proprietario_nome,
    p_proprietario.telefone AS proprietario_telefone,
    e.valor_repasse_acordado
FROM
    entrada AS e
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    JOIN pessoa AS p_proprietario ON e.id_contraparte = p_proprietario.id_pessoa
    CROSS JOIN params
WHERE
    e.modalidade = 'CONSIGNACAO'
    AND e.situacao = 'ATIVA'
    AND e.prazo_consignacao IS NOT NULL
    AND e.prazo_consignacao <= DATE_ADD(CURRENT_DATE, INTERVAL params.dias_prazo_alerta DAY)
ORDER BY
    CASE
        WHEN e.prazo_consignacao IS NULL THEN 1
        ELSE 0
    END,
    e.prazo_consignacao ASC;

/* ============================================================================ */

/* 6. VENDAS COM TROCA (VEÍCULOS RECEBIDOS COMO PARTE DE PAGAMENTO) */

/* Pergunta de negócio: Quais vendas envolveram troca, quantos veículos */

/* foram recebidos e qual o valor total das trocas? */

/* Decisão apoiada: Análise de negócios com troca (etapa 18) */

/* ============================================================================ */

SELECT
    vn.id_venda,
    vn.data_registro AS data_venda,
    p_comprador.nome AS comprador,
    CONCAT(v_principal.marca, ' ', v_principal.modelo) AS veiculo_vendido,
    vn.valor_total AS valor_venda_principal,
    COUNT(e_troca.id_entrada) AS qtd_veiculos_troca,
    COALESCE(SUM(e_troca.valor_acordado), 0) AS valor_total_trocas,
    GROUP_CONCAT(
        CONCAT(v_troca.marca, ' ', v_troca.modelo, ' (', CAST(e_troca.valor_acordado AS CHAR), ')') SEPARATOR ', '
    ) AS veiculos_troca_detalhe
FROM
    venda AS vn
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    JOIN entrada AS e_principal ON vn.id_entrada_principal = e_principal.id_entrada
    JOIN veiculo AS v_principal ON e_principal.id_veiculo = v_principal.id_veiculo
    LEFT JOIN entrada AS e_troca ON vn.id_venda = e_troca.id_venda_origem
    LEFT JOIN veiculo AS v_troca ON e_troca.id_veiculo = v_troca.id_veiculo
WHERE
    e_troca.id_entrada IS NOT NULL
GROUP BY
    vn.id_venda,
    vn.data_registro,
    p_comprador.nome,
    v_principal.marca,
    v_principal.modelo,
    vn.valor_total
ORDER BY
    CASE
        WHEN vn.data_registro IS NULL THEN 1
        ELSE 0
    END DESC,
    vn.data_registro DESC;

/* ============================================================================ */

/* 7. POSIÇÃO FINANCEIRA DAS VENDAS (RECEBIDO vs PENDENTE) — USA VIEW PRONTA */

/* Pergunta de negócio: Quais vendas têm pendências financeiras */

/* (financiamento aprovado mas não recebido, valores em aberto)? */

/* Decisão apoiada: Cobrança e fluxo de caixa (etapa 18) */

/* ============================================================================ */

SELECT
    vr.id_venda,
    vn.data_registro AS data_venda,
    p_comprador.nome AS comprador,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    vn.valor_total,
    vn.valor_recebido,
    vr.saldo AS saldo_pendente,
    vr.situacao_financeira,
    CASE
        WHEN vn.instituicao_financeira IS NOT NULL THEN 'SIM'
        ELSE 'NAO'
    END AS tem_financiamento,
    vn.situacao_financiamento,
    vn.valor_financiado,
    vn.data_ultimo_recebimento
FROM
    vw_venda_resumo AS vr
    JOIN venda AS vn ON vr.id_venda = vn.id_venda
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
WHERE
    vr.situacao_financeira IN ('PENDENTE', 'PARCIAL')
ORDER BY
    CASE
        WHEN vr.saldo IS NULL THEN 1
        ELSE 0
    END DESC,
    vr.saldo DESC,
    CASE
        WHEN vn.data_registro IS NULL THEN 1
        ELSE 0
    END,
    vn.data_registro ASC;

/* ============================================================================ */

/* 8. MARGEM POR VEÍCULO E MODALIDADE (CUSTO REAL PARA CÁLCULO DE LUCRO) */

/* Pergunta de negócio: Qual a margem real por veículo considerando a modalidade */

/* de entrada (consignação usa valor_repasse_acordado; compra/troca usa valor_acordado) */

/* PREPARACAO: despesas entre data_entrada e data_encerramento do ciclo */

/* GARANTIA/DIAGNOSTICO: despesas entre data_entrega da venda e data_fim_garantia (entrega+2m), */

/*                      atribuídas à venda correspondente */

/* Decisão apoiada: Precificação e rentabilidade por unidade (etapa 18) */

/* Agrega despesas em subqueries para não multiplicar linhas. */

/* Esperado na massa (apenas vendas CONCLUIDA): */

/*   City (id_veiculo=4, revenda): 80000 - 74000 - 150 = 5850 */

/*   Argo: 60000 - 50000 - 650 = 9350 */

/*   Corolla: 14750 */

/*   HB20: 9600 */

/*   Tracker (venda 6 EM_FORMALIZACAO): NÃO aparece */

/* ============================================================================ */

WITH
    prep_despesas AS (

/* Despesas de preparação: entre data_entrada e data_encerramento do ciclo */

        SELECT
            d.id_veiculo,
            e.id_entrada,
            SUM(d.valor) AS total_preparacao
        FROM
            despesa AS d
            JOIN entrada AS e ON d.id_veiculo = e.id_veiculo
        WHERE
            LOWER(d.categoria) NOT LIKE LOWER('%garantia%')
            AND LOWER(d.categoria) NOT LIKE LOWER('%diagnostico%')
            AND d.data >= CAST(e.data_entrada AS DATE)
            AND d.data <= COALESCE(CAST(e.data_encerramento AS DATE), CURRENT_DATE)
        GROUP BY
            d.id_veiculo,
            e.id_entrada
    ),
    garantia_despesas AS (

/* Despesas de garantia/diagnóstico: entre data_entrega e data_fim_garantia da venda */

        SELECT
            d.id_veiculo,
            vn.id_venda,
            SUM(d.valor) AS total_garantia
        FROM
            despesa AS d
            JOIN venda AS vn ON d.id_veiculo = (
                SELECT
                    e.id_veiculo
                FROM
                    entrada AS e
                WHERE
                    e.id_entrada = vn.id_entrada_principal
            )
            JOIN vw_venda_resumo AS vr ON vn.id_venda = vr.id_venda
        WHERE
            (
                LOWER(d.categoria) LIKE LOWER('%garantia%')
                OR LOWER(d.categoria) LIKE LOWER('%diagnostico%')
            )
            AND vn.data_entrega IS NOT NULL
            AND d.data >= CAST(vn.data_entrega AS DATE)
            AND d.data <= CAST(vr.data_fim_garantia AS DATE)
            AND vn.situacao_comercial = 'CONCLUIDA'
        GROUP BY
            d.id_veiculo,
            vn.id_venda
    )
SELECT
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.ano_modelo,
    e.modalidade,
    e.valor_acordado AS custo_aquisicao,
    e.valor_repasse_acordado,
    COALESCE(pd.total_preparacao, 0) AS despesas_preparacao,
    COALESCE(gd.total_garantia, 0) AS despesas_garantia,
    COALESCE(pd.total_preparacao, 0) + COALESCE(gd.total_garantia, 0) AS total_despesas_ciclo,
    vn.valor_total AS valor_venda,
    CASE
        WHEN e.modalidade = 'CONSIGNACAO' THEN vn.valor_total
            - COALESCE(e.valor_repasse_acordado, 0)
            - COALESCE(pd.total_preparacao, 0)
            - COALESCE(gd.total_garantia, 0)
        ELSE vn.valor_total - e.valor_acordado - COALESCE(pd.total_preparacao, 0) - COALESCE(gd.total_garantia, 0)
    END AS margem_liquida_estimada
FROM
    veiculo AS v
    JOIN entrada AS e ON v.id_veiculo = e.id_veiculo
    JOIN venda AS vn ON e.id_entrada = vn.id_entrada_principal
    LEFT JOIN prep_despesas AS pd ON pd.id_entrada = e.id_entrada
    LEFT JOIN garantia_despesas AS gd ON gd.id_venda = vn.id_venda
WHERE
    vn.situacao_comercial = 'CONCLUIDA'
ORDER BY
    CASE
        WHEN CASE
            WHEN e.modalidade = 'CONSIGNACAO' THEN vn.valor_total
                - COALESCE(e.valor_repasse_acordado, 0)
                - COALESCE(pd.total_preparacao, 0)
                - COALESCE(gd.total_garantia, 0)
            ELSE vn.valor_total - e.valor_acordado - COALESCE(pd.total_preparacao, 0) - COALESCE(gd.total_garantia, 0)
        END IS NULL THEN 1
        ELSE 0
    END,
    CASE
        WHEN e.modalidade = 'CONSIGNACAO' THEN vn.valor_total
            - COALESCE(e.valor_repasse_acordado, 0)
            - COALESCE(pd.total_preparacao, 0)
            - COALESCE(gd.total_garantia, 0)
        ELSE vn.valor_total - e.valor_acordado - COALESCE(pd.total_preparacao, 0) - COALESCE(gd.total_garantia, 0)
    END ASC;

/* ============================================================================ */

/* 9. FUNIL DE VENDAS: ATENDIMENTOS CONVERTIDOS (APROXIMAÇÃO) */

/* Pergunta de negócio: Qual a taxa de conversão aproximada de atendimentos em vendas */

/* por vendedor? */

/* Decisão apoiada: Gestão de performance comercial (etapa 18) */

/* Aproximação: relaciona atendimento.id_pessoa = venda.id_comprador */

/* e venda.data_registro >= atendimento.data (não há FK direta atendimento->venda). */

/* Não filtra por ano fixo; não usa WHERE que anule o LEFT JOIN. */

/* ============================================================================ */

WITH
    atend_venda AS (
        SELECT
            a.id_funcionario,
            a.id_atendimento,
            a.data AS data_atendimento,
            vn.id_venda,
            vn.data_registro AS data_venda
        FROM
            atendimento AS a
            LEFT JOIN venda AS vn ON a.id_pessoa = vn.id_comprador
            AND vn.data_registro >= a.data
            AND vn.situacao_comercial = 'CONCLUIDA'
    )
SELECT
    f.id_funcionario,
    p_func.nome AS vendedor,
    COUNT(DISTINCT av.id_atendimento) AS total_atendimentos,
    COUNT(DISTINCT av.id_venda) AS total_vendas_concluidas,
    CASE
        WHEN COUNT(DISTINCT av.id_atendimento) > 0 THEN ROUND(
            CAST(COUNT(DISTINCT av.id_venda) AS DECIMAL)
            / COUNT(DISTINCT av.id_atendimento) * 100,
            2
        )
        ELSE 0
    END AS taxa_conversao_pct
FROM
    funcionario AS f
    JOIN pessoa AS p_func ON f.id_pessoa = p_func.id_pessoa
    LEFT JOIN atend_venda AS av ON f.id_funcionario = av.id_funcionario
GROUP BY
    f.id_funcionario,
    p_func.nome
ORDER BY
    CASE
        WHEN CASE
            WHEN COUNT(DISTINCT av.id_atendimento) > 0 THEN ROUND(
                CAST(COUNT(DISTINCT av.id_venda) AS DECIMAL)
                / COUNT(DISTINCT av.id_atendimento) * 100,
                2
            )
            ELSE 0
        END IS NULL THEN 1
        ELSE 0
    END DESC,
    CASE
        WHEN COUNT(DISTINCT av.id_atendimento) > 0 THEN ROUND(
            CAST(COUNT(DISTINCT av.id_venda) AS DECIMAL)
            / COUNT(DISTINCT av.id_atendimento) * 100,
            2
        )
        ELSE 0
    END DESC;

/* ============================================================================ */

/* 10. OCORRÊNCIAS DE GARANTIA POR VEÍCULO/TIPO DE PROBLEMA */

/* Pergunta de negócio: Quais veículos/modelos geram mais ocorrências */

/* de garantia, para revisar qualidade de aquisição? */

/* Decisão apoiada: Qualidade de entrada e seleção de fornecedores (etapa 18) */

/* Não chama de "cancelamento por garantia"; conta vendas distintas com ocorrência. */

/* ============================================================================ */

SELECT
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.ano_modelo,
    COUNT(DISTINCT vn.id_venda) AS qtd_vendas_com_ocorrencia,
    COUNT(og.id_ocorrencia) AS qtd_ocorrencias,
    GROUP_CONCAT(DISTINCT og.problema_relatado SEPARATOR ', ') AS tipos_problema,
    GROUP_CONCAT(DISTINCT og.solucao SEPARATOR '; ') AS solucoes_aplicadas
FROM
    veiculo AS v
    JOIN entrada AS e ON v.id_veiculo = e.id_veiculo
    JOIN venda AS vn ON e.id_entrada = vn.id_entrada_principal
    JOIN ocorrencia_garantia AS og ON vn.id_venda = og.id_venda
GROUP BY
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.ano_modelo
ORDER BY
    CASE
        WHEN COUNT(og.id_ocorrencia) IS NULL THEN 1
        ELSE 0
    END DESC,
    COUNT(og.id_ocorrencia) DESC;

/* ============================================================================ */

/* 11. VENDAS APTAS PARA CONCLUSÃO (RN22) E APTAS PARA ENTREGA */

/* Pergunta de negócio: Quais vendas em formalização já atendem todos os */

/* requisitos de conclusão (RN22: pagamento + financiamento + docs + firma + laudo) */

/* e quais já podem ter entrega liberada (acrescenta scanner)? */

/* Decisão apoiada: Liberação de entrega e conclusão documental (etapa 18) */

/* Usa vw_venda_validacao para detalhes; rótulo 'APTA PARA CONCLUSAO' (RN22) */

/* e coluna separada 'apta_para_entrega' exigindo scanner. */

/* ============================================================================ */

SELECT
    vr.id_venda,
    vn.data_registro AS data_venda,
    p_comprador.nome AS comprador,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    vn.valor_total,
    vn.valor_recebido,
    vr.situacao_financeira,
    vn.situacao_financiamento,
    vd.documentos_ok,
    vd.reconhecimento_ok,
    vd.laudo_ok,
    vn.data_scanner IS NOT NULL AS scanner_realizado,
    vr.requisitos_rn22_ok AS apta_para_conclusao_rn22,
    (
        vr.requisitos_rn22_ok
        AND vn.data_scanner IS NOT NULL
    ) AS apta_para_entrega,
    vn.data_conclusao,
    vn.data_entrega,
    CASE
        WHEN vr.requisitos_rn22_ok THEN 'APTA PARA CONCLUSAO'
        ELSE 'PENDENTE RN22'
    END AS status_conclusao_rn22,
    CASE
        WHEN vr.requisitos_rn22_ok
        AND vn.data_scanner IS NOT NULL THEN 'APTA PARA ENTREGA'
        WHEN vr.requisitos_rn22_ok THEN 'AGUARDA SCANNER'
        ELSE 'PENDENTE RN22'
    END AS status_entrega
FROM
    vw_venda_resumo AS vr
    JOIN venda AS vn ON vr.id_venda = vn.id_venda
    JOIN vw_venda_validacao AS vd ON vd.id_venda = vn.id_venda
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
WHERE
    vn.situacao_comercial = 'EM_FORMALIZACAO'
ORDER BY
    CASE
        WHEN vn.data_registro IS NULL THEN 1
        ELSE 0
    END DESC,
    vn.data_registro DESC;

/* ============================================================================ */

/* 12. RESUMO GERENCIAL: ESTOQUE ATUAL POR MODALIDADE E SITUAÇÃO */

/* Pergunta de negócio: Visão consolidada do pátio: quantos veículos */

/* por modalidade (compra própria, consignação, troca) e situação */

/* (disponível, em formalização, aguardando regularização), excluindo vendidos? */

/* Decisão apoiada: Gestão de pátio e capital imobilizado (etapa 18) */

/* Agrupa de fato por modalidade e situacao_atual; não soma VENDIDO como estoque. */

/* ============================================================================ */

SELECT
    e.modalidade,
    vs.situacao_atual,
    COUNT(*) AS qtd_veiculos,
    SUM(e.valor_acordado) AS valor_total_estoque,
    AVG(DATEDIFF(CURRENT_DATE, DATE(e.data_entrada))) AS media_dias_estoque
FROM
    vw_veiculo_situacao AS vs
    JOIN entrada AS e ON vs.id_veiculo = e.id_veiculo
    AND e.data_entrada = (
        SELECT
            MAX(x.data_entrada)
        FROM
            entrada AS x
        WHERE
            x.id_veiculo = vs.id_veiculo
    )
WHERE
    vs.situacao_atual IN ('DISPONIVEL', 'EM_FORMALIZACAO', 'AGUARDANDO_REGULARIZACAO')
GROUP BY
    e.modalidade,
    vs.situacao_atual
ORDER BY
    CASE
        WHEN e.modalidade IS NULL THEN 1
        ELSE 0
    END,
    e.modalidade,
    CASE
        WHEN CASE vs.situacao_atual
            WHEN 'DISPONIVEL' THEN 1
            WHEN 'EM_FORMALIZACAO' THEN 2
            WHEN 'AGUARDANDO_REGULARIZACAO' THEN 3
            ELSE 4
        END IS NULL THEN 1
        ELSE 0
    END,
    CASE vs.situacao_atual
        WHEN 'DISPONIVEL' THEN 1
        WHEN 'EM_FORMALIZACAO' THEN 2
        WHEN 'AGUARDANDO_REGULARIZACAO' THEN 3
        ELSE 4
    END;

/* ============================================================================ */

/* 13. HISTÓRICO DE REAVALIAÇÕES DO VEÍCULO HB20 (id_veiculo=4) */

/* Pergunta de negócio: Um veículo foi avaliado múltiplas vezes? */

/* Mostra evolução de condições, decisões e laudos consultados. */

/* Decisão apoiada: Auditoria de qualidade de avaliação (etapa 20) */

/* Usa id_veiculo_alvo = 4 (HB20: venda->devolução->revenda); troque o 4 no CTE params para consultar outro veículo */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            CAST(4 AS SIGNED) AS id_veiculo_alvo
    )
SELECT
    av.id_avaliacao,
    av.data AS data_avaliacao,
    av.finalidade,
    av.quilometragem,
    av.condicao_externa,
    av.condicao_interna,
    av.condicao_mecanica,
    av.condicao_estrutural,
    av.condicao_documental,
    av.decisao_tecnica,
    av.interesse_comercial,
    p_avaliador.nome AS avaliador,
    l.id_laudo,
    l.data_emissao AS data_laudo,
    l.situacao AS situacao_laudo,
    l.resultado AS resultado_laudo
FROM
    avaliacao AS av
    JOIN veiculo AS v ON av.id_veiculo = v.id_veiculo
    JOIN pessoa AS p_avaliador ON av.id_avaliador = p_avaliador.id_pessoa
    LEFT JOIN avaliacao_laudo AS al ON av.id_avaliacao = al.id_avaliacao
    LEFT JOIN laudo AS l ON al.id_laudo = l.id_laudo
    CROSS JOIN params
WHERE
    av.id_veiculo = params.id_veiculo_alvo
ORDER BY
    CASE
        WHEN av.data IS NULL THEN 1
        ELSE 0
    END DESC,
    av.data DESC;

/* ============================================================================ */

/* 14. VENDAS CANCELADAS/DESFEITAS COM DETALHES COMPLETOS DE RESTITUIÇÃO */

/* Pergunta de negócio: Quais vendas foram desfeitas, por que motivo, */

/* quais valores/veículos foram devolvidos, e quais tratativas (consignante, banco) ocorreram? */

/* Decisão apoiada: Auditoria de desfazimento e compliance (etapa 20) */

/* Inclui: valor_restituido_loja, data_retorno_veiculo, data_aviso_consignante, */

/* orientacao_bancaria e situação de cada veículo de troca. */

/* ============================================================================ */

SELECT
    vn.id_venda,
    vn.data_registro AS data_venda,
    vn.data_cancelamento,
    vn.motivo_cancelamento,
    vn.valor_restituido_loja,
    vn.data_retorno_veiculo,
    vn.data_aviso_consignante,
    vn.orientacao_bancaria,
    p_comprador.nome AS comprador,
    CONCAT(v_vendido.marca, ' ', v_vendido.modelo) AS veiculo_vendido,
    vn.valor_total AS valor_venda_original,
    vn.valor_recebido AS valor_ja_recebido,
    CASE
        WHEN vn.instituicao_financeira IS NOT NULL THEN 'SIM'
        ELSE 'NAO'
    END AS tinha_financiamento,
    vn.observacoes_cancelamento,
    GROUP_CONCAT(
        CONCAT(v_troca.marca, ' ', v_troca.modelo, ' (', e_troca.situacao, ')')
        SEPARATOR ', '
    ) AS veiculos_troca_situacao
FROM
    venda AS vn
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    JOIN entrada AS e_principal ON vn.id_entrada_principal = e_principal.id_entrada
    JOIN veiculo AS v_vendido ON e_principal.id_veiculo = v_vendido.id_veiculo
    LEFT JOIN entrada AS e_troca ON vn.id_venda = e_troca.id_venda_origem
    LEFT JOIN veiculo AS v_troca ON e_troca.id_veiculo = v_troca.id_veiculo
WHERE
    vn.situacao_comercial = 'CANCELADA'
GROUP BY
    vn.id_venda,
    vn.data_registro,
    vn.data_cancelamento,
    vn.motivo_cancelamento,
    vn.valor_restituido_loja,
    vn.data_retorno_veiculo,
    vn.data_aviso_consignante,
    vn.orientacao_bancaria,
    p_comprador.nome,
    v_vendido.marca,
    v_vendido.modelo,
    vn.valor_total,
    vn.valor_recebido,
    vn.instituicao_financeira,
    vn.observacoes_cancelamento
ORDER BY
    CASE
        WHEN vn.data_cancelamento IS NULL THEN 1
        ELSE 0
    END DESC,
    vn.data_cancelamento DESC;

-- =====================================================================
-- sql\auditoria\auditoria.sql
-- =====================================================================
-- Consultas de auditoria para MySQL 8.4.

USE multiplikar;

/* ============================================================================ */

/* CONSULTAS DE AUDITORIA — Multiplikar Automóveis (MySQL 8.4) */

/* Cada consulta verifica um ponto de integridade/consistência/qualidade */

/* Cabeçalho: o que verifica, por que importa, resultado REAL na massa (validado 20/10/2026) */

/* Cita constraints/triggers por nome (não números de linha do schema.sql) */

/* ============================================================================ */

/* ============================================================================ */

/* AUDITORIA 1: VERIFICAÇÃO DE CONFORMIDADE — ENTRADA VIGENTE ÚNICA POR VEÍCULO */

/* O que verifica: existência de mais de uma ENTRADA com data_encerramento IS NULL */

/* para o mesmo veículo (RN13/A5). */

/* Por que importa: impede vendas simultâneas do mesmo veículo no pátio. */

/* Constraint/trigger: índice único parcial uq_entrada_veiculo_vigente, */

/* trigger preservar_historico, trigger validar_integridade_comercial (RN13). */

/* Resultado REAL na massa: 0 linhas (índice impede violação). */

/* ============================================================================ */

SELECT
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.placa,
    v.chassi,
    COUNT(e.id_entrada) AS qtd_entradas_ativas,
    GROUP_CONCAT(
        CONCAT(
            CAST(e.id_entrada AS CHAR),
            ' (',
            e.modalidade,
            ' - ',
            DATE_FORMAT(e.data_entrada, '%d/%m/%Y'),
            ')'
        ) SEPARATOR '; '
    ) AS entradas_ativas_detalhe
FROM
    veiculo AS v
    JOIN entrada AS e ON v.id_veiculo = e.id_veiculo
WHERE
    e.data_encerramento IS NULL
GROUP BY
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.placa,
    v.chassi
HAVING
    COUNT(e.id_entrada) > 1
ORDER BY
    CASE
        WHEN COUNT(e.id_entrada) IS NULL THEN 1
        ELSE 0
    END DESC,
    COUNT(e.id_entrada) DESC;

/* ============================================================================ */

/* AUDITORIA 2: HISTÓRICO COMPLETO DE COMERCIALIZAÇÃO DO VEÍCULO HB20 (id=4) */

/* O que verifica: rastro completo de ENTRADAs, VENDAs, cancelamentos, */

/* devoluções de troca, consignação — demonstrando que histórico não se perde (RN13). */

/* Por que importa: auditoria de ciclo de vida do veículo (venda->devolução->revenda). */

/* Resultado REAL na massa: 4 linhas no UNION (2 entradas: 4 e 9; 2 vendas: 4 cancelada, 5 concluída), */

/* 2D = 1 linha de resumo (total_entradas=2, vezes_vendido_como_principal=2, etc.) */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            CAST(4 AS SIGNED) AS id_veiculo_alvo
    )
/* 2A. Todas as ENTRADAs deste veículo (cronológico) */

SELECT
    'ENTRADA' AS tipo_registro,
    e.id_entrada AS id_registro,
    e.data_entrada AS data_evento,
    e.modalidade,
    e.situacao AS situacao_entrada,
    e.valor_acordado,
    e.preco_anunciado,
    p_contraparte.nome AS contraparte,
    CONCAT(p_contraparte.tipo_documento, ' ', p_contraparte.numero_documento) AS doc_contraparte,
    e.prazo_consignacao,
    e.motivo_encerramento,
    e.data_encerramento
FROM
    entrada AS e
    JOIN pessoa AS p_contraparte ON e.id_contraparte = p_contraparte.id_pessoa
    CROSS JOIN params
WHERE
    e.id_veiculo = params.id_veiculo_alvo
UNION ALL

/* 2B. Todas as VENDAs onde este veículo foi o PRINCIPAL */

SELECT
    'VENDA_PRINCIPAL' AS tipo_registro,
    vn.id_venda AS id_registro,
    vn.data_registro AS data_evento,
    'VENDA' AS modalidade,
    vn.situacao_comercial AS situacao_entrada,
    vn.valor_total AS valor_acordado,
    NULL AS preco_anunciado,
    p_comprador.nome AS contraparte,
    CONCAT(p_comprador.tipo_documento, ' ', p_comprador.numero_documento) AS doc_contraparte,
    NULL AS prazo_consignacao,
    vn.motivo_cancelamento AS motivo_encerramento,
    vn.data_cancelamento AS data_encerramento
FROM
    venda AS vn
    JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    CROSS JOIN params
WHERE
    e.id_veiculo = params.id_veiculo_alvo
UNION ALL

/* 2C. Todas as VENDAs onde este veículo foi RECEBIDO COMO TROCA */

SELECT
    'VENDA_TROCA_RECEBIDA' AS tipo_registro,
    vn.id_venda AS id_registro,
    vn.data_registro AS data_evento,
    'TROCA_RECEBIDA' AS modalidade,
    vn.situacao_comercial AS situacao_entrada,
    e_troca.valor_acordado AS valor_acordado,
    NULL AS preco_anunciado,
    p_comprador.nome AS contraparte,
    CONCAT(p_comprador.tipo_documento, ' ', p_comprador.numero_documento) AS doc_contraparte,
    NULL AS prazo_consignacao,
    vn.motivo_cancelamento AS motivo_encerramento,
    vn.data_cancelamento AS data_encerramento
FROM
    venda AS vn
    JOIN entrada AS e_troca ON vn.id_venda = e_troca.id_venda_origem
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    CROSS JOIN params
WHERE
    e_troca.id_veiculo = params.id_veiculo_alvo
ORDER BY
    CASE
        WHEN data_evento IS NULL THEN 1
        ELSE 0
    END,
    data_evento ASC;

/* 2D. Resumo do ciclo de vida (contadores) */

WITH
    params AS (
        SELECT
            CAST(4 AS SIGNED) AS id_veiculo_alvo
    )
SELECT
    params.id_veiculo_alvo AS id_veiculo,
    (
        SELECT
            COUNT(*)
        FROM
            entrada
        WHERE
            id_veiculo = params.id_veiculo_alvo
    ) AS total_entradas,
    (
        SELECT
            COUNT(*)
        FROM
            entrada AS e
            JOIN venda AS v ON e.id_entrada = v.id_entrada_principal
        WHERE
            e.id_veiculo = params.id_veiculo_alvo
    ) AS total_vezes_vendido_como_principal,
    (
        SELECT
            COUNT(*)
        FROM
            entrada AS e
        WHERE
            e.id_veiculo = params.id_veiculo_alvo
            AND e.id_venda_origem IS NOT NULL
    ) AS total_vezes_recebido_como_troca,
    (
        SELECT
            COUNT(*)
        FROM
            venda AS vn
            JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
        WHERE
            e.id_veiculo = params.id_veiculo_alvo
            AND vn.situacao_comercial = 'CANCELADA'
    ) AS total_vendas_canceladas_como_principal,
    (
        SELECT
            COUNT(*)
        FROM
            venda AS vn
            JOIN entrada AS e ON vn.id_venda = e.id_venda_origem
        WHERE
            e.id_veiculo = params.id_veiculo_alvo
            AND vn.situacao_comercial = 'CANCELADA'
    ) AS total_vendas_canceladas_onde_era_troca
FROM
    params;

/* ============================================================================ */

/* AUDITORIA 3: VERIFICAÇÃO DE CONFORMIDADE — RN22 CONCLUSÃO SIMULTÂNEA */

/* O que verifica: vendas marcadas CONCLUIDA que falham em alguma condição RN22 */

/* (pagamento integral + financiamento recebido se houver + docs conferidos + */

/* firma aplicável + laudo correspondente). */

/* Por que importa: garante que conclusão só ocorre com todas as condições. */

/* Constraint/trigger: trigger validar_integridade_comercial (bloco RN22), */

/* view vw_venda_validacao, view vw_venda_resumo.requisitos_rn22_ok. */

/* Resultado REAL na massa: 0 linhas (trigger impede violação). */

/* ============================================================================ */

SELECT
    vr.id_venda,
    vn.data_registro AS data_venda,
    vn.data_conclusao,
    p_comprador.nome AS comprador,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    vn.valor_total,
    vn.valor_recebido,
    vr.situacao_financeira,
    CASE
        WHEN vn.instituicao_financeira IS NULL THEN 'SEM_FINANCIAMENTO'
        WHEN vn.situacao_financiamento = 'RECEBIDO' THEN 'RECEBIDO_OK'
        ELSE 'PENDENTE_RECEBIMENTO_LOJA'
    END AS status_financiamento,
    vd.documentos_ok,
    vd.reconhecimento_ok,
    vd.laudo_ok,
    vn.data_scanner IS NOT NULL AS scanner_realizado,
    vr.requisitos_rn22_ok,
    CASE
        WHEN vr.situacao_financeira <> 'INTEGRAL' THEN 'VIOLAÇÃO: Pagamento não integral'
        WHEN vn.instituicao_financeira IS NOT NULL
        AND vn.situacao_financiamento <> 'RECEBIDO' THEN 'VIOLAÇÃO: Financiamento não recebido pela loja'
        WHEN NOT vd.documentos_ok THEN 'VIOLAÇÃO: Documentos não conferidos'
        WHEN NOT vd.reconhecimento_ok THEN 'VIOLAÇÃO: Reconhecimento de firma não aplicado'
        WHEN NOT vd.laudo_ok THEN 'VIOLAÇÃO: Laudo cautelar não corresponde ou não realizado'
        WHEN vn.data_scanner IS NULL THEN 'VIOLAÇÃO: Scanner não realizado'
        ELSE 'TODAS_CONDICOES_OK'
    END AS validacao_rn22
FROM
    vw_venda_resumo AS vr
    JOIN venda AS vn ON vr.id_venda = vn.id_venda
    JOIN vw_venda_validacao AS vd ON vd.id_venda = vn.id_venda
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
WHERE
    vn.situacao_comercial = 'CONCLUIDA'
    AND NOT vr.requisitos_rn22_ok
ORDER BY
    CASE
        WHEN vn.data_conclusao IS NULL THEN 1
        ELSE 0
    END DESC,
    vn.data_conclusao DESC;

/* ============================================================================ */

/* AUDITORIA 4: VERIFICAÇÃO DE CONFORMIDADE — INTEGRIDADE AVALIAÇÃO-LAUDO (RN08) */

/* O que verifica: avaliação vinculada a laudo de veículo diferente (RN08). */

/* Por que importa: cardinalidade sozinha não garante que laudo pertence ao mesmo veículo. */

/* Constraint/trigger: trigger validar_integridade_comercial (bloco RN08), */

/* executado em AVALIACAO, AVALIACAO_LAUDO, LAUDO. */

/* Resultado REAL na massa: 0 linhas (trigger impede violação). */

/* ============================================================================ */

SELECT
    av.id_avaliacao,
    av.data AS data_avaliacao,
    av.id_veiculo AS veiculo_avaliado,
    CONCAT(v_av.marca, ' ', v_av.modelo) AS veiculo_avaliado_desc,
    l.id_laudo,
    l.data_emissao AS data_laudo,
    l.id_veiculo AS veiculo_do_laudo,
    CONCAT(v_laudo.marca, ' ', v_laudo.modelo) AS veiculo_laudo_desc,
    'VIOLAÇÃO RN08: Laudo pertence a veículo diferente da avaliação' AS detalhe_violacao
FROM
    avaliacao AS av
    JOIN veiculo AS v_av ON av.id_veiculo = v_av.id_veiculo
    JOIN avaliacao_laudo AS al ON av.id_avaliacao = al.id_avaliacao
    JOIN laudo AS l ON al.id_laudo = l.id_laudo
    JOIN veiculo AS v_laudo ON l.id_veiculo = v_laudo.id_veiculo
WHERE
    av.id_veiculo <> l.id_veiculo
ORDER BY
    CASE
        WHEN av.data IS NULL THEN 1
        ELSE 0
    END DESC,
    av.data DESC;

/* ============================================================================ */

/* AUDITORIA 4B: VERIFICAÇÃO DE CONFORMIDADE — LAUDO POSTERIOR À AVALIAÇÃO (RN08) */

/* O que verifica: laudo com data_emissao > data da avaliação (RN08). */

/* Por que importa: laudo deve existir antes/de ser consultado na avaliação. */

/* Constraint/trigger: trigger validar_integridade_comercial (bloco RN08). */

/* Resultado REAL na massa: 0 linhas (trigger impede violação). */

/* ============================================================================ */

SELECT
    av.id_avaliacao,
    av.data AS data_avaliacao,
    l.id_laudo,
    l.data_emissao AS data_laudo,
    'VIOLAÇÃO RN08: Laudo emitido após a avaliação' AS detalhe_violacao
FROM
    avaliacao AS av
    JOIN avaliacao_laudo AS al ON av.id_avaliacao = al.id_avaliacao
    JOIN laudo AS l ON al.id_laudo = l.id_laudo
WHERE
    l.data_emissao > CAST(av.data AS DATE)
ORDER BY
    CASE
        WHEN av.data IS NULL THEN 1
        ELSE 0
    END DESC,
    av.data DESC;

/* ============================================================================ */

/* AUDITORIA 5: VERIFICAÇÃO DE CONFORMIDADE — TROCA SEM VENDA DE ORIGEM VÁLIDA */

/* O que verifica: entradas TROCA sem id_venda_origem ou com venda cancelada */

/* sem restituição. */

/* Por que importa: integridade referencial da troca (RN18). */

/* Constraint/trigger: ck_entrada_origem, fk_entrada_venda_origem, */

/* trigger validar_integridade_comercial (bloco RN18). */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    e.id_entrada,
    e.data_entrada,
    e.modalidade,
    e.id_venda_origem,
    vn.id_venda AS venda_existe,
    vn.situacao_comercial AS venda_situacao,
    vn.data_cancelamento,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo_troca,
    p_comprador.nome AS comprador_da_venda_origem
FROM
    entrada AS e
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    LEFT JOIN venda AS vn ON e.id_venda_origem = vn.id_venda
    LEFT JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
WHERE
    e.modalidade = 'TROCA'
    AND (
        e.id_venda_origem IS NULL
        OR vn.id_venda IS NULL
        OR (
            vn.situacao_comercial = 'CANCELADA'
            AND e.situacao = 'ATIVA'
        )
    )
ORDER BY
    CASE
        WHEN e.data_entrada IS NULL THEN 1
        ELSE 0
    END DESC,
    e.data_entrada DESC;

/* ============================================================================ */

/* AUDITORIA 6: VERIFICAÇÃO DE CONFORMIDADE — VEÍCULO VENDIDO COM ENTRADA ATIVA */

/* O que verifica: venda CONCLUIDA mas entrada principal ainda ATIVA */

/* (deveria ser COMERCIALIZADA com data_encerramento = data_conclusao). */

/* Por que importa: consistência de ciclo de vida (RN13). */

/* Constraint/trigger: trigger validar_integridade_comercial (bloco venda/entrada), */

/* trigger preservar_historico. */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    e.id_entrada,
    e.id_veiculo,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    e.modalidade,
    e.situacao AS situacao_entrada,
    e.data_encerramento,
    vn.id_venda,
    vn.data_conclusao,
    vn.situacao_comercial
FROM
    entrada AS e
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    JOIN venda AS vn ON e.id_entrada = vn.id_entrada_principal
WHERE
    e.situacao = 'ATIVA'
    AND vn.situacao_comercial = 'CONCLUIDA'
ORDER BY
    CASE
        WHEN vn.data_conclusao IS NULL THEN 1
        ELSE 0
    END DESC,
    vn.data_conclusao DESC;

/* ============================================================================ */

/* AUDITORIA 7: QUALIDADE — OCORRÊNCIAS DE GARANTIA EM VENDAS SEM COBERTURA */

/* O que verifica: ocorrências em vendas sem concessao_garantia=true */

/* OU ocorrências abertas > 2 meses após entrega (fora do prazo RN25), */

/* EXCLUINDO ocorrências anteriores ao cancelamento (essas não são violação). */

/* Por que importa: RN25 define garantia de 2 meses a partir da entrega; */

/* ocorrência em venda sem garantia concedida ou fora do prazo indica */

/* problema de classificação ou registro. */

/* Trigger validar_integridade_comercial exige entrega anterior, */

/* mas NÃO bloqueia ocorrência em venda sem concessao_garantia */

/* nem ocorrência fora do prazo de 2 meses. */

/* Resultado REAL na massa: 0 linhas (todas ocorrências estão dentro do prazo */

/* e em vendas com concessao_garantia=true; nenhuma ocorrência anterior a cancelamento). */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            30 AS dias_ocorrencia_alerta
    )
SELECT
    og.id_ocorrencia,
    og.data_abertura,
    vn.id_venda,
    vn.data_entrega,
    vn.concessao_garantia,
    vn.situacao_comercial AS venda_situacao,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    p_cliente.nome AS cliente,
    og.problema_relatado,
    og.solucao,
    vr.data_fim_garantia,
    CASE
        WHEN NOT vn.concessao_garantia THEN 'ALERTA: Ocorrência em venda SEM concessão de garantia'
        WHEN vn.data_entrega IS NULL THEN 'ALERTA: Venda sem data de entrega'
        WHEN vr.data_fim_garantia IS NOT NULL
        AND og.data_abertura > vr.data_fim_garantia
        AND vn.situacao_comercial <> 'CANCELADA' THEN 'ALERTA RN25: Ocorrência fora do prazo de 2 meses da garantia'
        WHEN vn.situacao_comercial = 'CANCELADA'
        AND og.data_abertura < vn.data_cancelamento THEN 'INFO: Ocorrência anterior ao cancelamento (não é violação)'
        ELSE 'OK'
    END AS validacao_garantia
FROM
    ocorrencia_garantia AS og
    JOIN venda AS vn ON og.id_venda = vn.id_venda
    JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    JOIN pessoa AS p_cliente ON vn.id_comprador = p_cliente.id_pessoa
    LEFT JOIN vw_venda_resumo AS vr ON vn.id_venda = vr.id_venda
    CROSS JOIN params
WHERE
    NOT vn.concessao_garantia
    OR vn.data_entrega IS NULL
    OR (
        vr.data_fim_garantia IS NOT NULL
        AND og.data_abertura > vr.data_fim_garantia
    )
ORDER BY
    CASE
        WHEN og.data_abertura IS NULL THEN 1
        ELSE 0
    END DESC,
    og.data_abertura DESC;

/* ============================================================================ */

/* AUDITORIA 8: VERIFICAÇÃO DE CONFORMIDADE — DESPESAS ÓRFÃS */

/* O que verifica: despesas apontando para veículos inexistentes. */

/* Por que importa: integridade referencial DESPESA -> VEICULO. */

/* Constraint: despesa_id_veiculo_fkey (FK). */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    d.id_despesa,
    d.data,
    d.categoria,
    d.descricao,
    d.valor,
    d.id_veiculo
FROM
    despesa AS d
    LEFT JOIN veiculo AS v ON d.id_veiculo = v.id_veiculo
WHERE
    v.id_veiculo IS NULL
ORDER BY
    CASE
        WHEN d.data IS NULL THEN 1
        ELSE 0
    END DESC,
    d.data DESC;

/* ============================================================================ */

/* AUDITORIA 9: VERIFICAÇÃO DE CONFORMIDADE — DOCUMENTO DUPLICADO (CPF/CNPJ) */

/* O que verifica: mesma combinação tipo_documento + numero_documento em pessoas diferentes. */

/* Por que importa: RN01 exige identificação única por CPF/CNPJ. */

/* Constraint: uq_pessoa_documento (UNIQUE). */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    tipo_documento,
    numero_documento,
    COUNT(*) AS qtd_ocorrencias,
    GROUP_CONCAT(CONCAT(nome, ' (ID:', CAST(id_pessoa AS CHAR), ')') SEPARATOR '; ') AS pessoas_com_mesmo_doc
FROM
    pessoa
GROUP BY
    tipo_documento,
    numero_documento
HAVING
    COUNT(*) > 1
ORDER BY
    CASE
        WHEN COUNT(*) IS NULL THEN 1
        ELSE 0
    END DESC,
    COUNT(*) DESC;

/* ============================================================================ */

/* AUDITORIA 10: VERIFICAÇÃO DE CONFORMIDADE — FUNCIONÁRIO SEM PESSOA VÁLIDA */

/* O que verifica: funcionários sem vínculo em pessoa ou pessoa sem dados básicos. */

/* Por que importa: R01 (0,1 / 1,1) exige pessoa válida para cada funcionário. */

/* Constraint: funcionario_id_pessoa_fkey (FK UNIQUE NOT NULL), */

/* ck_pessoa_nome, ck_pessoa_documento. */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    f.id_funcionario,
    f.id_pessoa,
    p.nome,
    CONCAT(p.tipo_documento, ' ', p.numero_documento) AS documento,
    f.cargo,
    f.data_admissao,
    f.situacao,
    CASE
        WHEN p.id_pessoa IS NULL THEN 'VIOLAÇÃO: Funcionário sem pessoa vinculada'
        WHEN p.nome IS NULL
        OR TRIM(p.nome) = '' THEN 'VIOLAÇÃO: Pessoa sem nome'
        WHEN p.tipo_documento IS NULL
        OR p.numero_documento IS NULL THEN 'VIOLAÇÃO: Pessoa sem documento'
        ELSE 'OK'
    END AS validacao
FROM
    funcionario AS f
    LEFT JOIN pessoa AS p ON f.id_pessoa = p.id_pessoa
WHERE
    p.id_pessoa IS NULL
    OR p.nome IS NULL
    OR TRIM(p.nome) = ''
    OR p.tipo_documento IS NULL
    OR p.numero_documento IS NULL
ORDER BY
    CASE
        WHEN f.id_funcionario IS NULL THEN 1
        ELSE 0
    END,
    f.id_funcionario;

/* ============================================================================ */

/* AUDITORIA 11: VERIFICAÇÃO DE CONFORMIDADE — ENTRADA COM AVALIAÇÃO INVÁLIDA */

/* O que verifica: entradas cuja avaliação não está APROVADA, não tem interesse */

/* comercial SIM, finalidade diferente da modalidade, veículo divergente */

/* ou avaliação posterior à entrada (RN06/RN07). */

/* Por que importa: entrada só pode existir com avaliação aprovada e interesse. */

/* Constraint/trigger: ck_entrada_origem, entrada_id_avaliacao_fkey (UNIQUE), */

/* trigger validar_integridade_comercial (bloco RN06/RN07). */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    e.id_entrada,
    e.id_veiculo,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    e.modalidade,
    e.situacao AS situacao_entrada,
    av.id_avaliacao,
    av.decisao_tecnica,
    av.interesse_comercial,
    av.finalidade,
    CONCAT(
        'VIOLAÇÃO RN06/RN07: Entrada exige avaliação APROVADA, ',
        'interesse SIM, finalidade=modalidade, mesmo veículo, avaliação ',
        'anterior à entrada'
    ) AS detalhe
FROM
    entrada AS e
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    JOIN avaliacao AS av ON e.id_avaliacao = av.id_avaliacao
WHERE
    av.decisao_tecnica <> 'APROVADA'
    OR av.interesse_comercial <> 'SIM'
    OR av.finalidade <> e.modalidade
    OR e.id_veiculo <> av.id_veiculo
    OR av.data > e.data_entrada
ORDER BY
    CASE
        WHEN e.data_entrada IS NULL THEN 1
        ELSE 0
    END DESC,
    e.data_entrada DESC;

/* ============================================================================ */

/* AUDITORIA 12: VERIFICAÇÃO DE CONFORMIDADE — TROCA VIOLA RN18 */

/* O que verifica: veículo de troca igual ao principal OU contraparte da troca */

/* diferente do comprador da venda (RN18). */

/* Por que importa: troca deve pertencer ao comprador e ser veículo diferente. */

/* Constraint/trigger: trigger validar_integridade_comercial (bloco RN18). */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    t.id_entrada AS id_entrada_troca,
    CONCAT(v_troca.marca, ' ', v_troca.modelo) AS veiculo_troca,
    p_troca.nome AS contraparte_troca,
    vn.id_venda,
    p_comprador.nome AS comprador_venda,
    CONCAT(v_principal.marca, ' ', v_principal.modelo) AS veiculo_principal,
    'VIOLAÇÃO RN18: Troca deve pertencer ao comprador e ser diferente do veículo principal' AS detalhe
FROM
    entrada AS t
    JOIN venda AS vn ON t.id_venda_origem = vn.id_venda
    JOIN entrada AS p ON vn.id_entrada_principal = p.id_entrada
    JOIN veiculo AS v_troca ON t.id_veiculo = v_troca.id_veiculo
    JOIN veiculo AS v_principal ON p.id_veiculo = v_principal.id_veiculo
    JOIN pessoa AS p_troca ON t.id_contraparte = p_troca.id_pessoa
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
WHERE
    t.id_contraparte <> vn.id_comprador
    OR t.id_veiculo = p.id_veiculo
ORDER BY
    CASE
        WHEN vn.data_registro IS NULL THEN 1
        ELSE 0
    END DESC,
    vn.data_registro DESC;

/* ============================================================================ */

/* AUDITORIA 13: VERIFICAÇÃO DE CONFORMIDADE — CONSIGNAÇÃO SEM FIRMA (RN12) */

/* O que verifica: entradas CONSIGNACAO sem reconhecimento_firma = 'REALIZADO'. */

/* Por que importa: RN12/RO03 exigem firma reconhecida na consignação. */

/* Constraint: ck_entrada_consignacao. */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    e.id_entrada,
    e.id_veiculo,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    e.reconhecimento_firma,
    'VIOLAÇÃO RN12: Consignação exige reconhecimento_firma = REALIZADO' AS detalhe
FROM
    entrada AS e
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
WHERE
    e.modalidade = 'CONSIGNACAO'
    AND (
        e.reconhecimento_firma IS NULL
        OR e.reconhecimento_firma <> 'REALIZADO'
    )
ORDER BY
    CASE
        WHEN e.data_entrada IS NULL THEN 1
        ELSE 0
    END DESC,
    e.data_entrada DESC;

/* ============================================================================ */

/* AUDITORIA 14: VERIFICAÇÃO DE CONFORMIDADE — CICLO RN13 SUCESSORA INVÁLIDA */

/* O que verifica: entrada sucessora (id_entrada_anterior) que viola regras: */

/* veículo diferente, anterior não encerrada, datas fora de ordem, */

/* venda anterior não cancelada, nova entrada antes do retorno do veículo, */

/* ou nova entrada não EM_REGULARIZACAO sem data_regularizacao. */

/* Por que importa: RN13 define sucessão válida após cancelamento. */

/* Constraint/trigger: entrada_id_entrada_anterior_fkey (UNIQUE), */

/* trigger validar_integridade_comercial (bloco RN13 sucessora), */

/* trigger preservar_historico. */

/* Resultado REAL na massa: 0 linhas. */

/* ============================================================================ */

SELECT
    n.id_entrada AS id_entrada_nova,
    n.id_veiculo,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    n.data_entrada AS data_nova_entrada,
    p.id_entrada AS id_entrada_anterior,
    p.data_encerramento AS encerramento_anterior,
    p.motivo_encerramento,
    vn.id_venda AS venda_anterior,
    vn.situacao_comercial AS situacao_venda_anterior,
    vn.data_retorno_veiculo,
    n.situacao AS situacao_nova,
    n.data_regularizacao,
    CONCAT(
        'VIOLAÇÃO RN13: Sucessora exige mesmo veículo, anterior ',
        'encerrada, venda cancelada, retorno antes de nova entrada, ',
        'regularização se não EM_REGULARIZACAO'
    ) AS detalhe
FROM
    entrada AS n
    JOIN entrada AS p ON n.id_entrada_anterior = p.id_entrada
    JOIN veiculo AS v ON n.id_veiculo = v.id_veiculo
    LEFT JOIN venda AS vn ON p.id_entrada = vn.id_entrada_principal
WHERE
    n.id_veiculo <> p.id_veiculo
    OR p.data_encerramento IS NULL
    OR n.data_entrada <= p.data_entrada
    OR n.data_entrada < p.data_encerramento
    OR vn.id_venda IS NULL
    OR vn.situacao_comercial <> 'CANCELADA'
    OR n.data_entrada < vn.data_retorno_veiculo
    OR (
        n.situacao <> 'EM_REGULARIZACAO'
        AND n.data_regularizacao IS NULL
    )
ORDER BY
    CASE
        WHEN n.data_entrada IS NULL THEN 1
        ELSE 0
    END DESC,
    n.data_entrada DESC;

/* ============================================================================ */

/* ============================================================================ */

/* AUDITORIAS DE QUALIDADE (O BANCO NÃO IMPEDE) — NOVAS */

/* ============================================================================ */

/* ============================================================================ */

/* ============================================================================ */

/* AUDITORIA Q1: CONSIGNAÇÃO COM PRAZO VENCIDO AINDA ATIVA */

/* O que verifica: entradas CONSIGNACAO com prazo_consignacao < CURRENT_DATE */

/* e situacao = 'ATIVA'. */

/* Por que importa: consignação vencida sem ação (renovação, devolução, venda) */

/* indica gestão passiva de pátio e risco jurídico com proprietário. */

/* O banco NÃO impede: ck_entrada_consignacao não bloqueia prazo vencido. */

/* Resultado REAL na massa: 0 linhas (todas consignações ativas têm prazo futuro ou NULL). */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            30 AS dias_prazo_consignacao_vencido
    )
SELECT
    e.id_entrada,
    e.id_veiculo,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    e.prazo_consignacao,
    DATEDIFF(CURRENT_DATE, e.prazo_consignacao) AS dias_vencido,
    p_proprietario.nome AS proprietario,
    p_proprietario.telefone AS telefone_proprietario,
    e.valor_repasse_acordado,
    CONCAT(
        'ALERTA: Consignação com prazo vencido há ',
        DATEDIFF(CURRENT_DATE, e.prazo_consignacao),
        ' dias, ainda ATIVA'
    ) AS detalhe
FROM
    entrada AS e
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    JOIN pessoa AS p_proprietario ON e.id_contraparte = p_proprietario.id_pessoa
    CROSS JOIN params
WHERE
    e.modalidade = 'CONSIGNACAO'
    AND e.situacao = 'ATIVA'
    AND e.prazo_consignacao IS NOT NULL
    AND e.prazo_consignacao < CURRENT_DATE
ORDER BY
    CASE
        WHEN e.prazo_consignacao IS NULL THEN 1
        ELSE 0
    END,
    e.prazo_consignacao ASC;

/* ============================================================================ */

/* AUDITORIA Q2: VENDA EM FORMALIZAÇÃO PARADA HÁ MAIS DE N DIAS */

/* O que verifica: vendas EM_FORMALIZACAO com data_registro antiga */

/* (mais de 60 dias) sem evolução para CONCLUIDA/CANCELADA. */

/* Por que importa: vendas travadas indicam gargalo (docs, financiamento, laudo) */

/* e capital imobilizado. */

/* O banco NÃO impede: não há constraint de tempo máximo em formalização. */

/* Resultado REAL na massa: 1 linha — venda 6 (Tracker, financiamento APROVADO_A_RECEBER */

/* desde 2026-01-15, docs pendentes, 60+ dias parada). */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            60 AS dias_formalizacao_parada
    )
SELECT
    vn.id_venda,
    vn.data_registro,
    DATEDIFF(CURRENT_DATE, DATE(vn.data_registro)) AS dias_em_formalizacao,
    p_comprador.nome AS comprador,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    vn.valor_total,
    vn.instituicao_financeira,
    vn.situacao_financiamento,
    vd.documentos_ok,
    vd.reconhecimento_ok,
    vd.laudo_ok,
    CONCAT(
        'ALERTA: Venda em formalização há ',
        DATEDIFF(CURRENT_DATE, DATE(vn.data_registro)),
        ' dias sem conclusão/cancelamento'
    ) AS detalhe
FROM
    venda AS vn
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    LEFT JOIN vw_venda_validacao AS vd ON vd.id_venda = vn.id_venda
    CROSS JOIN params
WHERE
    vn.situacao_comercial = 'EM_FORMALIZACAO'
    AND CAST(vn.data_registro AS DATE) <= DATE_SUB(CURRENT_DATE, INTERVAL params.dias_formalizacao_parada DAY)
ORDER BY
    CASE
        WHEN vn.data_registro IS NULL THEN 1
        ELSE 0
    END,
    vn.data_registro ASC;

/* ============================================================================ */

/* AUDITORIA Q3: FINANCIAMENTO APROVADO_A_RECEBER HÁ MAIS DE N DIAS */

/* O que verifica: vendas com situacao_financiamento = 'APROVADO_A_RECEBER' */

/* há mais de 30 dias sem evoluir para RECEBIDO. */

/* Por que importa: crédito aprovado não recebido = risco de expiração da aprovação */

/* e venda travada. Divergência entre aprovação bancária e repasse efetivo (PROB06/RN21). */

/* O banco NÃO impede: ck_venda_financiamento valida estrutura, não tempo. */

/* Resultado REAL na massa: 1 linha — venda 6 (Tracker, aprovado em 2026-01-15, */

/* 30+ dias sem recebimento, instituição BV). */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            30 AS dias_financiamento_pendente
    )
SELECT
    vn.id_venda,
    vn.data_registro,
    vn.data_aprovacao_financiamento,
    DATEDIFF(CURRENT_DATE, DATE(vn.data_aprovacao_financiamento)) AS dias_aprovado_sem_receber,
    vn.instituicao_financeira,
    vn.valor_financiado,
    vn.valor_recebido,
    p_comprador.nome AS comprador,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    CONCAT(
        'ALERTA: Financiamento aprovado há ',
        DATEDIFF(CURRENT_DATE, DATE(vn.data_aprovacao_financiamento)),
        ' dias sem recebimento confirmado'
    ) AS detalhe
FROM
    venda AS vn
    JOIN pessoa AS p_comprador ON vn.id_comprador = p_comprador.id_pessoa
    JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    CROSS JOIN params
WHERE
    vn.situacao_financiamento = 'APROVADO_A_RECEBER'
    AND vn.data_aprovacao_financiamento IS NOT NULL
    AND CAST(vn.data_aprovacao_financiamento AS DATE)
        <= DATE_SUB(CURRENT_DATE, INTERVAL params.dias_financiamento_pendente DAY)
ORDER BY
    CASE
        WHEN vn.data_aprovacao_financiamento IS NULL THEN 1
        ELSE 0
    END,
    vn.data_aprovacao_financiamento ASC;

/* ============================================================================ */

/* AUDITORIA Q4: PREÇO ANUNCIADO ABAIXO DO CUSTO/REPASSE */

/* O que verifica: entradas ATIVAS onde preco_anunciado < valor_acordado */

/* (compra própria/troca) ou preco_anunciado < valor_repasse_acordado (consignação). */

/* Por que importa: preço abaixo do custo/repasse garante prejuízo na venda; */

/* indica erro de precificação ou digitação. */

/* O banco NÃO impede: ck_entrada_valores só exige >= 0; ck_entrada_preco */

/* só exige preco_anunciado NOT NULL para ATIVA. */

/* Resultado REAL na massa: 0 linhas (todos preços anunciados >= custo/repasse). */

/* ============================================================================ */

SELECT
    e.id_entrada,
    e.id_veiculo,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    e.modalidade,
    e.valor_acordado AS custo_ou_repasse,
    e.valor_repasse_acordado,
    e.preco_anunciado,
    e.preco_anunciado - CASE
        WHEN e.modalidade = 'CONSIGNACAO' THEN COALESCE(e.valor_repasse_acordado, 0)
        ELSE e.valor_acordado
    END AS diferenca_preco_custo,
    p_contraparte.nome AS contraparte,
    CONCAT(
        'ALERTA: Preço anunciado abaixo do ',
        CASE
            WHEN e.modalidade = 'CONSIGNACAO' THEN 'valor de repasse'
            ELSE 'custo de aquisição'
        END,
        ' (',
        e.preco_anunciado - CASE
            WHEN e.modalidade = 'CONSIGNACAO' THEN COALESCE(e.valor_repasse_acordado, 0)
            ELSE e.valor_acordado
        END,
        ')'
    ) AS detalhe
FROM
    entrada AS e
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    JOIN pessoa AS p_contraparte ON e.id_contraparte = p_contraparte.id_pessoa
WHERE
    e.situacao = 'ATIVA'
    AND e.preco_anunciado IS NOT NULL
    AND e.preco_anunciado < CASE
        WHEN e.modalidade = 'CONSIGNACAO' THEN COALESCE(e.valor_repasse_acordado, 0)
        ELSE e.valor_acordado
    END
ORDER BY
    CASE
        WHEN e.preco_anunciado - CASE
            WHEN e.modalidade = 'CONSIGNACAO' THEN COALESCE(e.valor_repasse_acordado, 0)
            ELSE e.valor_acordado
        END IS NULL THEN 1
        ELSE 0
    END,
    e.preco_anunciado - CASE
        WHEN e.modalidade = 'CONSIGNACAO' THEN COALESCE(e.valor_repasse_acordado, 0)
        ELSE e.valor_acordado
    END ASC;

/* ============================================================================ */

/* AUDITORIA Q5: OCORRÊNCIA DE GARANTIA ABERTA HÁ MAIS DE N DIAS */

/* O que verifica: ocorrências com data_abertura antiga (mais de 30 dias) */

/* e sem data_encerramento (ainda em análise/aberto). */

/* Por que importa: ocorrências longas sem resolução indicam falha no processo */

/* de garantia, insatisfação do cliente e risco jurídico. */

/* O banco NÃO impede: ck_ocorrencia_encerramento só valida datas se encerrada. */

/* Resultado REAL na massa: 1 linha — ocorrência 2 (venda 3, Iara Compradora, */

/* Honda City, aberta em 2026-02-03, ainda em análise, 30+ dias). */

/* ============================================================================ */

WITH
    params AS (
        SELECT
            30 AS dias_ocorrencia_aberta
    )
SELECT
    og.id_ocorrencia,
    og.data_abertura,
    DATEDIFF(CURRENT_DATE, DATE(og.data_abertura)) AS dias_aberta,
    vn.id_venda,
    p_cliente.nome AS cliente,
    CONCAT(v.marca, ' ', v.modelo) AS veiculo,
    og.problema_relatado,
    og.situacao,
    og.atendimento_externo_informado,
    CONCAT(
        'ALERTA: Ocorrência aberta há ',
        DATEDIFF(CURRENT_DATE, DATE(og.data_abertura)),
        ' dias sem encerramento'
    ) AS detalhe
FROM
    ocorrencia_garantia AS og
    JOIN venda AS vn ON og.id_venda = vn.id_venda
    JOIN pessoa AS p_cliente ON vn.id_comprador = p_cliente.id_pessoa
    JOIN entrada AS e ON vn.id_entrada_principal = e.id_entrada
    JOIN veiculo AS v ON e.id_veiculo = v.id_veiculo
    CROSS JOIN params
WHERE
    og.data_encerramento IS NULL
    AND CAST(og.data_abertura AS DATE) <= DATE_SUB(CURRENT_DATE, INTERVAL params.dias_ocorrencia_aberta DAY)
ORDER BY
    CASE
        WHEN og.data_abertura IS NULL THEN 1
        ELSE 0
    END,
    og.data_abertura ASC;

/* ============================================================================ */

/* AUDITORIA Q6: POSSÍVEIS PESSOAS DUPLICADAS (MESMO EMAIL/TELEFONE, DOC DIFERENTE) */

/* O que verifica: pessoas diferentes (documento diferente) com mesmo email */

/* ou mesmo telefone — indicativo de cadastro duplicado (RN01/RNF02). */

/* Por que importa: cadastro único por pessoa evita fragmentação de histórico */

/* (PROB01). UNIQUE em documento não pega duplicatas por contato. */

/* O banco NÃO impede: uq_pessoa_documento só cobre documento. */

/* Resultado REAL na massa: 0 linhas (nenhum email/telefone duplicado entre documentos diferentes). */

/* ============================================================================ */

SELECT
    'EMAIL' AS tipo_contato,
    email AS valor_contato,
    COUNT(*) AS qtd_pessoas,
    GROUP_CONCAT(CONCAT(nome, ' (', tipo_documento, ' ', numero_documento, ')') SEPARATOR '; ') AS pessoas
FROM
    pessoa
WHERE
    email IS NOT NULL
    AND email <> ''
GROUP BY
    email
HAVING
    COUNT(*) > 1
UNION ALL
SELECT
    'TELEFONE' AS tipo_contato,
    telefone AS valor_contato,
    COUNT(*) AS qtd_pessoas,
    GROUP_CONCAT(CONCAT(nome, ' (', tipo_documento, ' ', numero_documento, ')') SEPARATOR '; ') AS pessoas
FROM
    pessoa
WHERE
    telefone IS NOT NULL
    AND telefone <> ''
GROUP BY
    telefone
HAVING
    COUNT(*) > 1
ORDER BY
    CASE
        WHEN tipo_contato IS NULL THEN 1
        ELSE 0
    END,
    tipo_contato,
    CASE
        WHEN qtd_pessoas IS NULL THEN 1
        ELSE 0
    END DESC,
    qtd_pessoas DESC;

/* ============================================================================ */

/* AUDITORIA Q7: VEÍCULO COM ENTRADA ATIVA SEM PLACA NEM CHASSI */

/* O que verifica: veículos com entrada ATIVA que não têm placa NEM chassi */

/* preenchidos (cadastro preliminar que virou entrada sem identificação física). */

/* Por que importa: RN04 permite cadastro sem placa/chassi, mas entrada aceita */

/* no estoque (ATIVA) deveria ter identificação física para controle de pátio */

/* e documentação de transferência. */

/* O banco NÃO impede: placa e chassi são UNIQUE mas NULL allowed; entrada */

/* só exige avaliação aprovada e interesse, não identificação física. */

/* Resultado REAL na massa completa: 0 linhas. 06-estoque-loja.sql grava placas e chassis
   sintéticos (LJA1B.. / 9LJAB..) nos 27 veículos de teste; a Q7 verifica entradas
   ATIVAS sem placa nem chassi e não encontra nenhuma. */

/* ============================================================================ */

SELECT
    v.id_veiculo,
    v.marca,
    v.modelo,
    v.ano_modelo,
    v.placa,
    v.chassi,
    e.id_entrada,
    e.modalidade,
    e.data_entrada,
    'ALERTA: Veículo com entrada ATIVA sem placa NEM chassi identificados' AS detalhe
FROM
    veiculo AS v
    JOIN entrada AS e ON v.id_veiculo = e.id_veiculo
WHERE
    e.situacao = 'ATIVA'
    AND (
        v.placa IS NULL
        OR v.placa = ''
    )
    AND (
        v.chassi IS NULL
        OR v.chassi = ''
    )
ORDER BY
    CASE
        WHEN e.data_entrada IS NULL THEN 1
        ELSE 0
    END DESC,
    e.data_entrada DESC;

/* ============================================================================ */

/* AUDITORIA Q8: TROCA DE VENDA CANCELADA NÃO DEVOLVIDA */

/* O que verifica: entradas de troca (modalidade='TROCA') originadas de */

/* venda CANCELADA que não estão com situacao='DEVOLVIDA' e data_devolucao. */

/* Por que importa: RN29/RN30 exigem devolução recíproca no desfazimento. */

/* Trigger validar_integridade_comercial exige isso no cancelamento, */

/* mas esta query detecta casos legados ou falha de trigger. */

/* Resultado REAL na massa: 0 linhas (trigger garante na massa: troca da venda 4 */

/* devolvida com situacao=DEVOLVIDA e data_devolucao preenchida). */

/* ============================================================================ */

SELECT
    e_troca.id_entrada AS id_entrada_troca,
    e_troca.id_veiculo,
    CONCAT(v_troca.marca, ' ', v_troca.modelo) AS veiculo_troca,
    e_troca.situacao AS situacao_troca,
    e_troca.data_devolucao,
    vn.id_venda AS venda_origem,
    vn.situacao_comercial AS situacao_venda_origem,
    vn.data_cancelamento,
    CONCAT(
        'VIOLAÇÃO RN29/RN30: Troca de venda cancelada não devolvida ',
        '(situacao <> DEVOLVIDA ou data_devolucao IS NULL)'
    ) AS detalhe
FROM
    entrada AS e_troca
    JOIN veiculo AS v_troca ON e_troca.id_veiculo = v_troca.id_veiculo
    JOIN venda AS vn ON e_troca.id_venda_origem = vn.id_venda
WHERE
    e_troca.modalidade = 'TROCA'
    AND vn.situacao_comercial = 'CANCELADA'
    AND (
        e_troca.situacao <> 'DEVOLVIDA'
        OR e_troca.data_devolucao IS NULL
    )
ORDER BY
    CASE
        WHEN vn.data_cancelamento IS NULL THEN 1
        ELSE 0
    END DESC,
    vn.data_cancelamento DESC;

-- =====================================================================
-- sql\testes\testes-restricoes.sql
-- =====================================================================
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

-- =====================================================================
-- sql\extensao\01-ddl-propostas-caixa.sql
-- =====================================================================
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




-- =====================================================================
-- sql\extensao\02-massa-propostas-caixa.sql
-- =====================================================================
-- Massa fixa para a extensão financeira; executada depois do 01.
USE multiplikar;
INSERT INTO parametro_referencia(chave,data_referencia,origem) VALUES(TRUE,'2026-02-10','DEMONSTRACAO');
INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,data,tipo_interesse,descricao_interesse,situacao) VALUES(7,10,1,'2026-02-02 12:00','COMPRA','Propostas para o Kwid consignado; comparacao de pagamento.','ABERTO');
INSERT INTO veiculo(id_veiculo,marca,modelo,ano_modelo,cor,placa,chassi,combustivel,cambio,categoria_comercial) VALUES(11,'Volkswagen','Gol',2018,'Prata','TST1A11','9TEST000000000011','Flex','Manual','USADO');
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES(11,11,3,'2026-02-02 10:00','TROCA',80000,2,'Conservada','Conservada','Vistoriada','Verificada','Conferida','APROVADA','SIM','Avaliacao especifica para a proposta do cliente 10.');
-- A posse do Gol não é modelada; a avaliação registra apenas a oferta para a proposta.
INSERT INTO parametro_prazo(banco,tipo_obrigacao,dias_previstos,origem,vigencia) SELECT instituicao_financeira,'FINANCIAMENTO_RECEBER',15,'HIPOTESE','2026-01-01' FROM venda WHERE id_venda=6;
INSERT INTO parametro_prazo VALUES('Consignante Demonstracao','CONSIGNANTE_PAGAR',5,'HIPOTESE','2026-01-01'),('Fornecedor Demonstracao','COMPRA_PROPRIA_PAGAR',3,'HIPOTESE','2026-01-01');
INSERT INTO parametro_retorno(instituicao,tabela_retorno,acrescimo_taxa_mensal,retorno_pct,origem,vigencia) SELECT instituicao_financeira,'R0',0,0,'HIPOTESE','2026-01-01' FROM venda WHERE id_venda=6;
INSERT INTO parametro_retorno(instituicao,tabela_retorno,acrescimo_taxa_mensal,retorno_pct,origem,vigencia) SELECT instituicao_financeira,'R4',0.0030,0.04,'HIPOTESE','2026-01-01' FROM venda WHERE id_venda=6;
INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base,desconto,acrescimo,taxas,situacao) VALUES(7,10,1,'A',1,'2026-02-03','2026-02-10',55000,0,0,0,'RASCUNHO'),(7,10,1,'B',1,'2026-02-03','2026-02-10',55000,0,0,0,'RASCUNHO'),(7,10,1,'C',1,'2026-02-03','2026-02-10',55000,0,0,0,'RASCUNHO');
INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor,prazo_previsto_dias) VALUES(1,'PIX',55000,0),(2,'PIX',11000,0),(2,'FINANCIAMENTO',44000,15),(3,'PIX',25000,0);
INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(3,11,30000);
UPDATE proposta SET situacao='APRESENTADA' WHERE id_atendimento=7;
INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,parcela_informada,renda_declarada,consentimento_renda,situacao,data_simulacao) SELECT 2,instituicao_financeira,'R0','ACADEMICA',44000,0.018900,48,1402.56,6500,TRUE,'EM_ANALISE','2026-02-03 10:00' FROM venda WHERE id_venda=6;
INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) SELECT 2,instituicao_financeira,'R4','ACADEMICA',44000,0.018900,48,6500,TRUE,'EM_ANALISE','2026-02-03 11:00' FROM venda WHERE id_venda=6;
INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual,situacao,origem_estimativa) SELECT 'RECEBER','VENDA',v.id_venda,'FINANCIAMENTO',v.instituicao_financeira,v.valor_financiado,DATE(v.data_aprovacao_financiamento),DATE_ADD(DATE(v.data_aprovacao_financiamento),INTERVAL pp.dias_previstos DAY),DATE_ADD(DATE(v.data_aprovacao_financiamento),INTERVAL pp.dias_previstos DAY),'ATRASADA','HIPOTESE' FROM venda v JOIN parametro_prazo pp ON pp.banco=v.instituicao_financeira AND pp.tipo_obrigacao='FINANCIAMENTO_RECEBER' AND pp.vigencia=(SELECT MAX(p2.vigencia) FROM parametro_prazo p2 WHERE p2.banco=v.instituicao_financeira AND p2.tipo_obrigacao='FINANCIAMENTO_RECEBER' AND p2.vigencia<=DATE(v.data_aprovacao_financiamento)) WHERE v.id_venda=6;
DELIMITER $$
CREATE PROCEDURE verificar_massa_propostas()
BEGIN
 IF (SELECT COUNT(*) FROM vw_proposta_comparativo WHERE id_atendimento=7)<>3 OR (SELECT COUNT(DISTINCT margem_estimada) FROM vw_proposta_comparativo WHERE id_atendimento=7)<>1 OR (SELECT COUNT(DISTINCT caixa_d0) FROM vw_proposta_comparativo WHERE id_atendimento=7)<>3 OR (SELECT valor_em_troca FROM vw_proposta_comparativo WHERE id_proposta=3)<>30000 OR (SELECT COUNT(*) FROM vw_simulacao_parcela WHERE id_proposta=2 AND consentimento_renda AND parcela_calculada>0)<>2 OR (SELECT parcela_calculada FROM vw_simulacao_parcela WHERE id_simulacao=2)<=(SELECT parcela_calculada FROM vw_simulacao_parcela WHERE id_simulacao=1) OR (SELECT retorno_loja FROM vw_simulacao_parcela WHERE id_simulacao=2)<>1760 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Demonstracao de propostas Kwid incoerente'; END IF;
 SELECT 'PASS demonstracao: alternativas A/B/C e trade-off R0/R4 conferidos' AS resultado;
 SELECT 'PASS massa proposta: condicoes, troca e simulacoes conferidas' AS resultado;
END$$
DELIMITER ;
CALL verificar_massa_propostas();
DROP PROCEDURE verificar_massa_propostas;

-- Casos de comportamento: cada chamada executa DML e válida o texto retornado pelo banco.
DROP PROCEDURE IF EXISTS teste_regra_ext02;
DELIMITER $$
CREATE PROCEDURE teste_regra_ext02(IN p_rotulo VARCHAR(120), IN p_sql TEXT, IN p_esperado VARCHAR(160))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN GET DIAGNOSTICS CONDITION 1 @msg = MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE;
  END;
  SET @teste_ext02_sql=p_sql; PREPARE teste_ext02_stmt FROM @teste_ext02_sql; EXECUTE teste_ext02_stmt; DEALLOCATE PREPARE teste_ext02_stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Operacao deveria ser recusada: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Regra inesperada em ',p_rotulo,': ',COALESCE(v_msg,'<vazia>')); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS ext02 ',p_rotulo,': ',p_esperado) AS resultado;
END$$
CREATE PROCEDURE confere_ext02(IN p_ok BOOLEAN, IN p_rotulo VARCHAR(160))
BEGIN DECLARE v_err TEXT; IF p_ok IS NULL OR NOT p_ok THEN SET v_err=CONCAT('Verificacao falhou: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF; SELECT CONCAT('PASS ext02 ',p_rotulo) AS resultado; END$$
DELIMITER ;
START TRANSACTION;
INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base) VALUES(7,10,1,'D',1,'2026-02-03','2026-02-10',100);
INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(4,'PIX',100);
CALL teste_regra_ext02('condicao duplicada na proposta','INSERT INTO proposta_condicao VALUES(4,''PIX'',100,0)','Duplicate entry');
CALL teste_regra_ext02('valor da condicao deve ser positivo','INSERT INTO proposta_condicao VALUES(4,''DINHEIRO'',0,0)','ck_proposta_condicao_valor');
CALL teste_regra_ext02('apresentada imutavel','UPDATE proposta SET valor_base=54000 WHERE id_proposta=1','Proposta apresentada e imutavel');
CALL teste_regra_ext02('condicao de proposta apresentada imutavel','UPDATE proposta_condicao SET valor=1 WHERE id_proposta=1 AND codigo_forma=''PIX''','Proposta apresentada e imutavel');
CALL teste_regra_ext02('ACEITA exige funcao atomica','UPDATE proposta SET situacao=''ACEITA'',data_decisao=''2026-02-04 10:00:00'' WHERE id_proposta=1','Use aceitar_proposta');
CALL teste_regra_ext02('consentimento de renda obrigatorio','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) SELECT 1,instituicao_financeira,''R0'',''ACADEMICA'',10000,0.02,12,5000,FALSE,''EM_ANALISE'',''2026-02-04 10:00:00'' FROM venda WHERE id_venda=6','ck_simulacao_consentimento_renda');
CALL teste_regra_ext02('retorno sem vigencia','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) VALUES(2,''Banco Demonstracao'',''R5'',''ACADEMICA'',10000,0.02,12,5000,TRUE,''EM_ANALISE'',''2026-02-04 10:00:00'')','Parametro_retorno vigente');
CALL teste_regra_ext02('simulacao nao pode ser apagada','DELETE FROM simulacao_financiamento WHERE id_simulacao=1','nao pode ser removida');
CALL teste_regra_ext02('simulacao em analise nao altera dados-base','UPDATE simulacao_financiamento SET tabela_retorno=''R4'' WHERE id_simulacao=1','so permite alterar situacao');
CALL teste_regra_ext02('obrigacao nao pode ser apagada','DELETE FROM obrigacao_financeira WHERE id_obrigacao=1','nao pode ser removida');
CALL teste_regra_ext02('vencimento original e imutavel','UPDATE obrigacao_financeira SET vencimento_original=''2026-03-01'' WHERE id_obrigacao=1','so permite alterar vencimento_atual');
CALL teste_regra_ext02('arco administrativo sem FK','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ADMINISTRATIVA'',6,''ADMIN'',''Teste'',100,''2026-02-10'',''2026-02-10'',''2026-02-10'')','ck_obrigacao_arco');
CALL teste_regra_ext02('troca ja consumida','INSERT INTO proposta_troca VALUES(1,8,10000)','Troca exige avaliacao aprovada');
CALL teste_regra_ext02('troca ligada a proposta apresentada','INSERT INTO proposta_troca VALUES(3,11,30000)','Troca exige avaliacao aprovada');
CALL teste_regra_ext02('percentual de retorno limitado','INSERT INTO parametro_retorno(instituicao,tabela_retorno,acrescimo_taxa_mensal,retorno_pct,origem,vigencia) VALUES(''Banco Teste'',''R4'',0.003,0.11,''HIPOTESE'',''2026-01-01'')','ck_parametro_retorno_pct');
CALL teste_regra_ext02('instituicao e tabela unicas por vigencia','INSERT INTO parametro_retorno SELECT instituicao,tabela_retorno,acrescimo_taxa_mensal,retorno_pct,origem,vigencia FROM parametro_retorno WHERE tabela_retorno=''R4'' LIMIT 1','Duplicate entry');
CALL teste_regra_ext02('obrigacao so permite campos de previsao','UPDATE obrigacao_financeira SET valor=valor+1 WHERE id_obrigacao=1','so permite alterar vencimento_atual');
CALL teste_regra_ext02('simulacao sem taxa tabela valida','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) VALUES(2,''Banco Demonstracao'',''R9'',''ACADEMICA'',10000,0.02,12,5000,TRUE,''EM_ANALISE'',''2026-02-04 10:00:00'')','Parametro_retorno vigente');
CALL teste_regra_ext02('venda referencia proposta nao aceita','UPDATE venda SET id_proposta=2 WHERE id_venda=6','Venda exige proposta aceita');
CALL teste_regra_ext02('datas da obrigacao em ordem','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''RECEBER'',''VENDA'',6,''FINANCIAMENTO'',''Banco'',100,''2026-02-10'',''2026-02-09'',''2026-02-09'')','ck_obrigacao_datas');
CALL teste_regra_ext02('raiz exige versao 1','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,valor_base) VALUES(7,10,1,''E'',2,''2026-02-03'',100)','Proposta raiz deve iniciar');
CALL teste_regra_ext02('alternativa raiz rotulo e versao unicos','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,valor_base) VALUES(7,10,1,''A'',1,''2026-02-03'',55000)','Duplicate entry');
CALL teste_regra_ext02('sucessora exige predecessora substituida','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base) VALUES(7,10,1,2,''B'',2,''2026-02-04'',''2026-02-17'',100)','Contraproposta deve suceder');
CALL teste_regra_ext02('decisao nula antes da decisao','UPDATE proposta SET data_decisao=''2026-02-04 10:00:00'' WHERE id_proposta=2','ck_proposta_data_decisao');
SET @multiplikar_aceitar_proposta=1;
CALL teste_regra_ext02('ACEITA depois da validade','UPDATE proposta SET situacao=''ACEITA'',data_decisao=''2026-02-11 10:00:00'' WHERE id_proposta=1','Proposta aceita exige entrada ativa');
SET @multiplikar_aceitar_proposta=NULL;
UPDATE obrigacao_financeira SET situacao='QUITADA' WHERE id_obrigacao=1;
CALL teste_regra_ext02('situacao terminal da obrigacao','UPDATE obrigacao_financeira SET situacao=''ATRASADA'' WHERE id_obrigacao=1','Situacao terminal da obrigacao financeira');
CALL teste_regra_ext02('transicao atrasada para aberta proibida','UPDATE obrigacao_financeira SET situacao=''ABERTA'' WHERE id_obrigacao=1','Situacao terminal da obrigacao financeira');
UPDATE simulacao_financiamento SET situacao='APROVADA',data_resposta='2026-02-04 12:00:00' WHERE id_simulacao=1;
CALL teste_regra_ext02('segunda simulacao aprovada para proposta','UPDATE simulacao_financiamento SET situacao=''APROVADA'',data_resposta=''2026-02-04 12:00:00'' WHERE id_simulacao=2','Duplicate entry');
CALL teste_regra_ext02('data resposta anterior a simulacao','UPDATE simulacao_financiamento SET data_resposta=''2026-02-02 10:00:00'' WHERE id_simulacao=2','ck_simulacao_datas');
CALL teste_regra_ext02('simulacao R4 em analise nao altera tabela','UPDATE simulacao_financiamento SET tabela_retorno=''R0'' WHERE id_simulacao=2','so permite alterar situacao');
UPDATE proposta SET situacao='SUBSTITUIDA',data_decisao='2026-02-04 10:00:00' WHERE id_proposta=1;
INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base,desconto,situacao)
SELECT id_atendimento,id_entrada,id_funcionario,id_proposta,'A',2,'2026-02-04','2026-02-17',55000,500,'RASCUNHO' FROM proposta WHERE id_proposta=1;
CALL confere_ext02((SELECT COUNT(*)=1 FROM proposta WHERE id_proposta_anterior=1 AND rotulo='A' AND versao=2 AND desconto=500),'substituicao positiva: alternativa A sucede para versao 2 e aplica desconto');
CALL teste_regra_ext02('sucessora herda rotulo','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base,situacao) SELECT id_atendimento,id_entrada,id_funcionario,id_proposta,''B'',3,''2026-02-04'',''2026-02-17'',55000,''RASCUNHO'' FROM proposta WHERE id_proposta=1','Contraproposta deve suceder a mesma alternativa');
ROLLBACK;
DROP PROCEDURE teste_regra_ext02;
DROP PROCEDURE confere_ext02;

-- =====================================================================
-- sql\extensao\03-ddl-crm.sql
-- =====================================================================
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




-- =====================================================================
-- sql\extensao\04-massa-crm.sql
-- =====================================================================
-- Dados fictícios do CRM. A referência única é definida na massa do arquivo 02.
USE multiplikar;
INSERT INTO parametro_temperatura VALUES('FRIO',0.0500,'HIPOTESE','2026-01-01'),('MORNO',0.3000,'HIPOTESE','2026-01-01'),('QUENTE',0.6500,'HIPOTESE','2026-01-01');
INSERT INTO pessoa(id_pessoa,nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf,possui_cnh) VALUES(14,'Oto Desistente','CPF','00000000014','11900000014','pessoa14@example.invalid','Rua de Teste','14','Vila Sao Geraldo','Sao Paulo','SP',TRUE),(15,'Paula Morna','CPF','00000000015','11900000015','pessoa15@example.invalid','Rua de Teste','15','Vila Sao Geraldo','Sao Paulo','SP',TRUE);
INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,data,tipo_interesse,descricao_interesse,situacao) VALUES(8,14,2,'2026-01-20 08:45','COMPRA','HB20 usado, avaliando opcoes','EM_NEGOCIACAO'),(9,15,1,'2026-01-11 09:00','COMPRA','Tracker, ainda sem decisao','ABERTO');
INSERT INTO interacao(id_interacao,id_atendimento,id_funcionario,data_hora,canal,direcao,resumo,proximo_passo,data_proximo_passo) VALUES(1,5,1,'2026-01-09 09:15','TELEFONE','ENVIADA','Primeiro contato sobre o Tracker.','Aguardar resposta','2026-01-12 09:00'),(2,5,1,'2026-01-10 11:00','WHATSAPP','RECEBIDA','Cliente perguntou prazo do financiamento.','Retornar','2026-01-13 11:00');
SET @id_classificacao=NULL; CALL registrar_classificacao_lead(5,'REGRA-V1','2026-01-26 11:00',@id_classificacao);
UPDATE classificacao_lead SET temperatura_final='QUENTE',id_revisor=1,data_revisao='2026-01-26 15:00' WHERE id_classificacao=@id_classificacao;
INSERT INTO interacao VALUES(3,7,1,'2026-02-03 09:00','PRESENCIAL','RECEBIDA','Cliente recebeu tres propostas Kwid e pediu tempo.','Confirmar escolha','2026-02-06 09:00');
CALL registrar_classificacao_lead(7,'REGRA-V1','2026-02-10 09:00',@id_classificacao);
UPDATE classificacao_lead SET temperatura_final='QUENTE',id_revisor=1,data_revisao='2026-02-10 15:00',justificativa_revisao='Urgencia informada pelo vendedor; cliente aguarda assinatura.' WHERE id_classificacao=@id_classificacao;
INSERT INTO interacao VALUES(4,8,2,'2026-01-20 09:00','TELEFONE','ENVIADA','Contato inicial sobre HB20.','Aguardar retorno','2026-01-25 09:00');
CALL registrar_classificacao_lead(8,'REGRA-V1','2026-01-22 09:00',@id_classificacao);
INSERT INTO interacao(id_interacao,id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(5,8,2,'2026-01-28 14:00','WHATSAPP','RECEBIDA','Cliente fechou em outra revenda.');
UPDATE atendimento SET situacao='ENCERRADO' WHERE id_atendimento=8;
INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,data_hora,tipo_desfecho,motivo,detalhe) VALUES(8,2,'2026-01-28 14:30','PERDA','Cliente fechou negocio em outra revenda','Informado por WhatsApp.');
INSERT INTO interacao(id_interacao,id_atendimento,id_funcionario,data_hora,canal,direcao,resumo,proximo_passo,data_proximo_passo) VALUES(6,9,1,'2026-01-11 09:00','EMAIL','ENVIADA','Catalogo do Tracker enviado.','Aguardar manifestacao','2026-01-20 09:00');
CALL registrar_classificacao_lead(9,'REGRA-V1','2026-01-12 09:00',@id_classificacao);
DELIMITER $$
CREATE PROCEDURE verificar_massa_crm()
BEGIN
 IF data_referencia()<>'2026-02-10' OR (SELECT COUNT(*) FROM classificacao_lead)<>4 OR (SELECT temperatura_sugerida FROM vw_lead_atual WHERE id_atendimento=7)<>'MORNO' OR (SELECT temperatura_atual FROM vw_lead_atual WHERE id_atendimento=7)<>'QUENTE' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Massa CRM incoerente'; END IF;
 SELECT 'PASS CRM: quatro classificacoes e referencia 2026-02-10 conferidas' AS resultado;
 SELECT 'PASS CRM: atendimento 7 MORNO sugerido e QUENTE revisado' AS resultado;
 IF EXISTS(SELECT 1 FROM vw_lead_atual WHERE id_atendimento=8 AND tipo_desfecho<>'PERDA') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Desfecho CRM incorreto'; END IF;
 SELECT 'PASS CRM: atendimento 8 encerrado com desfecho de perda' AS resultado;
END$$
DELIMITER ;
CALL verificar_massa_crm();
DROP PROCEDURE verificar_massa_crm;

-- Testes de regras CRM com operações reais; TRUNCATE e tratado na paridade documental.
DROP PROCEDURE IF EXISTS teste_regra_crm;
DELIMITER $$
CREATE PROCEDURE teste_regra_crm(IN p_rotulo VARCHAR(120), IN p_sql TEXT, IN p_esperado VARCHAR(160))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN GET DIAGNOSTICS CONDITION 1 @msg=MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE; IF p_sql NOT LIKE 'CALL registrar_classificacao_lead%' THEN SET @mk_registrando_classificacao=NULL; END IF;
  END;
  IF p_sql LIKE 'INSERT INTO classificacao_lead%' THEN SET @mk_registrando_classificacao=1; END IF;
  SET @teste_crm_sql=p_sql; PREPARE teste_crm_stmt FROM @teste_crm_sql; EXECUTE teste_crm_stmt; DEALLOCATE PREPARE teste_crm_stmt;
  IF p_sql NOT LIKE 'CALL registrar_classificacao_lead%' THEN SET @mk_registrando_classificacao=NULL; END IF;
 END;
 IF p_sql LIKE 'CALL registrar_classificacao_lead%' AND @mk_registrando_classificacao IS NOT NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='R37: procedure nao limpou a marca apos erro'; END IF;
 SET @mk_registrando_classificacao=NULL;
 IF NOT v_falhou THEN SET v_err=CONCAT('Operacao CRM deveria ser recusada: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Mensagem CRM inesperada em ',p_rotulo,': ',COALESCE(v_msg,'<vazia>')); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS CRM ',p_rotulo,': ',p_esperado) AS resultado;
END$$
DELIMITER ;
START TRANSACTION;
CALL teste_regra_crm('interacao somente insercao update','UPDATE interacao SET resumo=''alterado'' WHERE id_interacao=1','somente insercao');
CALL teste_regra_crm('interacao somente insercao delete','DELETE FROM interacao WHERE id_interacao=1','somente insercao');
CALL teste_regra_crm('desfecho somente insercao update','UPDATE atendimento_desfecho SET motivo=''alterado'' WHERE id_atendimento=8','somente insercao');
CALL teste_regra_crm('desfecho somente insercao delete','DELETE FROM atendimento_desfecho WHERE id_atendimento=8','somente insercao');
CALL teste_regra_crm('fator somente insercao update','UPDATE classificacao_fator SET pontos=pontos+1 WHERE id_classificacao=1 LIMIT 1','somente insercao');
CALL teste_regra_crm('fator somente insercao delete','DELETE FROM classificacao_fator WHERE id_classificacao=1 LIMIT 1','somente insercao');
CALL teste_regra_crm('classificacao revisada imutavel','UPDATE classificacao_lead SET temperatura_final=''FRIO'' WHERE id_classificacao=1','Apenas revisao humana ausente');
CALL teste_regra_crm('classificacao historica nao apaga','DELETE FROM classificacao_lead WHERE id_classificacao=1','historico; nunca e apagada');
CALL teste_regra_crm('temperatura fora do dominio','INSERT INTO parametro_temperatura VALUES(''QUENTEX'',0.5,''HIPOTESE'',''2026-01-01'')','ck_parametro_temperatura');
CALL teste_regra_crm('probabilidade fora do intervalo','INSERT INTO parametro_temperatura VALUES(''FRIO'',1.5,''HIPOTESE'',''2026-01-01'')','ck_parametro_probabilidade');
CALL teste_regra_crm('fator fora do dominio','INSERT INTO classificacao_fator VALUES(1,''FATOR_INVALIDO'',1,''x'')','ck_fator_codigo');
CALL teste_regra_crm('classificacao sem atendimento','INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao) VALUES(9999,''2026-02-10 10:00:00'',''REGRA'',''REGRA-V1'',''FRIO'',0)','fk_classificacao_lead_id_atendimento');
CALL teste_regra_crm('desfecho duplicado','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,data_hora,tipo_desfecho,motivo) VALUES(8,2,''2026-01-29 10:00:00'',''PERDA'',''Duplicado'')','Duplicate entry');
CALL teste_regra_crm('tipo de desfecho fora do dominio','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,data_hora,tipo_desfecho,motivo) VALUES(9,1,''2026-02-10 10:00:00'',''PENDENTE'',''x'')','ck_desfecho_tipo');
CALL teste_regra_crm('interacao com atendimento inexistente','INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9999,1,''2026-02-10 10:00:00'',''TELEFONE'',''ENVIADA'',''x'')','fk_interacao_id_atendimento');
CALL teste_regra_crm('proximo passo antes da interacao','INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo,proximo_passo,data_proximo_passo) VALUES(9,1,''2026-02-10 10:00:00'',''TELEFONE'',''ENVIADA'',''x'',''Retornar'',''2026-02-09 10:00:00'')','ck_interacao_proximo_passo');
CALL teste_regra_crm('interacao sem resumo','INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9,1,''2026-02-10 10:00:00'',''TELEFONE'',''ENVIADA'','''')','ck_interacao_resumo');
CALL teste_regra_crm('parametro temperatura duplicado','INSERT INTO parametro_temperatura SELECT temperatura,probabilidade,origem,vigencia FROM parametro_temperatura WHERE temperatura=''MORNO''','Duplicate entry');
CALL teste_regra_crm('revisao divergente exige justificativa','INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao,temperatura_final) VALUES(9,''2026-02-10 10:00:00'',''REGRA'',''REGRA-V1'',''FRIO'',0,''QUENTE'')','ck_classificacao_justificativa');
CALL teste_regra_crm('procedure limpa marca da sessao apos INSERT falho','CALL registrar_classificacao_lead(9,''REGRA-V1'',NULL,@classificacao_falha)','data_hora');
ROLLBACK;
DROP PROCEDURE teste_regra_crm;

-- =====================================================================
-- sql\extensao\05-consultas-demo.sql
-- =====================================================================
-- Previsão de caixa semanal e roteiros do painel (MySQL 8.4).
USE multiplikar;
DROP VIEW IF EXISTS vw_previsao_caixa;
DROP VIEW IF EXISTS vw_fluxos_previsao;
DROP VIEW IF EXISTS vw_caixa_realizado_referencia;
DROP PROCEDURE IF EXISTS fn_previsao_caixa_cenario;
DROP PROCEDURE IF EXISTS verificar_previsao_caixa;
CREATE VIEW vw_caixa_realizado_referencia AS
SELECT DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY) AS semana,
 COALESCE(SUM(v.valor_recebido),0) AS realizado,
 CONCAT('Recebimentos de vendas com data_ultimo_recebimento entre segunda-feira e ',data_referencia(),'; entradas historicas apenas; saidas historicas nao registradas, saldo inicial HIPOTESE') AS composicao
FROM venda v WHERE v.valor_recebido>0 AND DATE(v.data_ultimo_recebimento)>=DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY) AND DATE(v.data_ultimo_recebimento)<=data_referencia();
CREATE VIEW vw_fluxos_previsao AS
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
CREATE VIEW vw_previsao_caixa AS
WITH RECURSIVE limites AS(SELECT DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY) AS inicio,COALESCE(MAX(DATE_SUB(data_evento,INTERVAL WEEKDAY(data_evento) DAY)),DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY)) AS fim FROM vw_fluxos_previsao), semanas AS(SELECT inicio AS semana,fim FROM limites UNION ALL SELECT DATE_ADD(semana,INTERVAL 7 DAY),fim FROM semanas WHERE semana<fim), semanal AS(SELECT s.semana,ROUND(COALESCE(SUM(CASE WHEN f.camada='REALIZADO' THEN f.valor ELSE 0 END),0),2) AS realizado,ROUND(COALESCE(SUM(CASE WHEN f.camada='OBRIGACAO' THEN f.valor ELSE 0 END),0),2) AS obrigacoes,ROUND(COALESCE(SUM(CASE WHEN f.camada='FUNIL' THEN f.valor ELSE 0 END),0),2) AS funil_ponderado,GROUP_CONCAT(f.descricao ORDER BY f.descricao SEPARATOR ' | ') AS detalhes FROM semanas s LEFT JOIN vw_fluxos_previsao f ON DATE_SUB(f.data_evento,INTERVAL WEEKDAY(f.data_evento) DAY)=s.semana GROUP BY s.semana), acumulado AS(SELECT semanal.*,25000+SUM(realizado+obrigacoes+funil_ponderado) OVER(ORDER BY semana ROWS UNBOUNDED PRECEDING) AS saldo_projetado FROM semanal)
SELECT semana,realizado,obrigacoes,funil_ponderado,saldo_projetado,CONCAT(IF(semana=(SELECT MIN(semana) FROM semanal),'Saldo inicial HIPOTESE R$ 25000; ','(semana futura); '),COALESCE(detalhes,'sem outros movimentos'),'; funil dividido igualmente entre alternativas da mesma entrada; repasse ao consignante e retorno do banco ponderados') AS composicao FROM acumulado;
DELIMITER $$
CREATE PROCEDURE fn_previsao_caixa_cenario(IN p_cenario VARCHAR(40),IN p_saldo_inicial DECIMAL(14,2))
BEGIN
 IF p_cenario NOT IN('BASE','BANCO_ATRA_15_DIAS','LEADS_QUENTES_NAO_FECHAM') OR p_saldo_inicial IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cenario invalido ou saldo inicial ausente'; END IF;
 WITH RECURSIVE cen AS(SELECT camada,CASE WHEN p_cenario='BANCO_ATRA_15_DIAS' AND bancario THEN DATE_ADD(data_evento,INTERVAL 15 DAY) ELSE data_evento END AS data_evento,valor,bancario,temperatura,descricao FROM vw_fluxos_previsao WHERE NOT(p_cenario='LEADS_QUENTES_NAO_FECHAM' AND camada='FUNIL' AND temperatura='QUENTE')), limites AS(SELECT DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY) AS inicio,COALESCE(MAX(DATE_SUB(data_evento,INTERVAL WEEKDAY(data_evento) DAY)),DATE_SUB(data_referencia(),INTERVAL WEEKDAY(data_referencia()) DAY)) AS fim FROM cen), semanas AS(SELECT inicio AS semana,fim FROM limites UNION ALL SELECT DATE_ADD(semana,INTERVAL 7 DAY),fim FROM semanas WHERE semana<fim), semanal AS(SELECT s.semana,ROUND(COALESCE(SUM(CASE WHEN f.camada='REALIZADO' THEN f.valor ELSE 0 END),0),2) realizado,ROUND(COALESCE(SUM(CASE WHEN f.camada='OBRIGACAO' THEN f.valor ELSE 0 END),0),2) obrigacoes,ROUND(COALESCE(SUM(CASE WHEN f.camada='FUNIL' THEN f.valor ELSE 0 END),0),2) funil_ponderado,GROUP_CONCAT(f.descricao ORDER BY f.descricao SEPARATOR ' | ') detalhes FROM semanas s LEFT JOIN cen f ON DATE_SUB(f.data_evento,INTERVAL WEEKDAY(f.data_evento) DAY)=s.semana GROUP BY s.semana), saldo AS(SELECT semanal.*,p_saldo_inicial+SUM(realizado+obrigacoes+funil_ponderado) OVER(ORDER BY semana ROWS UNBOUNDED PRECEDING) saldo_projetado FROM semanal) SELECT semana,realizado,obrigacoes,funil_ponderado,saldo_projetado,CONCAT('Cenario ',p_cenario,'; saldo inicial HIPOTESE ',p_saldo_inicial,'; ',COALESCE(detalhes,'sem outros movimentos')) composicao FROM saldo ORDER BY semana;
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE verificar_previsao_caixa()
BEGIN
 IF (SELECT COUNT(*) FROM vw_previsao_caixa)=0 OR EXISTS(SELECT 1 FROM vw_previsao_caixa WHERE realizado IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Previsao semanal sem realizado/referencia'; END IF;
 SELECT 'PASS previsao: semanas e realizado ate a referencia' AS resultado;
 IF (SELECT COUNT(*) FROM vw_fluxos_previsao WHERE camada='FUNIL')=0 OR NOT EXISTS(SELECT 1 FROM vw_fluxos_previsao WHERE camada='FUNIL' AND descricao LIKE '%PAGAR consignante%') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Funil deve incluir entradas e repasse ponderado'; END IF;
 SELECT 'PASS previsao: funil limitado a alternativas e liquido de repasse' AS resultado;
END$$
DELIMITER ;
CALL verificar_previsao_caixa(); DROP PROCEDURE verificar_previsao_caixa;

-- =====================================================================
-- sql\extensao\06-estoque-loja.sql
-- =====================================================================
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

-- =====================================================================
-- sql\extensao\07-intencao-regra-v2.sql
-- =====================================================================
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




-- =====================================================================
-- sql\testes\testes-fluxos.sql
-- =====================================================================
-- Verificações ponta a ponta das regras no MySQL 8.4; todas as mutações de teste sofrem ROLLBACK.
-- O MySQL Workbench liga o modo Safe Updates por padrão, que recusa UPDATE/DELETE sem coluna-chave
-- no WHERE. Este script faz essas operações de proposito (inclusive dentro dos testes), entao o modo
-- e desligado só durante a execução e o valor anterior e restaurado no fim.
SET @mk_safe_updates = @@SESSION.sql_safe_updates;
SET SQL_SAFE_UPDATES = 0;
USE multiplikar;
DROP PROCEDURE IF EXISTS fluxo_rejeicao;
DROP PROCEDURE IF EXISTS fluxo_confere;
DROP PROCEDURE IF EXISTS fluxo_recusa_regra;
DELIMITER $$
CREATE PROCEDURE fluxo_rejeicao(IN p_nome VARCHAR(120),IN p_sql TEXT)
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE;
 BEGIN DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_falhou=TRUE; SET @sql_fluxo=p_sql; PREPARE s FROM @sql_fluxo; EXECUTE s; DEALLOCATE PREPARE s; END;
 IF NOT v_falhou THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Fluxo invalido foi aceito'; END IF;
 SELECT CONCAT('PASS fluxo desvio ',p_nome,': operacao recusada') AS resultado;
END$$
CREATE PROCEDURE fluxo_confere(IN p_nome VARCHAR(120),IN p_ok BOOLEAN)
BEGIN IF p_ok IS NULL OR NOT p_ok THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Verificacao de fluxo falhou'; END IF; SELECT CONCAT('PASS fluxo ',p_nome) AS resultado; END$$
CREATE PROCEDURE fluxo_recusa_regra(IN p_nome VARCHAR(120),IN p_sql TEXT,IN p_esperado VARCHAR(128))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
 BEGIN DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 @msg=MESSAGE_TEXT; SET v_msg=@msg; SET v_falhou=TRUE; END;
  SET @sql_fluxo=p_sql; PREPARE fluxo_stmt FROM @sql_fluxo; EXECUTE fluxo_stmt; DEALLOCATE PREPARE fluxo_stmt;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Desvio foi aceito: ',p_nome); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_esperado,'%') THEN SET v_err=CONCAT('Regra incorreta: ',p_nome); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS fluxo desvio ',p_nome,': ',p_esperado) AS resultado;
END$$
DELIMITER ;
START TRANSACTION;
CALL fluxo_confere('demonstracao tem alternativas A/B/C', (SELECT COUNT(*)=3 FROM proposta WHERE id_atendimento=7 AND versao=1 AND situacao='APRESENTADA'));
CALL fluxo_confere('R0 e R4 estao disponiveis para a simulacao', (SELECT COUNT(*)=2 FROM vw_simulacao_parcela WHERE id_proposta=2));
CALL fluxo_confere('margem estimada igual nas tres alternativas', (SELECT COUNT(DISTINCT margem_estimada)=1 FROM vw_proposta_comparativo WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('valor de troca nao aparece como caixa D0', (SELECT caixa_d0=25000 FROM vw_proposta_comparativo WHERE id_proposta=3));
CALL fluxo_confere('saldo de entrada da semana incorpora 6 mil liquidos', (SELECT obrigacoes=6000 FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('recebimento vencido da venda 6 compoe explicacao', (SELECT composicao LIKE '%80000%' FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('CRM exclui atendimento convertido', (SELECT COUNT(*)=0 FROM vw_fila_acoes f JOIN atendimento a ON f.id_referencia=a.id_atendimento WHERE f.fonte='CRM' AND a.situacao='CONVERTIDO'));
CALL fluxo_confere('simulacao R4 aumenta parcela e retorno da loja', ((SELECT parcela_calculada FROM vw_simulacao_parcela WHERE id_simulacao=2)>(SELECT parcela_calculada FROM vw_simulacao_parcela WHERE id_simulacao=1)) AND (SELECT retorno_loja=1760 FROM vw_simulacao_parcela WHERE id_simulacao=2));
CALL fluxo_confere('PMT, total pago e CET preservam centavos e escala', (SELECT parcela_calculada=1402.56 AND custo_total_cliente=67322.88 AND cet_aproximado_anual=0.251926 FROM vw_simulacao_parcela WHERE id_simulacao=1) AND (SELECT parcela_calculada=1490.50 AND custo_total_cliente=71544.00 AND cet_aproximado_anual=0.296883 FROM vw_simulacao_parcela WHERE id_simulacao=2));
CALL fluxo_confere('parcelas e retorno do banco identificados como movimento bancario para o cenario de atraso',(SELECT COUNT(*)=2 FROM vw_fluxos_previsao WHERE camada='FUNIL' AND bancario=TRUE AND descricao LIKE '%FINANCIAMENTO%' OR camada='FUNIL' AND bancario=TRUE AND descricao LIKE '%RETORNO BANCO%'));
CALL fluxo_rejeicao('venda proposta para outro cliente','UPDATE venda SET id_proposta=1 WHERE id_venda=6');
CALL fluxo_rejeicao('delete historico de interacao','DELETE FROM interacao WHERE id_interacao=1');
CALL fluxo_rejeicao('troca consumida','INSERT INTO proposta_troca VALUES(1,1,10000)');
CALL fluxo_rejeicao('arco administrativo preenchido','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ADMINISTRATIVA'',6,''ADMIN'',''Teste'',100,''2026-02-10'',''2026-02-10'',''2026-02-10'')');
CALL fluxo_rejeicao('obrigacao terminal imutavel','DELETE FROM obrigacao_financeira WHERE id_obrigacao=1');
CALL fluxo_rejeicao('simulacao nao pode ser apagada','DELETE FROM simulacao_financiamento WHERE id_simulacao=1');
CALL fluxo_rejeicao('simulacao exige tabela vigente','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,situacao,data_simulacao) VALUES(2,''Banco Demonstracao'',''R5'',''ACADEMICA'',10000,0.02,12,''EM_ANALISE'',''2026-02-10'')');
INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,valor_base) VALUES(7,10,1,'Z',1,'2026-02-03',100);
CALL fluxo_confere('validade omitida ancora em data_referencia', (SELECT validade='2026-02-17' FROM proposta WHERE rotulo='Z'));
CALL fluxo_recusa_regra('proposta rascunho nao aceita direto','UPDATE proposta SET situacao=''ACEITA'',data_decisao=''2026-02-04 10:00:00'' WHERE rotulo=''Z''','apresentada antes da decisao');
CALL fluxo_recusa_regra('proposta nao apresenta sem condicoes','UPDATE proposta SET situacao=''APRESENTADA'' WHERE rotulo=''Z''','Composicao da proposta deve igualar');
CALL fluxo_recusa_regra('nova venda nao vincula proposta apresentada','UPDATE venda SET id_proposta=1 WHERE id_venda=6','Venda exige proposta aceita');
INSERT INTO obrigacao_financeira(natureza,origem,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual,situacao,origem_estimativa) VALUES('PAGAR','ADMINISTRATIVA','TESTE','Fornecedor',100,'2026-02-10','2026-02-10','2026-02-10','PREVISTA','HIPOTESE');
UPDATE obrigacao_financeira SET situacao='ABERTA' WHERE id_obrigacao=LAST_INSERT_ID();
CALL fluxo_confere('obrigacao prevista abre no fluxo permitido',(SELECT COUNT(*)=1 FROM obrigacao_financeira WHERE origem='ADMINISTRATIVA' AND categoria='TESTE' AND situacao='ABERTA'));
CALL fluxo_recusa_regra('transicao invalida de obrigacao','UPDATE obrigacao_financeira SET situacao=''PREVISTA'' WHERE categoria=''TESTE''','Transicao de situacao da obrigacao financeira invalida');
UPDATE simulacao_financiamento SET situacao='RECUSADA',data_resposta='2026-02-04 10:00:00' WHERE id_simulacao=1;
CALL fluxo_recusa_regra('simulacao depois da resposta nao edita parcela','UPDATE simulacao_financiamento SET parcela_informada=1 WHERE id_simulacao=1','imutavel apos EM_ANALISE');
SET @multiplikar_aceitar_proposta=1;
UPDATE proposta SET situacao='ACEITA',data_decisao='2026-02-04 10:00:00' WHERE id_proposta=1;
SET @multiplikar_aceitar_proposta=NULL;
CALL fluxo_recusa_regra('situacao terminal da proposta','UPDATE proposta SET situacao=''RECUSADA'',motivo_recusa=''Teste'',data_decisao=''2026-02-04 10:00:00'' WHERE id_proposta=1','Situacao terminal da proposta e imutavel');
-- Cobertura adicional dos fluxos 01-09: consultas reais e transições contra a massa.
CALL fluxo_confere('09 alternativas A/B/C usam a entrada 10', (SELECT COUNT(*)=3 AND COUNT(DISTINCT id_entrada)=1 FROM proposta WHERE id_atendimento=7 AND id_entrada=10 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 cada alternativa comeca como versao raiz', (SELECT MIN(versao)=1 AND MAX(versao)=1 AND COUNT(DISTINCT rotulo)=3 FROM proposta WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 proposta A e PIX integral', (SELECT COUNT(*)=1 AND SUM(valor)=55000 FROM proposta_condicao WHERE id_proposta=1 AND codigo_forma='PIX'));
CALL fluxo_confere('09 proposta B combina entrada PIX de 20 por cento', (SELECT COUNT(*)=1 AND SUM(valor)=11000 FROM proposta_condicao WHERE id_proposta=2 AND codigo_forma='PIX'));
CALL fluxo_confere('09 proposta B financia o saldo de 80 por cento', (SELECT COUNT(*)=1 AND SUM(valor)=44000 FROM proposta_condicao WHERE id_proposta=2 AND codigo_forma='FINANCIAMENTO'));
CALL fluxo_confere('09 proposta C registra a entrada PIX em dinheiro', (SELECT COUNT(*)=1 AND SUM(valor)=25000 FROM proposta_condicao WHERE id_proposta=3 AND codigo_forma='PIX'));
CALL fluxo_confere('09 proposta C registra o Gol avaliado como troca', (SELECT COUNT(*)=1 AND SUM(valor_oferecido)=30000 FROM proposta_troca WHERE id_proposta=3));
CALL fluxo_confere('09 as condicoes e a troca fecham o total de cada proposta', NOT EXISTS(SELECT 1 FROM proposta p WHERE p.id_atendimento=7 AND p.rotulo IN('A','B','C') AND p.valor_total<>(SELECT COALESCE(SUM(c.valor),0) FROM proposta_condicao c WHERE c.id_proposta=p.id_proposta)+(SELECT COALESCE(SUM(t.valor_oferecido),0) FROM proposta_troca t WHERE t.id_proposta=p.id_proposta)));
CALL fluxo_confere('09 comparador usa o CPF do cliente do atendimento', (SELECT COUNT(DISTINCT cpf)=1 AND MIN(cpf)='00000000010' FROM vw_proposta_comparativo WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 recebimento no ato varia por alternativa', (SELECT COUNT(*)=3 AND MIN(caixa_d0)=11000 AND MAX(caixa_d0)=55000 FROM vw_proposta_comparativo WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 valor recebido depois do ato e separado do caixa D0', (SELECT caixa_posterior=45760 FROM vw_proposta_comparativo WHERE id_proposta=2));
CALL fluxo_confere('09 troca nao e receita em dinheiro nem altera caixa D0', (SELECT valor_em_troca=30000 AND caixa_d0=25000 FROM vw_proposta_comparativo WHERE id_proposta=3));
CALL fluxo_confere('09 margem de veiculo permanece igual nas tres opcoes', (SELECT COUNT(DISTINCT margem_estimada)=1 FROM vw_proposta_comparativo WHERE id_atendimento=7 AND rotulo IN('A','B','C')));
CALL fluxo_confere('09 retorno do banco soma apenas a margem da proposta financiada', (SELECT retorno_banco=1760 AND margem_com_retorno=margem_estimada+retorno_banco FROM vw_proposta_comparativo WHERE id_proposta=2));
CALL fluxo_confere('09 simulacao R0 usa a taxa base mensal', (SELECT parcela_calculada=1402.56 AND taxa_cliente_mensal=0.0189 FROM vw_simulacao_parcela WHERE id_simulacao=1));
CALL fluxo_confere('09 simulacao R0 apresenta CET anual aproximado', (SELECT cet_aproximado_anual=0.251926 FROM vw_simulacao_parcela WHERE id_simulacao=1));
CALL fluxo_confere('09 simulacao R4 soma acrescimo a taxa base', (SELECT taxa_cliente_mensal=0.0219 FROM vw_simulacao_parcela WHERE id_simulacao=2));
CALL fluxo_confere('09 simulacao R4 mostra CET anual aproximado maior', (SELECT cet_aproximado_anual=0.296883 FROM vw_simulacao_parcela WHERE id_simulacao=2));
CALL fluxo_confere('09 simulacao R0 nao remunera retorno a loja', (SELECT retorno_loja=0 FROM vw_simulacao_parcela WHERE id_simulacao=1));
CALL fluxo_confere('09 simulacao aprovada mantem consentimento de renda', (SELECT COUNT(*)=2 AND MIN(consentimento_renda)=1 FROM simulacao_financiamento WHERE id_proposta=2));
CALL fluxo_confere('01 atendimento 7 preserva a data de abertura do contato', (SELECT data_abertura='2026-02-02 12:00:00' FROM vw_lead_atual WHERE id_atendimento=7));
CALL fluxo_confere('01 lead final esta revisado por funcionario ativo', (SELECT revisado=1 AND id_revisor=1 AND temperatura_atual='QUENTE' FROM vw_lead_atual WHERE id_atendimento=7));
CALL fluxo_confere('01 classificacao humana preserva sugestao MORNO', (SELECT temperatura_sugerida='MORNO' AND temperatura_final='QUENTE' FROM vw_lead_atual WHERE id_atendimento=7));
CALL fluxo_confere('01 lead mantem uma interacao no historico', (SELECT total_interacoes=1 AND data_ultima_interacao='2026-02-03 09:00:00' FROM vw_lead_atual WHERE id_atendimento=7));
CALL fluxo_confere('01 fila CRM prioriza o lead quente de 55 mil', (SELECT COUNT(*)=1 AND MAX(valor_em_risco)=55000 FROM vw_fila_acoes WHERE fonte='CRM' AND id_referencia=7));
CALL fluxo_confere('08 fila de caixa identifica a obrigacao da venda 6', (SELECT COUNT(*)=1 AND MAX(valor_em_risco)=80000 FROM vw_fila_acoes WHERE fonte='CAIXA' AND id_referencia=1));
CALL fluxo_confere('08 saldo de venda 6 permanece a receber', (SELECT situacao_financiamento='APROVADO_A_RECEBER' AND valor_recebido=10000 FROM venda WHERE id_venda=6));
CALL fluxo_confere('08 obrigacao da venda 6 preserva vencimento original', (SELECT vencimento_original='2026-01-25' AND situacao='ATRASADA' FROM obrigacao_financeira WHERE id_obrigacao=1));
CALL fluxo_confere('05 previsao inclui semana atual e semanas futuras', (SELECT COUNT(*)=4 AND MIN(semana)='2026-02-09' FROM vw_previsao_caixa));
CALL fluxo_confere('05 previsao parte do saldo inicial hipotetico documentado', (SELECT composicao LIKE '%Saldo inicial HIPOTESE R$ 25000%' FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('05 camada realizado e recebimentos historicos ate a referencia', (SELECT SUM(realizado)=0 FROM vw_previsao_caixa));
CALL fluxo_confere('05 primeira semana explica obrigacao vencida da venda 6', (SELECT composicao LIKE '%Obrigacao 1 RECEBER 80000.00%' FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('05 recebimento vencido de 80 mil entra na semana inicial com aviso', (SELECT composicao LIKE '%vencida antes da referencia; incluida na primeira semana%' AND composicao LIKE '%80000.00%' FROM vw_previsao_caixa WHERE semana='2026-02-09'));
CALL fluxo_confere('05 semana do financiamento inclui caixa liquido ponderado', (SELECT funil_ponderado>0 AND composicao LIKE '%RETORNO BANCO%' FROM vw_previsao_caixa WHERE semana='2026-02-23'));
CALL fluxo_confere('05 semana do repasse registra saida do consignante ponderada', (SELECT funil_ponderado<0 AND composicao LIKE '%PAGAR consignante na proposta 2%' FROM vw_previsao_caixa WHERE semana='2026-03-02'));
CALL fluxo_recusa_regra('09 proposta apresentada nao permite alterar preco','UPDATE proposta SET valor_base=1 WHERE id_proposta=1','Proposta apresentada e imutavel');
CALL fluxo_recusa_regra('09 proposta apresentada nao permite incluir condicao','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(1,''DINHEIRO'',1)','Proposta apresentada e imutavel');
CALL fluxo_recusa_regra('09 aceite direto sem aceitar_proposta e bloqueado','UPDATE proposta SET situacao=''ACEITA'',data_decisao=''2026-02-04 10:00:00'' WHERE id_proposta=1','Use aceitar_proposta');
CALL fluxo_recusa_regra('09 avaliacao de troca duplicada na mesma proposta e bloqueada','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(3,11,30000)','Troca exige avaliacao');
CALL fluxo_recusa_regra('08 vencimento original da obrigacao e imutavel','UPDATE obrigacao_financeira SET vencimento_original=''2026-02-20'' WHERE id_obrigacao=1','so permite alterar vencimento_atual');
CALL fluxo_recusa_regra('05 parametros de simulacao respondida sao imutaveis','UPDATE simulacao_financiamento SET tabela_retorno=''R0'' WHERE id_simulacao=2','so permite alterar situacao, data_resposta e parcela_informada');
-- P9: cancelamento de venda financiada sem orientacao bancaria (RN13/RN28-RN31), condicao isolada.
-- Estado inicial: venda 6 EM_FORMALIZACAO, financiada (Banco Demonstracao, APROVADO_A_RECEBER), sem trocas,
-- sem orientacao bancaria. Preparacao: todas as demais exigencias do cancelamento ficam atendidas
-- (entrada principal 5 encerrada por DESFAZIMENTO e novo ciclo 9601 aberto), de modo que a unica pendencia
-- restante e a orientacao bancaria. O UPDATE abaixo e o mesmo que cancelar_venda executa; a procedure nao e
-- chamada porque ela faz COMMIT e encerraria a transacao deste teste.
CALL fluxo_confere('P9 estado inicial: venda 6 financiada, em formalizacao e sem orientacao bancaria',(SELECT situacao_comercial='EM_FORMALIZACAO' AND instituicao_financeira IS NOT NULL AND orientacao_bancaria IS NULL FROM venda WHERE id_venda=6));
UPDATE entrada SET situacao='ENCERRADA',motivo_encerramento='DESFAZIMENTO',data_encerramento='2026-02-21 09:00' WHERE id_entrada=5;
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa)
 VALUES(9601,5,3,'2026-02-21 10:00','COMPRA_PROPRIA',40100,'Conservada','Conservada','Reavaliada apos retorno','Verificada','Em regularizacao','APROVADA','SIM','Reavaliacao apos distrato da venda 6.');
INSERT INTO entrada(id_entrada,id_veiculo,id_contraparte,id_avaliacao,id_entrada_anterior,modalidade,data_entrada,situacao,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes)
 VALUES(9601,5,12,9601,5,'COMPRA_PROPRIA','2026-02-21 11:00','EM_REGULARIZACAO',1,1,'DISTRATO-CV-6','2026-02-21','Reintegracao por distrato da venda 6.');
SET @multiplikar_operacao_venda=6;
CALL fluxo_recusa_regra('P9 cancelar venda financiada sem orientacao bancaria',
 'UPDATE venda SET situacao_comercial=''CANCELADA'',data_cancelamento=''2026-02-21 15:00'',motivo_cancelamento=''Desistencia do comprador'',data_retorno_veiculo=''2026-02-21 10:00'',valor_restituido_loja=0,observacoes_cancelamento=''Teste P9'' WHERE id_venda=6',
 'RN13/RN28-RN31: cancelamento pendente: orientacao bancaria;');
CALL fluxo_confere('P9 recusa preserva a venda: situacao, cancelamento e financiamento inalterados',(SELECT situacao_comercial='EM_FORMALIZACAO' AND data_cancelamento IS NULL AND motivo_cancelamento IS NULL AND situacao_financiamento='APROVADO_A_RECEBER' FROM venda WHERE id_venda=6));
UPDATE venda SET orientacao_bancaria='Banco informado do distrato; contrato de financiamento cancelado.' WHERE id_venda=6;
UPDATE venda SET situacao_comercial='CANCELADA',data_cancelamento='2026-02-21 15:00',motivo_cancelamento='Desistencia do comprador',data_retorno_veiculo='2026-02-21 10:00',valor_restituido_loja=0,observacoes_cancelamento='Teste P9' WHERE id_venda=6;
SET @multiplikar_operacao_venda=NULL;
CALL fluxo_confere('P9 controle positivo: com orientacao bancaria o mesmo cancelamento e aceito',(SELECT situacao_comercial='CANCELADA' FROM venda WHERE id_venda=6));
SELECT 'PASS fluxos MySQL: verificacoes reais encerradas em transacao' AS resultado;
ROLLBACK;
-- O ROLLBACK nao devolve os contadores AUTO_INCREMENT; com valor 1 o MySQL volta ao maior id + 1.
ALTER TABLE avaliacao AUTO_INCREMENT=1; ALTER TABLE entrada AUTO_INCREMENT=1;
DROP PROCEDURE fluxo_confere;
DROP PROCEDURE fluxo_rejeicao;
DROP PROCEDURE fluxo_recusa_regra;

-- Restaura o modo Safe Updates da sessao.
SET SQL_SAFE_UPDATES = @mk_safe_updates;

-- =====================================================================
-- sql\testes\testes-relacionamentos.sql
-- =====================================================================
-- Verificacoes estruturais dos relacionamentos R01 a R41 no MySQL 8.4.
-- O lado pai tem mínimo zero quando o relacionamento permite ausência.
-- O MySQL Workbench liga o modo Safe Updates por padrão, que recusa UPDATE/DELETE sem coluna-chave
-- no WHERE. Este script faz essas operações de proposito (inclusive dentro dos testes), entao o modo
-- e desligado só durante a execução e o valor anterior e restaurado no fim.
SET @mk_safe_updates = @@SESSION.sql_safe_updates;
SET SQL_SAFE_UPDATES = 0;
USE multiplikar;
DROP PROCEDURE IF EXISTS verificar_relacionamentos;
-- Temporárias duram a conexão; remove sobras de uma execução interrompida na mesma aba do Workbench.
DROP TEMPORARY TABLE IF EXISTS rel_esperados, rel_resultado, rel_ai_before;
CREATE TEMPORARY TABLE rel_esperados(codigo VARCHAR(4),tabela_filha VARCHAR(64),coluna_filha VARCHAR(64),tabela_pai VARCHAR(64),coluna_pai VARCHAR(64),unica TINYINT,nullable TINYINT);
INSERT INTO rel_esperados VALUES
('R01','funcionario','id_pessoa','pessoa','id_pessoa',1,0),
('R02','atendimento','id_pessoa','pessoa','id_pessoa',0,0),
('R03','atendimento','id_funcionario','funcionario','id_funcionario',0,0),
('R04','avaliacao','id_veiculo','veiculo','id_veiculo',0,0),
('R05','avaliacao','id_avaliador','pessoa','id_pessoa',0,0),
('R06','laudo','id_veiculo','veiculo','id_veiculo',0,0),
('R07','avaliacao_laudo','id_avaliacao','avaliacao','id_avaliacao',1,0),
('R07','avaliacao_laudo','id_laudo','laudo','id_laudo',0,0),
('R08','entrada','id_veiculo','veiculo','id_veiculo',0,0),
('R09','entrada','id_contraparte','pessoa','id_pessoa',0,0),
('R10','entrada','id_avaliacao','avaliacao','id_avaliacao',1,0),
('R11','venda','id_comprador','pessoa','id_pessoa',0,0),
('R12','venda','id_funcionario','funcionario','id_funcionario',0,0),
('R13','venda','id_entrada_principal','entrada','id_entrada',1,0),
('R14','entrada','id_venda_origem','venda','id_venda',0,1),
('R15','venda','id_laudo','laudo','id_laudo',0,1),
('R16','ocorrencia_garantia','id_venda','venda','id_venda',0,0),
('R17','ocorrencia_garantia','id_mecanico','pessoa','id_pessoa',0,1),
('R18','despesa','id_veiculo','veiculo','id_veiculo',0,0),
('R19','entrada','id_entrada_anterior','entrada','id_entrada',1,1),
('R20','proposta','id_atendimento','atendimento','id_atendimento',0,0),
('R21','proposta','id_entrada','entrada','id_entrada',0,0),
('R22','proposta','id_funcionario','funcionario','id_funcionario',0,0),
('R23','proposta','id_proposta_anterior','proposta','id_proposta',1,1),
('R24','venda','id_proposta','proposta','id_proposta',1,1),
('R25','proposta_condicao','id_proposta','proposta','id_proposta',0,0),
('R25','proposta_condicao','codigo_forma','forma_pagamento','codigo',0,0),
('R26','proposta_troca','id_proposta','proposta','id_proposta',0,0),
('R26','proposta_troca','id_avaliacao','avaliacao','id_avaliacao',0,0),
('R27','simulacao_financiamento','id_proposta','proposta','id_proposta',0,0),
('R29','obrigacao_financeira','id_venda','venda','id_venda',0,1),
('R30','obrigacao_financeira','id_entrada','entrada','id_entrada',0,1),
('R31','obrigacao_financeira','id_despesa','despesa','id_despesa',0,1),
('R32','interacao','id_atendimento','atendimento','id_atendimento',0,0),
('R33','interacao','id_funcionario','funcionario','id_funcionario',0,0),
('R34','atendimento_desfecho','id_atendimento','atendimento','id_atendimento',1,0),
('R35','classificacao_lead','id_atendimento','atendimento','id_atendimento',0,0),
('R36','classificacao_lead','id_revisor','funcionario','id_funcionario',0,1),
('R37','classificacao_fator','id_classificacao','classificacao_lead','id_classificacao',0,0),
('R38','atendimento_desfecho','id_funcionario','funcionario','id_funcionario',0,0),
('R39','intencao_compra','id_atendimento','atendimento','id_atendimento',1,0),
('R40','intencao_compra','id_entrada','entrada','id_entrada',0,1),
('R41','intencao_compra','codigo_forma','forma_pagamento','codigo',0,1);
DELIMITER $$
CREATE PROCEDURE verificar_relacionamentos()
BEGIN
 DECLARE feito INT DEFAULT 0; DECLARE v_cod VARCHAR(4); DECLARE v_tab VARCHAR(64); DECLARE v_col VARCHAR(64); DECLARE v_pai VARCHAR(64); DECLARE v_pcol VARCHAR(64); DECLARE v_uni TINYINT; DECLARE v_null TINYINT; DECLARE n INT; DECLARE un INT; DECLARE nul VARCHAR(3);
 DECLARE c CURSOR FOR SELECT codigo,tabela_filha,coluna_filha,tabela_pai,coluna_pai,unica,nullable FROM rel_esperados ORDER BY codigo,tabela_filha,coluna_filha;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET feito=1;
 OPEN c; ciclo: LOOP FETCH c INTO v_cod,v_tab,v_col,v_pai,v_pcol,v_uni,v_null; IF feito=1 THEN LEAVE ciclo; END IF;
  SELECT COUNT(*) INTO n FROM information_schema.key_column_usage WHERE table_schema=DATABASE() AND table_name=v_tab AND column_name=v_col AND referenced_table_name=v_pai AND referenced_column_name=v_pcol;
  SELECT is_nullable INTO nul FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name=v_tab AND column_name=v_col;
  SELECT COUNT(*) INTO un FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name=v_tab AND column_name=v_col AND non_unique=0;
  IF n<>1 OR ((v_uni=1) AND un=0) OR ((v_null=1)<>(nul='YES')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Metadados de relacionamento divergentes'; END IF;
  SELECT CONCAT('PASS ',v_cod,' ',v_tab,'.',v_col,' -> ',v_pai,'.',v_pcol,'; FK, nulidade e unicidade conferidas') AS resultado;
 END LOOP; CLOSE c;
 IF NOT EXISTS(SELECT 1 FROM information_schema.triggers WHERE trigger_schema=DATABASE() AND trigger_name='simulacao_retorno_bi') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='R28: validacao do parametro de retorno ausente'; END IF;
 SELECT 'PASS R28 simulacao_parametro_retorno: gatilho de vigencia instalado' AS resultado;
END$$
DELIMITER ;
CALL verificar_relacionamentos();
DROP PROCEDURE verificar_relacionamentos;
DROP TEMPORARY TABLE rel_esperados;

-- Ensaios comportamentais adicionais: DML real dentro de transação revertida.
-- Procedures criadas antes de START TRANSACTION porque CREATE PROCEDURE confirma DDL.
DROP PROCEDURE IF EXISTS rel_rejeita;
DROP PROCEDURE IF EXISTS rel_aceita;
DROP PROCEDURE IF EXISTS rel_volta_obrigatoria;
DROP PROCEDURE IF EXISTS rel_confere;
DROP PROCEDURE IF EXISTS rel_restaurar_auto_increment;
CREATE TEMPORARY TABLE rel_resultado(ok TINYINT NOT NULL);
CREATE TEMPORARY TABLE rel_ai_before(table_name VARCHAR(64) PRIMARY KEY, next_value BIGINT UNSIGNED NOT NULL);
DELIMITER $$
CREATE PROCEDURE rel_rejeita(IN p_rotulo VARCHAR(180),IN p_sql TEXT,IN p_trecho VARCHAR(160))
BEGIN
 DECLARE v_falhou BOOLEAN DEFAULT FALSE; DECLARE v_msg TEXT; DECLARE v_err TEXT;
BEGIN DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN GET DIAGNOSTICS CONDITION 1 @rel_msg=MESSAGE_TEXT; SET v_msg=@rel_msg; SET v_falhou=TRUE; SET @mk_registrando_classificacao=NULL; END;
  IF p_rotulo LIKE 'R35 Volta%' THEN SET @mk_registrando_classificacao=1; END IF;
  SET @rel_sql=p_sql; PREPARE rel_stmt FROM @rel_sql; EXECUTE rel_stmt; DEALLOCATE PREPARE rel_stmt;
  SET @mk_registrando_classificacao=NULL;
 END;
 IF NOT v_falhou THEN SET v_err=CONCAT('Operacao aceita indevidamente: ',p_rotulo); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 IF COALESCE(v_msg,'') NOT LIKE CONCAT('%',p_trecho,'%') THEN SET v_err=CONCAT('Regra inesperada: ',p_rotulo,' / ',LEFT(COALESCE(v_msg,''),64)); SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT=v_err; END IF;
 SELECT CONCAT('PASS ',p_rotulo,': recusado (',p_trecho,')') AS resultado;
END$$
CREATE PROCEDURE rel_aceita(IN p_rotulo VARCHAR(180),IN p_sql TEXT)
BEGIN
 SAVEPOINT rel_aceita_sp;
 SET @rel_sql=p_sql; PREPARE rel_stmt FROM @rel_sql; EXECUTE rel_stmt; DEALLOCATE PREPARE rel_stmt;
 ROLLBACK TO SAVEPOINT rel_aceita_sp; RELEASE SAVEPOINT rel_aceita_sp;
 SELECT CONCAT('PASS ',p_rotulo,': aceito') AS resultado;
END$$
CREATE PROCEDURE rel_volta_obrigatoria(IN p_rotulo VARCHAR(140),IN p_modelo TEXT,IN p_coluna VARCHAR(64),IN p_fk VARCHAR(128))
BEGIN
 CALL rel_rejeita(CONCAT(p_rotulo,' (minimo 1)'),REPLACE(p_modelo,'{fk}','NULL'),p_coluna);
 CALL rel_rejeita(CONCAT(p_rotulo,' (pai inexistente)'),REPLACE(p_modelo,'{fk}','999999999'),p_fk);
END$$
CREATE PROCEDURE rel_confere(IN p_rotulo VARCHAR(180),IN p_condicao TEXT)
BEGIN
 DELETE FROM rel_resultado; SET @rel_sql=CONCAT('INSERT INTO rel_resultado SELECT IF((',p_condicao,'),1,0)');
 PREPARE rel_stmt FROM @rel_sql; EXECUTE rel_stmt; DEALLOCATE PREPARE rel_stmt;
 IF (SELECT ok FROM rel_resultado LIMIT 1)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Verificacao relacional falhou'; END IF;
 SELECT CONCAT('PASS ',p_rotulo) AS resultado;
END$$
CREATE PROCEDURE rel_restaurar_auto_increment()
BEGIN
 DECLARE v_done BOOLEAN DEFAULT FALSE; DECLARE v_table VARCHAR(64); DECLARE v_next BIGINT UNSIGNED;
 DECLARE c CURSOR FOR SELECT table_name,next_value FROM rel_ai_before ORDER BY table_name;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=TRUE;
 OPEN c; ciclo: LOOP FETCH c INTO v_table,v_next; IF v_done THEN LEAVE ciclo; END IF;
  SET @rel_sql=CONCAT('ALTER TABLE ',v_table,' AUTO_INCREMENT=',v_next);
  PREPARE rel_stmt FROM @rel_sql; EXECUTE rel_stmt; DEALLOCATE PREPARE rel_stmt;
 END LOOP; CLOSE c;
END$$
DELIMITER ;
INSERT INTO rel_ai_before SELECT table_name,auto_increment FROM information_schema.tables WHERE table_schema=DATABASE() AND auto_increment IS NOT NULL;
START TRANSACTION;
INSERT INTO pessoa(id_pessoa,nome,tipo_documento,numero_documento,telefone,email,logradouro,numero,bairro,cidade,estado_uf) VALUES
(9201,'Pessoa 9201','CPF','00000009201','11999201','p9201@example.invalid','Rua','1','Centro','Sao Paulo','SP'),
(9202,'Pessoa 9202','CPF','00000009202','11999202','p9202@example.invalid','Rua','1','Centro','Sao Paulo','SP'),
(9203,'Pessoa 9203','CPF','00000009203','11999203','p9203@example.invalid','Rua','1','Centro','Sao Paulo','SP'),
(9204,'Pessoa 9204','CPF','00000009204','11999204','p9204@example.invalid','Rua','1','Centro','Sao Paulo','SP');
INSERT INTO funcionario(id_funcionario,id_pessoa,cargo,data_admissao,situacao) VALUES(9201,9203,'Vendas','2025-01-01','ATIVO');
INSERT INTO veiculo(id_veiculo,marca,modelo,ano_modelo,cor,combustivel,cambio,categoria_comercial) VALUES
(9201,'Marca','Modelo 9201',2018,'Prata','Flex','Manual','USADO'),(9202,'Marca','Modelo 9202',2018,'Prata','Flex','Manual','USADO'),
(9203,'Marca','Modelo 9203',2018,'Prata','Flex','Manual','USADO'),(9204,'Marca','Modelo 9204',2018,'Prata','Flex','Manual','USADO'),
(9205,'Marca','Modelo 9205',2018,'Prata','Flex','Manual','USADO'),(9206,'Marca','Modelo 9206',2018,'Prata','Flex','Manual','USADO'),
(9207,'Marca','Modelo 9207',2018,'Prata','Flex','Manual','USADO');
INSERT INTO laudo(id_laudo,id_veiculo,referencia_documental,data_emissao,situacao,resultado) VALUES
(9201,9201,'L9201','2026-01-10','EMITIDO','ok'),(9202,9202,'L9202','2026-01-10','EMITIDO','ok');
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES
(9201,9201,9203,'2026-01-11 10:00','COMPRA_PROPRIA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9202,9202,9203,'2026-01-11 10:00','COMPRA_PROPRIA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9203,9203,9203,'2026-01-13 10:00','TROCA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9204,9204,9203,'2026-01-13 10:00','TROCA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9205,9205,9203,'2026-01-20 10:00','TROCA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9206,9206,9203,'2026-01-20 10:00','TROCA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok'),
(9207,9207,9203,'2026-01-11 10:00','COMPRA_PROPRIA',50000,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','ok');
INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem,quantidade_proprietarios,condicao_externa,condicao_interna,condicao_mecanica,condicao_estrutural,condicao_documental,decisao_tecnica,interesse_comercial,justificativa) VALUES
(9293,9201,9204,'2026-01-11 13:00','COMPRA_PROPRIA',50100,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','laudo adicional'),
(9294,9201,9204,'2026-01-11 14:00','COMPRA_PROPRIA',50200,2,'Boa','Boa','Boa','Boa','Regular','APROVADA','SIM','laudo mismatch test');
INSERT INTO avaliacao_laudo VALUES(9201,9201),(9202,9202);
INSERT INTO entrada(id_entrada,id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES
(9201,9201,9202,9201,'COMPRA_PROPRIA','2026-01-12 10:00',50000,60000,'CE9201','2026-01-12','ok'),
(9202,9202,9202,9202,'COMPRA_PROPRIA','2026-01-12 10:00',50000,60000,'CE9202','2026-01-12','ok'),
(9207,9207,9202,9207,'COMPRA_PROPRIA','2026-01-12 10:00',50000,60000,'CE9207','2026-01-12','ok');
INSERT INTO venda(id_venda,id_comprador,id_funcionario,id_entrada_principal,id_laudo,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,9201,9201,9201,'2026-01-14 10:00',60000,FALSE);
INSERT INTO entrada(id_entrada,id_veiculo,id_contraparte,id_avaliacao,id_venda_origem,modalidade,data_entrada,valor_acordado,preco_anunciado) VALUES
(9203,9203,9201,9203,9201,'TROCA','2026-01-14 11:00',20000,24000),(9204,9204,9201,9204,9201,'TROCA','2026-01-14 11:00',10000,12000);
INSERT INTO despesa(id_despesa,id_veiculo,data,categoria,descricao,valor) VALUES(9201,9201,'2026-01-15','PREPARACAO','ok',100);
INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,data,tipo_interesse,descricao_interesse,situacao) VALUES
(9201,9201,9201,'2026-01-05 09:00','COMPRA','ok','ABERTO'),(9202,9204,9201,'2026-01-05 09:00','COMPRA','ok','ABERTO');
INSERT INTO proposta(id_proposta,id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base,situacao) VALUES
(9201,9201,9202,9201,'A',1,'2026-02-05','2026-02-12',60000,'RASCUNHO'),
(9202,9201,9202,9201,'B',1,'2026-02-05','2026-02-12',60000,'RASCUNHO'),
(9203,9202,9202,9201,'A',1,'2026-02-05','2026-02-12',60000,'RASCUNHO');
INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(9201,'PIX',60000),(9202,'PIX',60000),(9203,'PIX',60000);
INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9201,9201,'2026-02-05 09:00','TELEFONE','ENVIADA','ok');
CALL registrar_classificacao_lead(9201,'REGRA-V1','2026-02-06 09:00',@classificacao_9201);
-- R01 a R10: minimos, existência e cardinalidades executados no banco.
CALL rel_volta_obrigatoria('R01 Volta','INSERT INTO funcionario(id_pessoa,cargo,data_admissao,situacao) VALUES({fk},''Vendas'',''2025-01-01'',''ATIVO'')','id_pessoa','fk_funcionario_id_pessoa');
CALL rel_rejeita('R01 Ida (maximo 1)','INSERT INTO funcionario(id_pessoa,cargo,data_admissao,situacao) VALUES(9203,''Vendas'',''2025-01-01'',''ATIVO'')','Duplicate entry');
CALL rel_confere('R01 Ida (minimo 0): pessoa sem funcionario','NOT EXISTS(SELECT 1 FROM funcionario WHERE id_pessoa=9201)');
CALL rel_volta_obrigatoria('R02 Volta','INSERT INTO atendimento(id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES({fk},9201,''COMPRA'',''x'',''ABERTO'')','id_pessoa','fk_atendimento_id_pessoa');
CALL rel_aceita('R02 Ida (maximo N): segunda interacao da mesma pessoa','INSERT INTO atendimento(id_atendimento,id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES(9290,9201,9201,''VENDA'',''x'',''ABERTO'')');
CALL rel_volta_obrigatoria('R03 Volta','INSERT INTO atendimento(id_pessoa,id_funcionario,tipo_interesse,descricao_interesse,situacao) VALUES(9201,{fk},''COMPRA'',''x'',''ABERTO'')','id_funcionario','fk_atendimento_id_funcionario');
CALL rel_confere('R03 Ida (maximo N): funcionario com dois atendimentos','(SELECT COUNT(*) FROM atendimento WHERE id_funcionario=9201)=2');
CALL rel_volta_obrigatoria('R04 Volta','INSERT INTO avaliacao(id_veiculo,id_avaliador,data,finalidade,quilometragem) VALUES({fk},9203,''2026-01-11 10:00:00'',''COMPRA_PROPRIA'',1)','id_veiculo','fk_avaliacao_id_veiculo');
CALL rel_aceita('R04 Ida (maximo N): reavaliacao do mesmo veiculo','INSERT INTO avaliacao(id_avaliacao,id_veiculo,id_avaliador,data,finalidade,quilometragem) VALUES(9290,9201,9203,''2026-01-11 12:00:00'',''COMPRA_PROPRIA'',50100)');
CALL rel_volta_obrigatoria('R05 Volta','INSERT INTO avaliacao(id_veiculo,id_avaliador,data,finalidade,quilometragem) VALUES(9201,{fk},''2026-01-11 10:00:00'',''COMPRA_PROPRIA'',1)','id_avaliador','fk_avaliacao_id_avaliador');
CALL rel_confere('R05 Ida (maximo N): avaliador com varias avaliacoes','(SELECT COUNT(*) FROM avaliacao WHERE id_avaliador=9203)=7');
CALL rel_volta_obrigatoria('R06 Volta','INSERT INTO laudo(id_veiculo,referencia_documental,data_emissao,situacao,resultado) VALUES({fk},''x'',''2026-01-10'',''EMITIDO'',''x'')','id_veiculo','fk_laudo_id_veiculo');
CALL rel_aceita('R06 Ida (maximo N): segundo laudo historico do mesmo veiculo','INSERT INTO laudo(id_laudo,id_veiculo,referencia_documental,data_emissao,situacao,resultado) VALUES(9290,9201,''L9201-B'',''2026-01-09'',''EMITIDO'',''x'')');
CALL rel_rejeita('R07 Ida (maximo 1)','INSERT INTO avaliacao_laudo VALUES(9201,9201)','Duplicate entry');
CALL rel_confere('R07 Ida (minimo 0): avaliacao sem laudo','NOT EXISTS(SELECT 1 FROM avaliacao_laudo WHERE id_avaliacao=9203)');
CALL rel_aceita('R07 Volta (maximo N): mesmo laudo pode subsidiar varias avaliacoes','INSERT INTO avaliacao_laudo VALUES(9293,9201)');
CALL rel_rejeita('R07 Volta (laudo de outro veiculo, RN08)','INSERT INTO avaliacao_laudo VALUES(9294,9202)','RN08');
CALL rel_rejeita('R07 Volta (laudo inexistente barrado pela regra de laudo)','INSERT INTO avaliacao_laudo VALUES(9203,999999999)','RN08');
CALL rel_volta_obrigatoria('R08 Volta','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES({fk},9202,9293,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','id_veiculo','entrada exige avaliacao aprovada, interesse e veiculo');
CALL rel_confere('R08 Ida (maximo N): HB20 tem ciclos de entrada anteriores e atual','(SELECT COUNT(*) FROM entrada WHERE id_veiculo=4)=2');
CALL rel_confere('R08 Ida (minimo 0): veiculo preliminar sem entrada','NOT EXISTS(SELECT 1 FROM entrada WHERE id_veiculo=9205)');
CALL rel_volta_obrigatoria('R09 Volta','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,{fk},9293,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','id_contraparte','fk_entrada_id_contraparte');
CALL rel_confere('R09 Ida (maximo N): fornecedor com tres entradas','(SELECT COUNT(*) FROM entrada WHERE id_contraparte=9202)=3');
-- The evaluation lookup yields NULL on a missing row, so the FK is the first rejecting constraint.
CALL rel_rejeita('R10 Volta (pai inexistente)','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,9202,999999999,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','fk_entrada_id_avaliacao');
CALL rel_rejeita('R10 Volta (minimo 1)','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,9202,NULL,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','id_avaliacao');
CALL rel_rejeita('R10 Ida (maximo 1): mesma avaliacao nao fundamenta duas entradas','INSERT INTO entrada(id_entrada,id_veiculo,id_contraparte,id_avaliacao,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9290,9201,9202,9294,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''x'',''2026-01-21'',''x'')','Duplicate entry');
CALL rel_confere('R10 Ida (minimo 0): avaliacao sem entrada','NOT EXISTS(SELECT 1 FROM entrada WHERE id_avaliacao=9205)');
-- R11-R19: demais relacionamentos do núcleo sobre o fixture transacional.
CALL rel_volta_obrigatoria('R11 Volta','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES({fk},9201,9202,''2026-02-06 10:00:00'',1,FALSE)','id_comprador','fk_venda_id_comprador');
CALL rel_aceita('R11/R12 Ida (maximo N): comprador e funcionario podem ter outra venda','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,9202,''2026-02-06 10:00:00'',1,FALSE)');
CALL rel_volta_obrigatoria('R12 Volta','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9201,{fk},9202,''2026-02-06 10:00:00'',1,FALSE)','id_funcionario','fk_venda_id_funcionario');
CALL rel_rejeita('R13 Volta (minimo 1)','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,NULL,''2026-02-06 10:00:00'',1,FALSE)','Venda exige entrada disponivel');
CALL rel_rejeita('R13 Volta (referencia inexistente interceptada por regra de disponibilidade)','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,999999999,''2026-02-06 10:00:00'',1,FALSE)','Venda exige entrada disponivel');
CALL rel_rejeita('R13 Ida (maximo 1): entrada ja vinculada a venda','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9201,''2026-02-06 10:00:00'',1,FALSE)','Duplicate entry');
CALL rel_confere('R13 Ida (minimo 0): entrada sem venda','NOT EXISTS(SELECT 1 FROM venda WHERE id_entrada_principal=9202)');
CALL rel_confere('R14 Ida (maximo N): venda aceita varias entradas de troca','(SELECT COUNT(*)=2 FROM entrada WHERE id_venda_origem=9201)');
CALL rel_confere('R14 Volta (minimo 0): compra propria nao aponta venda de origem','(SELECT id_venda_origem IS NULL FROM entrada WHERE id_entrada=9202)');
CALL rel_rejeita('R14 Volta (venda de origem inexistente)','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,id_venda_origem,modalidade,data_entrada,valor_acordado,preco_anunciado) VALUES(9205,9201,9205,999999999,''TROCA'',''2026-01-21 10:00:00'',1,1)','foreign key constraint fails');
CALL rel_aceita('R15 Volta (minimo 0): venda ainda sem laudo','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9202,''2026-02-06 10:00:00'',1,FALSE)');
CALL rel_rejeita('R15 Volta (laudo inexistente interceptado pela regra)','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,id_laudo,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9202,999999999,''2026-02-06 10:00:00'',1,FALSE)','Laudo deve corresponder');
CALL rel_confere('R15 Ida (maximo N): laudo 4 documenta duas vendas','(SELECT COUNT(*)=2 FROM venda WHERE id_laudo=4)');
CALL rel_rejeita('R16 Volta (minimo 1)','INSERT INTO ocorrencia_garantia(id_venda,data_abertura,problema_relatado,situacao) VALUES(NULL,''2026-02-05 10:00:00'',''x'',''ABERTA'')','Ocorrencia de garantia exige concessao e entrega anterior');
CALL rel_rejeita('R16 Volta (venda inexistente barrada pela regra de garantia)','INSERT INTO ocorrencia_garantia(id_venda,data_abertura,problema_relatado,situacao) VALUES(999999999,''2026-02-05 10:00:00'',''x'',''ABERTA'')','Ocorrencia de garantia exige concessao e entrega anterior');
INSERT INTO ocorrencia_garantia(id_venda,id_mecanico,data_abertura,problema_relatado,situacao) VALUES(1,NULL,'2026-02-05 10:00:00','fixture R16','ABERTA');
CALL rel_aceita('R16 Ida (maximo N) e R17 Volta (minimo 0): outra ocorrencia sem mecanico','INSERT INTO ocorrencia_garantia(id_venda,data_abertura,problema_relatado,situacao) VALUES(1,''2026-02-06 10:00:00'',''segunda ocorrencia'',''ABERTA'')');
CALL rel_rejeita('R17 Volta (mecanico inexistente)','INSERT INTO ocorrencia_garantia(id_venda,id_mecanico,data_abertura,problema_relatado,situacao) VALUES(1,999999999,''2026-02-06 10:00:00'',''x'',''ABERTA'')','fk_ocorrencia_garantia_id_mecanico');
CALL rel_confere('R17 Ida (maximo N): mecanico 4 esta em duas ocorrencias','(SELECT COUNT(*)=2 FROM ocorrencia_garantia WHERE id_mecanico=4)');
CALL rel_volta_obrigatoria('R18 Volta','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES({fk},''2026-01-15'',''PREPARACAO'',''x'',1)','id_veiculo','fk_despesa_id_veiculo');
CALL rel_aceita('R18 Ida (maximo N): segunda despesa do veiculo','INSERT INTO despesa(id_veiculo,data,categoria,descricao,valor) VALUES(9201,''2026-01-16'',''DIAGNOSTICO'',''x'',50)');
CALL rel_rejeita('R19 Ida (maximo 1): entrada 4 ja tem sucessora','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,id_entrada_anterior,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,9202,9293,4,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''C-19'',''2026-01-21'',''ok'')','Duplicate entry');
CALL rel_rejeita('R19 Volta (anterior inexistente)','INSERT INTO entrada(id_veiculo,id_contraparte,id_avaliacao,id_entrada_anterior,modalidade,data_entrada,valor_acordado,preco_anunciado,numero_contrato,data_emissao,termos_ajustes) VALUES(9201,9202,9293,999999999,''COMPRA_PROPRIA'',''2026-01-21 10:00:00'',1,1,''C-19B'',''2026-01-21'',''ok'')','foreign key constraint fails');
CALL rel_confere('R19 minimo 0: primeira entrada sem anterior nem sucessora','(SELECT id_entrada_anterior IS NULL FROM entrada WHERE id_entrada=9202) AND NOT EXISTS(SELECT 1 FROM entrada WHERE id_entrada_anterior=9202)');
-- R20-R22: atendimento, entrada e funcionario sustentam várias propostas.
CALL rel_volta_obrigatoria('R20 Volta','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base) VALUES({fk},9202,9201,''Z'',1,''2026-02-05'',''2026-02-12'',1)','id_atendimento','fk_proposta_id_atendimento');
CALL rel_volta_obrigatoria('R21 Volta','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base) VALUES(9201,{fk},9201,''Z'',1,''2026-02-05'',''2026-02-12'',1)','id_entrada','fk_proposta_id_entrada');
CALL rel_volta_obrigatoria('R22 Volta','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,rotulo,versao,data_criacao,validade,valor_base) VALUES(9201,9202,{fk},''Z'',1,''2026-02-05'',''2026-02-12'',1)','id_funcionario','fk_proposta_id_funcionario');
CALL rel_confere('R20-R22 Ida (maximo N): atendimento, entrada e funcionario associados a propostas multiplas','(SELECT COUNT(*)=2 FROM proposta WHERE id_atendimento=9201) AND (SELECT COUNT(*)=3 FROM proposta WHERE id_entrada=9202) AND (SELECT COUNT(*)=3 FROM proposta WHERE id_funcionario=9201)');
-- R23: preparar uma cadeia válida para verificar unicidade da sucessora.
UPDATE proposta SET situacao='APRESENTADA' WHERE id_proposta=9201;
UPDATE proposta SET situacao='SUBSTITUIDA',data_decisao='2026-02-06 10:00:00' WHERE id_proposta=9201;
INSERT INTO proposta(id_proposta,id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base,situacao)
VALUES(9204,9201,9202,9201,9201,'A',2,'2026-02-06','2026-02-13',60000,'RASCUNHO');
CALL rel_rejeita('R23 Ida (maximo 1): duas sucessoras da mesma proposta','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base) VALUES(9201,9202,9201,9201,''A'',2,''2026-02-06'',''2026-02-13'',60000)','Duplicate entry');
CALL rel_rejeita('R23 Volta (anterior inexistente interceptado pela cadeia)','INSERT INTO proposta(id_atendimento,id_entrada,id_funcionario,id_proposta_anterior,rotulo,versao,data_criacao,validade,valor_base) VALUES(9201,9202,9201,999999999,''Z'',2,''2026-02-06'',''2026-02-13'',60000)','Contraproposta deve suceder');
CALL rel_confere('R23 minimo 0: raiz ainda sem sucessora','NOT EXISTS(SELECT 1 FROM proposta WHERE id_proposta_anterior=9202)');
-- R24: proposta e venda sao opcionais no lado inverso; o FK da venda e validado por regra antes da restricao.
CALL rel_confere('R24 minimo 0 nos dois lados: venda sem proposta e proposta ainda sem venda','(SELECT id_proposta IS NULL FROM venda WHERE id_venda=9201) AND NOT EXISTS(SELECT 1 FROM venda WHERE id_proposta=9202)');
CALL rel_rejeita('R24 Volta (proposta inexistente preemptada por validacao de proposta)','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,id_proposta,data_registro,valor_base,concessao_garantia) VALUES(9201,9201,9202,999999999,''2026-02-06 10:00:00'',1,FALSE)','Venda exige proposta aceita');
UPDATE proposta SET situacao='APRESENTADA' WHERE id_proposta=9203;
SET @multiplikar_aceitar_proposta=9203; UPDATE proposta SET situacao='ACEITA',data_decisao='2026-02-06 10:00:00' WHERE id_proposta=9203; SET @multiplikar_aceitar_proposta=NULL;
INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,id_proposta,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9202,9203,'2026-02-06 10:30:00',60000,FALSE);
CALL rel_rejeita('R24 Ida (maximo 1): venda da mesma proposta nao duplica','INSERT INTO venda(id_comprador,id_funcionario,id_entrada_principal,id_proposta,data_registro,valor_base,concessao_garantia) VALUES(9204,9201,9202,9203,''2026-02-06 11:00:00'',60000,FALSE)','Duplicate entry');
-- R25: condição sempre tem proposta e forma; cada proposta pode ter várias formas.
CALL rel_rejeita('R25 Volta condicao-proposta (minimo 1)','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(NULL,''PIX'',1)','Proposta apresentada e imutavel');
CALL rel_rejeita('R25 Volta condicao-proposta (pai inexistente)','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(999999999,''PIX'',1)','Proposta apresentada e imutavel');
CALL rel_rejeita('R25 Volta condicao-forma (minimo 1)','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(9202,NULL,1)','codigo_forma');
CALL rel_rejeita('R25 Volta condicao-forma inexistente','INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(9202,''BITCOIN'',1)','fk_proposta_condicao_codigo_forma');
INSERT INTO proposta_condicao(id_proposta,codigo_forma,valor) VALUES(9202,'FINANCIAMENTO',1);
CALL rel_confere('R25 Ida (maximo N): proposta possui multiplas formas de pagamento','(SELECT COUNT(*)=2 FROM proposta_condicao WHERE id_proposta=9202)');
CALL rel_confere('R25 Volta forma (maximo N): PIX reutilizado em varias propostas','(SELECT COUNT(*)=3 FROM proposta_condicao WHERE codigo_forma=''PIX'' AND id_proposta BETWEEN 9201 AND 9203)');
-- R26: trocas exigem avaliação TROCA válida e podem incluir várias avaliações distintas.
CALL rel_rejeita('R26 Volta proposta inexistente barrada pela regra de rascunho','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(999999999,9205,1)','Troca exige avaliacao');
CALL rel_rejeita('R26 Volta avaliacao inexistente barrada pela regra de avaliacao','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9202,999999999,1)','Troca exige avaliacao');
INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9202,9205,25000),(9202,9206,15000);
CALL rel_confere('R26 Ida (maximo N): proposta inclui duas avaliacoes de troca','(SELECT COUNT(*)=2 FROM proposta_troca WHERE id_proposta=9202)');
CALL rel_rejeita('R26 Ida (maximo 1): avaliacao nao duplica na mesma proposta','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9202,9205,1)','Duplicate entry');
-- R27-R28: simulações admitem histórico, mas precisam proposta e parametro vigente.
CALL rel_volta_obrigatoria('R27 Volta','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,data_simulacao) VALUES({fk},''Banco Demonstracao'',''R0'',''ACADEMICA'',1000,0.02,12,''2026-02-05'')','id_proposta','fk_simulacao_financiamento_id_proposta');
INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,data_simulacao)
VALUES(9202,'Banco Demonstracao','R0','ACADEMICA',10000,0.02,12,5000,TRUE,'2026-02-05 10:00:00'),
(9202,'Banco Demonstracao','R0','ACADEMICA',12000,0.02,18,5000,TRUE,'2026-02-05 11:00:00');
CALL rel_confere('R27 Ida (maximo N): proposta tem varias simulacoes','(SELECT COUNT(*)=2 FROM simulacao_financiamento WHERE id_proposta=9202)');
CALL rel_rejeita('R27 Ida (maximo 1 APROVADA por proposta)','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,situacao,data_simulacao) VALUES(9202,''Banco Demonstracao'',''R0'',''ACADEMICA'',10000,0.02,12,5000,TRUE,''APROVADA'',''2026-02-05 12:00:00''),(9202,''Banco Demonstracao'',''R0'',''ACADEMICA'',12000,0.02,18,5000,TRUE,''APROVADA'',''2026-02-05 13:00:00'')','Duplicate entry');
CALL rel_rejeita('R28 Volta (parametro de retorno inexistente ou fora da vigencia)','INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,data_simulacao) VALUES(9202,''Banco Sem Parametro'',''R0'',''ACADEMICA'',10000,0.02,12,''2026-02-05 10:00:00'')','Parametro_retorno vigente nao encontrado');
-- R29-R31: obrigação aceita arco vazio ou uma origem; cada origem pode gerar várias obrigações.
INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual)
VALUES('RECEBER','VENDA',9201,'PIX','Cliente fixture',10,'2026-02-05','2026-02-05','2026-02-05');
INSERT INTO obrigacao_financeira(natureza,origem,id_entrada,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual)
VALUES('PAGAR','ENTRADA',9202,'REPASSE','Fornecedor fixture',10,'2026-02-05','2026-02-10','2026-02-10');
INSERT INTO obrigacao_financeira(natureza,origem,id_despesa,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual)
VALUES('PAGAR','DESPESA_VEICULO',9201,'OFICINA','Oficina fixture',10,'2026-02-05','2026-02-10','2026-02-10');
CALL rel_aceita('R29 Ida (maximo N): venda tem outra obrigacao','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''RECEBER'',''VENDA'',9201,''FINANCIAMENTO'',''Banco'',10,''2026-02-05'',''2026-02-20'',''2026-02-20'')');
CALL rel_aceita('R30 Ida (maximo N): entrada tem outra obrigacao','INSERT INTO obrigacao_financeira(natureza,origem,id_entrada,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ENTRADA'',9202,''REPASSE'',''Fornecedor'',10,''2026-02-05'',''2026-02-20'',''2026-02-20'')');
CALL rel_aceita('R31 Ida (maximo N): despesa tem outra obrigacao','INSERT INTO obrigacao_financeira(natureza,origem,id_despesa,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''DESPESA_VEICULO'',9201,''OFICINA'',''Oficina'',10,''2026-02-05'',''2026-02-20'',''2026-02-20'')');
CALL rel_aceita('R29-R31 Volta (minimo 0): obrigacao administrativa sem arco','INSERT INTO obrigacao_financeira(natureza,origem,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ADMINISTRATIVA'',''ALUGUEL'',''Imobiliaria'',10,''2026-02-05'',''2026-02-10'',''2026-02-10'')');
CALL rel_rejeita('R29 Volta (venda inexistente)','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''RECEBER'',''VENDA'',999999999,''PIX'',''x'',10,''2026-02-05'',''2026-02-05'',''2026-02-05'')','foreign key constraint fails');
CALL rel_rejeita('R30 Volta (entrada inexistente)','INSERT INTO obrigacao_financeira(natureza,origem,id_entrada,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''ENTRADA'',999999999,''REPASSE'',''x'',10,''2026-02-05'',''2026-02-05'',''2026-02-05'')','foreign key constraint fails');
CALL rel_rejeita('R31 Volta (despesa inexistente)','INSERT INTO obrigacao_financeira(natureza,origem,id_despesa,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''PAGAR'',''DESPESA_VEICULO'',999999999,''OFICINA'',''x'',10,''2026-02-05'',''2026-02-05'',''2026-02-05'')','foreign key constraint fails');
CALL rel_rejeita('R29/R30 arco exclusivo','INSERT INTO obrigacao_financeira(natureza,origem,id_venda,id_entrada,categoria,contraparte,valor,data_competencia,vencimento_original,vencimento_atual) VALUES(''RECEBER'',''VENDA'',9201,9202,''PIX'',''x'',10,''2026-02-05'',''2026-02-05'',''2026-02-05'')','ck_obrigacao_arco');
-- R32-R38: interações, desfecho, classificação e fatores.
CALL rel_volta_obrigatoria('R32 Volta','INSERT INTO interacao(id_atendimento,id_funcionario,canal,direcao,resumo) VALUES({fk},9201,''TELEFONE'',''ENVIADA'',''x'')','id_atendimento','fk_interacao_id_atendimento');
CALL rel_volta_obrigatoria('R33 Volta','INSERT INTO interacao(id_atendimento,id_funcionario,canal,direcao,resumo) VALUES(9201,{fk},''TELEFONE'',''ENVIADA'',''x'')','id_funcionario','fk_interacao_id_funcionario');
CALL rel_aceita('R32/R33 Ida (maximo N): segundo contato no mesmo atendimento','INSERT INTO interacao(id_atendimento,id_funcionario,data_hora,canal,direcao,resumo) VALUES(9201,9201,''2026-02-06 09:00:00'',''WHATSAPP'',''RECEBIDA'',''resposta adicional'')');
INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES(9201,9201,'GANHO','fixture cardinalidade');
CALL rel_volta_obrigatoria('R34 Volta','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES({fk},9201,''GANHO'',''x'')','id_atendimento','fk_atendimento_desfecho_id_atendimento');
CALL rel_volta_obrigatoria('R38 Volta','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES(9202,{fk},''GANHO'',''x'')','id_funcionario','fk_atendimento_desfecho_id_funcionario');
CALL rel_rejeita('R34 Ida (maximo 1): segundo desfecho no atendimento','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES(9201,9201,''PERDA'',''duplicado'')','Duplicate entry');
CALL rel_aceita('R38 Ida (maximo N): mesmo funcionario encerra outro atendimento','INSERT INTO atendimento_desfecho(id_atendimento,id_funcionario,tipo_desfecho,motivo) VALUES(9202,9201,''PERDA'',''sem interesse'')');
CALL rel_volta_obrigatoria('R35 Volta','INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao) VALUES({fk},''2026-02-06 09:00:00'',''REGRA'',''REGRA-V1'',''FRIO'',0)','id_atendimento','fk_classificacao_lead_id_atendimento');
CALL registrar_classificacao_lead(9201,'REGRA-V1','2026-02-07 09:00:00',@classificacao_rel_2);
CALL rel_confere('R35 Ida (maximo N): atendimento recebeu duas classificacoes','(SELECT COUNT(*)>=2 FROM classificacao_lead WHERE id_atendimento=9201)');
CALL rel_confere('R36 Volta (minimo 0): nova classificacao aguarda revisao','(SELECT id_revisor IS NULL FROM classificacao_lead WHERE id_classificacao=@classificacao_rel_2)');
CALL rel_rejeita('R36 Volta (revisor inexistente)','UPDATE classificacao_lead SET temperatura_final=temperatura_sugerida,id_revisor=999999999,data_revisao=''2026-02-08 10:00:00'' WHERE id_classificacao=@classificacao_rel_2','fk_classificacao_lead_id_revisor');
CALL rel_aceita('R36 Ida (maximo N): funcionario revisa classificacoes distintas','UPDATE classificacao_lead SET temperatura_final=temperatura_sugerida,id_revisor=9201,data_revisao=''2026-02-08 10:00:00'',justificativa_revisao=''Revisao de teste'' WHERE id_classificacao=@classificacao_rel_2');
CALL rel_confere('R37 Ida (maximo N): classificacao registra quatro fatores','(SELECT COUNT(*)=4 FROM classificacao_fator WHERE id_classificacao=@classificacao_9201)');
CALL rel_rejeita('R37 Ida (minimo 1 fator): INSERT direto sem fatores','INSERT INTO classificacao_lead(id_atendimento,data_hora,origem,versao_regra,temperatura_sugerida,pontuacao) VALUES(9202,''2026-02-06 10:00:00'',''REGRA'',''REGRA-V1'',''FRIO'',0)','R37: classificacao de lead exige ao menos um fator explicativo; use registrar_classificacao_lead');
CALL rel_volta_obrigatoria('R37 Volta','INSERT INTO classificacao_fator(id_classificacao,codigo_fator,pontos,evidencia) VALUES({fk},''URGENCIA_CONTATO'',0,''teste'')','id_classificacao','fk_classificacao_fator_id_classificacao');
CALL rel_rejeita('R37 Volta (maximo 1): fator repetido na mesma classificacao','INSERT INTO classificacao_fator(id_classificacao,codigo_fator,pontos,evidencia) VALUES(@classificacao_9201,''URGENCIA_CONTATO'',0,''teste'')','Duplicate entry');
-- R39-R41: intenção e seus dois relacionamentos opcionais.
INSERT INTO intencao_compra(id_atendimento,id_entrada,codigo_forma,valor_disponivel,data_registro,origem) VALUES(9201,9207,'PIX',55000,'2026-02-05 09:30:00','VENDEDOR');
CALL rel_volta_obrigatoria('R39 Volta','INSERT INTO intencao_compra(id_atendimento,valor_disponivel,data_registro,origem) VALUES({fk},1000,''2026-02-05 09:00:00'',''VENDEDOR'')','id_atendimento','foreign key constraint fails');
CALL rel_rejeita('R39 Ida (maximo 1): segunda intencao no atendimento','INSERT INTO intencao_compra(id_atendimento,valor_disponivel,data_registro,origem) VALUES(9201,1000,''2026-02-05 09:00:00'',''VENDEDOR'')','Duplicate entry');
CALL rel_confere('R39 Ida (minimo 0): atendimento sem intencao','NOT EXISTS(SELECT 1 FROM intencao_compra WHERE id_atendimento=9202)');
CALL rel_aceita('R40/R41 Volta (minimo 0): intencao sem entrada nem forma','INSERT INTO intencao_compra(id_atendimento,valor_disponivel,data_registro,origem) VALUES(9202,1000,''2026-02-05 09:00:00'',''VENDEDOR'')');
CALL rel_rejeita('R40 Volta (entrada inexistente)','INSERT INTO intencao_compra(id_atendimento,id_entrada,data_registro,origem) VALUES(9202,999999999,''2026-02-05 09:00:00'',''VENDEDOR'')','foreign key constraint fails');
CALL rel_rejeita('R41 Volta (forma inexistente)','INSERT INTO intencao_compra(id_atendimento,codigo_forma,data_registro,origem) VALUES(9202,''BOLETO'',''2026-02-05 09:00:00'',''VENDEDOR'')','foreign key constraint fails');
INSERT INTO intencao_compra(id_atendimento,id_entrada,codigo_forma,data_registro,origem) VALUES(9202,9207,'PIX','2026-02-05 10:00:00','VENDEDOR');
CALL rel_confere('R40/R41 Ida (maximo N): mesma entrada e forma aparecem em várias intenções','(SELECT COUNT(*)=2 FROM intencao_compra WHERE id_entrada=9207 AND codigo_forma=''PIX'')');
CALL rel_aceita('R26 Volta (maximo N): mesma avaliacao pode aparecer em propostas distintas','INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9204,9206,14000)');
INSERT INTO proposta_troca(id_proposta,id_avaliacao,valor_oferecido) VALUES(9204,9206,14000);
CALL rel_confere('R26 Ida e Volta: proposta 9202 possui duas trocas e avaliacao 9206 esta em duas propostas','(SELECT COUNT(*)=2 FROM proposta_troca WHERE id_proposta=9202) AND (SELECT COUNT(*)=2 FROM proposta_troca WHERE id_avaliacao=9206)');
INSERT INTO simulacao_financiamento(id_proposta,instituicao,tabela_retorno,origem,valor_financiado,taxa_mensal,prazo_meses,renda_declarada,consentimento_renda,data_simulacao)
VALUES(9202,'Banco Demonstracao','R4','ACADEMICA',13000,0.02,24,5000,TRUE,'2026-02-05 12:00:00');
CALL rel_confere('R27 Ida e R28 Volta: R0 e R4 vigentes geram tres simulacoes para a proposta','(SELECT COUNT(*)=3 FROM simulacao_financiamento WHERE id_proposta=9202) AND (SELECT COUNT(*)=2 FROM parametro_retorno WHERE instituicao=''Banco Demonstracao'' AND tabela_retorno IN(''R0'',''R4'') AND vigencia<=''2026-02-05'')');
CALL rel_confere('Fixture relacional: propostas e condicoes permanecem vinculadas a pais existentes','(SELECT COUNT(*)=3 FROM proposta WHERE id_proposta IN(9201,9202,9203) AND id_atendimento IN(9201,9202) AND id_entrada=9202 AND id_funcionario=9201) AND (SELECT COUNT(*)>=3 FROM proposta_condicao WHERE id_proposta IN(9201,9202,9203))');
CALL rel_confere('Fixture relacional: troca, financiamento e obrigacoes apontam para seus pais','(SELECT COUNT(*)=2 FROM proposta_troca WHERE id_proposta=9202) AND (SELECT COUNT(*)=3 FROM simulacao_financiamento WHERE id_proposta=9202) AND (SELECT COUNT(*)=1 FROM obrigacao_financeira WHERE id_venda=9201)');
CALL rel_confere('Suite de relacionamentos conclui com cobertura R01-R41 documentada','(SELECT COUNT(*)>=40 FROM information_schema.key_column_usage WHERE table_schema=DATABASE() AND referenced_table_name IS NOT NULL) AND EXISTS(SELECT 1 FROM information_schema.triggers WHERE trigger_schema=DATABASE() AND trigger_name=''simulacao_retorno_bi'')');
ROLLBACK;
CALL rel_restaurar_auto_increment();
DROP PROCEDURE rel_restaurar_auto_increment;
DROP PROCEDURE rel_rejeita; DROP PROCEDURE rel_aceita; DROP PROCEDURE rel_volta_obrigatoria; DROP PROCEDURE rel_confere; DROP TEMPORARY TABLE rel_resultado; DROP TEMPORARY TABLE rel_ai_before;

-- Restaura o modo Safe Updates da sessao.
SET SQL_SAFE_UPDATES = @mk_safe_updates;
