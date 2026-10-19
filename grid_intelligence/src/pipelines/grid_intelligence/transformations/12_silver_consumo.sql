CREATE OR REFRESH MATERIALIZED VIEW ${catalogo}.${schema_silver}.consumo_diario
TBLPROPERTIES ('delta.feature.timestampNtz' = 'supported')
AS WITH leituras AS (SELECT
  c.*, u.id_cliente, u.id_conjunto, u.nome_conjunto, u.municipio, u.bairro,
  u.classe_consumo,
  -- Daily plausibility ceilings agreed with the telemetry data consumer.
  CASE u.classe_consumo
    WHEN 'residencial' THEN 200.0 WHEN 'comercial' THEN 2000.0
    WHEN 'industrial' THEN 50000.0 WHEN 'rural' THEN 3000.0
    WHEN 'poder_publico' THEN 5000.0 ELSE 200.0
  END AS limite_fisico_kwh_dia
FROM ${catalogo}.${schema_bronze}.consumo_diario c
INNER JOIN ${catalogo}.${schema_silver}.unidades_consumidoras u USING (id_uc)
)
SELECT * FROM leituras
WHERE consumo_kwh IS NOT NULL
  AND consumo_kwh >= 0 AND consumo_kwh <= limite_fisico_kwh_dia
QUALIFY row_number() OVER (
  PARTITION BY id_uc, data
  ORDER BY ingerido_em DESC, arquivo_origem, consumo_kwh DESC,
    horas_com_leitura DESC, sinal_violacao_medidor DESC
) = 1;

CREATE OR REFRESH MATERIALIZED VIEW ${catalogo}.${schema_silver}.baseline_consumo
AS WITH referencia AS (
  SELECT max(data) AS ultimo_dia FROM ${catalogo}.${schema_bronze}.consumo_diario
), medias AS (
  SELECT c.id_uc, c.id_conjunto, c.nome_conjunto, c.bairro, c.classe_consumo,
    r.ultimo_dia,
    avg(c.consumo_kwh) FILTER (WHERE c.data < date_sub(r.ultimo_dia, 29))
      AS consumo_medio_baseline_kwh,
    avg(c.consumo_kwh) FILTER (WHERE c.data >= date_sub(r.ultimo_dia, 29))
      AS consumo_medio_recente_kwh,
    count(*) FILTER (WHERE c.data < date_sub(r.ultimo_dia, 29)) AS dias_no_baseline,
    count(*) FILTER (WHERE c.data >= date_sub(r.ultimo_dia, 29)) AS dias_no_periodo_recente,
    bool_or(c.sinal_violacao_medidor) FILTER (
      WHERE c.data >= date_sub(r.ultimo_dia, 29)) AS sinal_violacao_recente
  FROM ${catalogo}.${schema_silver}.consumo_diario c CROSS JOIN referencia r
  WHERE c.data BETWEEN date_sub(r.ultimo_dia, 119) AND r.ultimo_dia
  GROUP BY ALL
), conjunto AS (
  SELECT id_conjunto,
    sum(consumo_medio_baseline_kwh * dias_no_baseline) / sum(dias_no_baseline)
      AS consumo_medio_baseline_conjunto_kwh,
    sum(consumo_medio_recente_kwh * dias_no_periodo_recente) / sum(dias_no_periodo_recente)
      AS consumo_medio_recente_conjunto_kwh,
    sum(dias_no_baseline) AS dias_no_baseline_conjunto,
    sum(dias_no_periodo_recente) AS dias_no_periodo_recente_conjunto
  FROM medias GROUP BY id_conjunto
)
SELECT m.*, c.* EXCEPT (id_conjunto),
  100.0 * (m.consumo_medio_recente_kwh / nullif(m.consumo_medio_baseline_kwh, 0) - 1)
    AS variacao_da_uc,
  100.0 * (c.consumo_medio_recente_conjunto_kwh /
    nullif(c.consumo_medio_baseline_conjunto_kwh, 0) - 1) AS variacao_do_conjunto
FROM medias m INNER JOIN conjunto c USING (id_conjunto);
