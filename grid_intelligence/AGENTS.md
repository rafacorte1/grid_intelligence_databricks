# Agent instructions

This project is a governed Databricks lakehouse built from a fixed specification. The
specification lives in [`prompts/`](prompts/) and the domain rules in [`.llm/prd.md`](.llm/prd.md).
Read both before changing anything: the prompts define scope per step, and the business rules
(RN-01 to RN-14) are not suggestions.

The human owner wrote the prompts, the rules and the acceptance criteria, and runs the
validation. An agent implements. That split is documented in the
[repository README](../README.md#how-this-was-built-ai-assisted-human-validated).

## Before you start

Read the `databricks-core` skill if it is available; it covers CLI authentication, profile
selection, data discovery and the bundle workflow. Install Databricks AI Tools with
`databricks aitools install` if the skill is missing. CLI install:
https://docs.databricks.com/dev-tools/cli/install

## Non-negotiable conventions

- Identifiers stay in Brazilian Portuguese, without accents: tables (`consumo_diario`,
  `interrupcoes`, `unidades_consumidoras`), columns (`qtd_ucs_afetadas`, `nome_conjunto`) and
  files (`20_gold_continuidade.sql`). Prose, comments and documentation are in English.
- DEC and FEC exist in exactly one place: the `continuidade_metricas` metric view. Never
  compute them by hand in another query.
- Bronze does not filter, correct or apply business rules; invalid readings are evidence about
  the meter. The 3-minute threshold (RN-01) belongs in Silver.
- Personal data is masked before content analysis, and the identified original keeps
  restricted access. Both protections coexist.
- Inspection priority is technical triage. Never use fraud, theft or blame as an output label
  in a column, variable, comment or answer, even when the question is phrased that way.
- The copilot reads only the four curated Gold sources.
- Relative windows anchor on the latest dataset date, never on `current_timestamp()` or
  `current_date()`.

## Verify before you claim a step is done

```bash
cd grid_intelligence
export BUNDLE_VAR_warehouse_id='<YOUR_SQL_WAREHOUSE_ID>'
databricks bundle validate --strict -t dev --profile grid_intelligence
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tests/verificar_dashboard.py --profile grid_intelligence \
  --catalog grid_dev --schema gold --warehouse "$BUNDLE_VAR_warehouse_id"
```

The SQL acceptance files in `tests/` run on the warehouse, statement by statement. A step is
done when its acceptance criteria pass against the real workspace, not when the code looks
right. If something fails, record it in `docs/validation.md` instead of hiding it.
