CREATE OR REFRESH MATERIALIZED VIEW ${catalogo}.${schema_gold}.prioridade_inspecao_uc
COMMENT 'UCs showing signals that justify a site visit. High priority requires an individual drop, a stable neighborhood and a meter signal. The list guides field verification.'
AS WITH eixos AS (
  SELECT *, variacao_da_uc <= -${queda_consumo_pct} AS caiu_contra_si,
    abs(variacao_do_conjunto) <= ${estabilidade_conjunto_pct} AS vizinhanca_estavel
  FROM ${catalogo}.${schema_silver}.baseline_consumo
)
SELECT *, caiu_contra_si AND vizinhanca_estavel AS atende_os_dois_eixos,
  CASE WHEN caiu_contra_si AND vizinhanca_estavel AND sinal_violacao_recente THEN 'alta'
    WHEN (caiu_contra_si AND vizinhanca_estavel) OR sinal_violacao_recente THEN 'media'
    ELSE 'baixa' END AS prioridade_inspecao,
  CASE WHEN caiu_contra_si AND vizinhanca_estavel AND sinal_violacao_recente
      THEN 'Queda individual com vizinhanca estavel e sinal no medidor. Verificar em campo.'
    WHEN caiu_contra_si AND vizinhanca_estavel
      THEN 'Queda individual com vizinhanca estavel. Verificar ocupacao e leitura.'
    WHEN sinal_violacao_recente THEN 'Sinal no medidor requer verificacao tecnica.'
    ELSE 'Queda acompanha a vizinhanca. Avaliar evento de rede.' END AS motivo_observado
FROM eixos
WHERE caiu_contra_si OR sinal_violacao_recente;
