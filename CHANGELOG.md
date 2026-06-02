# Changelog

Current versions of all plugins. Compare against local versions to check for updates.

| Plugin | Version | Last Updated |
|--------|---------|--------------|
| codebase-analyzer | 1.0.0 | 2026-02-27 |
| generate-release-notes | 1.0.0 | 2026-03-02 |
| triangulated-code-review | 1.3.0 | 2026-05-22 |
| durable-spec-development | 1.2.0 | 2026-05-22 |
| find-past-conversation | 1.0.0 | 2026-05-22 |
| skill-scout | 1.0.0 | 2026-05-29 |

## Recent Changes

### 2026-06-02
- Removed the `git-worktree` plugin. Agents create and manage git worktrees on their own by default, so the dedicated skill was redundant. Removed the plugin directory, its marketplace entry, the CHANGELOG version-table row, and all references across `README.md`, `AGENTS.md`, and `CONTRIBUTING.md` (illustrative naming/description examples re-pointed to `codebase-analyzer`). Legitimate `git worktree` command usage in other plugins (e.g. `durable-spec-development`) is unaffected.
- Removed the `git-commit` and `pr-title` plugins. Agents now format Conventional Commit messages and PR titles by default, so the dedicated skills were redundant. Removed both plugin directories, their marketplace entries, and all references across `README.md`, `AGENTS.md`, `CONTRIBUTING.md`, and the remaining plugins' cross-references. The PR title validation GitHub Actions workflow (`.github/workflows/pr-lint-title.yml`) is retained — it enforces Conventional Commit PR titles independently of any skill — with its skill-reference tips removed.

### 2026-05-29
- Added `skill-scout` plugin: scouts an agent conversation — the current session by default, or a past `.jsonl` transcript under `~/.claude/projects/` when asked — for skill opportunities and produces a `# Skill Scout Report` in chat. Detects five signals (manual workflows worth packaging, existing-skill output that had to be corrected, repeated user corrections, reusable multi-step research, and skill content to simplify or remove), inventories existing skills across repo-local / user / cache / mounted sources and tracks each skill's origin so edits route to the right place (direct Edit for editable sources, print-and-hand-off for read-only caches and mounts), then hands off to `/skill-creator` for new skills or edits the affected SKILL.md directly. Generalized from an internal version — no company-specific marketplace assumptions.

### 2026-05-22
- Bumped `durable-spec-development` to v1.2.0: extended the `address-pr-comments` skill with a post-push "Request re-review from bots" step. The skill now @-mentions bots with the required `[bot]` suffix (`@review-bot[bot]`, not `@review-bot` — without the suffix the mention silently resolves to the wrong account and the bot is never notified), only pings bots whose feedback was actually addressed in the round, and can combine the "Addressed in <commit>" reply and the re-review ping into one comment on the same thread.
- Bumped `triangulated-code-review` to v1.3.0: added a final QA validation step. After merging findings but before writing the report, the orchestrator now spawns a `review QA analyst` subagent that substantiates each draft finding by re-reading the cited file/line, walking the reasoning, and — for any claim about a third-party library, framework, SDK, or cloud service touched by the diff — verifying current usage via the `context7` MCP (`resolve-library-id` + doc query). Findings the analyst can't substantiate are removed from the main "Findings (Prioritized)" list and moved into a new "Invalidated Findings" section with the analyst's reason, evidence, and any `library_checks` entries — so the user sees what was rejected and can override if they disagree. Process flow renumbered (now 9 steps), report header gains a `QA Validation` line, and `Raw Reviewer Output` gains a `QA Analyst` sub-section with the verbatim verdict JSON.
- Bumped `triangulated-code-review` to v1.2.1: corrected the security reviewer's framing — `/security-review` is a **built-in slash command in the Claude Code CLI binary**, not a plugin. The fallback message no longer tells the user to install anything; it explains the only failure mode (running this skill under a non-Claude-Code runtime like Copilot CLI, Gemini CLI, or Codex CLI) and the error field renamed from `install_hint` to `runtime_hint`. Step 4 and Edge Cases updated to match.
- Bumped `triangulated-code-review` to v1.2.0: the security reviewer now delegates to `/security-review` via the `Skill` tool, and the two Codex reviewers reframe their bash invocation as "running the same companion script `/codex:review` and `/codex:adversarial-review` run" — including a robust `$CLAUDE_PLUGIN_ROOT` → `find` path-resolution probe and softer install hints. The comprehensive reviewer's rubric (`references/review-guidelines.md`) was rewritten to add a "Getting the diff" section (prefer `mcp__conductor__GetWorkspaceDiff`, fall back to git) and a clearly-fenced "Standalone use only" output-format section so subagents in the orchestrator path don't get confused.
- Renamed `code-review` plugin to `triangulated-code-review` (v1.0.0 → v1.1.0). Borrows from research methodology, where you check a finding against multiple independent sources to reduce blind spots. Updates the plugin directory, skill name, manifest, description, and the report filename prefix (`triangulated-code-review-<timestamp>.md`).
- Folded the standalone `address-pr-comments` plugin into `durable-spec-development` as a third bundled skill, bumping the plugin to v1.1.0. The skill itself is unchanged; the standalone plugin entry was removed from the marketplace because the durable-spec workflow already owns the per-PR review-response phase and the two were being installed together in practice.
- Added `find-past-conversation` plugin: searches past Claude Code session transcripts under `~/.claude/projects/` to locate a previous conversation by recalled keyword or phrase. Reports session ID, project, date, and a short summary; on request, parses the transcript for commits, pushes, and PR URLs and reports the current PR state via `gh`. Includes guidance on JSON-aware extraction with `jq`, search-string hygiene, and skipping noisy subagent transcripts by default.

### 2026-05-21
- Fleshed out `durable-spec-development/plan-to-tickets` Linear reference (`references/linear.md`): replaced the stub with concrete OAuth setup, MCP tool inventory, unified `save_issue` create/update semantics, `blockedBy` direction, project-icon validation footgun, and the `list_issues` output-cap workaround — validated across a multi-phase Linear import.
- Added `durable-spec-development` plugin bundling two skills for the durable spec lifecycle:
  - `plan-to-tickets` — imports a structured planning document into ClickUp / Linear / Jira / Asana / Notion / GitHub Projects (or a markdown fallback) as a ticket hierarchy with dependencies wired. Migrated from the standalone `plan-to-tickets` plugin.
  - `implement-full-spec` — turns a parent ticket with N actionable subtasks into N stacked pull requests, then drives the stack to merge-ready by addressing every bot and human review comment and cascading rebases across the stack.
- Removed the standalone `plan-to-tickets` plugin; its skill now lives inside `durable-spec-development`.

### 2026-05-19
- Added `plan-to-tickets` plugin for importing structured planning documents into task trackers (ClickUp, Linear, Jira, Asana, Notion, GitHub Projects) as ticket hierarchies with dependencies wired

### 2026-04-30
- Added `address-pr-comments` plugin: walks through unresolved GitHub PR comments on the current branch, classifies actionable items, plans changes, applies them after user approval, then replies with the commit reference and resolves threads

### 2026-04-25
- Added `code-review` plugin: multi-reviewer orchestrator that runs comprehensive, security, codex, and codex adversarial reviews in parallel and combines their findings into one prioritized, timestamped report

### 2026-03-11
- Added `pr-title` plugin for generating PR titles following the Conventional Commits specification
- Updated `git-commit` plugin to v1.1.0: added optional ticket ID support, raised subject line limit to 100 characters, improved revert example

### 2026-03-02
- Added `generate-release-notes` plugin for generating release notes and changelogs from conventional commit messages

### 2026-02-27
- Added `git-worktree` plugin for parallel branch development with consistent naming conventions
- Added `codebase-analyzer` plugin with multi-phase technical analysis skill
- Added `validate-skills.sh` for validating skills against the Agent Skills spec
- Added project instructions (`AGENTS.md`, `CLAUDE.md`)
- Fixed `git-commit` skill name to match directory
- Initial marketplace scaffold
- Added `git-commit` plugin with formatting skill based on Chris Beams' seven rules
