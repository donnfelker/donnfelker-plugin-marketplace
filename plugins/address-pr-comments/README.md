# address-pr-comments

A Claude Code plugin that helps systematically review, plan, address, and resolve unresolved pull request comments on the current branch.

## What it does

The `address-pr-comments` skill walks through the open PR for the current branch, fetches inline review comments and general PR comments (from human reviewers and automated tools like CodeRabbit or Claude Code Review), filters out non-actionable items (praise, questions, summaries), and produces a plan. After you approve the plan, it makes the code changes, lets you commit, then replies to each comment on GitHub with the commit reference and resolves the thread.

## Installation

Install via the marketplace:

```bash
/plugin marketplace add donnfelker/donnfelker-plugin-marketplace
/plugin install address-pr-comments
```

## Usage

Invoke the skill with:

```
/address-pr-comments
```

Run this from a branch that has an open PR. The skill will discover the PR automatically via `gh pr view`.

## Prerequisites

- [`gh` CLI](https://cli.github.com/) installed and authenticated
- An open pull request on the current branch
- Permissions to comment on and resolve threads in the PR

## Flow

```mermaid
flowchart TD
    Start([User runs /address-pr-comments]) --> Discover[Phase 1: Discover PR & Fetch Comments]
    Discover --> HasPR{Open PR<br/>on branch?}
    HasPR -->|No| StopNoPR([Stop: no PR found])
    HasPR -->|Yes| Fetch[Fetch inline review comments<br/>+ general PR comments<br/>+ resolution status]

    Fetch --> Classify[Phase 2: Classify & Filter]
    Classify --> Split{Comment type?}
    Split -->|Actionable| Actionable[Add to plan]
    Split -->|Praise / Question / Summary| Skipped[Mark as skipped]
    Split -->|Ambiguous| NeedsClarify[Mark 'needs clarification']

    Actionable --> Plan[Phase 3: Present Plan to User]
    Skipped --> Plan
    NeedsClarify --> Plan

    Plan --> Approve{User approves?}
    Approve -->|No / adjust| Plan
    Approve -->|Yes| Address[Phase 4: Address Comments]

    Address --> Edit[Read file, make change<br/>group by file when possible]
    Edit --> Lint[Run linter / formatter]
    Lint --> Review[Phase 5: User Review of Diff]

    Review --> Commit{User commits?}
    Commit -->|Not yet| Review
    Commit -->|Yes| CaptureHash[Capture commit hash + URL]

    CaptureHash --> Reply[Phase 6: Reply & Resolve on GitHub]
    Reply --> ReplyInline[Reply to inline threads:<br/>'Addressed in commit-hash']
    Reply --> ReplyGeneral[Reply to general comments<br/>with commit link]
    ReplyInline --> Resolve[Resolve threads]
    ReplyGeneral --> Resolve
    Resolve --> Done([Report PR URL to user])
```

## Phases

1. **Discover** — find the PR for the current branch and fetch all comments
2. **Classify** — separate actionable comments from praise/questions/summaries
3. **Plan** — present a numbered plan with file, reviewer, comment, proposed fix
4. **Address** — apply the approved changes, run linters
5. **Review** — let the user review the diff and commit on their own terms
6. **Reply & Resolve** — post `Addressed in <commit>` replies and resolve threads

## Notes

- The skill never commits automatically — you decide when and how.
- Ambiguous comments are surfaced in the plan as `needs clarification` rather than silently skipped.
- Automated bot summaries (e.g., CodeRabbit walkthroughs) are treated as informational, not actionable.

## License

MIT
