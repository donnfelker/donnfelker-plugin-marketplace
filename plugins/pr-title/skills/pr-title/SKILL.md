---
name: pr-title
description: Generates PR titles following the Conventional Commits specification. This skill should be used when someone says "create a PR", "open a PR", "make a pull request", "PR title", "write a PR title", "title this PR", "format PR title", "gh pr create", "submit PR", or when creating, reviewing, or improving pull request titles. Also applies when a pull request is about to be opened and needs a well-formatted title.
---

# PR Title Formatter

Generate pull request titles following the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification. PR titles use the same type/scope/description format as commit messages, but are limited to a single subject line — no body or footers.

This project enforces PR title format via the `amannn/action-semantic-pull-request` GitHub Action, so a malformed title will block the PR from merging.

## Gather Context

Before writing a PR title, understand what the PR actually changes:

1. Run `git log main..HEAD --oneline` to see all commits on the branch.
2. Run `git diff main...HEAD --stat` to see which files changed and by how much.
3. If the commits and stat summary aren't enough to understand the intent, run `git diff main...HEAD` for the full diff.

Use this context to write an accurate, specific title that captures the overall purpose of the PR — not just the last commit.

## Title Format

```
<type>[optional scope]: [optional ticket] <description>
```

- **type** — one of the allowed types below (always lowercase)
- **scope** — a noun in parentheses identifying the area of the codebase (optional, but use it when it adds clarity)
- **ticket** — if a Linear ticket is associated, include the ticket ID in lowercase (e.g., `tos-123`) after the colon and space, before the description. Look for ticket IDs in branch names, commit messages, or ask the user if not obvious.
- **description** — a concise summary of the change

## Allowed Types

| Type | Purpose |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Changes that do not affect the meaning of the code (whitespace, formatting, etc.) |
| `refactor` | A code change that neither fixes a bug nor adds a feature |
| `perf` | A code change that improves performance |
| `test` | Adding missing tests or correcting existing tests |
| `build` | Changes that affect the build system or external dependencies |
| `ci` | Changes to CI configuration files and scripts |
| `chore` | Other changes that don't modify src or test files |
| `revert` | Reverts a previous commit |

## Writing the Description

- **Use imperative mood**: "add feature" not "added feature" or "adds feature". A properly formed description completes the sentence: "This PR will ___."
- **Start with a lowercase letter.** The GitHub Action enforces this — an uppercase first letter will fail the check.
- **Do not end with a period.**
- **Keep the full title under 70 characters.** GitHub truncates long titles in the PR list, and shorter titles are easier to scan. This is a soft target — go slightly over if needed for clarity, but never exceed 100 characters.

## Choosing the Right Type

When a PR contains multiple commits with different types, choose the type that best describes the PR's overall purpose:

- If the PR adds a new feature with supporting tests and docs, use `feat` — the tests and docs support the feature.
- If the PR fixes a bug and refactors surrounding code, use `fix` — the refactor serves the fix.
- If commits are truly unrelated, consider whether the PR should be split. But if it can't be, pick the most significant change.

## Choosing a Scope

Use a scope when it helps the reader quickly understand which part of the codebase is affected. Good scopes are short nouns that match how the team talks about the codebase:

- `feat(auth):` — authentication system
- `fix(leaderboard):` — leaderboard feature
- `ci(deploy):` — deployment pipeline
- `refactor(feed):` — social feed

Omit the scope if the change is broad or the type alone is descriptive enough (e.g., `docs: update README` doesn't need a scope).

## Examples

```
feat(crew): tos-456 add crew invitation flow
```

```
fix(leaderboard): tos-789 resolve crash from firebase-admin import
```

```
ci: replace commitlint workflow with semantic PR title check
```

```
refactor(auth): tos-234 extract token refresh into dedicated service
```

```
docs: add conventional commits documentation
```

```
feat(chat)!: tos-891 replace Stream Chat with custom implementation
```
