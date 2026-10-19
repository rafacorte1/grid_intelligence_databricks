# Privacy and publication review

Review date: **19 October 2026**. Scope: current repository content, local publication
candidates and the three reachable commits. Pattern-based inspection is useful
screening; it cannot prove that no secret or identifying data exists anywhere.

## Findings and handling

| Category | Finding | Handling |
| --- | --- | --- |
| Authentication secrets | No credential/private-key/token patterns identified in reviewed content/history | No rotation indicated by this review |
| Raw synthetic fixtures | Caller names, phone-like values, CPF-like values, addresses and coordinates exist locally | Ignore `landing/` and Parquet files; publish neither records nor original transcripts |
| Current configuration | Workspace host, personal email and deployment paths were hardcoded | Use explicit CLI profile, current-user substitutions and a local warehouse variable |
| Raw Genie evidence | API payloads contain user, conversation, query and workspace identifiers | Ignore raw reports; write future evidence under `.databricks/evidence/` by default |
| Screenshots | Workspace chrome, identity and operational metadata were visible; final visual acceptance is pending | Withhold existing screenshot from the public commit and LinkedIn assets |
| Historical metadata | Older commits contain personal email, workspace host and user paths | Documented residual exposure; history was not rewritten |

Workspace URLs and resource IDs are not credentials and do not themselves grant
access. They still reveal unnecessary infrastructure/identity details, so the
public documentation avoids them. Git commit author metadata may also identify
the repository owner; choose a GitHub no-reply address for future commits if desired.

Removing a value from the latest tree does **not** erase older commits, caches,
clones or already shared content. No credential was identified that would justify
claiming rotation or a history rewrite was performed. If historical identity or
workspace metadata must also be removed, agree on a separate history-cleanup plan
before rewriting shared branches. If a real credential is ever discovered,
revoke/rotate it first; deleting it from Git is insufficient.

## Material safe to share publicly

Use the architecture diagram, aggregate synthetic dataset counts and engineering tradeoffs.
State that the company and dataset are fictional and that the deployment is a development
demonstration.

Do not include raw transcripts, input Parquet, terminal authentication output,
workspace/profile configuration, private execution links, conversation payloads,
customer-level exports, account menus, user emails or unreviewed screenshots.
Even synthetic identifier-like data is unnecessary for the technical story.

## Recheck before publishing

Review the staged file list and diff, verify ignore rules, inspect any new image
at full size, and repeat credential-pattern screening on the staged content.
`.gitignore` prevents accidental additions; it does not remove files already in Git.
Operational evidence and local configuration should stay in ignored directories.
