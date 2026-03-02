---
name: git-commit
description: Formats git commit messages following the Conventional Commits specification. This skill should be used when the user says "commit this", "make a commit", "commit my changes", "git commit", "write a commit message", "help with commit message format", or when writing, reviewing, reformatting, or improving git commit messages, commit message style, wording, or subject lines.
---

# Git Commit Message Formatter

Format commit messages following the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification, augmented with prose quality guidelines from the cbeams approach.

## Gather Context

Before writing a commit message, run `git diff --staged` to see what is being committed. If nothing is staged, run `git diff` to see unstaged changes. Use the diff output to understand the actual changes and write an accurate, specific commit message.

## Message Structure

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Conventional Commits Specification

These rules are **mandatory**. They follow the Conventional Commits v1.0.0 spec using RFC 2119 language.

1. Commits MUST be prefixed with a type, followed by an OPTIONAL scope, OPTIONAL `!`, and a REQUIRED terminal colon and space.
2. The type `feat` MUST be used when a commit adds a new feature to the application or library.
3. The type `fix` MUST be used when a commit represents a bug fix.
4. A scope MAY be provided after a type. A scope MUST consist of a noun describing a section of the codebase surrounded by parentheses, e.g., `fix(parser):`.
5. A description MUST immediately follow the colon and space after the type/scope prefix. The description is a short summary of the code changes.
6. A longer commit body MAY be provided after the short description. The body MUST begin one blank line after the description.
7. A commit body is free-form and MAY consist of any number of newline-separated paragraphs.
8. One or more footers MAY be provided one blank line after the body. Each footer MUST consist of a word token, followed by either `:<space>` or `<space>#` separator, followed by a string value.
9. A footer's token MUST use `-` in place of whitespace characters, e.g., `Acked-by`. An exception is made for `BREAKING CHANGE`, which MAY also be used as a token.
10. A footer's value MAY contain spaces and newlines, and parsing MUST terminate when the next valid footer token/separator pair is observed.
11. Breaking changes MUST be indicated in the type/scope prefix of a commit, or as an entry in the footer.
12. If included as a footer, a breaking change MUST consist of the uppercase text `BREAKING CHANGE`, followed by a colon, space, and description.
13. If included in the type/scope prefix, breaking changes MUST be indicated by a `!` immediately before the `:`. If `!` is used, `BREAKING CHANGE:` MAY be omitted from the footer section, and the commit description SHALL be used to describe the breaking change.
14. Types other than `feat` and `fix` MAY be used in commit messages.
15. The units of information that make up Conventional Commits MUST NOT be treated as case sensitive by implementors, with the exception of `BREAKING CHANGE` which MUST be uppercase. **Note:** This rule governs parser tolerance, not authoring style. Always use lowercase types (`feat`, `fix`, etc.) to match ecosystem conventions and tooling expectations.
16. `BREAKING-CHANGE` MUST be synonymous with `BREAKING CHANGE` when used as a token in a footer.

## Allowed Types

| Type | Purpose |
|---|---|
| `feat` | A new feature (correlates with SemVer MINOR) |
| `fix` | A bug fix (correlates with SemVer PATCH) |
| `docs` | Documentation only changes |
| `style` | Changes that do not affect the meaning of the code (whitespace, formatting, missing semicolons, etc.) |
| `refactor` | A code change that neither fixes a bug nor adds a feature |
| `perf` | A code change that improves performance |
| `test` | Adding missing tests or correcting existing tests |
| `build` | Changes that affect the build system or external dependencies |
| `ci` | Changes to CI configuration files and scripts |
| `chore` | Other changes that don't modify src or test files |
| `revert` | Reverts a previous commit |

## SemVer Mapping

- `fix` type commits → PATCH release
- `feat` type commits → MINOR release
- Commits with `BREAKING CHANGE` in footer or `!` after type/scope → MAJOR release

## Prose Quality Guidelines (from cbeams)

These guidelines augment the Conventional Commits spec to improve human readability and long-term maintainability. Apply them within the structure defined above.

### Description (Subject Line)

- **Use imperative mood** in the description: "Add feature" not "Added feature" or "Adds feature". A properly formed description should complete the sentence: "If applied, this commit will ___."
- **Do not end the description with a period.** Trailing punctuation wastes space and adds no clarity.
- **Keep the description concise.** The full subject line (type, scope, and description combined) should stay under 72 characters as a hard limit.

### Body

- **Wrap the body at 72 characters.** Git never wraps text automatically. Hard-wrap at 72 characters so that Git has room to indent while keeping everything under 80 characters.
- **Use the body to explain *what* and *why*, not *how*.** The diff shows how. The body should provide the motivation for the change, the problem it solves, and why this approach was chosen over alternatives. This context is what makes a repository's history useful months or years later.

### When to Include a Body

Use a subject-only commit for trivial, self-explanatory changes. Include a body when:

- The motivation for the change is not obvious from the diff
- There are trade-offs or alternative approaches worth documenting
- The change has side effects or unintuitive consequences
- The change is a breaking change that requires migration context

## Formatting Checklist

When formatting a commit message:

1. Select the correct type from the allowed types table
2. Add a scope in parentheses if it clarifies which part of the codebase is affected
3. Append `!` before `:` if the change is a breaking change
4. Write the description in imperative mood after the colon and space
5. Ensure the full subject line stays under 72 characters
6. If a body is needed, add a blank line after the subject
7. Wrap all body lines at 72 characters
8. Focus the body on motivation and context, not implementation details
9. Add footers after a blank line using git-trailer format
10. Include `BREAKING CHANGE: <description>` in the footer for breaking changes (required if `!` is omitted from the prefix)
11. Add issue references and other metadata as footers (e.g., `Refs: #123`)

## Examples

### Simple commit (no body needed)

```
docs: correct spelling in CHANGELOG
```

### Commit with scope

```
feat(lang): add Polish language support
```

### Commit with body explaining why

```
fix(api): add rate limiting to public endpoints

The public API was vulnerable to abuse through excessive requests.
This adds a token bucket algorithm limiting clients to 100 requests
per minute, with appropriate 429 responses when exceeded.

Refs: #234
```

### Breaking change with `!` and footer

```
feat(auth)!: replace session-based auth with JWT tokens

Replace session-based authentication with stateless JWT tokens to
enable horizontal scaling. Sessions required sticky load balancing
which limited deployment options and created a single point of
failure under high traffic.

The token refresh endpoint provides seamless credential rotation
without requiring re-authentication.

BREAKING CHANGE: Clients must update to handle the token refresh
flow. Session cookies are no longer issued or accepted. See the
migration guide in docs/auth-migration.md.

Refs: #891
See-also: #445, #892
```

### Breaking change with `!` only (no footer)

```
feat!: send email to customer when product is shipped
```

### Revert commit

```
revert: let us never again speak of the noodle incident

Refs: 676104e, a215868
```

### Multi-paragraph body with multiple footers

```
fix(http): prevent racing of concurrent requests

Introduce a request id and a reference to the latest request.
Dismiss incoming responses other than from the latest request.

Remove timeouts which were used to mitigate the racing issue but
are obsolete now.

Reviewed-by: Z
Refs: #123
```
