CREATE OR REFRESH MATERIALIZED VIEW ${catalogo}.${schema_gold}.painel_operacional_dia
COMMENT 'Daily district-level events combined with service calls, network and consumption. Inspection priorities appear only on the last day of the dataset. Recommended action prioritizes health risk, ombudsman escalation, network and site visits.'
AS WITH interrupcoes AS (
  SELECT id_conjunto, data_evento AS data,
    count(*) AS qtd_interrupcoes, sum(uc_horas_interrompidas) AS uc_horas_interrompidas,
    sum(qtd_ucs_afetadas) AS uc_interrupcoes
  FROM ${catalogo}.${schema_silver}.interrupcoes_validas GROUP BY ALL
), chamados AS (
  SELECT id_conjunto, data_chamado AS data, count(*) AS qtd_chamados,
    count_if(risco_a_saude) AS qtd_chamados_risco_saude,
    count_if(ameacou_ouvidoria) AS qtd_mencoes_ouvidoria
  FROM ${catalogo}.${schema_silver}.chamados_enriquecidos GROUP BY ALL
), consumo AS (
  SELECT id_conjunto, data, sum(consumo_kwh) AS consumo_kwh, count(*) AS ucs_com_leitura
  FROM ${catalogo}.${schema_silver}.consumo_diario GROUP BY ALL
), prioridades AS (
  SELECT id_conjunto, ultimo_dia AS data, count_if(prioridade_inspecao = 'alta') AS ucs_prioridade_alta
  FROM ${catalogo}.${schema_gold}.prioridade_inspecao_uc GROUP BY ALL
), cadastro AS (
  SELECT id_conjunto, nome_conjunto, municipio, count(*) AS total_ucs
  FROM ${catalogo}.${schema_silver}.unidades_consumidoras GROUP BY ALL
), diario AS (
  -- Aggregating before the join avoids multiplying events. FULL OUTER keeps days from every source.
  SELECT coalesce(i.id_conjunto, c.id_conjunto, l.id_conjunto) AS id_conjunto,
    coalesce(i.data, c.data, l.data) AS data,
    coalesce(i.qtd_interrupcoes, 0) AS qtd_interrupcoes,
    coalesce(i.uc_horas_interrompidas, 0) AS uc_horas_interrompidas,
    coalesce(i.uc_interrupcoes, 0) AS uc_interrupcoes,
    coalesce(c.qtd_chamados, 0) AS qtd_chamados,
    coalesce(c.qtd_chamados_risco_saude, 0) AS qtd_chamados_risco_saude,
    coalesce(c.qtd_mencoes_ouvidoria, 0) AS qtd_mencoes_ouvidoria,
    l.consumo_kwh, coalesce(l.ucs_com_leitura, 0) AS ucs_com_leitura
  FROM interrupcoes i FULL OUTER JOIN chamados c USING (id_conjunto, data)
  FULL OUTER JOIN consumo l
    ON l.id_conjunto = coalesce(i.id_conjunto, c.id_conjunto)
    AND l.data = coalesce(i.data, c.data)
)
SELECT d.*, u.nome_conjunto, u.municipio, u.total_ucs,
  coalesce(p.ucs_prioridade_alta, 0) AS ucs_prioridade_alta,
  CASE WHEN d.qtd_chamados_risco_saude > 0 THEN 'Acionar atendimento prioritario por risco a saude'
    WHEN d.qtd_mencoes_ouvidoria > 0 THEN 'Retornar ao cliente e tratar escalada a ouvidoria'
    WHEN d.qtd_interrupcoes > 0 THEN 'Mobilizar equipe para continuidade do fornecimento'
    WHEN p.ucs_prioridade_alta > 0 THEN 'Programar visitas tecnicas prioritarias'
    ELSE 'Acompanhar operacao' END AS acao_recomendada
FROM diario d LEFT JOIN cadastro u USING (id_conjunto)
LEFT JOIN prioridades p USING (id_conjunto, data);
