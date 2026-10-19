# Silver and gold — implementation plan

Goal: run prompts 02, 03 via regex and 04 against the existing bronze layer.
Architecture: a serverless pipeline with parameterized SQL, followed by SQL governance
tasks and creation of the metric view in a STANDARD job.

- [x] Create 10_silver_cadastro.sql, 11_silver_interrupcoes.sql and
  12_silver_consumo.sql. Verify 1,073 events, valid consumption with no duplicates
  and 30/90-day windows anchored to the largest day in the data.
- [x] Create 13_silver_chamados.sql with anonymization before enrichment.
  Verify 2,801 rows, remaining CPF/phone numbers and names, distributions
  and identical results across two runs.
- [x] Create the four gold files, 20 through 23. Check the 1,073 events,
  the two priority axes and the customer grain of service health.
- [x] Create src/sql/governanca_dado_pessoal.sql and metric_view_continuidade.sql,
  configure the warehouse and job in the bundle and run end to end.
  Files and resources published. The full job finished successfully after
  repairing the function DDL. Atendimento group provisioned, three masks applied,
  a new refresh preserved the text and the masks. 16 checks passed.
- [x] Query MEASURE for the last month and for several months, priorities by neighborhood,
  high-risk customers and dashboard actions. Record results and limitations.

The prompts are the detailed specification. Do not change bronze, do not use AI,
do not publish to prod and do not create expectations. The Atendimento group must include
the execution identity so the mask does not hide the anonymizer's text.
