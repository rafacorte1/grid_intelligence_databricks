CREATE OR REFRESH MATERIALIZED VIEW ${catalogo}.${schema_gold}.continuidade_conjunto_mes
COMMENT 'Monthly continuity inputs per district. DEC and FEC are defined only in the continuidade_metricas metric view.'
TBLPROPERTIES ('delta.feature.timestampNtz' = 'supported')
AS WITH cadastro AS (
  SELECT id_conjunto, nome_conjunto, municipio, count(*) AS total_ucs
  FROM ${catalogo}.${schema_silver}.unidades_consumidoras GROUP BY ALL
), eventos AS (
  SELECT id_conjunto, mes_apuracao,
    sum(uc_horas_interrompidas) AS uc_horas_interrompidas,
    sum(qtd_ucs_afetadas) AS uc_interrupcoes, count(*) AS qtd_interrupcoes,
    count_if(causa_climatica) AS qtd_interrupcoes_climaticas,
    count_if(tipo = 'programada') AS qtd_interrupcoes_programadas,
    max(duracao_horas) AS maior_duracao_horas
  FROM ${catalogo}.${schema_silver}.interrupcoes_validas GROUP BY ALL
), meses AS (
  SELECT explode(sequence(
    date_trunc('MONTH', cast(min(data) AS TIMESTAMP_NTZ)),
    date_trunc('MONTH', cast(max(data) AS TIMESTAMP_NTZ)), INTERVAL 1 MONTH)) AS mes_apuracao
  FROM ${catalogo}.${schema_bronze}.consumo_diario
)
-- A month without an event still has a UC base: omitting it would inflate the monthly average.
SELECT u.id_conjunto, u.nome_conjunto, u.municipio, m.mes_apuracao, u.total_ucs,
  coalesce(i.uc_horas_interrompidas, 0) AS uc_horas_interrompidas,
  coalesce(i.uc_interrupcoes, 0) AS uc_interrupcoes,
  coalesce(i.qtd_interrupcoes, 0) AS qtd_interrupcoes,
  coalesce(i.qtd_interrupcoes_climaticas, 0) AS qtd_interrupcoes_climaticas,
  coalesce(i.qtd_interrupcoes_programadas, 0) AS qtd_interrupcoes_programadas,
  coalesce(i.maior_duracao_horas, 0) AS maior_duracao_horas
FROM cadastro u CROSS JOIN meses m
LEFT JOIN eventos i ON u.id_conjunto = i.id_conjunto AND m.mes_apuracao = i.mes_apuracao;
