# Changelog

Current versions of all plugins. Compare against local versions to check for updates.

| Plugin | Version | Last Updated |
|--------|---------|--------------|
| git-commit | 1.1.0 | 2026-03-11 |
| codebase-analyzer | 1.0.0 | 2026-02-27 |
| git-worktree | 1.0.0 | 2026-02-27 |
| generate-release-notes | 1.0.0 | 2026-03-02 |
| pr-title | 1.0.0 | 2026-03-11 |

## Recent Changes

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
