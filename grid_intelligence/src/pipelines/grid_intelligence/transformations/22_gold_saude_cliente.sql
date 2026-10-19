CREATE OR REFRESH MATERIALIZED VIEW ${catalogo}.${schema_gold}.saude_cliente
COMMENT 'Historical signals of escalation to the regulatory service channel, per customer. Recurrence is measured over 30-day windows. Considers every UC of the customer and keeps only anonymized transcripts.'
TBLPROPERTIES ('delta.feature.timestampNtz' = 'supported')
AS WITH janelas AS (
  SELECT *, count(*) OVER janela AS chamados_30_dias,
    count_if(sentimento = 'negative') OVER janela AS negativos_30_dias
  FROM ${catalogo}.${schema_silver}.chamados_enriquecidos
  WINDOW janela AS (PARTITION BY id_cliente ORDER BY unix_date(data_chamado)
    RANGE BETWEEN 29 PRECEDING AND CURRENT ROW)
), clientes AS (
  SELECT id_cliente,
    max_by(id_conjunto, struct(abertura, id_chamado)) AS id_conjunto,
    max_by(nome_conjunto, struct(abertura, id_chamado)) AS nome_conjunto,
    max_by(bairro, struct(abertura, id_chamado)) AS bairro,
    count(*) AS qtd_chamados, count(DISTINCT id_uc) AS qtd_ucs_com_chamado,
    count_if(sentimento = 'negative') AS qtd_chamados_negativos,
    count_if(sentimento = 'negative') * 1.0 / count(*) AS proporcao_negativa,
    count_if(ameacou_ouvidoria) AS qtd_mencoes_ouvidoria,
    count_if(risco_a_saude) AS qtd_chamados_risco_saude,
    count_if(urgencia = 'alta') AS qtd_urgencia_alta,
    bool_or(chamados_30_dias >= 3) AS reincidente,
    bool_or(chamados_30_dias >= 3 AND negativos_30_dias > 0) AS reincidente_negativo,
    mode(motivo, true) AS motivo_predominante,
    max_by(equipamento_citado, struct(abertura, id_chamado))
      FILTER (WHERE equipamento_citado IS NOT NULL) AS ultimo_equipamento_citado,
    max_by(transcricao_anonimizada, struct(abertura, id_chamado)) AS ultima_fala,
    min(abertura) AS primeiro_chamado_em, max(abertura) AS ultimo_chamado_em
  FROM janelas GROUP BY id_cliente
)
SELECT * EXCEPT (reincidente_negativo), CASE WHEN qtd_mencoes_ouvidoria > 0 THEN 'alto'
  WHEN reincidente_negativo THEN 'alto'
  WHEN qtd_chamados_risco_saude > 0 THEN 'medio'
  ELSE 'baixo' END AS risco_ouvidoria
FROM clientes;
