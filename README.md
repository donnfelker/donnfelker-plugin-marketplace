# Engineering Plugins for Claude Code

A collection of Claude Code plugins for common engineering workflows and use cases. Each plugin can be installed independently — pick only what you need.

Built by [Donn Felker](https://donnfelker.com).

**Contributions welcome!** Found a way to improve a plugin or have a new one to add? [Open a PR](#contributing).

Run into a problem or have a question? [Open an issue](https://github.com/donnfelker/donnfelker-plugin-marketplace/issues).

## What are Plugins?

Plugins are packages of skills, commands, agents, and hooks that extend Claude Code with specialized capabilities. Each plugin in this marketplace focuses on a specific engineering workflow and can be installed independently.

## Available Plugins

<!-- PLUGINS:START -->
| Plugin | Description |
|--------|-------------|
| [codebase-analyzer](plugins/codebase-analyzer/) | Multi-phase technical analysis of codebases covering architecture, code quality, testing, and infrastructure |
| [generate-release-notes](plugins/generate-release-notes/) | Generates release notes and changelogs from [Conventional Commits](https://www.conventionalcommits.org/) parsed from git log history |
| [triangulated-code-review](plugins/triangulated-code-review/) | Triangulated multi-reviewer code review orchestrator. Borrows from research methodology — checks each finding against multiple independent reviewers (comprehensive, security, codex, codex adversarial) to reduce blind spots, then runs a QA analyst pass that substantiates every finding (verifying any third-party library claims via the context7 MCP) and demotes unsubstantiated ones into a dedicated "Invalidated Findings" section of the prioritized, timestamped report |
| [durable-spec-development](plugins/durable-spec-development/) | End-to-end durable spec workflow. Bundles `plan-to-tickets` (import a structured plan into ClickUp, Linear, Jira, Asana, Notion, GitHub Projects, or markdown), `implement-full-spec` (turn a parent ticket with N actionable subtasks into N stacked PRs and drive each to merge-ready through multi-round bot and human review), `dev-team` (drive a single unit of work from spec to a committed, reviewed result with an agent team of Dev → QA → Reviewer roles in a bounded cycle — runs as a real agent team where the harness supports one, else coordinated subagents, so it works across agents and models; usable standalone or as the per-subtask engine behind `implement-full-spec`), `address-pr-comments` (review and address unresolved GitHub PR comments on the current branch), and `pr-autopilot` (autonomously watch a single PR and loop through review rounds — fetch, fix, commit, push, reply, re-request review — until they settle) |
| [find-past-conversation](plugins/find-past-conversation/) | Searches past Claude Code session transcripts under `~/.claude/projects/` to find a previous conversation by recalled keyword or phrase, then optionally reports the outcome (commit, branch, PR opened, merged) |
| [skill-scout](plugins/skill-scout/) | Scouts an agent conversation (current or a past saved transcript under `~/.claude/projects/`) for skill opportunities and produces a markdown report of new skills to create, existing skills to improve or simplify, and rules for CLAUDE.md, then hands off to `/skill-creator` or edits the affected SKILL.md directly |
| [multi-llm-convergence](plugins/multi-llm-convergence/) | Drives any artifact (plan, PRD, design doc, spec, or implementation diff) to convergence by alternating two genuinely different LLM reviewers — a Codex reviewer and an independent Claude review subagent — applying each round's findings and looping until both independently clear the bar (default: no critical/high findings). Grounds offline reviewers in local source-of-truth clones, runs a liveness watchdog so a silent reviewer can't hang the loop, commits per round for an auditable trail, and holds both roles to a set of general anti-over-engineering rules (adapted from [Andrej Karpathy's `CLAUDE.md`](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md)) |
<!-- PLUGINS:END -->

## Installation

### Option 1: CLI Install (Recommended)

Use [npx skills](https://github.com/vercel-labs/skills) to install skills directly:

```bash
# Install all plugins
npx skills add donnfelker/donnfelker-plugin-marketplace

# Install specific plugins
npx skills add donnfelker/donnfelker-plugin-marketplace --skill codebase-analyzer

# List available plugins
npx skills add donnfelker/donnfelker-plugin-marketplace --list
```

This automatically installs to your `.claude/skills/` directory.

### Option 2: Claude Code Plugin

Install via Claude Code's built-in plugin system:

```bash
# Add the marketplace
/plugin marketplace add donnfelker/donnfelker-plugin-marketplace

# Install a specific plugin
/plugin install codebase-analyzer@donnfelker-plugins
```

### Option 3: Clone and Copy

Clone the repo and copy the plugins you want:

```bash
git clone https://github.com/donnfelker/donnfelker-plugin-marketplace.git
cp -r donnfelker-plugin-marketplace/plugins/codebase-analyzer .claude/plugins/
```

### Option 4: Git Submodule

Add as a submodule for easy updates:

```bash
git submodule add https://github.com/donnfelker/donnfelker-plugin-marketplace.git .claude/donnfelker-plugins
```

Then reference plugins from `.claude/donnfelker-plugins/plugins/`.

### Option 5: Fork and Customize

1. Fork this repository
2. Customize plugins for your specific needs
3. Clone your fork into your projects

### Option 6: SkillKit (Multi-Agent)

Use [SkillKit](https://github.com/rohitg00/skillkit) to install skills across multiple AI agents (Claude Code, Cursor, Copilot, etc.):

```bash
# Install all plugins
npx skillkit install donnfelker/donnfelker-plugin-marketplace

# Install specific plugins
npx skillkit install donnfelker/donnfelker-plugin-marketplace --skill codebase-analyzer

# List available plugins
npx skillkit install donnfelker/donnfelker-plugin-marketplace --list
```

## Usage

Once installed, just use the skills naturally:

```
"Generate release notes since the last release"
→ Uses generate-release-notes plugin

"Analyze this codebase and write up the architecture"
→ Uses codebase-analyzer plugin
```

Or invoke skills directly:

```
/generate-release-notes
```

## Plugin Categories

### Git & Dev Workflow
- Coming soon

### Documentation
- Coming soon

### Code Review
- Coming soon

### Technical Analysis
- Coming soon

### Presentations & Media
- Coming soon

## GitHub Workflow: PR Title Validation

This repository includes a GitHub Actions workflow (`.github/workflows/pr-lint-title.yml`) that validates PR titles against the [Conventional Commits](https://www.conventionalcommits.org/) format using [`amannn/action-semantic-pull-request`](https://github.com/amannn/action-semantic-pull-request).

The workflow runs on every PR open, reopen, and title edit. It enforces that the PR title follows the `type(scope): description` format with a valid type and a lowercase description. If the title doesn't match, the check fails and the PR is blocked from merging.

This matters because GitHub's **squash merge** uses the PR title as the resulting commit message. By validating the title at the PR level, every merged commit on `main` is guaranteed to follow Conventional Commits — even if individual branch commits don't. This keeps `git log` clean and enables automated changelog generation, semantic versioning, and commit classification.

### Enforced Rules

- **Type** must be one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`
- **Description** must start with a lowercase letter
- **Format**: `type(scope): [ticket] description`

### Example

```
feat(auth): tos-123 add login support
```

If a PR title fails validation, the error message includes the expected format so you can correct the title.

## Contributing

Found a way to improve a plugin? Have a new one to suggest? PRs and issues welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE) — use these however you want.
