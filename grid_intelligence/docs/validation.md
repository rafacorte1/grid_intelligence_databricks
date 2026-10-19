# Development validation

Assessment date: **19 October 2026**. This was a targeted health check of the
existing development deployment, not a new production deployment or full reload.

| Check | Evidence | Result |
| --- | --- | --- |
| Latest recorded Lakeflow Job | Existing run history | SUCCESS |
| Silver/Gold and governance acceptance | 16 SQL assertions executed again | 16 passed |
| Dashboard datasets and widget/filter projections | Live SQL warehouse execution | 27 passed |
| Genie example SQL | Executed before applying the current definition | 4 passed |
| Conversation API acceptance | Five business questions plus one adversarial question; Campinas retested after a coverage fix | 6 completed |
| Local deployment-script tests | Catalog rendering, space reuse, ambiguous titles, CLI argument handling and profile-based host resolution | 5 passed |
| Public configuration | Strict bundle validation | Passed |

## What the evidence shows

The numerical transformations preserve 5,803,274 valid, unique UC/day records
from 5,854,587 inputs. Continuity includes 1,073 eligible interruption events;
2,801 service calls remain available after deterministic text enrichment.
The Gold monthly grid covers six districts and 48 months, including zero-event
periods so the UC denominator is retained.

The conversational tests used only the four attached Gold sources. The continuity
question called `MEASURE()` and `GROUP BY ALL`. Campinas analysis combined daily
outages, calls and measured consumption with the governed monthly DEC/FEC values.
The final retest identified partial reading coverage rather than asserting that
every UC had a reading. The adversarial question was answered with a refusal to
attribute misconduct and an explanation of the evidence limits.

See [the public Genie evaluation summary](genie-evaluation.md). Full API payloads
and operational links remain in ignored local evidence, not in this repository.

## Known limits

- The most recent complete job run was inspected; it was not rerun during this
  quick assessment. This does not prove future scheduling, load or availability.
- The dashboard was created and published in dev. Its SQL and structural checks
  pass, but the last browser session intermittently left the DEC chart blank.
  A complete final visual acceptance and a clean screenshot are still pending.
  No screenshot is published as proof of full visual acceptance.
- The dashboard axis correction was published through the native editor and is
  represented in local JSON. A subsequent bundle deploy detects a changed remote
  version. Reconciliation requires a reviewed, explicitly authorized forced deploy;
  no safety check was bypassed.
- Regex masking removed the tested formatted CPF/phone patterns. It does not
  guarantee removal of every name, alias or identifier and is not a privacy certification.
- Governance was tested under the authorized identity. A separate non-member
  identity still needs an end-to-end access test.
- Inspection priority is a latest-load snapshot, without historical daily scores.
- Customer health aggregates historical calls; it is not a same-day customer count.
- Six conversational questions are smoke/acceptance coverage, not an accuracy
  benchmark. Natural language summaries remain probabilistic and require review.
- The adversarial answer refused accusation but offered to list inspection
  priorities rather than returning a technical list immediately.
- Production is configured as a target but was not deployed or validated here.
- Raw fixture generation/distribution, CI automation, a larger evaluation suite
  and operational monitoring remain future improvements.

The implementation is a working **development demonstration with documented
limitations**. It should not be marketed as production-ready, real-time,
fully anonymized, loss prevention software or an autonomous decision maker.
