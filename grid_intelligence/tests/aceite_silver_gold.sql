-- Run on the warehouse after the job in dev. Never reads identified personal text.
SELECT assert_true(count(*) = 1073, 'RN-01: expected 1073 valid events')
FROM grid_dev.silver.interrupcoes_validas;

SELECT assert_true(count(*) = 0, 'Invalid consumption in Silver')
FROM grid_dev.silver.consumo_diario
WHERE consumo_kwh IS NULL OR consumo_kwh < 0 OR consumo_kwh > limite_fisico_kwh_dia;

SELECT assert_true(count(*) > 5000000, 'Consumption not materialized')
FROM grid_dev.silver.consumo_diario;

SELECT assert_true(count(*) = 0, 'Duplicated UC/day key') FROM (
  SELECT id_uc, data FROM grid_dev.silver.consumo_diario GROUP BY ALL HAVING count(*) > 1
);

SELECT assert_true(count(*) > 0 AND abs(max(variacao_do_conjunto)) <= 10,
  'District CPQ-02 missing or outside the stability band')
FROM grid_dev.silver.baseline_consumo WHERE id_conjunto = 'CPQ-02';

SELECT assert_true(count(*) = 2801, 'Service calls lost'),
  assert_true(count_if(transcricao_anonimizada RLIKE
    r'[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}|\([0-9]{2}\)\s*9?[0-9]{4}-?[0-9]{4}') = 0,
    'CPF or phone number left in the text'),
  assert_true(count_if(anonimizado_por <> 'regras_de_texto'
    OR enriquecido_por <> 'regras_de_texto') = 0, 'Wrong provenance')
FROM grid_dev.silver.chamados_enriquecidos;

SELECT assert_true(count(*) = 0, 'High priority requires both axes and a physical signal')
FROM grid_dev.gold.prioridade_inspecao_uc
WHERE prioridade_inspecao = 'alta'
  AND NOT (caiu_contra_si AND vizinhanca_estavel AND sinal_violacao_recente);

SELECT assert_true(sum(qtd_interrupcoes) = 1073, 'Gold diverges from Silver')
FROM grid_dev.gold.continuidade_conjunto_mes;

SELECT assert_true(count(*) = 288, 'Expected 6 districts x 48 months, including months with no event')
FROM grid_dev.gold.continuidade_conjunto_mes;

SELECT assert_true(MEASURE(`Total de UCs`) = 4000, 'Wrong UC base')
FROM grid_dev.gold.continuidade_metricas;

SELECT assert_true(count(*) = count(DISTINCT id_cliente), 'Customer health must keep the customer grain')
FROM grid_dev.gold.saude_cliente;

SELECT assert_true(sum(qtd_chamados) = 2801, 'Customer health must preserve the service call history')
FROM grid_dev.gold.saude_cliente;

SELECT assert_true(count(*) = 0, 'Operational panel must keep the district/day grain') FROM (
  SELECT id_conjunto, data FROM grid_dev.gold.painel_operacional_dia
  GROUP BY ALL HAVING count(*) > 1
);

SELECT assert_true(count_if(dec_acumulado > dec_mensal) = 6,
  'Accumulated DEC and monthly average DEC must diverge across months') FROM (
  SELECT `Codigo do Conjunto`, MEASURE(`DEC`) AS dec_mensal,
    MEASURE(`DEC Acumulado`) AS dec_acumulado
  FROM grid_dev.gold.continuidade_metricas GROUP BY ALL
);
