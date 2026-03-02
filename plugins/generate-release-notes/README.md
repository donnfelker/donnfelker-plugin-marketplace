# Generate Release Notes Plugin

Generates release notes and changelogs by parsing [Conventional Commits](https://www.conventionalcommits.org/) from git log history. Designed to work with the [git-commit](../git-commit/) plugin's structured commit format.

## What It Does

Parses conventional commit messages (`feat:`, `fix:`, `docs:`, etc.) from a git revision range and produces categorized, well-formatted markdown output as:

- **Release Notes** (`RELEASE_NOTES.md`) — a summary for a single release
- **Changelog** (`CHANGELOG.md`) — an append-friendly log following [Keep a Changelog](https://keepachangelog.com/)
- **Both** — generate both files from the same commit range

## How It Works

1. Determines the commit range (since last tag or a custom range)
2. Runs `scripts/parse-commits.sh` to extract structured commit data
3. Categorizes commits by type into sections (Features, Bug Fixes, etc.)
4. Surfaces breaking changes prominently
5. Suggests a SemVer version bump based on commit types
6. Writes formatted markdown output

## Usage

```
"Generate release notes"
"Generate changelog"
"What changed since v1.0.0?"
"Prepare release notes for v2.0.0"
"Update the changelog"
```

## Commit Type → Section Mapping

| Commit Type | Release Notes Section | Changelog Section |
|-------------|----------------------|-------------------|
| `feat` | Features | Added |
| `fix` | Bug Fixes | Fixed |
| `perf` | Performance Improvements | Changed |
| `refactor` | Code Refactoring | Changed |
| `docs` | Documentation | Changed |
| `style` | Styles | Changed |
| `test` | Tests | Changed |
| `build` | Build System | Changed |
| `ci` | Continuous Integration | Changed |
| `chore` | Chores | Other |
| `revert` | Reverts | Removed/Changed |

Breaking changes (signaled by `!` suffix or `BREAKING CHANGE:` footer) are collected into a dedicated section at the top regardless of their type.

## SemVer Integration

The skill suggests version bumps based on the [Semantic Versioning](https://semver.org/) rules defined by Conventional Commits:

- Any `BREAKING CHANGE` → **MAJOR** bump
- Any `feat` → **MINOR** bump
- Only `fix`, `docs`, etc. → **PATCH** bump

## Plugin Structure

```
generate-release-notes/
├── .claude-plugin/
│   └── plugin.json
├── README.md
└── skills/
    └── generate-release-notes/
        ├── SKILL.md
        ├── references/
        │   └── formats.md
        └── scripts/
            └── parse-commits.sh
```

## Further Reading

- [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning 2.0.0](https://semver.org/)
