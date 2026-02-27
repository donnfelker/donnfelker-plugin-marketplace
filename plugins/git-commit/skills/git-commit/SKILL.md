---
name: git-commit
description: Formats git commit messages following the seven rules of great git commit messages. This skill should be used when the user says "commit this", "make a commit", "write a commit message", "help with commit message format", or when writing, reviewing, reformatting, or improving git commit messages, commit message style, wording, or subject lines.
---

# Git Commit Message Formatter

Format commit messages following the seven rules of great git commit messages.

## Gather Context

Before writing a commit message, run `git diff --staged` to see what is being committed. If nothing is staged, run `git diff` to see unstaged changes. Use the diff output to understand the actual changes and write an accurate, specific commit message.

## The Seven Rules

1. **Separate subject from body with a blank line**
2. **Limit subject line to 50 characters** (72 is the hard limit)
3. **Capitalize the subject line**
4. **Do not end the subject line with a period**
5. **Use imperative mood in the subject line** (e.g., "Add feature" not "Added feature")
6. **Wrap body at 72 characters**
7. **Use the body to explain *what* and *why*, not *how***

## Imperative Mood Test

A properly formed subject should complete: "If applied, this commit will _____"

- Correct: "If applied, this commit will **refactor authentication module**"
- Correct: "If applied, this commit will **fix null pointer exception in parser**"
- Incorrect: "If applied, this commit will **fixed bug with login**"
- Incorrect: "If applied, this commit will **fixing the tests**"

## Template

```
<Subject: imperative, capitalized, no period, ≤50 chars>

<Body: wrap at 72 chars, explain what/why not how>

<Footer: issue refs, breaking changes>
```

## When to Include a Body

Use a subject-only commit for trivial, self-explanatory changes. Include a body when the change requires context about motivation or trade-offs.

## Examples

### Simple commit (no body needed)

```
Fix typo in user guide introduction
```

### Commit with body

```
Add rate limiting to API endpoints

The public API was vulnerable to abuse through excessive requests.
This adds a token bucket algorithm limiting clients to 100 requests
per minute, with appropriate 429 responses when exceeded.

Resolves: #234
```

### Complex change

```
Refactor authentication to use JWT tokens

Replace session-based auth with stateless JWT tokens to enable
horizontal scaling. Sessions required sticky load balancing which
limited our deployment options.

Key changes:
- Replace express-session with jsonwebtoken
- Add token refresh endpoint
- Migrate existing sessions during deployment

Breaking change: Clients must update to handle token refresh flow.

Resolves: #891
See also: #445, #892
```

## Formatting Checklist

When formatting a commit message:

1. Start with imperative verb (Add, Fix, Update, Remove, Refactor, etc.)
2. Keep subject ≤50 chars (hard limit: 72)
3. Capitalize first letter, no trailing period
4. If body needed, add blank line after subject
5. Wrap body lines at 72 characters
6. Focus body on motivation and context, not implementation details
7. Add issue references at the bottom