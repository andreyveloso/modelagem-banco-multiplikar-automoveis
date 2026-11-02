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





