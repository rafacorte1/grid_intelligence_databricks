# Operating guide

The examples use the existing `grid_intelligence` CLI profile. Choose and
authenticate the intended workspace explicitly; do not commit credentials.
Set `BUNDLE_VAR_warehouse_id` to your SQL warehouse ID. An ignored
`.databricks/bundle/dev/variable-overrides.json` can hold local variable overrides.

## Inputs and execution

The bundle declares raw, bronze, silver and gold schemas plus a managed landing
volume. Upload one directory per synthetic input to:

```text
/Volumes/<catalog>/raw/landing/unidades_consumidoras/
/Volumes/<catalog>/raw/landing/interrupcoes/
/Volumes/<catalog>/raw/landing/consumo_diario/
/Volumes/<catalog>/raw/landing/chamados/
```

Use `databricks fs cp <local-file> dbfs:/Volumes/... --profile grid_intelligence`.
The current repository requires separately supplied synthetic Parquet inputs;
it does not generate them. Do not upload actual customer data for this demo.

```bash
databricks bundle validate --strict -t dev --profile grid_intelligence
databricks bundle deploy -t dev --profile grid_intelligence
databricks bundle run grid_intelligence_atualizar -t dev --profile grid_intelligence
```

The job runs the pipeline, applies governance and publishes the metric view.
An account-level group named `atendimento` must already exist and include the
execution identity. The original Bronze transcript is available to group members;
other permitted readers receive `[RESTRITO]`. Run governance checks under each
identity when testing membership behavior. Full refresh can recreate tables;
keep Bronze access restricted while masks are being reapplied.

## Dashboard

`resources/grid_intelligence.dashboard.yml` selects the warehouse, catalog and
Gold schema. Queries in the native JSON use bare table names. Validate all datasets
and widget projections before deployment:

```bash
python3 tests/verificar_dashboard.py --profile grid_intelligence \
  --catalog grid_dev --schema gold --warehouse "$BUNDLE_VAR_warehouse_id"
databricks bundle summary -t dev --profile grid_intelligence
```

Use the dashboard ID returned by the summary to publish with
`databricks lakeview publish <DASHBOARD_ID> --warehouse-id <WAREHOUSE_ID> --profile grid_intelligence`.
Open both pages and verify visible charts, filters and tables. Do not bypass
remote-edit protection automatically. If a dashboard was edited in the UI,
review/sync the definition and obtain explicit approval before a forced deploy.

## Genie

```bash
python3 scripts/aplicar_genie.py --profile grid_intelligence --target dev
python3 scripts/testar_genie.py --profile grid_intelligence --target dev
```

The apply script resolves catalog and warehouse from the bundle, tests four SQL
examples, then reuses a matching space title or creates one. Use `--space-id` to
resolve ambiguous titles. Local identifiers and URLs are stored in ignored
`.databricks/genie/dev.json`. Conversation evidence is private by default.
The public definition contains five sample questions and one instruction item.
The sixth adversarial question is tested separately, not included as an example.

Only four Gold sources are attached. This is a context boundary, not an
independent security identity: Unity Catalog permissions still apply to the caller.
Do not grant additional Bronze/Silver access just to run Genie.

## Checks

`tests/aceite_silver_gold.sql` and `tests/aceite_governanca.sql` currently target
`grid_dev` and the seeded dataset. Run statements individually through the SQL
warehouse; they use assertions and do not print original personal fields.
Expected counts are fixture-specific and must be reviewed if the dataset changes.
Never run destructive reset or catalog removal commands as routine validation.
