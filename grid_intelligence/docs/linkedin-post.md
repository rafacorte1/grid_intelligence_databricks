# LinkedIn draft — international audience

## Suggested post

How do you turn utility data into operational decisions without creating another
source of inconsistent metrics?

I built **Grid Intelligence**, a Databricks portfolio project for a fictional
electric utility. It connects power interruptions, electricity consumption and
customer service calls through a governed Bronze → Silver → Gold lakehouse.

The synthetic dataset includes **5.85 million consumption records, 4,000 delivery
points and 2,801 service calls**. The engineering work goes beyond moving data:

• SQL pipelines validate readings, remove duplicates and retain source evidence.
• One governed metric view defines continuity KPIs for both BI and conversational analytics.
• Original transcripts are access-controlled; masked text supports downstream analysis.
• Inspection priorities combine individual consumption changes with neighborhood
stability, with an explicit distinction between technical triage and accusation.
• A Portuguese Genie copilot uses four curated Gold sources and is tested through
the Conversation API, including an adversarial question.

One useful lesson: correct SQL does not guarantee a correct narrative. During
evaluation, I added reading-coverage context after the copilot overgeneralized
partial readings into full coverage.

The current development checks include **16 data/governance assertions and 27
dashboard SQL checks**. The repository documents the implementation, evaluation
results and remaining limitations, including final dashboard visual acceptance.

This is a synthetic-data development demonstration—not a production deployment
or a claim of financial savings. It reflects the kind of work I want to contribute
to internationally: reliable data platforms, governed analytics and AI systems
that make their evidence and limitations visible.

Code and architecture:
https://github.com/rafacorte1/grid_intelligence_databricks

I'd be glad to connect with data engineering and analytics engineering teams
working on similar challenges.

#DataEngineering #Databricks #AnalyticsEngineering #DataGovernance #Portfolio

## Suggested attachment

Use the architecture diagram from the README or a short architecture walkthrough.
Do not use the current private dashboard screenshot. Before adding a new screenshot,
finish visual acceptance, capture only the relevant canvas and inspect it for
identity, infrastructure details and record-level data.

## 60–90 second walkthrough

1. Explain the operational question and explicitly identify the synthetic dataset.
2. Show the lakehouse layers and why numerical and text rules live in Silver.
3. Explain why dashboard and copilot share a single metric definition.
4. Show an aggregate inspection result and the no-accusation boundary.
5. Describe the API evaluation and one concrete issue it uncovered.
6. End with the public repository and the limitations/next steps.

Publish only after reviewing the final GitHub diff and any chosen visual asset.
This file is a draft; it is not an instruction to post automatically.
