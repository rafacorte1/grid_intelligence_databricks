# The prompt sequence

Each file in this folder is a **prompt ready to paste into Claude Code**. Together they
build Grid Intelligence from scratch — from an empty catalog to the copilot answering
board-level questions.

| # | File | Deliverable | Visible result |
|---|---|---|---|
| 00 | [`00-setup.md`](00-setup.md) | Context, business rules, schemas and volume | A catalog with the four layers and the data in the volume |
| 01 | [`01-bronze.md`](01-bronze.md) | Faithful ingestion | Four bronze tables and the quality dashboard flagging the defects |
| 02 | [`02-silver-numeros.md`](02-silver-numeros.md) | Registry, RN-01, dedup and baseline | How many interruptions the 3-minute rule discarded |
| 03 | [`03-silver-texto-regex.md`](03-silver-texto-regex.md) | Anonymization and enrichment with regex and `CASE` | The masked columns, in seconds |
| 04 | [`04-gold.md`](04-gold.md) | The four deliverables and the metric view | DEC and FEC by district, coming out of a single definition |
| 05 | [`05-dashboard.md`](05-dashboard.md) | AI/BI dashboard | A two-page dashboard |
| 06 | [`06-agente.md`](06-agente.md) | Conversational copilot | The agent answering about Campinas |

Two prompts from the original design are not published here: an AI-based variant of step 03
(described below) and a final executive-report step.

## Who wrote what

These files are the specification, not the implementation. An AI agent (Claude Code) wrote
the SQL, the bundle resources, the dashboard JSON and the Genie definition by executing these
prompts one at a time. I wrote the prompts, the business rules, the acceptance criteria, and
ran the acceptance SQL against the workspace after each step; anything that failed was
corrected before the next prompt started. The visible result of that review is in
[`docs/validation.md`](../docs/validation.md).

## Step 03 has two routes — this repository ships the regex one

**It is the only point in the sequence where AI can enter the data pipeline**, and it is where
it gets expensive: each AI function is one inference per row, and with 2,801 service calls
and four functions in the chain that is ~11,000 model calls. Execution can take tens of
minutes — enough to stall a live class.

| | With AI | With regex (published) |
|---|---|---|
| Time | tens of minutes | seconds |
| Extraction quality | understands the text | catches whatever matches the pattern |
| Reproducibility | varies between runs | identical every time |

Both produce **the same columns** and satisfy RN-09 and RN-10. That is why prompt 04
onward — gold, dashboard and agent — works the same way, without knowing which route you
took.

## How to use it

1. Open Claude Code in the repository
2. Paste the whole prompt, from start to finish
3. Let it work, review, deploy and **look at the result**
4. Only then move on to the next one

Do not skip the order. Each prompt assumes the previous one is done and says explicitly
what must **not** be done yet — that is what keeps the agent from trying to build the whole
project at once and delivering everything half-finished.

## Why a prompt and not an issue

Each of these files carries three things a regular ticket does not:

- **the business rule next to the request** — the agent does not have to guess why the
  threshold is 3 minutes
- **the known traps** — baseline over a series with trend, append-only streaming table,
  `execCommand` outside the user gesture
- **the acceptance criteria** — what has to be true for the step to be done

## Reusing it on another project

The sequence is the template: **setup → ingestion → cleaning → enrichment → business →
visualization → agent → proof**. Changing the domain means rewriting prompt 00 entirely and
adjusting the table names in the others. The structure, the technical traps and the
acceptance-criteria format still hold.
