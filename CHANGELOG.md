# Changelog

Current versions of all plugins. Compare against local versions to check for updates.

| Plugin | Version | Last Updated |
|--------|---------|--------------|
| git-commit | 1.1.0 | 2026-03-11 |
| codebase-analyzer | 1.0.0 | 2026-02-27 |
| git-worktree | 1.0.0 | 2026-02-27 |
| generate-release-notes | 1.0.0 | 2026-03-02 |
| pr-title | 1.0.0 | 2026-03-11 |
| code-review | 1.0.0 | 2026-04-25 |
| address-pr-comments | 0.1.0 | 2026-04-30 |
| durable-spec-development | 1.0.0 | 2026-05-21 |
| find-past-conversation | 1.0.0 | 2026-05-22 |

## Recent Changes

### 2026-05-22
- Added `find-past-conversation` plugin: searches past Claude Code session transcripts under `~/.claude/projects/` to locate a previous conversation by recalled keyword or phrase. Reports session ID, project, date, and a short summary; on request, parses the transcript for commits, pushes, and PR URLs and reports the current PR state via `gh`. Includes guidance on JSON-aware extraction with `jq`, search-string hygiene, and skipping noisy subagent transcripts by default.

### 2026-05-21
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
