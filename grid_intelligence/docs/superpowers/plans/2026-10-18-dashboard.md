# AI/BI dashboard — plan

Specification: prompts/05-dashboard.md. Publish only to dev, using the
grid_intelligence profile, the existing warehouse and gold as the dataset context.

- [x] Create src/dashboards/grid_intelligence.lvdash.json with two pages:
  operations, with four time-based KPIs, a service calls/UC-hours series, DEC via
  MEASURE and current actions; inspection and customers, with a priority caveat,
  distribution by neighborhood and tables of evidence and anonymized last utterance.
- [x] Declare resources/grid_intelligence.dashboard.yml with dataset_catalog,
  dataset_schema and warehouse_id referenced from the bundle.
- [x] Run each SQL via CLI in the gold context and verify bindings and versions.
- [ ] Complete the final visual acceptance. Deploy and publishing to dev are done; open both pages in the browser,
  check the widgets and filters and save a real screenshot of page 1.

Time window anchored to the dataset. Inspection priority is a snapshot
of the latest load: flag the historical limitation in the fourth KPI. Do not recompute
DEC/FEC, do not access bronze/silver and do not broaden sharing permissions.

Initial deploy completed. Dual axis fixed in the editor and published, with the
equivalent configuration preserved in the local JSON. The final bundle
reconciliation requires explicit authorization for --force because of the remote etag.

The SQL verification passed, but the final session showed DEC blank intermittently.
Screenshot kept private; final visual acceptance remains pending.
