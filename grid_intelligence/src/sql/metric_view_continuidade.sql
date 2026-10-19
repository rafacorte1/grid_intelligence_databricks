-- The YAML literal does not substitute parameters. Set catalog and schema before it.
-- Do not use semicolons inside the literal, not even in comments.
-- The denominator repeats for every month. DEC is a monthly average; DEC Acumulado sums the period.
-- Total de UCs divides the sum by the number of months so the base is not multiplied.
USE CATALOG IDENTIFIER(:catalogo);
USE SCHEMA IDENTIFIER(:schema_gold);

CREATE OR REPLACE VIEW continuidade_metricas
WITH METRICS LANGUAGE YAML AS $$
version: 1.1
source: continuidade_conjunto_mes
comment: Continuity indicators per consumer unit. Single definition of DEC and FEC for dashboard, agent and report.
dimensions:
  - name: Conjunto
    expr: nome_conjunto
    comment: Name of the supply region.
    synonyms: [regiao, area de fornecimento]
  - name: Codigo do Conjunto
    expr: id_conjunto
    comment: Identifier of the electrical district.
    synonyms: [codigo da regiao]
  - name: Municipio
    expr: municipio
    comment: Municipality served by the district.
    synonyms: [cidade]
  - name: Mes
    expr: mes_apuracao
    comment: Reference month of the events.
    synonyms: [mes de referencia, competencia]
measures:
  - name: DEC
    expr: SUM(uc_horas_interrompidas) / SUM(total_ucs)
    comment: Average hours without supply per UC per month in the selected slice.
    synonyms: [quantas horas sem luz, duracao equivalente]
    format: {type: number, decimal_places: {type: exact, places: 2}}
  - name: FEC
    expr: SUM(uc_interrupcoes) / SUM(total_ucs)
    comment: Average number of interruptions per UC per month in the selected slice.
    synonyms: [quantas vezes sem luz, frequencia equivalente]
    format: {type: number, decimal_places: {type: exact, places: 2}}
  - name: DEC Acumulado
    expr: SUM(uc_horas_interrompidas) / (SUM(total_ucs) / COUNT(DISTINCT mes_apuracao))
    comment: Average hours without supply per UC accumulated over the selected months.
    synonyms: [horas sem luz no periodo]
    format: {type: number, decimal_places: {type: exact, places: 2}}
  - name: Interrupcoes
    expr: SUM(qtd_interrupcoes)
    comment: Supply events whose duration exceeds the regulatory threshold.
    format: {type: number, decimal_places: {type: exact, places: 0}}
  - name: Interrupcoes Climaticas
    expr: SUM(qtd_interrupcoes_climaticas)
    comment: Events attributed to weather causes.
    format: {type: number, decimal_places: {type: exact, places: 0}}
  - name: Proporcao Climatica
    expr: SUM(qtd_interrupcoes_climaticas) / NULLIF(SUM(qtd_interrupcoes), 0)
    comment: Share of weather events in total interruptions.
    format: {type: percentage, decimal_places: {type: exact, places: 1}}
  - name: Interrupcoes Programadas
    expr: SUM(qtd_interrupcoes_programadas)
    comment: Interruptions announced in advance within the period.
    format: {type: number, decimal_places: {type: exact, places: 0}}
  - name: Horas UC Interrompidas
    expr: SUM(uc_horas_interrompidas)
    comment: Sum of duration in hours weighted by the UCs affected in each event.
    format: {type: number, decimal_places: {type: exact, places: 1}}
  - name: Maior Interrupcao
    expr: MAX(maior_duracao_horas)
    comment: Duration in hours of the longest event in the slice.
    format: {type: number, decimal_places: {type: exact, places: 2}}
  - name: Total de UCs
    expr: SUM(total_ucs) / COUNT(DISTINCT mes_apuracao)
    comment: Average monthly UC base across districts in the selected period.
    format: {type: number, decimal_places: {type: exact, places: 0}}
$$;
