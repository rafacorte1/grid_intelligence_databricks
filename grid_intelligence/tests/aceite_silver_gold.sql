-- Executar no warehouse depois do job em dev. Sem ler texto pessoal identificado.
SELECT assert_true(count(*) = 1073, 'RN-01: esperado 1073 eventos validos')
FROM grid_dev.silver.interrupcoes_validas;

SELECT assert_true(count(*) = 0, 'Consumo invalido na silver')
FROM grid_dev.silver.consumo_diario
WHERE consumo_kwh IS NULL OR consumo_kwh < 0 OR consumo_kwh > limite_fisico_kwh_dia;

SELECT assert_true(count(*) > 5000000, 'Consumo nao materializado')
FROM grid_dev.silver.consumo_diario;

SELECT assert_true(count(*) = 0, 'Chave UC/dia duplicada') FROM (
  SELECT id_uc, data FROM grid_dev.silver.consumo_diario GROUP BY ALL HAVING count(*) > 1
);

SELECT assert_true(count(*) > 0 AND abs(max(variacao_do_conjunto)) <= 10,
  'Vizinhanca CPQ-02 ausente ou fora de estabilidade')
FROM grid_dev.silver.baseline_consumo WHERE id_conjunto = 'CPQ-02';

SELECT assert_true(count(*) = 2801, 'Chamados perdidos'),
  assert_true(count_if(transcricao_anonimizada RLIKE
    r'[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}|\([0-9]{2}\)\s*9?[0-9]{4}-?[0-9]{4}') = 0,
    'CPF ou telefone remanescente'),
  assert_true(count_if(anonimizado_por <> 'regras_de_texto'
    OR enriquecido_por <> 'regras_de_texto') = 0, 'Proveniencia incorreta')
FROM grid_dev.silver.chamados_enriquecidos;

SELECT assert_true(count(*) = 0, 'Prioridade alta exige os dois eixos e sinal fisico')
FROM grid_dev.gold.prioridade_inspecao_uc
WHERE prioridade_inspecao = 'alta'
  AND NOT (caiu_contra_si AND vizinhanca_estavel AND sinal_violacao_recente);

SELECT assert_true(sum(qtd_interrupcoes) = 1073, 'Gold diverge da silver')
FROM grid_dev.gold.continuidade_conjunto_mes;

SELECT assert_true(count(*) = 288, 'Esperado 6 conjuntos por 48 meses inclusive sem evento')
FROM grid_dev.gold.continuidade_conjunto_mes;

SELECT assert_true(MEASURE(`Total de UCs`) = 4000, 'Base de UCs incorreta')
FROM grid_dev.gold.continuidade_metricas;

SELECT assert_true(count(*) = count(DISTINCT id_cliente), 'Saude deve ter grao cliente')
FROM grid_dev.gold.saude_cliente;

SELECT assert_true(sum(qtd_chamados) = 2801, 'Saude deve preservar o historico de chamados')
FROM grid_dev.gold.saude_cliente;

SELECT assert_true(count(*) = 0, 'Painel deve ter grao conjunto/dia') FROM (
  SELECT id_conjunto, data FROM grid_dev.gold.painel_operacional_dia
  GROUP BY ALL HAVING count(*) > 1
);

SELECT assert_true(count_if(dec_acumulado > dec_mensal) = 6,
  'DEC acumulado e media mensal devem divergir em varios meses') FROM (
  SELECT `Codigo do Conjunto`, MEASURE(`DEC`) AS dec_mensal,
    MEASURE(`DEC Acumulado`) AS dec_acumulado
  FROM grid_dev.gold.continuidade_metricas GROUP BY ALL
);
