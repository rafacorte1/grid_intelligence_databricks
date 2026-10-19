# Prompt 02 — Silver: the numbers

> **Prompt 3 of 8.** Requires bronze done and populated.

---

Read `.llm/prd.md`, including the **simplicity guideline**. Now the **silver layer**, in its
numeric part: registry, interruptions and consumption. The free text of the service calls is left for the
next prompt.

## What this prompt creates

Three files in `src/pipelines/grid_intelligence/transformations/`, four tables:

| File | Creates | Type | Grain |
|---|---|---|---|
| `10_silver_cadastro.sql` | `silver.unidades_consumidoras` | streaming table | one UC (electricity delivery point) |
| `11_silver_interrupcoes.sql` | `silver.interrupcoes_validas` | streaming table | one event that passed RN-01 |
| `12_silver_consumo.sql` | `silver.consumo_diario` | materialized view | UC × day |
| `12_silver_consumo.sql` | `silver.baseline_consumo` | materialized view | one UC |

**Why 12 is a materialized view and the other two are not:** deduplicating requires looking at all
rows of the same key, and the baseline requires a window — both things are batch. A streaming table
sees only the new batch, and serves well for row-by-row filtering, which is the case of 10 and 11.

**No expectations, no `CONSTRAINT`, no `COMMENT`.** Every discard in this layer is a
`WHERE` that reads out loud.

## 1. `silver.unidades_consumidoras` — a clean registry

A streaming table from `STREAM(bronze.unidades_consumidoras)`.

The generator spoils a small fraction of the registry entries on purpose, and this is where that gets
resolved — three cases, three expressions:

| Problem at the source | What to do |
|---|---|
| `classe_consumo` arrives as `'  RESIDENCIAL '` | `lower(trim(classe_consumo))` |
| `bairro` arrives empty | `'nao informado'` — **do not invent a district** |
| A UC with no key or no district | `WHERE id_uc IS NOT NULL AND id_conjunto IS NOT NULL` |

Normalizing the class is not fussiness: without it, the `GROUP BY` by class returns two
rows for the same class, and the dashboard shows "residencial" twice.

A missing district is a registry problem that someone has to solve at the source. Marking it
as `'nao informado'` preserves the fact; filling it with the neighbor's district would erase it.

## 2. `silver.interrupcoes_validas` — RN-01

**This is the most important file in the prompt.** It is where the 3-minute rule lives.

> Only **supply** interruptions with a duration greater than or equal to 3 minutes enter the
> calculation of the continuity indicators.

The cut is on the `duracao_minutos` column of `bronze.interrupcoes`. An event below that is the
recloser operating — a branch on the line, trip and automatic reclose in seconds. The
customer sees the light flicker; it is not a power outage. In the dataset they are 310 of 1,383 events,
22.4%.

The whole rule is one line:

```sql
WHERE duracao_minutos >= ${duracao_minima_interrupcao_min}
```

Three things I want explicit:

1. **The threshold cannot be `3` written in the middle of the query.** It comes from the pipeline
   `configuration`. The rule belongs to the regulator, not to the engineer: if ANEEL changes the threshold,
   one configuration line changes.
2. **The discard happens here, once.** If each area applied its own filter, each
   one would compute a different DEC — and a number mismatch between internal reports is
   a real problem in regulatory inspection.
3. **Short interruptions do not disappear from the world:** they remain in bronze, where anyone
   can count them. What they do not do is become an indicator.

Two comment lines above the `WHERE`, explaining the recloser. It is the kind of decision that
the code does not tell on its own.

### The derived columns — this is where DEC starts

Filtering is not enough. This file prepares the inputs that gold will only sum:

| Derived column | Expression | What for |
|---|---|---|
| `data_evento` | `to_date(inicio)` | grain of the operational dashboard |
| `mes_apuracao` | `date_trunc('MONTH', inicio)` | grain of the calculation (RN-05) |
| `duracao_horas` | `duracao_minutos / 60.0` | the indicator is in hours |
| **`uc_horas_interrompidas`** | `duracao_horas × qtd_ucs_afetadas` | **DEC numerator (RN-02)** |
| `causa_climatica` | `causa = 'climatica'` | separates weather from the rest |

**Why the product is computed here and not in gold.** `uc_horas_interrompidas` is an
**additive** quantity: summing it over any slice — month, district, year — gives the right number.
If the product were done after the aggregation, it would be an average of averages, which it is not.
Leaving the input ready at the grain of the event is what allows the metric view to answer correctly
any cut the user asks for.

The FEC numerator does not need a new column: it is `qtd_ucs_afetadas`, which already comes from the source.

## 3. `silver.consumo_diario` — discard and deduplication

**A materialized view, not a streaming table.** The reason is concrete: the concentrator resends
readings and the same key `(id_uc, data)` arrives twice. Choosing one of the two requires
looking at all rows of that key — that is batch, not streaming.

What to discard, in a single `WHERE`:

- null consumption — a meter that did not communicate in the cycle
- negative consumption — a sign error in the recorder
- consumption above the physical limit of the connection

The **physical limit is defined here**, on the side of whoever consumes the data, and not inherited from the
generator. In a utility that is how it works: whoever receives the telemetry establishes what it considers
plausible for each type of connection. Use a `CASE` per consumption class.

For the duplicate, `qualify row_number() over (partition by id_uc, data order by ingerido_em desc) = 1`
solves it in one line — no CTE needed.

Join with the registry so that each row already carries district, neighborhood and class — the
non-technical loss rules should not have to redo that join.

## 4. `silver.baseline_consumo` — the input for the two axes

It is the table that gives RN-06 its two comparisons:

- **recent window:** the last 30 days of the dataset
- **baseline window:** the **90 days immediately before** it

### Why the baseline is not "everything that came before" — read this before simplifying

The load on Luz do Vale grows ~30% a year and the dataset has four years. Comparing the last
30 days against the average of the entire history flags **an increase of more than 50% in every UC in the
system**, because the average includes the first year, when consumption was almost three times
lower. Practical result: the second axis of RN-06 never considers the neighborhood stable and
loss detection stops working completely.

A baseline over a series with a trend needs a **comparable window**. Ninety days
immediately before carry ~4% growth between the center of one window and that of the
other — noise small enough for the stability band to absorb, and a period long enough
for the average not to swing with two atypical weeks.

### Another trap

Anchor the window on the **largest day in the dataset**, never on `current_date()`. The dataset is
synthetic and may have been generated last week; anchoring to the clock makes the analysis slide
out of the data and return an empty table — a classic and annoying symptom to diagnose.

Compute, per UC: the average in the baseline, the average in the recent window, the day count in each window, and the
percentage change. And, per district, the same averages — that is the second axis.

## When you finish

Run the pipeline and show me:

1. How many interruptions RN-01 discarded, in number and in percentage — it should be **310 of
   1,383**, leaving **1,073**
2. How many consumption rows were discarded, and how many duplicates disappeared
3. The average change of district `CPQ-02` between the two windows — it needs to be close to
   zero, otherwise the second axis will not work in the next prompt

## Acceptance criteria

- The 3-minute threshold comes from configuration, it is not written in the SQL
- `silver.interrupcoes_validas` has 1,073 rows
- `silver.consumo_diario` has no null, negative or above-limit consumption, nor a repeated
  `(id_uc, data)` key
- The district change between the windows is within ±10%
- No expectation, no `CONSTRAINT`, no `COMMENT`
- Each file fits on a screen and a half
