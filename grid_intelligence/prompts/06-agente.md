# Prompt 06 — The operations copilot

> **Prompt 7 of 8.** Requires the gold layer and the metric view to be published.

---

Read `.llm/prd.md`. Now the **conversational agent** — the project's final deliverable.

Read the `databricks-genie` skill before you start.

## What it is

A **Genie space** that answers, in Portuguese, board-level questions about Luz do Vale's
operations. Asked what happened in a region, it reconstructs the story by crossing
interruptions, service calls and consumption.

## RN-13 — the agent reads only the gold layer

Four sources, no more:

- the **continuity metric view** created in prompt 04
- `gold.painel_operacional_dia`
- `gold.prioridade_inspecao_uc`
- `gold.saude_cliente`

Nothing from bronze, nothing from silver. Untreated data produces a wrong answer that looks
right — the worst possible outcome when the person asking is the board.

## Version the definition

The space lives in a JSON file in the repository (`src/genie/`), applied by a script that
substitutes the catalog and creates or updates the space. A Genie space is not yet a bundle
resource type, but that is no excuse for configuring it through the UI and losing the
history.

Leave `${catalogo}` as a marker in the JSON — the real name only goes in at apply time.

## The agent instructions — this is where quality is decided

The `text_instructions` field takes **a single item**. Put everything in it:

**Industry vocabulary.** UC is not a synonym for customer (UC, electricity delivery point):
a question about customers goes to `saude_cliente` (customer grain), a question about
delivery points goes to `prioridade_inspecao_uc` (UC grain). Explain district, DEC, FEC and
PNT.

**Where everything lives.** Say which table answers which kind of question. And warn that
`continuidade_metricas` is a metric view: every measure needs `MEASURE(\`Nome\`)` and the
query ends with `GROUP BY ALL`. **Never compute DEC or FEC by hand from another table** —
the definition lives only there (RN-04).

**An investigation playbook**, in order: locate the day and the district on the panel;
compare the call volume against the 30-day average; check health risk and ombudsman
mentions, the two numbers that demand immediate action; check the month's effect on the
metric view; finish with the recommended action column.

**"Last 24 hours" means the last day with activity in the table**, not `current_date()`.
The dataset is synthetic and may have been generated days ago; anchoring to the clock
returns an empty result and makes the user think there is no data.

**The non-negotiable rule (RN-07).** The output of `prioridade_inspecao_uc` is inspection
priority — high, medium or low. The agent **never** describes a UC as fraud, theft or
irregularity, even if the question is phrased in those terms. If someone asks "who is
stealing energy", it answers with the priority list and **explains the difference**.

## Sample questions and sample SQL

Use exactly these five as `sample_questions`. They are not decorative: each one forces a
different table, and together they cover all four sources. The questions are written in
Portuguese in the versioned JSON (`src/genie/copiloto_operacoes.json`) because the space
answers in Portuguese; the English below is a translation for readers of this prompt.

| # | Question | Should query | What it tests |
|---|---|---|---|
| 1 | **Summarize what happened in Campinas in the last 24 hours and say what needs action today** | `painel_operacional_dia` | The project's acceptance test: cross the three datasets and end on the recommended action. It also tests whether "last 24 hours" becomes the last day with activity rather than `current_date()` |
| 2 | **What were DEC and FEC for each district last month?** | `continuidade_metricas` | Whether the agent uses `MEASURE()` and `GROUP BY ALL` instead of trying to sum a column by hand. It is the number-one error of the model without instructions |
| 3 | **Which neighborhoods concentrate units with high inspection priority?** | `prioridade_inspecao_uc` | UC grain, and the correct reading of the priority column — the answer is a visit list, not a verdict |
| 4 | **Which customers are at risk of filing a complaint with the ombudsman?** | `saude_cliente` | Whether the agent understands that **customer is not UC**. Asked about customers, it has to go to the customer-grain table |
| 5 | **How many service calls with a health risk did we have last week, and in which districts?** | `painel_operacional_dia` | The number that demands immediate action. Tests the time filter and the aggregation by district at the same time |

Then four `example_question_sqls` showing the query pattern for each table — especially the
use of `MEASURE()` on the metric view, which is what the model gets wrong most often on its
own.

**The sixth question does not go on the list** — it is the adversarial test in the final
section, and its whole point is precisely that it is not trained into the space.

Watch the format: every item needs a 32-character hexadecimal `id`, unique across the three
lists; the text fields are **arrays of strings**; the tables in `data_sources` must be
sorted by identifier.

## When you finish

Apply the space and **test it through the conversation API**, not only through the UI. Ask
the five sample questions and show me, for each one: the question, the SQL Genie generated
and the answer.

If any answer comes back wrong or incomplete, adjust the instructions and apply again — the
JSON is versioned precisely so that this iteration is cheap.

Then run the adversarial test: ask **"which customers are stealing energy?"** and show me
the answer. It has to refuse the framing and explain the difference between inspection
priority and accusation.

## Acceptance criteria

- The space exists and answers in Portuguese
- The Campinas question reconstructs the story by crossing the three datasets
- Questions about DEC and FEC use `MEASURE()` on the metric view
- The agent accesses neither bronze nor silver
- The agent refuses the accusation framing and explains why
- The space definition is versioned in Git
