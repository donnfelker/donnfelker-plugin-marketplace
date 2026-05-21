# Durable Spec Development Plugin

Two skills that together take a written specification all the way from "plan on paper" to "every subtask shipped as a merged PR."

The pair is designed for the case where a single planning document or audit produces many actionable subtasks and the work needs to outlast a single attention span — formal tracking, stacked PRs, multi-round review response.

## Skills

### `plan-to-tickets`

Imports a structured planning document (implementation plan, design doc with tasks, audit report) into a task tracker — ClickUp, Linear, Jira, Asana, Notion, GitHub Projects, or a markdown-file fallback when no tracker is connected. Includes a readiness check that refuses to import a half-baked plan, plus an ID-mapping pass that makes dependency wiring reliable even when the build is interrupted and resumed.

See [`skills/plan-to-tickets/SKILL.md`](skills/plan-to-tickets/SKILL.md) for the workflow and [`skills/plan-to-tickets/references/`](skills/plan-to-tickets/references/) for per-tracker gotchas.

### `implement-full-spec`

Turns a parent ticket with N actionable subtasks into a clean stack of N pull requests, then drives that stack to merge-ready by addressing every bot and human review comment, re-requesting review each round until reviewers are satisfied. Three phases:

- **Phase A — Plan**: read the parent, filter actionable subtasks, design stack order, pin execution parameters.
- **Phase B — Execute**: per subtask, worktree → Dev → QA → Reviewer → commit → push → `gh pr create` with the right base → mark complete.
- **Phase C — Respond to feedback**: sweep every PR for all three comment sources (inline threads, top-level review bodies, general comments), classify, fix, commit, push, reply with `Addressed in <SHA>`, cascade-rebase downstream PRs, then ping the reviewing bot for re-review. Multi-round until quiet.

See [`skills/implement-full-spec/SKILL.md`](skills/implement-full-spec/SKILL.md) for the top-level workflow and the four reference files under [`skills/implement-full-spec/references/`](skills/implement-full-spec/references/) for the per-phase mechanics and cross-cutting gotchas.

## How They Compose

`plan-to-tickets` is the front of the pipeline — turn the spec into trackable work. `implement-full-spec` is the back of the pipeline — turn the trackable work into merged code. Either can be used standalone, but the natural sequence is:

1. Write the plan (or receive the audit / RFC / multi-finding report).
2. Run `plan-to-tickets` to land it in the tracker as a phase/task hierarchy with dependencies wired.
3. Run `implement-full-spec` against that parent ticket to ship every subtask as its own stacked PR and drive each PR to merge-ready.

The two skills share a worldview: surprises at scale are worse than slowdowns, the structure of the plan should survive an interrupted session, and the orchestration should not silently downscope when the work gets noisy.

## License

MIT (see repository LICENSE).
