@AGENTS.md

## Generalization rule for plugins and skills

When authoring or editing any content under `plugins/` — `SKILL.md`, reference files, command files, agent prompts, hooks, scripts, or assets — **never include specifics from the source material that produced the lesson**. The repo is published to other operators; their context will not match yours.

Strip or generalize:

- **Workspace, team, customer, or company names** (e.g., real team short codes, workspace slugs, org names). Use placeholder tokens like `TEAM`, `ACME`, `<workspace>`, `<team>`, `<TEAM>-<N>` instead.
- **Real project, product, feature, or codename references** (e.g., internal project names, product codenames, branded initiatives). Either drop them or replace with a generic phrasing ("a multi-phase plan", "the project").
- **Specific issue/ticket/PR identifiers and URLs** (e.g., `TRX-5`, `LIN-1234`, `https://linear.app/acme/issue/…`). Replace with shape-only examples (`<TEAM>-<N>`, `https://linear.app/<workspace>/issue/<TEAM>-<N>`).
- **UUIDs, API keys, account IDs, session IDs, file paths under a real user home, internal hostnames**. Use `<uuid>`, `/Users/<user>/...`, `<session>`, etc.
- **Exact counts that only happened once** (e.g., "the import created 56 issues across 7 phases"). Generalize to shape ("a typical multi-phase plan produces a project plus a few dozen task sub-issues") unless the exact count itself is the lesson.
- **Label names, status names, or workflow values from a specific team** that aren't part of the platform's defaults. Either name the platform default or describe the shape ("a label scoped to the import").

Keep:

- Platform-default vocabulary (e.g., Linear's default workflow states `Backlog`, `Todo`, `In Progress`, `In Review`, `Done`, `Canceled`, `Duplicate` — these come from Linear, not the source import).
- Tool names, parameter names, and exact error strings — these are the platform's, not the operator's.
- Generic example identifiers using placeholder tokens (`TEAM-5`, `ACME-6`).

The test before saving: would a reader at a different company learn the same lesson from this content, or would they have to mentally substitute every example? If the latter, generalize.
