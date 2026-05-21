# Prompt Templates

Copy-paste skeletons for the agents this skill dispatches. Replace `<angle-brackets>` with concrete values. Treat these as starting points — adapt to the specific subtask.

These templates are distilled from real multi-PR orchestration runs. The phrases marked **important** are the ones that demonstrably change agent behavior in production.

## Table of contents

- [Dev agent (Phase B)](#dev-agent-phase-b)
- [QA agent (Phase B)](#qa-agent-phase-b)
- [Reviewer + commit agent (Phase B)](#reviewer--commit-agent-phase-b)
- [Combined single-shot agent (small tickets, Phase B)](#combined-single-shot-agent-small-tickets-phase-b)
- [Phase C single-PR agent](#phase-c-single-pr-agent-for-prs-with-multiple-comments-to-address)
- [Phase A kickoff prompt](#phase-a-kickoff-prompt-for-the-orchestrator-to-surface-to-the-operator)
- [Adapting the templates](#adapting-the-templates)

Phase files reference these anchors directly — e.g., `prompt-templates.md#dev-agent-phase-b`.

---

## Dev agent (Phase B)
<a id="dev-agent-phase-b"></a>

```
You are the developer fixing **<TICKET_ID>** — <one-line description>. One-shot agent.

## Workspace
- **Worktree**: <absolute path>
- **Branch**: <branch> (off <stack-parent>)
- Always prefix Bash with `cd <worktree> && …`. Absolute paths in file ops.
- Do NOT touch <operator's primary checkout path>.

## Ticket spec (verbatim from <source>)
<paste the full spec body — severity, location, description, data flow, impact, every remediation bullet>

## Scope partition
- **(IN SCOPE)** Bullet 1: …
- **(IN SCOPE)** Bullet 2: …
- **(OUT OF SCOPE — deferred to <follow-up-ticket-name>)** Bullet 3: …
- **(OUT OF SCOPE — large new capability)** Bullet 4: …

For deferred bullets, list them in your READY report so they can become follow-up tickets.

## What to do
1. Read these files: <paths>
2. Implement bullet 1 by: <hint>
3. Implement bullet 2 by: <hint>
4. Write tests for: <cases>
5. Run: `npm test -w <package>` and `npm run typecheck && npm run lint`
6. DO NOT COMMIT. Leave changes unstaged.

## Constraints
- Follow CLAUDE.md conventions (don't re-list them — inherit).
- No back-compat shims unless explicitly justified.
- This branch stacks on <upstream tickets> — leverage their primitives.
- No --no-verify, no `git add -A`.

## READY report
Return: files changed (grouped), approach summary, test counts + key new tests,
deferred items with proposed follow-up names, anything escalated.

If you hit a real blocker, return BLOCKED with specifics. Otherwise push through.
```

---

## QA agent (Phase B)

```
You are QA verifying the developer's fix for **<TICKET_ID>**. One-shot. Return
`PASSED — <TICKET>` or `FAILED — <TICKET> — cycle N`.

## Workspace
<same as dev>

## Spec
<verbatim spec>

## What the dev reports
<paste the dev's READY message>

**Trust nothing — verify by reading code and running tests yourself.**

## Step 1 — Inspect the diff
- `git status && git diff --stat`
- Read every file the dev claims to have changed.

## Step 2 — Verify each Remediation bullet
For each bullet:
- Find the code that addresses it.
- Verify implementation actually achieves the bullet's intent (not log-only, not partial).
- Specifically: <bullet-specific checks>

## Step 3 — Check test quality
- Read the new tests' assertion bodies, not just titles.
- **Mental revert**: if the fix were reverted, which tests would fail? Confirm at least one new test would actually fail without the fix. If none, the tests are theater — flag that.
- Run the tests yourself.

## Step 4 — Run the canonical checks
<paste exact commands>

## Step 5 — Decision
PASSED with 4-6 bullet verification summary OR FAILED with itemized issues
(file:line + severity + remediation hint). Nits-only findings → PASSED with nits noted.
```

---

## Reviewer + commit agent (Phase B)

```
Combined QA + code review + commit for **<TICKET_ID>**. One-shot. Return
`APPROVED & COMMITTED` (SHA) or `REJECTED` (itemized).

## Workspace
<same>

## Context
<summary of dev's implementation + QA's findings if applicable>

## Steps
### Step 1 — Read the diff
### Step 2 — Code review (use superpowers:requesting-code-review skill if available)
### Step 3 — Manual checklist
- Correctness: <ticket-specific>
- Security: <ticket-specific>
- Style (CLAUDE.md): no comments restating WHAT; _MS suffix on duration constants; no dead code.
- No new deps.
- No back-compat shims.
- Imports / dead code clean.

### Step 4 — Run canonical checks
<paste commands>

### Step 5 — Decision

### Step 6 — On APPROVED, commit
git add <specific files by name>
git commit -m "$(cat <<'EOF'
<conventional-commit subject, ≤72 chars>

<paragraph: what changed and why>
<paragraph: deferred items + follow-ups if any>

Closes <TICKET> (<ticket-URL>).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"

No push. No --no-verify. No `git add -A`.

Return SHA + git log -1 --stat summary, OR itemized rejection.
```

---

## Combined single-shot agent (small tickets, Phase B)

```
Full Dev + verify + commit for **<TICKET_ID>**. Single-shot. Return
`APPROVED & COMMITTED` (SHA) or `BLOCKED` (reason).

## Workspace + Spec
<as above>

## What to do
1. Read <files>.
2. Implement: <bullets>.
3. Tests for <cases>.
4. Run <commands>.
5. Commit with this message template:
   fix(security): <TICKET> <short subject>
   <body>
   Closes <TICKET> (<URL>).
   Co-Authored-By: …

No push. No --no-verify. Stage by file name, never `git add -A`.
```

---

## Phase C single-PR agent (for PRs with multiple comments to address)

```
You are addressing review comments on PR #<N> for <REPO>. One-shot agent.

## Workspace
- **Worktree**: <absolute path>
- **Branch**: <branch> (already rebased on its parent's current tip)
- Always prefix Bash with `cd <worktree> && …`.
- Do NOT touch <operator's primary checkout>.

## Unresolved feedback to address

### Inline review threads
<for each unresolved thread, paste:
- Thread graphql id (for resolveReviewThread mutation)
- First-comment databaseId (for /comments/{id}/replies)
- File:line, author, full body
>

### Top-level review bodies
<for each non-empty review body, paste:
- review id
- author
- state (APPROVED / COMMENTED / CHANGES_REQUESTED)
- full body
>

### General PR comments
<for each non-bot-noise comment, paste:
- comment id
- author
- full body
>

## Classification rules
<per address-pr-comments decision matrix — actionable vs informational>
Spell out which items are actionable. Skip the rest.

## What to do

1. For each actionable item, read the file and make the change.
2. Add or update tests if applicable.
3. Run: <canonical checks>
4. Commit (default: NEW commit, no amend) with subject ≤72 chars:

   <conventional commit message template>

5. Push: `git push origin <branch>` (plain push).

6. For each addressed item, post a reply with the addressing commit:

   **Inline thread** (has resolve op):
   ```
   gh api repos/OWNER/REPO/pulls/<N>/comments/<first-comment-databaseId>/replies \
     -f body="Addressed in [\`<short>\`](https://github.com/OWNER/REPO/commit/<full>)"
   gh api graphql -f query='mutation($threadId: ID!) {
     resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } }
   }' -F threadId='<thread.id>'
   ```

   **Top-level review** (no resolve op):
   ```
   gh pr comment <N> --body "Addressed [@<reviewer>'s review](https://github.com/OWNER/REPO/pull/<N>#pullrequestreview-<review-id>) in [\`<short>\`](https://github.com/OWNER/REPO/commit/<full>):
   - **Item 1:** <change>.
   - **Item 2:** <change>.

   @<reviewer-bot-handle> re-review"
   ```

   **General comment** (no resolve op): same as top-level review reply, referencing the comment URL.

## Return format
- Each addressed item: <which source, what changed>
- Commit SHA
- Reply URLs
- Thread resolution statuses (for inline threads)
- Test output summary

## Constraints
- Worktree only.
- NO --no-verify. NEW commit, no amend (unless explicitly told to amend for a commit-message-subject-too-long item).
- Don't open PRs, don't merge, don't touch other branches.
```

---

## Phase A "kickoff" prompt (for the orchestrator to surface to the operator)

After Phase A is drafted but before exiting plan mode, present this back to the operator for sign-off:

```
## Plan: <PARENT-TICKET-ID> → <N>-PR stack

**Source**: <URL to the parent>
**Filter**: <criteria — e.g., P1/P2/P3 subtasks, status=open>
**Subtask count**: <N>

## Stack order

| # | Subtask | Branch | Worktree | Stack-parent |
|---|---|---|---|---|
| 1 | <ID> — <title> | <branch> | ~/.claude-worktrees/<slug>/ | main |
| 2 | <ID> — <title> | <branch> | ~/.claude-worktrees/<slug>/ | <prev branch> |
| ... |

## Execution parameters

- **PR strategy**: one per subtask, stacked.
- **Branching**: one branch per subtask, off the prior subtask's tip.
- **Worktrees**: yes, one per subtask.
- **Concurrency**: strict serial (the stack enforces it).
- **Cycle cap**: 3 Dev → QA → Reviewer cycles, then escalate.
- **Tier boundaries**: <continue without stopping | pause for go/no-go>.
- **Stop condition**: <only on hard block | end of each tier>.

## What I'll do when you approve

1. Create the worktree for subtask #1 off `main`.
2. Mark subtask #1 status as in-progress.
3. Dispatch the Dev → QA → Reviewer cycle.
4. Open PR #1 with base = main.
5. Advance to subtask #2 (parent = subtask #1's branch).
6. Continue through subtask #<N>.
7. Hand off to Phase C (review-response sweep) when all PRs are open.

Plan saved to ~/.claude/plans/<task-slug>.md.

OK to proceed?
```

Don't exit plan mode until the operator approves.

---

## Adapting the templates

In practice, these templates get modified in flight. Common adaptations:

1. **Collapse Dev + QA + Reviewer into one agent for small subtasks** — a single-comment-in-single-file fix doesn't warrant 3 round-trips.
2. **Drop the "tier boundary pause"** — when the operator says "don't stop until done", do a fast verification at each tier boundary and continue.
3. **Embed the Phase C reply templates into the Dev/QA agents** when those agents are also doing Phase C work — reduces round-trips and lets the agent commit + reply in one shot.

Adapt these similarly. The skeletons are a starting point, not a contract.
