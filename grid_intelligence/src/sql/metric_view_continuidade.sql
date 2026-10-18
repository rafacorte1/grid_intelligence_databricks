-- O literal YAML nao substitui parametros. Definir catalogo e schema antes dele.
-- Nao usar ponto e virgula dentro do literal, inclusive em comentarios.
-- O denominador se repete por mes. DEC e media mensal, DEC Acumulado soma o periodo.
-- Total de UCs divide a soma pelo numero de meses para nao multiplicar a base.
USE CATALOG IDENTIFIER(:catalogo);
USE SCHEMA IDENTIFIER(:schema_gold);

CREATE OR REPLACE VIEW continuidade_metricas
WITH METRICS LANGUAGE YAML AS $$
version: 1.1
source: continuidade_conjunto_mes
comment: Indicadores de continuidade por unidade consumidora. Definicao unica de DEC e FEC para painel, agente e relatorio.
dimensions:
  - name: Conjunto
    expr: nome_conjunto
    comment: Nome da regiao de fornecimento.
    synonyms: [regiao, area de fornecimento]
  - name: Codigo do Conjunto
    expr: id_conjunto
    comment: Identificador do conjunto eletrico.
    synonyms: [codigo da regiao]
  - name: Municipio
    expr: municipio
    comment: Municipio atendido pelo conjunto.
    synonyms: [cidade]
  - name: Mes
    expr: mes_apuracao
    comment: Mes de apuracao dos eventos.
    synonyms: [mes de referencia, competencia]
measures:
  - name: DEC
    expr: SUM(uc_horas_interrompidas) / SUM(total_ucs)
    comment: Horas medias sem fornecimento por UC por mes no recorte selecionado.
    synonyms: [quantas horas sem luz, duracao equivalente]
    format: {type: number, decimal_places: {type: exact, places: 2}}
  - name: FEC
    expr: SUM(uc_interrupcoes) / SUM(total_ucs)
    comment: Numero medio de interrupcoes por UC por mes no recorte selecionado.
    synonyms: [quantas vezes sem luz, frequencia equivalente]
    format: {type: number, decimal_places: {type: exact, places: 2}}
  - name: DEC Acumulado
    expr: SUM(uc_horas_interrompidas) / (SUM(total_ucs) / COUNT(DISTINCT mes_apuracao))
    comment: Horas medias sem fornecimento por UC acumuladas nos meses selecionados.
    synonyms: [horas sem luz no periodo]
    format: {type: number, decimal_places: {type: exact, places: 2}}
  - name: Interrupcoes
    expr: SUM(qtd_interrupcoes)
    comment: Eventos de fornecimento com duracao acima do limiar regulatorio.
    format: {type: number, decimal_places: {type: exact, places: 0}}
  - name: Interrupcoes Climaticas
    expr: SUM(qtd_interrupcoes_climaticas)
    comment: Eventos atribuidos a causas climaticas.
    format: {type: number, decimal_places: {type: exact, places: 0}}
  - name: Proporcao Climatica
    expr: SUM(qtd_interrupcoes_climaticas) / NULLIF(SUM(qtd_interrupcoes), 0)
    comment: Participacao dos eventos climaticos no total de interrupcoes.
    format: {type: percentage, decimal_places: {type: exact, places: 1}}
  - name: Interrupcoes Programadas
    expr: SUM(qtd_interrupcoes_programadas)
    comment: Interrupcoes com aviso previo no periodo.
    format: {type: number, decimal_places: {type: exact, places: 0}}
  - name: Horas UC Interrompidas
    expr: SUM(uc_horas_interrompidas)
    comment: Soma da duracao em horas ponderada pelas UCs afetadas em cada evento.
    format: {type: number, decimal_places: {type: exact, places: 1}}
  - name: Maior Interrupcao
    expr: MAX(maior_duracao_horas)
    comment: Duracao em horas do evento mais longo do recorte.
    format: {type: number, decimal_places: {type: exact, places: 2}}
  - name: Total de UCs
    expr: SUM(total_ucs) / COUNT(DISTINCT mes_apuracao)
    comment: Base media mensal de UCs dos conjuntos no periodo selecionado.
    format: {type: number, decimal_places: {type: exact, places: 0}}
$$;
