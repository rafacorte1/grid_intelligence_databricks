# Prompt 03-B — Silver: the text, without AI

> **Prompt 4 of 8, deterministic route.** Replaces `03-silver-texto-ia.md`. Requires the
> numeric silver to be ready. Pick **one of the two** — the prompts that follow work the same
> on either route.

---

Read `.llm/prd.md`, including the **simplicity guideline**. Now the part of silver that deals
with **free text**: the transcripts of calls to the service center. Here they are handled with
no model call at all — only SQL: regular expression, `CASE` and aggregation.

## What this prompt creates

The same tables as the AI route, with the same schema:

| File | Creates | Type | Grain |
|---|---|---|---|
| `src/pipelines/grid_intelligence/transformations/13_silver_chamados.sql` | `silver.chamados_anonimizados` | materialized view | one service call |
| the same file | `silver.chamados_enriquecidos` | materialized view | one service call |
| `src/sql/governanca_dado_pessoal.sql` | column mask on `bronze.chamados` | SQL task of the job | — |

There are 2,801 service calls. Here the file can be **`.sql`**, not `.py` as in the AI route: with no
AI function to route around through configuration, there is no reason for the Python `if`.

## Why a deterministic route exists

Every AI function is **one inference per row**. With 2,801 service calls and four functions in the
chain, that is ~11 thousand model calls — enough to make a run take dozens of
minutes and stall a live class. And the PRD requires (RF-09) that the project work in a
workspace where the AI functions are not available.

| | `03-silver-texto-ia` | This prompt |
|---|---|---|
| Time | dozens of minutes | seconds |
| Anonymization | understands the text; catches a name however it is written | catches what matches the pattern |
| Reason for the call | classifies by meaning | classifies by keyword |
| Reproducibility | varies between runs | **identical every time** |
| Cost | tokens | zero |

**It is not a downgrade on every count.** Determinism is a real advantage: the same input gives the
same output, always — which makes the result testable, and the class predictable.

## Two layers, in this order, and the order matters

1. **Anonymize** (RN-09) — the text loses name, CPF and phone number
2. **Enrich** (RF-05) — sentiment, reason, urgency and equipment come out of the text **already
   anonymized**

Inverting this would send identified personal data into the content analysis with
no need for it at all: the sentiment and the reason for the service call do not depend on the name
of whoever called.
The UC key already identifies the delivery point.

## 1. `silver.chamados_anonimizados` — regex in place of `ai_mask`

**This is what satisfies RN-09.** Without this table, any content analysis reads identified text.

Three patterns, applied in sequence over `transcricao`:

```sql
regexp_replace(
  regexp_replace(
    replace(transcricao, nome_solicitante, '[MASCARADO]'),
    '[0-9]{3}\\.[0-9]{3}\\.[0-9]{3}-[0-9]{2}',            -- formatted CPF
    '[MASCARADO]'),
  '\\([0-9]{2}\\)\\s*9?[0-9]{4}-?[0-9]{4}',               -- phone with area code
  '[MASCARADO]') AS transcricao_anonimizada
```

Why this order: **the name goes first**, using the `nome_solicitante` column of the record
itself — that is the information a regex alone would not catch, because a name has no format. The
other two have a fixed pattern and go afterwards.

**The UC key stays.** `UC0001147` identifies the delivery point, not the person — and the
analysis needs it to join with the registry.

Bring in from the registry: customer, district, neighborhood and class of the UC. Derive the date and
time of the service call.

Validate against the dataset: of the 2,801 transcripts, **all** of them carry the requester's name,
1,684 have a CPF and 1,819 have a phone number. After anonymization, a search for
`[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}` must return **zero**.

## 2. `silver.chamados_enriquecidos` — `CASE` in place of `ai_classify`

The same columns as the AI route, derived by rule:

| Column | How to derive it |
|---|---|
| `sentimento` | `negative` if the text matches dissatisfaction terms; `positive` with thanking terms; otherwise `neutral` |
| `motivo` | chained `CASE` — **order matters**, see below |
| `equipamento_citado` | `regexp_extract` with an alternation of the known equipment |
| `risco_a_saude` | risk term in the text: oxygen, dialysis, medication, child, hospital, spark, fire, elderly |
| `urgencia` | high if there is a health risk; medium for an outage, urgent reconnection, damaged pole; low for the rest |
| `ameacou_ouvidoria` | ombudsman, ANEEL, Procon or lawsuit |

**The order of the `CASE` is the business rule.** A text can match several patterns, and the
first one that matches wins. Put the most specific before the most generic:

```sql
CASE
  -- health risk comes BEFORE ordinary reconnection: it is the same sentence
  -- with a person at risk in the middle
  WHEN texto RLIKE '(?i)dialise|oxigenio|remedio na geladeira|crianca pequena'
    THEN 'religacao_urgente'
  WHEN texto RLIKE '(?i)escuro|sem energia|apagou|falta de energia|sem luz'
    THEN 'falta_energia'
  WHEN texto RLIKE '(?i)piscando|oscila|queimou|tensao'
    THEN 'oscilacao_tensao'
  WHEN texto RLIKE '(?i)releitura|estimativa|nao bate'
    THEN 'erro_leitura'
  WHEN texto RLIKE '(?i)conta veio|dobro|fatura subiu|trezentos reais'
    THEN 'fatura_alta'
  WHEN texto RLIKE '(?i)poste|galho|lampada da rua'
    THEN 'poste_avariado'
  WHEN texto RLIKE '(?i)religacao|religar|paguei'
    THEN 'religacao'
  ELSE 'duvida_cadastral'
END AS motivo
```

Use `(?i)` to ignore case, and **test without accents**: the transcripts were generated
without accentuation, so much of the speech has none.

Write `anonimizado_por = 'regras_de_texto'` and `enriquecido_por = 'regras_de_texto'` on every
row. Whoever queries the table needs to know what they are dealing with — and that is what lets you
compare the two routes later, if you run the AI version in parallel.

**The columns produced are the same on both routes.** What changes is the quality of the
extraction, not the schema — which is why gold, the dashboard and the agent do not need to know which route
you chose.

## 3. RN-10 — the other half of the protection

RN-09 protected the analysis. The read from the source is still unprotected, and **that does not change
with the route**: it depends on no AI at all.

Create a Unity Catalog **column mask**: a function that returns the original value to
members of the customer service group and `[RESTRITO]` to everyone else. Apply it to the columns
`nome_solicitante`, `telefone_solicitante` and `transcricao` of `bronze.chamados`.

Whoever is in customer service sees the customer's phone number — they need it to call back.
Everyone else does not.

**Watch out:** `bronze.chamados` is materialized by the pipeline, and a full refresh recreates the
table and drops the mask. Put this in a job task that runs **after** the pipeline, on
every run, and leave the limitation written down in a comment.

## 4. Where this route falls short — and what to do about it

Record **in a comment at the top of the file** that the extraction is by rule, not by
model, and what it does not catch:

- **Irony and negation.** *"Great, another day without power"* becomes `positive`.
- **A synonym outside the list.** *"it's all dark"* is caught; *"I was left in the pitch black"* is not.
- **Composite reason.** Someone who calls about an outage **and** a high bill gets a single label.
- **A name written differently from the column.** If the customer introduces themselves with a nickname, the
  name regex does not match — and the text goes through identified.

The last one is the most serious, because it is an LGPD risk, not a quality risk. Measure it: count how many
anonymized transcripts still contain the requester's first name and tell me the number.

## What not to do now

**Do not build the gold layer.** It is prompt 04 and it does not change between routes: it consumes
`chamados_enriquecidos` without knowing how the columns were filled.

## When you finish

1. Run the pipeline and show me the total execution time
2. One transcript before and after anonymization, side by side
3. The distribution of `motivo` and `sentimento`
4. The search for CPF and phone number in the anonymized table — it must return zero
5. How many transcripts still contain the requester's name
6. The result of querying `bronze.chamados` — the masked columns must show as
   `[RESTRITO]`, unless you are in the group

## Acceptance criteria

- No AI function call in this step
- The enrichment reads the anonymized text, never the original
- No CPF or phone number survives in `chamados_anonimizados`
- The columns of `chamados_enriquecidos` are the same as the AI route's — gold cannot tell the difference
- `anonimizado_por` and `enriquecido_por` equal `'regras_de_texto'` on every row
- The comment at the top of the file states the limitations of rule-based extraction
- The column mask is applied and works
- Two consecutive runs produce an identical result
