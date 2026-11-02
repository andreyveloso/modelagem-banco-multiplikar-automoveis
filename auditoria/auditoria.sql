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
