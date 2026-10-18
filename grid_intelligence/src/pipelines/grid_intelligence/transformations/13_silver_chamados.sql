-- Extracao por regras, nao por modelo: ironia e negacao podem inverter sentimento.
-- Sinonimos fora da lista nao casam. Motivo composto recebe somente o primeiro rotulo.
-- Apelidos ou nomes diferentes da coluna podem permanecer identificados no texto.
CREATE OR REFRESH MATERIALIZED VIEW ${catalogo}.${schema_silver}.chamados_anonimizados
TBLPROPERTIES ('delta.feature.timestampNtz' = 'supported')
AS SELECT
  c.id_chamado, c.id_uc, c.abertura, c.canal, c.duracao_segundos,
  c.origem, c.ingerido_em, c.arquivo_origem, c.ingerido_bronze_em,
  u.id_cliente, u.id_conjunto, u.nome_conjunto, u.bairro, u.classe_consumo,
  to_date(c.abertura) AS data_chamado, hour(c.abertura) AS hora_chamado,
  regexp_replace(regexp_replace(
    replace(c.transcricao, c.nome_solicitante, '[MASCARADO]'),
    r'[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}', '[MASCARADO]'),
    r'\([0-9]{2}\)\s*9?[0-9]{4}-?[0-9]{4}', '[MASCARADO]') AS transcricao_anonimizada,
  'regras_de_texto' AS anonimizado_por
FROM ${catalogo}.${schema_bronze}.chamados c
LEFT JOIN ${catalogo}.${schema_silver}.unidades_consumidoras u USING (id_uc);

CREATE OR REFRESH MATERIALIZED VIEW ${catalogo}.${schema_silver}.chamados_enriquecidos
TBLPROPERTIES ('delta.feature.timestampNtz' = 'supported')
AS WITH texto AS (
  SELECT *, translate(lower(transcricao_anonimizada), 'áàâãéêíóôõúç', 'aaaaeeiooouc') AS fala
  FROM ${catalogo}.${schema_silver}.chamados_anonimizados
), sinais AS (
  SELECT * EXCEPT (fala),
    CASE WHEN fala RLIKE 'absurdo|vergonha|cansad|revolt|irritad|insatisfeit|nao aguento|reclama|ninguem resolve'
      THEN 'negative' WHEN fala RLIKE 'obrigad|agradec|otimo|excelente|parabens'
      THEN 'positive' ELSE 'neutral' END AS sentimento,
    CASE WHEN fala RLIKE 'dialise|oxigenio|remedio na geladeira|crianca pequena' THEN 'religacao_urgente'
      WHEN fala RLIKE 'escuro|sem energia|apagou|apagado|falta de energia|sem luz' THEN 'falta_energia'
      WHEN fala RLIKE 'piscando|oscila|queimou|tensao' THEN 'oscilacao_tensao'
      WHEN fala RLIKE 'releitura|estimativa|nao bate' THEN 'erro_leitura'
      WHEN fala RLIKE 'conta veio|dobro|fatura subiu|trezentos reais' THEN 'fatura_alta'
      WHEN fala RLIKE 'poste|galho|lampada da rua' THEN 'poste_avariado'
      WHEN fala RLIKE 'religacao|religar|paguei' THEN 'religacao'
      ELSE 'duvida_cadastral' END AS motivo,
    nullif(regexp_extract(fala,
      '(transformador|religador|disjuntor|medidor|poste|geladeira|televisao|televisor|lampada|fiacao)', 1), '')
      AS equipamento_citado,
    fala RLIKE 'oxigenio|dialise|remedio|crianca|hospital|faisca|incendio|idoso' AS risco_a_saude,
    fala RLIKE 'ouvidoria|aneel|procon|processo' AS ameacou_ouvidoria
  FROM texto
)
SELECT *, CASE WHEN risco_a_saude THEN 'alta'
  WHEN motivo IN ('falta_energia', 'religacao_urgente', 'poste_avariado') THEN 'media'
  WHEN motivo = 'religacao' AND transcricao_anonimizada RLIKE '(?i)urgent' THEN 'media'
  ELSE 'baixa' END AS urgencia, 'regras_de_texto' AS enriquecido_por
FROM sinais;
