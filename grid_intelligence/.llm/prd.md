# Grid Intelligence — product and business rules

## Domain

Luz do Vale Distribuidora S.A. is a fictional electricity distribution utility,
regulated by ANEEL. The platform connects supply continuity, non-technical losses
and customer service to operational and financial decisions.

Three pain points motivate the project: compensation for interruptions above the
regulatory limits, distributed and unbilled energy, and early signs of ombudsman
complaints present in the service transcripts.

The figures of more than R$ 1.1 billion in compensation in 2024 and approximately
R$ 11.5 billion in losses in 2025, with R$ 7.9 billion passed through to the tariff,
are context provided by the prompt. They are not results computed from the dataset.

## Glossary

| Term | Definition |
|---|---|
| UC | Electricity delivery point. One customer can have several UCs; UC is not a synonym for customer. |
| District | Geographic subdivision of the concession area and the unit of aggregation for the regulator. |
| DEC | Average interruption duration per UC (hours): average time without supply. |
| FEC | Average interruption frequency per UC: average number of interruptions. |
| PNT | Non-technical losses. |
| Inspection priority | Classification of how much a UC warrants a technical visit: high, medium or low. |

## Business rules (RN)

Prompt 00 supplied ten rules. Prompts 02 and 04 completed RN-02, RN-05 and RN-08.
RN-03 remains reserved, without inventing requirements.

| Rule | Definition |
|---|---|
| RN-01 | Only interruptions lasting 3 minutes or more enter DEC and FEC. Apply in the transformation, never in the report. |
| RN-02 | DEC = sum of duracao_horas times qtd_ucs_afetadas divided by the total number of UCs in the district. FEC = sum of qtd_ucs_afetadas divided by the same total. |
| RN-03 | Not provided in prompt 00; definition pending. |
| RN-04 | DEC and FEC have a single definition, shared by the dashboard, the agent and the report. |
| RN-05 | Continuity assessment is monthly per district. Monthly DEC and the cumulative total for the period are distinct measures in the metric view. |
| RN-06 | A UC is an inspection candidate only when its consumption falls against its own baseline while the neighborhood stays stable, both at the same time. |
| RN-07 | The output is inspection priority high, medium or low. Never use fraud, theft or culprit as an output label in a column, variable or comment. Change of occupant, vacant property, meter defect and reading error also explain drops. |
| RN-08 | Inspection priority uses an explainable rule, with no supervised model without a reliable label. Each decision exposes the two axes and the numbers behind it. |
| RN-09 | Mask personal data in the transcripts before any content analysis. |
| RN-10 | Preserve the identified original text under restricted access. Read protection and masking for analysis coexist. |
| RN-11 | Ingestion does not filter, correct or apply business rules; invalid readings are evidence about the meter. |
| RN-12 | Every ingested record carries its origin and ingestion timestamp. |
| RN-13 | The conversational agent accesses only the business layer. |
| RN-14 | Gold entities and the metric view carry descriptions in business language. Bronze and silver are transient and do not need descriptions. |

## Information model

Metadata checked against the local Parquet files during setup, without modifying the
files. The keys indicate the logical grain; deliberate defects may produce duplicates.

| Base | Grain and volume | Attributes |
|---|---|---|
| unidades_consumidoras | One per electricity delivery point; 4,000 records | id_uc, id_cliente, id_conjunto, nome_conjunto, municipio, bairro, logradouro, classe_consumo, subgrupo_tarifario, tensao_nominal_v, situacao, data_ligacao, possui_medidor_inteligente, consumo_medio_kwh_dia, latitude, longitude, origem, ingerido_em |
| interrupcoes | One grid event; 1,383 records | id_interrupcao, id_conjunto, inicio, fim, duracao_minutos, tipo, causa, equipamento, qtd_ucs_afetadas, origem, ingerido_em |
| consumo_diario | One UC per day; 5,854,587 physical records | id_uc, data, consumo_kwh, horas_com_leitura, sinal_violacao_medidor, origem, ingerido_em |
| chamados | One call; 2,801 records | id_chamado, id_uc, abertura, canal, nome_solicitante, telefone_solicitante, transcricao, duracao_segundos, origem, ingerido_em |

UCs relate to customers by id_cliente and to districts by id_conjunto.
Consumption and service calls relate to UCs by id_uc; interruptions relate to
districts by id_conjunto. A district event does not say which individual UCs were
affected: qtd_ucs_afetadas represents the registered scope of impact.

The stated history covers four years, with 30% year-over-year growth in load and
summer seasonality in service: December to March receives almost twice as many calls.
Null, negative and physically impossible consumption, duplicates and interruptions
under three minutes are deliberate defects, preserved during ingestion.

## Four planned business deliverables

1. Continuity by district: DEC/FEC under a single definition, to track supply and
   compensation risk. Detailed formulas and thresholds will be defined in the
   silver and gold stages.
2. Inspection priority per UC: cross the drop against the UC's own baseline and the
   stability of the neighborhood to guide technical visits, without assigning blame.
3. Service intelligence: analyze masked transcripts to identify reasons and signs of
   dissatisfaction, preserving the restricted original.
4. Integrated executive view: bring continuity, inspections and service together in
   gold, consumed by an AI/BI dashboard, a Portuguese-language copilot and an
   executive report.

## Architecture and conventions

- Isolation by catalog, configured in databricks.yml via ${var.catalog}.
- Schemas raw, bronze, silver and gold declared once in the bundle resources;
  later references use ${resources.schemas.<camada>.name}.
- Managed landing volume in raw; one folder per base, initially one Parquet per folder.
- Bronze preserves the facts; silver handles numbers and text; gold publishes
  business products and the shared DEC/FEC metric view.
- Schemas keep the same names in dev and prod, with no user prefix.
- Tables do not repeat the layer prefix in their name.
- CLI always with --profile grid_intelligence; dev is the default target.
- Text in Brazilian Portuguese; entity, column and file names without accents.
- No fixed AI model name: use ai_* functions in the stages that need AI.
- No expectations, CONSTRAINT, COMMENT in bronze/silver, TBLPROPERTIES or CLUSTER BY,
  unless some configuration is indispensable for it to work.
- Prefer direct SELECT and rules in WHERE; CTE only when it simplifies reading.
- Comment only non-obvious decisions, such as the three-minute regulatory threshold.
- Do not add validations without discussing them with the user.
- Do not sync the Parquet files through the bundle; identified originals require restricted access.

## Scope and sequence

In this stage: create the two catalogs and the user permissions; declare four schemas
 and the volume; validate and publish only dev. Prod stays configured, with the catalog
created, without deploying schemas. Do not create tables, transformations, dashboard or agent.
The Parquet upload will be carried out by the user, separately.

Sequence: 01 bronze; 02 silver numbers; 03 silver text (AI or regex);
04 gold and metric view; 05 dashboard; 06 agent; 07 report and demo.
