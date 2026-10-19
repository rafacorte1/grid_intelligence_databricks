# Prompt 04 — The gold layer and the metric view

> **Prompt 5 of 8.** Requires the complete silver — numbers and text.
>
> Two of the four deliverables (`saude_cliente` and `painel_operacional_dia`) depend on the signals
> extracted from the transcripts. They **do not need AI**: a mention of the ombudsman/ANEEL/Procon,
> a health risk and the reason for the service call are explicit terms, and a classification by term is
> auditable word by word — which in a regulated sector is worth more than a few points of
> accuracy. If the text silver does not exist yet, build it by deterministic rule
> before moving on; it takes seconds.

---

Read `.llm/prd.md`, including the **simplicity guideline**. Now the **gold layer**: the
business deliverables.

One caveat to the guideline, and it applies only here: **gold carries `COMMENT`**. It is the layer the
conversational agent reads, and there the description is not documentation — it is what makes the agent
get it right (RN-14). The rest still holds: no expectations, no `CONSTRAINT`, no CTE that
does not need to exist.

A naming rule for the whole layer: **if the table name is not a business question, the deliverable is
not ready yet.**

## What this prompt creates

Five files, five objects. All in `src/pipelines/grid_intelligence/transformations/`,
except the last one:

| File | Creates | Grain | Question it answers |
|---|---|---|---|
| `20_gold_continuidade.sql` | `gold.continuidade_conjunto_mes` | district × month | Are we within the regulatory limit this month? |
| `21_gold_prioridade_inspecao.sql` | `gold.prioridade_inspecao_uc` | one candidate UC | Which UCs deserve a field visit first? |
| `22_gold_saude_cliente.sql` | `gold.saude_cliente` | one customer | Which customers are heading for an ombudsman complaint? |
| `23_gold_painel_operacional.sql` | `gold.painel_operacional_dia` | district × day | What happened yesterday and what needs action today? |
| `src/sql/metric_view_continuidade.sql` | `gold.continuidade_metricas` | — | **The definition of DEC and FEC** |

All four tables are **materialized view**: aggregation over a window and `GROUP BY` do not
fit in a streaming table, which is append-only and sees only the new batch.

The fifth file **stays outside the pipeline** and runs as a SQL task of the job. A metric view is not a
Lakeflow dataset.

## 1. Continuity — and RN-04, which is the central lesson of the project

### The two indicators, before the code

Both are **averages per UC in the district**, computed per month (RN-05):

```
        Σ (duracao_horas × qtd_ucs_afetadas)              Σ qtd_ucs_afetadas
DEC  =  ────────────────────────────────────      FEC  =  ──────────────────────
             total UCs in the district                     total UCs in the district

     "how many hours, on average, each UC          "how many times, on average, each UC
      in the district went without power"           in the district went without power"
```

**The denominator is the total number of UCs in the district, not the count of those affected.** A
two-hour event that hits 50 of 800 UCs is worth `2 × 50 / 800 = 0.125 h` of DEC — the duration diluted across
the whole base, including those who never lost power. That is what makes districts of different
sizes comparable. If the denominator were "affected UCs", the indicator would always return
the average duration of the event, and Sumaré would look as well served as Campinas.

The DEC numerator **already comes ready from silver**: `uc_horas_interrompidas`, calculated in
`11_silver_interrupcoes.sql`. Here it is only summed.

### `gold.continuidade_conjunto_mes` — the columns

Grain: one row per `(id_conjunto, mes_apuracao)`. Source: `silver.interrupcoes_validas`
aggregated, with an `INNER JOIN` on `silver.unidades_consumidoras` to bring the total UCs.

| Column | What it is | Role |
|---|---|---|
| `id_conjunto` | district key | grain |
| `nome_conjunto`, `municipio` | readable labels | dashboard dimension |
| `mes_apuracao` | `date_trunc('MONTH', inicio)` | grain (RN-05) |
| `total_ucs` | `count(*)` of the district's UCs | **denominator** of DEC and FEC |
| `uc_horas_interrompidas` | `sum(duracao_horas × qtd_ucs_afetadas)` | **DEC numerator** |
| `uc_interrupcoes` | `sum(qtd_ucs_afetadas)` | **FEC numerator** |
| `qtd_interrupcoes` | `count(*)` of the events | context |
| `qtd_interrupcoes_climaticas` | events with a weather cause | separates the weather-driven events |
| `qtd_interrupcoes_programadas` | events with prior notice | these get different regulatory treatment |
| `maior_duracao_horas` | `max(duracao_horas)` | the worst event of the month |

No expectations. The `INNER JOIN` with the registry already guarantees that every district has a UC — and
a district with no UC would divide by zero.

### Why the table has no DEC column

Here comes the counterintuitive part: **the gold continuity table has no `dec_horas` column.**

If the table calculated the DEC and the metric view calculated it again, there would be **two
definitions** — and on the day the formula changes, someone updates one and forgets the other.
That is how the company ended up with three different DECs in circulation.

The division of labor is:

- **the table** holds the **additive inputs**: interrupted UC-hours, UC-interruptions and the
  total UCs in the district. Summing an input over any slice gives the right number.
- **the metric view** holds the **definition**: `DEC = UC-hours / total UCs`. A single one,
  versioned in `src/sql/metric_view_continuidade.sql`, consumed by the dashboard, the agent and the
  report.

### The metric view — `gold.continuidade_metricas`

`CREATE OR REPLACE VIEW ... WITH METRICS LANGUAGE YAML`, over
`continuidade_conjunto_mes`.

**Dimensions:** `Conjunto` (from `nome_conjunto`), `Codigo do Conjunto`, `Municipio`, `Mes`.

**Measures — ten of them, each an expression over the columns of the table above:**

| Measure | Expression | Format |
|---|---|---|
| `DEC` | `SUM(uc_horas_interrompidas) / SUM(total_ucs)` | `#,##0.00` |
| `FEC` | `SUM(uc_interrupcoes) / SUM(total_ucs)` | `#,##0.00` |
| `DEC Acumulado` | see pitfall 3 — a formula **different** from the one in `DEC` | `#,##0.00` |
| `Interrupcoes` | `SUM(qtd_interrupcoes)` | `#,##0` |
| `Interrupcoes Climaticas` | `SUM(qtd_interrupcoes_climaticas)` | `#,##0` |
| `Proporcao Climatica` | `SUM(climaticas) / NULLIF(SUM(interrupcoes), 0)` | `0.0%` |
| `Interrupcoes Programadas` | `SUM(qtd_interrupcoes_programadas)` | `#,##0` |
| `Horas UC Interrompidas` | `SUM(uc_horas_interrompidas)` | `#,##0.0` |
| `Maior Interrupcao` | `MAX(maior_duracao_horas)` | `#,##0.00` |
| `Total de UCs` | see pitfall 3 | `#,##0` |

The `NULLIF` in the proportion is not pedantry: a month with no interruption at all exists in the dataset, and
without it the view breaks on division by zero.

Put `synonyms` on the dimensions and on the main measures — `DEC` has to answer to
"how many hours without power", `Conjunto` to "region". That is what the agent in prompt 06 will use to
translate the manager's question. And `comment` on everything (RN-14).

**How it is queried:**

```sql
SELECT `Conjunto`, MEASURE(`DEC`), MEASURE(`FEC`)
FROM ${catalogo}.${schema_gold}.continuidade_metricas
WHERE `Mes` = '2026-07-01'
GROUP BY ALL
```

Note that the names carry backticks and spaces: the metric view exposes **business language**, and that is
why the agent can translate the manager's question. And `MEASURE()` is not decoration — it is what tells
the engine to apply the measure definition to the slice being requested. Summing the
column by hand returns a different number, and that is exactly the deviation RN-04 prevents.

Three pitfalls to record in a comment in the file:

1. The YAML body sits inside a `$$...$$` literal and **does not go through parameter
   substitution**. Position catalog and schema beforehand, with `USE CATALOG IDENTIFIER(:catalogo)`
   and `USE SCHEMA`, and write plain names inside the YAML.

2. **No `;` inside the `$$...$$` block, not even in `comment` text.** This one breaks the
   task on the first run, and the error seems to have nothing to do with the cause: the SQL file
   executor splits the script into statements on `;` and **does not understand the `$$` literal**. A
   semicolon in the middle of a sentence — "…was without power; FEC is the average number…" —
   cuts the `CREATE VIEW` in half, and the message points to the end of a line of prose,
   as if the YAML were malformed. Use periods or dashes when wording the comments.

3. When you aggregate several months, the denominator repeats once per month. That is what makes the
   direct division return a **monthly average**, and not a cumulative total. Offer both measures, with
   **different** formulas — writing them the same is easy and goes unnoticed, because in a
   single month both return the same number:

   ```
   DEC           = SUM(horas_uc) / SUM(total_ucs)                          -- monthly average
   DEC Acumulado = SUM(horas_uc) / (SUM(total_ucs) / COUNT(DISTINCT mês))  -- period total
   ```

   The same goes for `Total de UCs`: sum it and divide by the number of months, otherwise the base
   shows up multiplied by the length of the period.

The metric view is created by a **SQL task of the job**, from the versioned file, on
every run. Never by a `CREATE VIEW` that someone ran in the UI.

`sql_task` is the only thing in the bundle that does **not** run on pipeline serverless: it needs a
`warehouse_id`. Declare it as a variable in `databricks.yml` — the id comes from
`databricks warehouses list --profile grid_intelligence`.

## 2. Inspection priority — RN-06, RN-07 and RN-08 together

`21_gold_prioridade_inspecao.sql` creates `gold.prioridade_inspecao_uc`, one row per candidate
UC. The source is `silver.baseline_consumo` — which already brings the two comparable windows
ready from prompt 02, and that is why this file recalculates no average at all.

**The two axes:**

- axis 1: the UC dropped against its own baseline by more than the threshold
- axis 2: **while** the district's variation stayed within the stability band

Both thresholds come from the pipeline `configuration`, not written into the SQL.

**The classification:**

| Situation | Priority |
|---|---|
| Both axes plus a tampering signal on the meter | high |
| Both axes, no physical signal | medium |
| A signal on the meter without a relevant drop | medium |
| Dropped along with the neighborhood | **low** — this is a network event, not an individual case |

**The columns the decision has to carry.** A priority list that does not show the math is no use
to the inspector:

| Column | What it is for |
|---|---|
| `id_uc`, `id_conjunto`, `nome_conjunto`, `bairro`, `classe_consumo` | where to go |
| `prioridade_inspecao` | high, medium or low |
| `caiu_contra_si`, `vizinhanca_estavel`, `atende_os_dois_eixos` | the two axes, explicit as booleans |
| `sinal_violacao_recente` | the physical aggravating factor |
| `variacao_da_uc`, `variacao_do_conjunto` | **the numbers behind the booleans** |
| `consumo_medio_baseline_kwh`, `consumo_medio_recente_kwh` | from how much to how much |
| `dias_no_baseline`, `dias_no_periodo_recente` | how much evidence sits behind it |
| `motivo_observado` | the sentence in business language |

**The output is a priority, never an accusation (RN-07).** The `motivo_observado` column states, in
business language, what was actually seen in the data — it is what the inspector needs to
know before knocking on someone's door.

No column, value or comment in this file may use the words fraud, theft or culprit.

**An explainable rule, not a trained model (RN-08).** There is no reliable label for
irregularity in this dataset; a supervised classifier without labels is theater. Any
person has to be able to reconstruct, row by row, why a UC made the list.

## 3. Customer health

`22_gold_saude_cliente.sql` creates `gold.saude_cliente` from
`silver.chamados_enriquecidos`.

**The grain is the customer, not the UC.** That choice is the reason the glossary separates the two
terms on the first line: whoever files a complaint with the ombudsman is the person, and they may have three
UCs. Grouping by UC would hide the customer who called once for each one — and it is the
`qtd_ucs_com_chamado` column that makes that visible.

Classify `risco_ouvidoria` (high, medium, low) by, in this order of weight: an explicit mention of the ombudsman / ANEEL / Procon; recurrence (3+ service calls in 30 days) with a negative tone; a report of health risk.

**The columns:** `id_cliente`, `id_conjunto`, `nome_conjunto`, `bairro`, `qtd_chamados`,
`qtd_ucs_com_chamado`, `qtd_chamados_negativos`, `proporcao_negativa`,
`qtd_mencoes_ouvidoria`, `qtd_chamados_risco_saude`, `qtd_urgencia_alta`, `reincidente`,
`motivo_predominante`, `ultimo_equipamento_citado`, `ultima_fala`, `primeiro_chamado_em`,
`ultimo_chamado_em`, `risco_ouvidoria`.

`ultima_fala` comes from the **anonymized text** — whoever handles the case needs context, not the
customer's CPF (RN-09).

Use `mode()` for `motivo_predominante`: a report that changes its answer on every run
destroys the manager's trust in the number.

## 4. Daily operational panel

`23_gold_painel_operacional.sql` creates `gold.painel_operacional_dia` — one row per district
per day, stitching together **five sources**: `silver.interrupcoes_validas`,
`silver.chamados_enriquecidos`, `silver.consumo_diario`, `gold.prioridade_inspecao_uc` and
`silver.unidades_consumidoras`.

It is the only gold table that reads another gold table — the priority one — and the order of the numeric
prefix in the file names exists precisely to keep that readable.

**A modeling decision I want made explicit:** aggregate the three blocks **separately** and
combine them with a `FULL OUTER JOIN`, rather than a single join of the three bases. A day with an
interruption and no service call exists; a day with a service call and no interruption does too. A plain
join would eat those rows precisely on the days the manager most wants to look at.

Finish with an `acao_recomendada` column, with the conditions in the order an operations manager
would look at them: people at risk first, then a customer threatening the ombudsman, then
network impact, then inspection.

## When you finish

Run the pipeline and the metric view task, and show me:

1. DEC and FEC for each district in the last month, **querying the metric view** with `MEASURE()`
2. How many UCs ended up at high priority, and in which neighborhoods
3. The customers at high risk of going to the ombudsman
4. The daily panel for the events, with the recommended action column

### What to expect to see, to know the math is right

The dataset has **4,000 UCs across 6 districts** and 4 years of history. With that, the numbers come out
in this order of magnitude:

| Slice | DEC | FEC |
|---|---|---|
| One month, one district | 0.03 to 1.3 h | 0.1 to 0.6 |
| Cumulative over the 4 years | 4.8 to 11 h | 5.3 to 13.4 |

**If the DEC for a single month comes in on the order of hours, the denominator is wrong** — almost
always it is `qtd_ucs_afetadas` in place of `total_ucs`, and the indicator has turned into "average duration of
the event".

Check the totals as well: `silver.interrupcoes_validas` has **1,073 rows** out of the 1,383 in
bronze, and `sum(qtd_interrupcoes)` in gold has to match those 1,073.

## Acceptance criteria

- The gold continuity table has **no** calculated DEC or FEC column
- The metric view answers `MEASURE(\`DEC\`)` correctly
- `DEC` and `DEC Acumulado` have different formulas — check by querying **two months or
  more**, where the values must diverge. In a single month they coincide, and an error here
  goes unnoticed
- Inspection priority requires both axes to classify as high
- No "fraud", "theft" or "culprit" label in the **project code** or in any value
  written to a table. The rule documents (`prd.md`, this prompt) and the schema comment
  that *prohibits* those labels are the obvious exception: stating the prohibition is not violating it
- The four gold tables and the metric view have `COMMENT` in business language — it is what the
  agent in prompt 06 reads (RN-14). They are the **exception** to the simplicity guideline
- The job runs end to end with the metric view task included
