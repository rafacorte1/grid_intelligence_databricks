# Prompt 00 — Setup and planning

> **How to use it:** paste this entire text into Claude Code, inside the project repository.
> It is the first of a sequence of **8 prompts**. Each one delivers a complete feature,
> with a deploy and a visible result. Do not skip the order: every prompt assumes the previous one is done.

---

You are going to help me build the data and AI platform of a fictional electric utility,
**Luz do Vale Distribuidora S.A.**, on Databricks. The project is called
**Grid Intelligence**.

This is **prompt 1 of 8**. In this first one I want only the foundation: understand the domain,
record the business rules and create the infrastructure. Do not build transformation,
dashboard or agent now — each one has its own prompt.

## Business context

An electric utility operates under ANEEL regulation and has three simultaneous pain points,
all of them measurable in money:

1. **Continuity of supply.** Interrupting beyond the regulatory limit triggers automatic
   financial compensation to the customer. In 2024 Brazilian utilities paid more than
   R$ 1.1 billion in compensations.
2. **Non-technical losses.** Energy delivered and not billed — theft, fraud and metering
   error. In 2025 they added up to ~R$ 11.5 billion, of which ~R$ 7.9 billion were passed
   through to the tariff.
3. **Customer service.** Thousands of calls become transcripts and nobody reads them. Inside
   them is the early warning of the ombudsman complaint.

## Glossary — use these terms, no approximate synonym

| Term | Definition |
|---|---|
| **UC — electricity delivery point** | The delivery point of electricity. **It is not a synonym for customer**: one customer may have several UCs |
| **District** | Geographic subdivision of the concession area. It is the regulator's aggregation unit |
| **DEC** | Average interruption duration per UC — average time, in hours, without supply |
| **FEC** | Average interruption frequency per UC — average number of interruptions |
| **PNT** | Non-technical losses |
| **Inspection priority** | A ranking of how much a UC deserves a technical visit |

## Business rules that apply to the whole project

- **RN-01** — Only interruptions of **3 minutes or more** enter the DEC and FEC calculation.
  The rule lives in the transformation layer, never in the report.
- **RN-04** — DEC and FEC have **a single definition** in the system, consumed by dashboard,
  agent and report.
- **RN-06** — A UC is a candidate for inspection when consumption drops on **two axes at the
  same time**: against its own baseline **and** while the neighborhood stays stable.
  The first axis alone would flag the whole neighborhood after a blackout.
- **RN-07** — The output of the detection is **inspection priority** — high, medium, low.
  **Never** a label of fraud, theft or blame. A consumption drop is also a change of
  occupant, an empty property, a meter defect and a reading error. In a regulated sector the
  difference is legal. No column, variable or comment in the project may use the
  words "fraud", "theft" or "guilty" as an output label.
- **RN-09** — Personal data in a transcript is **masked before** any analysis of
  content.
- **RN-10** — The identified original text is preserved with **restricted access**. Two
  protections that coexist: one at reading, the other at analysis.
- **RN-11** — The ingestion layer **does not filter, does not correct and does not apply a business
  rule**. An invalid meter reading is a fact about the meter. Filtering at ingestion
  looks like cleaning; it is destruction of evidence.
- **RN-12** — Every ingested record carries its origin and the ingestion timestamp.
- **RN-13** — The conversational agent accesses **only the business layer**.
- **RN-14** — The entities of the **gold layer** carry a description in business language —
  that is what the agent reads. Bronze and silver do not need one: they are a passage.

## Simplicity guideline — applies to all 8 prompts

This project is built **live, in class**. Code that nobody can read on screen in
ten seconds does not work, even when it is more robust.

**Write the minimum that makes the thing work:**

- **No expectations and no `CONSTRAINT`** on the tables. A business rule becomes a `WHERE`, which
  anyone can read without needing to know what `ON VIOLATION` is.
- **No `COMMENT` on bronze and silver.** They are a passage. Only **gold** and the **metric view**
  carry descriptions — they are what the conversational agent reads, and there curation is the product
  (RN-14).
- **No `TBLPROPERTIES`, `CLUSTER BY` and the like**, unless something breaks without them.
- **No handling for a case the dataset does not have.** Do not invent a defense for data that does not
  exist.
- **One direct `SELECT` beats a `WITH` with four CTEs.** Only break into a CTE when the query
  really does not fit in your head.

A comment in the code only where the decision **is not obvious from the code** — the 3-minute rule
deserves two lines explaining why; a `CAST` deserves none.

If at any point you think the right thing is to add validation, **do not add it**: tell me
in one line what you would do, and I decide.

## Mandatory conventions

- All text and every name in **Brazilian Portuguese**; entity, column and
  file names **without accents**.
- **No catalog name hardcoded.** The catalog comes from `${var.catalog}` in
  `databricks.yml`; the schema comes from `${resources.schemas.<camada>.name}`.
- **No AI model name hardcoded.** Use the Databricks `ai_*` functions.
- CLI profile: `grid_intelligence`. Every command carries `--profile grid_intelligence`.

## The data

Four synthetic bases, already generated, in Parquet:

| Base | Grain | Volume |
|---|---|---|
| `unidades_consumidoras` | one per delivery point | 4,000 |
| `interrupcoes` | one per grid event | 1,383 |
| `consumo_diario` | one per UC per day | **~5.85 million** (4 years) |
| `chamados` | one per call, with transcript | 2,801 |

The dataset has **four years of history**, **30% year-over-year** growth in load and
**summer seasonality** in customer service (December to March take almost double the
calls). It carries **deliberate defects** — null, negative and physically
impossible consumption, duplicate rows and interruptions under 3 minutes. They are not bugs: they exist
so that the quality validations and RN-01 have something to do.

## What to do now

1. **Read the `databricks-core` skill** before any command, and then
   `databricks-dabs`.
2. Write **`.llm/prd.md`** with the context above: domain, glossary, business rules,
   information model and the four planned business deliverables. It is the document that every
   following prompt will consult.
3. **Create the catalogs** (see below).
4. Create in the bundle the **schemas** `raw`, `bronze`, `silver` and `gold`, and the **volume**
   `raw.landing`. One schema per layer — the schema name already is the layer, so the tables
   inside it do not repeat the prefix (`bronze.chamados`, never `bronze_chamados`).
5. Configure `dev` and `prod` isolated **by catalog**, not by schema name.
6. Run `databricks bundle validate` and `databricks bundle deploy -t dev`.
7. Tell me exactly **where to upload the data files**, with the full path.

## The catalogs

Two catalogs, one per environment. It is the catalog that isolates dev from production — the schemas keep the
exact names `raw`, `bronze`, `silver` and `gold` on both sides, so that the same SQL runs in
any environment without a single different line.

| Environment | Catalog | Who uses it |
|---|---|---|
| `dev` | `grid_dev` | you, day to day |
| `prod` | `grid_intelligence` | the final environment, after being validated in dev |

**The catalog is the only thing the bundle does not create** — it is an account resource, and the deploy assumes it
already exists. Schemas and volume live in the bundle; the catalog does not.

Create both **with SQL**, and not with `databricks catalogs create`:

```bash
databricks experimental aitools tools query --profile grid_intelligence \
  "CREATE CATALOG IF NOT EXISTS grid_dev COMMENT 'Grid Intelligence development catalog'"

databricks experimental aitools tools query --profile grid_intelligence \
  "CREATE CATALOG IF NOT EXISTS grid_intelligence COMMENT 'Grid Intelligence production catalog'"

databricks catalogs list --profile grid_intelligence
```

**Why SQL and not `catalogs create`:** in any account with Default Storage enabled — the case of
Free Edition — the API behind the command requires an explicit `storage_root` and returns
`Metastore storage root URL does not exist`. A `CREATE CATALOG` through SQL uses the account's default
storage and goes through. If even that complains, let me know: then the way is the UI, in Catalog → Create
catalog.

Then grant permission to my user on both catalogs:

```bash
databricks grants update CATALOG grid_dev \
  --json '{"changes":[{"principal":"YOUR-EMAIL","add":["ALL_PRIVILEGES"]}]}' \
  --profile grid_intelligence
```

A catalog without a *grant* is a useless catalog: the pipeline fails later with
`user does not have permission to CREATE SCHEMA`.

### Starting over from scratch

If a catalog already exists and I want to start clean, the command is destructive and **does not ask
twice** — `CASCADE` removes schemas, tables, volumes and the files inside them:

```bash
databricks experimental aitools tools query --profile grid_intelligence \
  "DROP CATALOG IF EXISTS grid_dev CASCADE"
```

**Always confirm with me before running this.** Leave the command recorded in the README, in the
setup section, with the warning that it is destructive.

## The schemas and the volume, in the bundle

Declare in `resources/grid_schemas.yml`:

- the schemas `raw`, `bronze`, `silver` and `gold`
- the **managed** volume `landing`, inside `raw`

Schema names come from `${resources.schemas.<camada>.name}` wherever they are referenced; the catalog
comes from `${var.catalog}`. **Neither of them written literally in any file.**

Add `experimental.skip_name_prefix_for_schema: true` to `databricks.yml`. Without it, in
`mode: development` the bundle prefixes the schemas with my username and `bronze` becomes
`myusername_bronze` — isolation between environments is done by the catalog, not by the schema name.

Then: `databricks bundle validate` and `databricks bundle deploy -t dev`.

## Where I will upload the data

With the volume created by the deploy, tell me the full path of each base, in a format I can
paste straight into the upload UI:

```
/Volumes/grid_dev/raw/landing/unidades_consumidoras/
/Volumes/grid_dev/raw/landing/interrupcoes/
/Volumes/grid_dev/raw/landing/consumo_diario/
/Volumes/grid_dev/raw/landing/chamados/
```

And also give me the command to upload everything at once from the terminal, remembering that **the source
path is the one on my machine** — check where the Parquet files are before assembling the command:

```bash
databricks fs cp -r <LOCAL_FOLDER> dbfs:/Volumes/grid_dev/raw/landing \
  --overwrite --profile grid_intelligence
```

The `dbfs:` prefix is mandatory even for a Unity Catalog Volume.

One folder per base, with a single Parquet file inside — including the daily consumption one, with 5.85
million rows. It is the folder, and not the file, that is the contract with the bronze layer: if one day a
base needs to be partitioned, the pipeline does not change.

## Acceptance criteria

- Both catalogs exist and I have `ALL PRIVILEGES` on both
- The command to drop the catalog is documented in the README, with the warning that it is destructive
- `databricks bundle validate --profile grid_intelligence` passes without error
- `databricks bundle deploy -t dev` creates the four schemas and the `raw.landing` volume
- The schemas do **not** have my username as a prefix
- No catalog or schema name appears written literally in the code
- I received the four upload paths and the `fs cp` command
- `.llm/prd.md` exists and contains the glossary and the 14 business rules

## What comes next

Do not do any of this now — each item is a prompt of its own:

| # | Prompt | Deliverable |
|---|---|---|
| 01 | Bronze layer | Faithful ingestion of the volume, with no business rule |
| 02 | Silver — the numbers | Clean registry, the 3-minute rule, dedup and baseline |
| 03 | Silver — the text | Anonymization and enrichment of the transcripts — with AI or by regex |
| 04 | Gold layer | The four business deliverables and the DEC/FEC metric view |
| 05 | Dashboard | AI/BI panel on top of gold |
| 06 | Agent | Conversational copilot in Portuguese |
| 07 | Report and demo | Executive report and the queries that prove it all |

When you finish the setup, tell me what you created and stop. I will send the next one.
