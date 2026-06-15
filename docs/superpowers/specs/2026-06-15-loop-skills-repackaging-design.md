# Design: Repackage the loop skills into the `loop-skills` marketplace

**Date:** 2026-06-15
**Status:** Approved design — pending implementation plan
**Author:** Operator + Claude (brainstorming session)

## Summary

Re-home the seven autonomous-loop skills currently scattered across three plugins in
`donnfelker-plugin-marketplace` into a **new `donnfelker/loop-skills` marketplace** organized as
**five logical plugins**. Grouping is driven by *actual code coupling and standalone-usage patterns*,
not by theme and not by a single flat bundle. `address-pr-comments` is retired and folded into
`pr-autopilot`. The three source plugins are removed from `donnfelker-plugin-marketplace` (a clean
break — the operator is the only user, so no migration shims are needed).

This design replaces the earlier "flat one-plugin marketplace" plan, which an adversarial review
showed would drop three boundaries (per-run state isolation, a version/contract boundary for the
coupled spec workflow, and blast-radius control) without replacing them.

## Background & rationale

An adversarial Codex review of the original flat plan returned `needs-attention` with three findings:

1. **Shared mutable state collisions** across autonomous loops sharing one `.loop-skills/state.json`
   with no per-run namespace or ownership.
2. **Dissolving the bundle removes a version boundary** while the cross-skill contracts
   (`implement-full-spec` → `dev-team` → PR review-response) stay implicit.
3. **One-install flat marketplace expands blast radius** for breaking removals.

The operator accepted findings 1–2 as real and discounted finding 3 (sole user, no migration
concern). The response is to **package by logical domain** instead of flat, and to make the one
remaining cross-plugin contract **explicit** (a dependency preflight) rather than implicit.

Key facts established by reading the source skills:

- `implement-full-spec` is the hub. It hard-depends on `dev-team` (per-subtask engine, referenced
  throughout its phase files), on the PR review-response skill (Phase C), and on
  `pr-review-mechanics.md`.
- `pr-autopilot` is coupled into the spec workflow (Phase C review-response) **and** is a
  general-purpose standalone PR utility — the same dual-use shape as `dev-team`.
- `pr-review-mechanics.md` is shared by `implement-full-spec`, `pr-autopilot`, and the
  (retired) `address-pr-comments`.
- `triangulated-code-review` and `multi-llm-convergence` are fully decoupled — from the spec
  workflow and from each other. `multi-llm-convergence` only name-drops `pr-autopilot` to
  disambiguate itself ("I am *not* that").
- `address-pr-comments` and `pr-autopilot` are explicit counterparts: single interactive pass with a
  human approval gate vs. autonomous loop until quiet. Same mechanics file.

## Decisions

| # | Decision |
|---|----------|
| 1 | New repo `donnfelker/loop-skills`, a marketplace of **5 plugins** (not flat). |
| 2 | `dev-team` → its own plugin. Used standalone often enough to warrant independent install. |
| 3 | `pr-autopilot` → its own plugin; **owns** `pr-review-mechanics.md`. |
| 4 | `plan-to-tickets` + `implement-full-spec` → one plugin, renamed **`spec-development`** (was `durable-spec-development`). |
| 5 | `triangulated-code-review` and `multi-llm-convergence` → stay as separate one-skill plugins (unchanged structure, relocated to the new repo). |
| 6 | `address-pr-comments` → **retired**. `pr-autopilot` gains `--single-pass` (≡ `--max-rounds 1`): one autonomous round, no human gate. |
| 7 | Cross-plugin dependency from `spec-development` → `dev-team` + `pr-autopilot` is made **explicit** via a preflight check (plugins do not auto-install dependencies). |
| 8 | Remove `durable-spec-development`, `multi-llm-convergence`, `triangulated-code-review` from `donnfelker-plugin-marketplace`. Clean break, documented as breaking in CHANGELOG. |
| 9 | **Out of scope** (deferred): the `loop-skills` conductor, `goal-intake`, `definition-of-done`, `loop-status`, the `loop-engine.md` reference, and the `pr-autopilot` CI/§7 extension. |

## Target structure — `donnfelker/loop-skills`

```
loop-skills/                              # new repo root
├── .claude-plugin/
│   └── marketplace.json                  # name "loop-skills"; 5 plugin entries
├── README.md                             # what it is, per-plugin install, skill index (PLUGINS markers)
├── CHANGELOG.md
├── AGENTS.md
├── CONTRIBUTING.md
├── LICENSE
├── validate-skills.sh                    # adapted from donnfelker-plugin-marketplace
└── plugins/
    ├── spec-development/
    │   ├── .claude-plugin/plugin.json     # name "spec-development", v1.0.0, MIT; documents dep on dev-team + pr-autopilot
    │   └── skills/
    │       ├── plan-to-tickets/           # moved unchanged (+ references/{asana,clickup,github-projects,jira,linear,notion,markdown-fallback}.md)
    │       └── implement-full-spec/       # moved + cross-plugin seam fixes (+ references/{phase-a,phase-b,phase-c,gotchas,prompt-templates}.md)
    ├── dev-team/
    │   ├── .claude-plugin/plugin.json     # name "dev-team", v1.0.0, MIT
    │   └── skills/
    │       └── dev-team/                  # moved unchanged (+ references/prompt-templates.md)
    ├── pr-autopilot/
    │   ├── .claude-plugin/plugin.json     # name "pr-autopilot", v1.0.0, MIT
    │   ├── references/
    │   │   └── pr-review-mechanics.md     # moved here from durable-spec-development root
    │   └── skills/
    │       └── pr-autopilot/              # moved + extended with --single-pass (absorbs address-pr-comments)
    ├── triangulated-code-review/
    │   ├── .claude-plugin/plugin.json     # moved unchanged
    │   └── skills/
    │       └── triangulated-code-review/  # (+ references/review-guidelines.md)
    └── multi-llm-convergence/
        ├── .claude-plugin/plugin.json     # moved unchanged
        └── skills/
            └── multi-llm-convergence/     # (+ references/reviewer-dispatch.md)
```

Skill `name` fields and `/command` invocations are **unchanged** — `/implement-full-spec`,
`/dev-team`, `/pr-autopilot`, `/plan-to-tickets`, `/triangulated-code-review`,
`/multi-llm-convergence` all keep working. Only plugin homes and the repo change.

## The three transforms

### Transform 1 — Dissolve `durable-spec-development` into 3 plugins

- `git mv` each skill directory into its new plugin's `skills/`, preserving each skill's local
  `references/`.
- `pr-review-mechanics.md` moves from the old plugin root into `pr-autopilot/references/`. Because it
  stays at the new plugin's root `references/`, pr-autopilot's existing
  `${CLAUDE_PLUGIN_ROOT}/references/pr-review-mechanics.md` citation needs no change.
- Author a `plugin.json` for each new plugin (`spec-development`, `dev-team`, `pr-autopilot`).

### Transform 2 — Retire `address-pr-comments`, fold into `pr-autopilot`

- Delete the `address-pr-comments` skill entirely.
- Add a `--single-pass` flag to `pr-autopilot` (alias for `--max-rounds 1`): runs exactly one
  autonomous `address → commit → push → reply → resolve` round, then stops. No human approval gate.
- Rework `pr-autopilot`'s description and "Operating mode" section: drop the "unlike
  /address-pr-comments" framing; document `--single-pass` as the one-shot mode.

### Transform 3 — Fix the cross-plugin seams in `spec-development`

All in `implement-full-spec` (SKILL.md + its `references/`):

1. **Relative doc-links → skill-name references.** `../dev-team/SKILL.md` and
   `../../dev-team/SKILL.md` will not resolve across plugin boundaries. Replace with references to the
   `dev-team` skill by name ("invoke the `dev-team` skill"), which is how invocation actually works.
2. **`address-pr-comments` references → `pr-autopilot --single-pass`.** Update Phase C
   (`phase-c-review-response.md`), `prompt-templates.md`, and the decision-matrix mentions in
   `SKILL.md`.
3. **Phase C delegates per-PR mechanics to `/pr-autopilot`.** Phase C keeps only the stacked-PR
   cascade-rebase + ordering layer; each individual PR's fetch/classify/reply/resolve is delegated to
   `/pr-autopilot`. Consequence: `spec-development` needs **no** copy of `pr-review-mechanics.md` (no
   duplication, no drift). Remove the `${CLAUDE_PLUGIN_ROOT}/references/pr-review-mechanics.md`
   citation in `implement-full-spec/SKILL.md`.
4. **Dependency preflight.** `implement-full-spec` opens by confirming `/dev-team` and `/pr-autopilot`
   are available; if either is missing, it names the exact plugin(s) to `/plugin install` and stops.
   The dependency is also documented in `spec-development`'s `plugin.json` description, the plugin
   README section, and `marketplace.json`.

## Cleanup in `donnfelker-plugin-marketplace`

Only after the new repo is populated and pushed:

1. Delete `plugins/durable-spec-development/`, `plugins/multi-llm-convergence/`,
   `plugins/triangulated-code-review/`.
2. `.claude-plugin/marketplace.json` — remove those three plugin entries.
3. `README.md` — remove the three PLUGINS-table rows; add a short "Moved to the `loop-skills`
   marketplace" note with the new install command.
4. `CHANGELOG.md` — remove the three version-table rows; add a dated `2026-06-15` entry documenting
   the move as **breaking**, pointing to `/plugin marketplace add donnfelker/loop-skills`.
5. Delete the scratch `LOOP-SKILLS-PLAN.md` created during the adversarial-review step.

## Verification

1. `./validate-skills.sh plugins/*/skills/` in the new repo — all skills pass frontmatter/naming.
2. `jq . .claude-plugin/marketplace.json` and each `plugin.json` valid; plugin/skill names match
   directories.
3. Every `SKILL.md` < 500 lines; descriptions single-line, < 1024 chars.
4. No dangling relative links in `implement-full-spec` (no `../dev-team/...`); the dependency preflight
   names real, installable plugins.
5. `grep` moved + edited content for CLAUDE.md generalization violations (real names/IDs/URLs) —
   placeholders only.
6. `donnfelker-plugin-marketplace`: `marketplace.json` and `README.md` valid, no dangling references
   to the three removed plugins; `LOOP-SKILLS-PLAN.md` gone.
7. Smoke test: `/plugin marketplace add donnfelker/loop-skills`, then install `spec-development`,
   `dev-team`, `pr-autopilot` and confirm `/implement-full-spec`'s preflight is satisfied and each
   `/command` is individually invocable.

## Order of operations (for the implementation plan)

1. Create + scope `donnfelker/loop-skills` (GitHub MCP `create_repository`; fallback: build the tree
   locally under `loop-skills/` ready to push).
2. Move the six skills into their five plugins; relocate `pr-review-mechanics.md`; author the five
   `plugin.json` files and the repo scaffolding (`marketplace.json`, README, CHANGELOG, AGENTS,
   CONTRIBUTING, LICENSE, `validate-skills.sh`).
3. Apply Transform 2 (retire `address-pr-comments`, add `--single-pass`) and Transform 3 (cross-plugin
   seam fixes + preflight).
4. Validate; push the new repo to `main`.
5. Only then run the `donnfelker-plugin-marketplace` cleanup; commit and push the branch.

## Open questions / risks

- **Plugin dependency mechanism.** Claude Code plugins have no auto-install dependency field, so the
  `spec-development` → `dev-team`/`pr-autopilot` contract is enforced by a runtime preflight + docs.
  If a future Claude Code version adds declarative plugin dependencies, migrate the preflight to it.
- **Deferred conductor & shared state.** When the `loop-skills` conductor and `loop-engine.md` are
  built later, Codex finding #1 (per-run state namespacing/locking in `.loop-skills/state.json`) must
  be addressed then — it is not in scope now because no shared state is introduced by this repackaging.
