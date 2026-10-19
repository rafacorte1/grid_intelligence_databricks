# Prompt 05 — AI/BI dashboard

> **Prompt 6 of 8.** Requires the gold layer and the metric view to be published.

---

Read `.llm/prd.md`. Now the **AI/BI dashboard** (Lakeview) over the gold layer, declared
in the bundle.

Read the `databricks-aibi-dashboards` skill before writing the JSON — the format has
version-specific widget definitions, and getting the version wrong breaks the widget
silently.

## Who opens this dashboard

The distributor's operations manager, at 8 a.m., with two minutes to spare. He wants to
know **what happened** and **what needs action today** — in that order.

## Two pages

### Page 1 — Today's operations

- **Four KPIs at the top**, with a sparkline: UC-hours without supply, service calls,
  service calls with a health risk, UCs on inspection priority (UC, electricity delivery
  point). For the sparkline to work, the dataset has to keep the time dimension — one row
  per day, not one aggregated row.
- **Time series** crossing service calls and interrupted UC-hours on the same chart. That
  crossover is what the dashboard exists to show: the spike in calls follows the night of
  the cascade.
- **Horizontal bar** with DEC by district, coming from the **metric view** with `MEASURE()`,
  not from a calculation of your own (RN-04).
- **Table** of what needs action, with the `acao_recomendada` column.

### Page 2 — Non-technical losses and customers

Open the page with a text block explaining, for whoever is looking, that the classification
is **inspection priority and never an accusation** (RN-07). Anyone who sees a list of UCs on
a dashboard needs to read that before drawing a conclusion.

- **Stacked bar** of UCs by neighborhood and priority. Concentration in a single
  neighborhood while the district stays stable is exactly the pattern the two-axis rule
  looks for.
- **Table** with the detail of the prioritization, including the observed reason.
- **Table** of customers on the ombudsman route, with the latest statement. Make it clear
  in the widget description that the text has already been anonymized.

## JSON rules

- Queries use **bare table names** (`FROM painel_operacional_dia`). Catalog and schema come
  from the `dataset_catalog` and `dataset_schema` fields of the bundle resource — same rule
  as the rest of the project: the catalog name lives only in `databricks.yml`.
- `queryLines` is an array of strings **concatenated with no separator** — end every line
  with a space or `\n`, or the query comes out glued together.
- Widgets **inline** in `layout[].widget`, never in a separate `widgets` array.
- `query.fields[].name` must match `encodings.*.fieldName` exactly.
- Versions: `counter` and `table` are version 2; `bar` and `line` are version 3.

## Color

Define the theme in `uiSettings.theme` — without it the dashboard inherits the workspace
default and looks generic. Use a coherent family moving **across hues**, not a pale blue
fading into white.

Semantic colors go in as **literal hex** in `color.scale.mappings`: high priority in warm
coral, medium in yellow. A reference to a palette position is silently discarded in
`mappings`.

## When you finish

1. **Test every dashboard query through the CLI before publishing** — a dashboard with a
   broken query only errors when someone opens it.
2. `databricks bundle deploy -t dev --profile grid_intelligence`
3. Send me the dashboard link and a screenshot of page 1

## Acceptance criteria

- Every query runs without error against gold
- The dashboard's DEC comes from the metric view, not from a calculation of your own
- No catalog name inside the JSON
- Page 2 states that the output is inspection priority, not an accusation
- The dashboard opens and the widgets render
