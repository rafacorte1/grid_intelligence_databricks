# Prompt 01 — Bronze layer

> **Prompt 2 of 8.** Requires prompt 00 completed: schemas, volume and `.llm/prd.md` in place.

---

Read `.llm/prd.md` before starting, including the **simplicity guideline**. Now we are going to
build the **bronze layer** of the Grid Intelligence medallion.

## What I want

A **serverless Lakeflow Declarative Pipeline** that ingests the four bases from the
`raw.landing` volume into the `bronze` schema, one table per base.

**A single file:** `src/pipelines/grid_intelligence/transformations/01_bronze.sql`, with the
four tables. They share the same ingestion pattern, and splitting them into four identical
files would only spread the same decision across four places.

| Source in the volume | Bronze table | Expected rows |
|---|---|---|
| `unidades_consumidoras/` | `bronze.unidades_consumidoras` | 4,000 |
| `interrupcoes/` | `bronze.interrupcoes` | 1,383 |
| `consumo_diario/` | `bronze.consumo_diario` | ~5.85 million |
| `chamados/` | `bronze.chamados` | 2,801 |

All of them are **streaming tables**: ingestion is an append of a new file, and that is what Auto Loader
knows how to do incrementally.

Use **Auto Loader** (`STREAM read_files`) with Parquet format. Point it at the **folder**, not
at the file: today each base takes a single Parquet, but if one of them needs to be
partitioned tomorrow, nothing changes in the pipeline.

## The format of each table

Four blocks identical to this one, and nothing beyond that:

```sql
CREATE OR REFRESH STREAMING TABLE ${catalogo}.${schema_bronze}.interrupcoes
AS SELECT
  *,
  _metadata.file_path AS arquivo_origem,
  current_timestamp() AS ingerido_bronze_em
FROM STREAM read_files(
  '${volume_landing}/interrupcoes/',
  format => 'parquet'
);
```

**No expectations, no `CONSTRAINT`, no `COMMENT`, no `CLUSTER BY`.** Bronze is a
passage: what it has to do is copy faithfully and say where it came from.

The two extra columns are RN-12: `arquivo_origem` and `ingerido_bronze_em`. The columns
`origem` and `ingerido_em` that already come from the data say which *system* it came out of; these two
say through which path it *entered* here.

## The rule that governs this file: RN-11

**Ingestion does not apply a business rule, does not filter and does not correct.**

Negative consumption, an impossible reading, a 40-second interruption, a registry entry with an empty
district — everything enters exactly as it arrived. Filtering here would look like cleaning; it is destruction of
evidence. Silver is what discards, with a named rule visible in the `WHERE`.

The `SELECT *` above is not laziness: it is RN-11 written in code. Any column you
listed by hand would be a decision about what is worth keeping — and that decision is not
bronze's.

## Parameterization

The pipeline receives through `configuration`: catalog, the name of each schema, the volume path and
the minimum interruption duration threshold. **No catalog name written inside the
SQL** — the files use `${catalogo}.${schema_bronze}.<tabela>`, and the value comes from
`databricks.yml`.

## A trap I want recorded in a comment

Each base takes a single file, which is overwritten when the dataset is regenerated.
`allowOverwrites => true` makes Auto Loader reprocess the swapped file, but a **streaming
table is append-only**: the old rows stay there and the volume doubles. Leave that written
at the top of the file, together with the solution — running the pipeline with a **full refresh** after
regenerating.

## If the pipeline fails with `DELTA_FEATURE_REQUIRES_MANUAL_ENABLEMENT: timestampNtz`

It will happen. The dataset timestamps are **without a time zone** (`TIMESTAMP_NTZ`), and
Delta requires this feature to be enabled explicitly on the table.

There are two ways out, and one of them is wrong:

- **Convert to `TIMESTAMP` at ingestion** — it would assume a time zone that the data does not declare.
  That is transformation inside bronze, exactly what RN-11 forbids.
- **Enable the feature on the table** — the type enters as it arrived, and whoever decides the time zone is
  silver, if it needs to.

Use the second. It is the only exception to the rule of not using `TBLPROPERTIES`:

```sql
CREATE OR REFRESH STREAMING TABLE ${catalogo}.${schema_bronze}.interrupcoes
TBLPROPERTIES ('delta.feature.timestampNtz' = 'supported')
AS SELECT ...
```

## If bronze ingests nothing

Before investigating Auto Loader, check the timestamp precision of the Parquet:

```bash
databricks experimental aitools tools query --profile grid_intelligence \
  "SELECT * FROM parquet.`/Volumes/grid_dev/raw/landing/interrupcoes/` LIMIT 1"
```

Parquet written by pandas without handling ends up as `timestamp[ns]`, and **Spark does not read
nanoseconds**. This project's generator already converts to microseconds; if the data came from
somewhere else, that is the first thing to check — the failure is not obvious and looks like a path
problem.

## When you finish

1. `databricks bundle deploy -t dev --profile grid_intelligence`
2. Run the pipeline and show me the result
3. The row count of each bronze table
4. **How much defect came in**, with a single query — it is what silver will have to resolve:

```sql
SELECT
  count(*)                                                   AS eventos,
  count_if(duracao_minutos < 3)                              AS abaixo_de_3_min,
  round(100.0 * count_if(duracao_minutos < 3) / count(*), 1) AS pct
FROM grid_dev.bronze.interrupcoes
```

It should return **1,383, 310 and 22.4%**. Those 22.4% are exactly what RN-01 will discard
in the next prompt — and it is good to see the number beforehand, to recognize it later.

## Acceptance criteria

- The four bronze tables exist and have the expected volume
- No row was filtered, corrected or discarded
- Every table has `arquivo_origem` and `ingerido_bronze_em`
- No catalog name appears inside the SQL
- Each table fits on one screen
