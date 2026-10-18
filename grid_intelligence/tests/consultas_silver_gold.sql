SELECT count(*) AS bronze, count_if(duracao_minutos < 3) AS descartadas,
  round(100.0 * count_if(duracao_minutos < 3) / count(*), 1) AS pct_descartadas
FROM grid_dev.bronze.interrupcoes;

WITH leituras AS (
  SELECT c.*, u.id_conjunto,
    c.consumo_kwh IS NOT NULL AND c.consumo_kwh >= 0 AND c.consumo_kwh <=
      CASE u.classe_consumo WHEN 'residencial' THEN 200.0 WHEN 'comercial' THEN 2000.0
        WHEN 'industrial' THEN 50000.0 WHEN 'rural' THEN 3000.0
        WHEN 'poder_publico' THEN 5000.0 ELSE 200.0 END AND u.id_uc IS NOT NULL AS valido
  FROM grid_dev.bronze.consumo_diario c
  LEFT JOIN grid_dev.silver.unidades_consumidoras u USING (id_uc)
)
SELECT count(*) AS bronze, count_if(consumo_kwh IS NULL) AS nulas,
  count_if(consumo_kwh < 0) AS negativas, count_if(id_conjunto IS NULL) AS sem_cadastro,
  count(*) - count_if(valido) AS descartadas,
  count_if(valido) AS validas_antes_deduplicacao,
  count_if(valido) - count(DISTINCT CASE WHEN valido THEN struct(id_uc, data) END) AS duplicatas,
  (SELECT count(*) FROM grid_dev.silver.consumo_diario) AS silver
FROM leituras;

SELECT id_conjunto, round(max(variacao_do_conjunto), 4) AS variacao_pct,
  max(consumo_medio_baseline_conjunto_kwh) AS media_baseline,
  max(consumo_medio_recente_conjunto_kwh) AS media_recente
FROM grid_dev.silver.baseline_consumo GROUP BY id_conjunto ORDER BY id_conjunto;

SELECT motivo, sentimento, count(*) AS chamados
FROM grid_dev.silver.chamados_enriquecidos GROUP BY ALL ORDER BY motivo, sentimento;

SELECT count(*) AS chamados,
  count_if(a.transcricao_anonimizada RLIKE r'[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}') AS cpf_restante,
  count_if(a.transcricao_anonimizada RLIKE r'\([0-9]{2}\)\s*9?[0-9]{4}-?[0-9]{4}') AS telefone_restante,
  count_if(instr(lower(a.transcricao_anonimizada), lower(split_part(b.nome_solicitante, ' ', 1))) > 0)
    AS primeiro_nome_substring,
  count_if(regexp_like(a.transcricao_anonimizada,
    concat(r'(?i)\b', split_part(b.nome_solicitante, ' ', 1), r'\b'))) AS primeiro_nome_palavra
FROM grid_dev.silver.chamados_anonimizados a JOIN grid_dev.bronze.chamados b USING (id_chamado);

SELECT `Codigo do Conjunto`, `Conjunto`, MEASURE(`DEC`) AS dec_horas, MEASURE(`FEC`) AS fec
FROM grid_dev.gold.continuidade_metricas
WHERE `Mes` = (SELECT max(mes_apuracao) FROM grid_dev.gold.continuidade_conjunto_mes)
GROUP BY ALL ORDER BY `Codigo do Conjunto`;

SELECT `Codigo do Conjunto`, MEASURE(`DEC`) AS dec_mensal,
  MEASURE(`DEC Acumulado`) AS dec_acumulado, MEASURE(`Total de UCs`) AS total_ucs
FROM grid_dev.gold.continuidade_metricas GROUP BY ALL ORDER BY `Codigo do Conjunto`;

SELECT id_conjunto, bairro, count(*) AS ucs_prioridade_alta
FROM grid_dev.gold.prioridade_inspecao_uc WHERE prioridade_inspecao = 'alta'
GROUP BY ALL ORDER BY ucs_prioridade_alta DESC, bairro;

SELECT id_cliente, id_conjunto, bairro, qtd_chamados, qtd_ucs_com_chamado,
  qtd_mencoes_ouvidoria, qtd_chamados_negativos, motivo_predominante, risco_ouvidoria
FROM grid_dev.gold.saude_cliente WHERE risco_ouvidoria = 'alto'
ORDER BY qtd_mencoes_ouvidoria DESC, qtd_chamados DESC, id_cliente;

SELECT data, id_conjunto, qtd_interrupcoes, qtd_chamados, qtd_chamados_risco_saude,
  qtd_mencoes_ouvidoria, ucs_prioridade_alta, acao_recomendada
FROM grid_dev.gold.painel_operacional_dia
WHERE data = (SELECT max(data) FROM grid_dev.gold.painel_operacional_dia)
ORDER BY id_conjunto;

SELECT data, id_conjunto, qtd_interrupcoes, qtd_chamados, acao_recomendada
FROM grid_dev.gold.painel_operacional_dia
WHERE data = (SELECT max(data_evento) FROM grid_dev.silver.interrupcoes_validas)
ORDER BY id_conjunto;
