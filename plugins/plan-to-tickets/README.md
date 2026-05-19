# Plan to Tickets Plugin

A skill that converts a written implementation plan into a hierarchy of tickets in a task tracker (ClickUp, Linear, Jira, Asana, Notion, GitHub Projects) with dependencies wired. It captures the durable process lessons that aren't obvious the first time you do this work at scale, plus the platform-specific quirks that bite if you don't know about them.

## Why This Exists

Turning a planning document into a ticket hierarchy looks mechanical — read structured input, create things, wire relationships — but two failure modes are common and expensive enough to justify a dedicated skill.

The first is **wrong hierarchy depth**. A 3-level hierarchy (Phase → Task → Steps) with 5 step-subtasks per task can balloon a 130-task plan into 770 tickets. Most of those step subtasks carry no information beyond their parent's description; they're just process boilerplate (TDD red / green / refactor / verify) that clutters the tracker view without adding tracking value. The decision of whether to use 2-level (with steps as a markdown checklist inside the task description) or 3-level (with steps as real subtasks) should be negotiated *before* the first ticket is created — discovering the mismatch at ticket 47 means deleting work and starting over.

The second is **no ID map**. Trackers return their own opaque IDs (`86ahjxrh2`, `LIN-1234`, etc.) when you create a ticket. To wire dependencies later, you need those IDs alongside the plan IDs they correspond to. If they aren't captured as creates happen, dependency wiring requires a second lookup pass — slow, error-prone, and especially painful when partial progress needs to be resumed after an interrupted session.

The skill exists to make sure those two traps don't catch you, and to surface the smaller gotchas that compound when you're moving fast: status-string format mismatches that fail entire create calls, markdown-field-name differences across trackers, dependency-direction conventions, parallel-batch ceilings.

## What It Does

When the operator says something like "import this plan into ClickUp" or "break this design doc into tickets," the skill runs a structured 7-step workflow:

1. **Capture intent** — confirm the source doc, target tracker, target container (list/project/board), and any items already done. If no tracker was named, list the ones with working MCP integrations and let the operator choose. If none are wired up, offer a markdown-file fallback (covered below).
2. **Readiness check** — assess whether the plan is actually structured enough to ticket. The skill defines required signals (discrete task units, task identifiers, hierarchical grouping), strongly-recommended signals (per-task context, acceptance criteria, dependencies), and nice-to-haves. If the required signals aren't there, the skill stops and tells the operator specifically what's missing, with quotes from the source doc — refusing to import a half-baked plan is part of the contract, not a failure mode.
3. **Four clarifying questions** — hierarchy depth, handling of already-done items, dependencies (native or description-only), and tags. Asked together in a single `AskUserQuestion` because the answers are coupled (a 2-level hierarchy makes phase tags redundant, etc.).
4. **Build estimation** — multiply task count by hierarchy multiplier, estimate elapsed time, surface the number to the operator before starting. A 770-ticket build deserves a heads-up.
5. **ID mapping** — set up `.plan-import/ids.csv` as the source of truth for `plan_id → tracker_id`. Per-ticket appends, never batched. The CSV doubles as the resume point if the session is interrupted.
6. **Top-down creation** — root → phase parents → task children, with the structured metadata and source-doc sections faithfully mirrored into each ticket's markdown description. Dependencies are deliberately deferred.
7. **Dependency wiring** — translated through the ID map in a single pass, fired in parallel batches of 15–20 per turn. `awk` for exact-match resolution (so `P1.T1` doesn't match `P1.T10`). Failed edges captured for a retry pass.
8. **Verify** — spot-read 2–3 tickets in the tracker UI, count totals, report back.

The skill explicitly handles failure modes that bite during real runs: mid-build create failures (log and skip, don't retry inline), session resume (read ids.csv, skip already-mapped IDs), operator-changes-hierarchy-mid-build (stop and ask, give them the convert-in-place vs. delete-and-restart choice).

## Platform Coverage

The workflow generalizes across trackers, but the specifics differ enough to warrant per-tracker reference files. The skill uses progressive disclosure: `SKILL.md` covers the generic workflow; `references/<tracker>.md` covers the platform-specific gotchas the agent needs to consult before working against that tracker.

- **ClickUp** — fully documented. Covers the MCP tool names, the `markdown_description` vs. `description` field difference (the plain field renders as literal text — a common first-time mistake), the exact status strings that work (`complete`, `in progress` with the space, not `completed` / `in_progress`), the `clickup_get_list` validation quirk that errors even when the list exists, dependency direction (`waiting_on` from child to parent), the 15–20 parallel-batch ceiling validated against a 272-edge run, and the rule that tags must be pre-created at the space level.
- **Linear, Jira, Asana, Notion, GitHub Projects** — stubs with a checklist of what to capture on the first real job against that tracker. Each stub names the things that are likely to be different (Jira's transitions-vs-status-field distinction, GitHub Projects' lack of native dependencies, Notion's block-children API for descriptions). The stubs prevent cold use from hitting a missing-file error and give the first-time user a structured place to write down what they learn.

## Markdown File Fallback

When no tracker MCP is connected — or when the operator just prefers version-controlled progress — the skill produces a directory of markdown files that act as the ticket system. The structure mirrors what a tracker would give you: a root `README.md` with one checkbox per phase that links to a per-phase markdown file, and each phase file holding the full task specs with their own `[ ] Task complete` checkboxes plus an inline `### Steps` checklist.

This isn't a worse-tracker imitation. It's a coordination model that works for cases where the tracker would be overhead: small projects in-repo, parallel agents working off the same plan, no requirement for cross-team visibility. Git becomes the audit trail — every checkbox flip is a commit, every status change is a diff. Agents pick up tasks by reading the root file, finding the first unchecked phase, opening the phase file, finding the first task whose `Blocked by:` dependencies are all checked, flipping the first Step to claim, working through Steps, then flipping the Task-complete box. Same coordination protocol as a real tracker's dependency view, expressed in plain text.

The reference documents when to recommend it (in-repo coordination, small projects, parallel agents) and when not to (cross-team visibility, >150 tasks, critical-path views), so the skill doesn't push the fallback when a real tracker would serve the operator better.

## Triggering Phrases

The skill triggers on natural variations of "import this plan into [tracker]" — explicitly including the named trackers (ClickUp / Linear / Jira / Asana) in the description so a literal mention reliably activates it, but also covering phrasings like "break this plan into tickets," "create tickets for this plan," "turn this doc into tasks," and "set up the project in [tracker]." It also triggers when the operator references both a planning document and a tracker URL in the same request — that combination is usually unambiguous about what's wanted.

## What This Plugin Won't Do

It won't try to import an unstructured document. The readiness check is deliberately strict: if the plan reads more like a brief, vision statement, or meeting transcript than an implementation plan, the skill stops and explains what's missing rather than guessing at task boundaries. The remedy is to spec the plan out further — possibly using a separate plan-writing skill if available — and come back.

It won't silently downscope. If the operator approves a 770-ticket build and the skill realizes partway through that the approach is too heavy, it stops and asks rather than quietly switching to a smaller structure. Surprises are worse than slowdowns.

It won't decide deletion unilaterally. Cleanup operations always require explicit confirmation, even when the MCP tool wouldn't enforce it. Trackers don't always make deletion reversible.

## License

MIT (see repository LICENSE).
