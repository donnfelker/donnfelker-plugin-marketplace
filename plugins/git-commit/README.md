# Git Commit Message Plugin

A commit message plugin (a skill) that combines [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) with the prose quality principles from [How to Write a Git Commit Message](https://cbea.ms/git-commit/) by Chris Beams.

## Why Two Standards?

Conventional Commits and the cbeams approach solve different problems. Neither is complete on its own.

**Conventional Commits** provides a machine-parseable grammar for commit messages. Every subject line begins with a structured `type(scope): description` prefix that automated tools can decompose reliably. This enables changelog generation, semantic version bumping, breaking change detection, and deterministic commit classification by CI pipelines and AI agents — all without natural language inference. The spec is enforceable through commit hooks and linters, which means a repository can guarantee structural consistency across its entire history.

What Conventional Commits does *not* address is the quality of communication within that structure. The specification permits a body but offers no guidance on what it should contain. In practice, this leads to messages like `feat(auth): add OAuth2 support` with no explanation of *why* OAuth2 was chosen, what problem it solves, or what trade-offs were accepted. The type prefix creates an illusion of completeness that discourages authors from providing the context that makes a repository's history genuinely useful over time.

**The cbeams approach** fills exactly this gap. Its seven rules are rooted in decades of kernel and open-source practice, and its most important contribution is Rule 7: *use the body to explain what and why, not how.* A commit body that walks through the reasoning behind a change — the problem, the motivation, the alternatives considered, the implications — is vastly more valuable than a well-typed but contextless subject line. The imperative mood rule ("If applied, this commit will...") produces subject lines that read naturally in `git log`. The 72-character wrapping rule ensures body text renders cleanly in terminals and code review tools.

Where the cbeams approach falls short is structure. Its messages are free-form prose with no machine-parseable grammar. An automated tool cannot distinguish a bug fix from a feature from a refactor without natural language understanding. There is no mechanical path from commit history to a version number or a changelog. Consistency depends entirely on team discipline because the rules resist automated enforcement.

## The Combined Approach

This standard uses Conventional Commits as the structural envelope and applies cbeams' prose philosophy inside it.

### From Conventional Commits

We adopt the full specification as our foundation:

- **Structured prefix** — every commit begins with `type(scope): description`, giving machines and agents a deterministic grammar to parse
- **Semantic typing** — `feat`, `fix`, and the extended Angular/commitlint type set (`docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) classify every change explicitly
- **Scoping** — an optional parenthetical scope attributes changes to specific subsystems
- **Breaking change signaling** — the `!` suffix and `BREAKING CHANGE:` footer provide unambiguous markers that can gate deployments and trigger migration workflows
- **SemVer integration** — `fix` maps to PATCH, `feat` maps to MINOR, `BREAKING CHANGE` maps to MAJOR, enabling automated version computation
- **Git-trailer footers** — structured metadata like `Refs:`, `Reviewed-by:`, and `BREAKING CHANGE:` in a consistent, parseable format
- **Mechanical enforceability** — the entire prefix structure can be validated by tools like [commitlint](https://commitlint.js.org/) at the hook or CI level

### From the cbeams Approach

We adopt the prose quality principles that Conventional Commits underspecifies:

- **Imperative mood** — the description after the prefix is written as a command: "Add feature" not "Added feature." This produces subject lines that complete the sentence "If applied, this commit will ___" and aligns with Git's own conventions (`Merge branch`, `Revert "..."`)
- **No trailing period** — punctuation at the end of the subject line wastes space and adds no information
- **72-character body wrapping** — Git does not wrap text automatically. Hard-wrapping at 72 characters keeps body text readable in terminals, email patches, and code review tools where Git indents content
- **What and why, not how** — the body explains the motivation for the change, the problem it addresses, and why this approach was chosen. The diff shows *how*; the body provides the reasoning that makes the change understandable months or years later without reading the code
- **Body inclusion criteria** — a body is warranted when the motivation is not obvious from the diff, when trade-offs or alternatives deserve documentation, when the change has unintuitive side effects, or when a breaking change requires migration context

### What We Deliberately Omitted

**The 50-character subject line limit.** The cbeams approach recommends keeping subject lines to 50 characters with 72 as a hard limit. The Conventional Commits type and scope prefix consumes significant character budget before the description even begins — `feat(parser): ` is already 15 characters. Imposing a 50-character total would leave roughly 35 characters for the actual description, which is too constraining to write meaningful imperative sentences. We retain 72 characters as the hard limit for the full subject line, which is the point at which GitHub truncates with an ellipsis.

**The capitalization rule.** The cbeams approach requires capitalizing the first letter of the subject line. In Conventional Commits, the subject line begins with a lowercase type prefix (`feat`, `fix`, etc.), and the community convention is to continue in lowercase after the colon. We follow the Conventional Commits convention here for consistency with the broader ecosystem and its tooling.

## What This Enables

For **automated tooling and CI pipelines**, the structured prefix provides everything needed to generate changelogs, compute semantic versions, detect breaking changes, and enforce commit standards mechanically.

For **AI agents** reviewing pull requests, triaging regressions, or summarizing repository activity, the type and scope provide deterministic classification without NLP inference, and the body provides the reasoning context that classification alone cannot capture.

For **human developers** reading `git log`, the imperative descriptions scan naturally, the type prefixes enable categorical filtering in high-volume repositories, and well-written bodies preserve the institutional knowledge of *why* decisions were made.

For **long-term maintainability**, the combination of structure and prose creates a commit history that is simultaneously queryable by machines and comprehensible to people — a durable record of not just what changed, but what kind of change it was and why it was made.

## Quick Reference

### Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Allowed Types

| Type | Purpose | SemVer |
|---|---|---|
| `feat` | A new feature | MINOR |
| `fix` | A bug fix | PATCH |
| `docs` | Documentation only changes | — |
| `style` | Formatting, whitespace, semicolons (not CSS) | — |
| `refactor` | Code change that neither fixes a bug nor adds a feature | — |
| `perf` | A code change that improves performance | — |
| `test` | Adding or correcting tests | — |
| `build` | Changes to the build system or external dependencies | — |
| `ci` | Changes to CI configuration files and scripts | — |
| `chore` | Other changes that don't modify src or test files | — |
| `revert` | Reverts a previous commit | — |

Any type combined with `BREAKING CHANGE` in the footer or `!` after the type/scope triggers a MAJOR release.

### Examples

**Simple change:**
```
docs: correct spelling in CHANGELOG
```

**Scoped feature:**
```
feat(lang): add Polish language support
```

**Fix with body explaining why:**
```
fix(api): add rate limiting to public endpoints

The public API was vulnerable to abuse through excessive requests.
This adds a token bucket algorithm limiting clients to 100 requests
per minute, with appropriate 429 responses when exceeded.

Refs: #234
```

**Breaking change:**
```
feat(auth)!: replace session-based auth with JWT tokens

Replace session-based authentication with stateless JWT tokens to
enable horizontal scaling. Sessions required sticky load balancing
which limited deployment options and created a single point of
failure under high traffic.

BREAKING CHANGE: Clients must update to handle the token refresh
flow. Session cookies are no longer issued or accepted.

Refs: #891
```

## Further Reading

- [Conventional Commits v1.0.0 Specification](https://www.conventionalcommits.org/en/v1.0.0/)
- [How to Write a Git Commit Message — Chris Beams](https://cbea.ms/git-commit/)
- [Angular Commit Message Guidelines](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines)
- [commitlint — Lint commit messages](https://commitlint.js.org/)
- [Semantic Versioning 2.0.0](https://semver.org/)
