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
