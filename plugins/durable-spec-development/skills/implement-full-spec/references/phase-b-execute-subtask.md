# Phase B — Execute a Subtask

This file is the per-subtask loop. It runs once for each filtered subtask, in stack order.

## Loop overview

```
For each subtask N in stack order:
  ┌────────────────────────────────────────────────┐
  │ 1. Set up the worktree                          │
  │ 2. Update ticket status → "in progress"         │
  │ 3. Dev Agent (one-shot, verbatim spec)          │
  │ 4. QA Agent (one-shot, "trust nothing")         │
  │      ↑ ←─── on FAIL, re-dispatch dev with feedback │
  │ 5. Reviewer Agent (one-shot)                    │
  │      ↑ ←─── on REJECT, back to Dev (cycle)      │
  │ 6. Commit (inside reviewer or by orchestrator)  │
  │ 7. Push + gh pr create --base <stack-parent>    │
  │ 8. Comment SHA + branch + PR URL on the ticket  │
  │ 9. Mark ticket complete                         │
  └────────────────────────────────────────────────┘
  advance to N+1, parent = N's branch
```

Cycle cap: 3 Dev → QA → Reviewer cycles total. Hit it → escalate, do NOT silently retry.

## Step 1: Set up the worktree

The worktree path and the parent branch come from the Phase A plan. The setup differs by Phase A mode:

### Mode A — Single PR

Worktree + branch created ONCE, at the start of the run. Reused for every subtask.

```bash
# At the start of Phase B, before any subtask:
git worktree add -b <feat-prefix>/<task-slug> ~/.claude-worktrees/<task-slug>/ main
```

For subtasks 2..N, Step 1 is a no-op — the worktree already exists, just verify it:

```bash
git -C ~/.claude-worktrees/<task-slug>/ status --short
git -C ~/.claude-worktrees/<task-slug>/ log --oneline -5
```

### Mode B — Stacked PRs

Per-subtask worktree, each branched off the prior subtask's branch.

```bash
git worktree add -b <new-branch> <worktree-path> <stack-parent-branch>
```

For subtask #1, `<stack-parent-branch>` is `main`. For every subsequent subtask, it's the prior subtask's branch.

### Mode C — Independent PRs with selective stacking

Per-subtask worktree. `<stack-parent-branch>` comes from the "Depends on" column in the Phase A plan: `main` for independent subtasks, the depended-on subtask's branch for dependent ones.

```bash
git worktree add -b <new-branch> <worktree-path> <parent-branch-from-plan>
```

### Verify (all modes)

After creating the worktree, verify the state before dispatching the dev:

```bash
git -C <worktree-path> status --short
git -C <worktree-path> log --oneline -3
```

## Step 2: Update the ticket to in-progress

Examples by tracker:

| Tracker | Status update |
|---|---|
| ClickUp | `clickup_update_task` with `status: "in progress"` |
| Linear | `update_issue` with `state: "In Progress"` |
| Jira | `transitionJiraIssue` to the in-progress transition id |
| GitHub Issue | `gh issue edit <n> --add-label "in-progress"` |

This is intentional friction — it broadcasts that work has started, useful when other humans are watching the tracker.

## Step 3: Dispatch the Dev Agent

Use a single `Agent` tool call. Pass the verbatim subtask spec, worktree path, branch name, stack-parent name, IN/OUT-of-scope partition for every remediation bullet, and the expected return format. The full skeleton is in [`prompt-templates.md#dev-agent-phase-b`](prompt-templates.md#dev-agent-phase-b).

Critical content:

- **Verbatim spec**. No summarization. Including severity, file paths + line numbers, description, impact, every remediation bullet.
- **IN/OUT-of-scope partition** for every bullet. If a bullet requires infrastructure outside the repo (creating a GitHub App, provisioning a KV namespace, deploying a sidecar), mark it OUT OF SCOPE with the proposed follow-up ticket name.
- **CLAUDE.md reference**. Do not re-list conventions. Just say "follow CLAUDE.md conventions" and trust inheritance.
- **Worktree restriction**. Explicitly say "Do not touch <operator's primary checkout path>." The agent should `cd <worktree>` and stay there.
- **Do NOT commit**. Leave changes unstaged. The orchestrator (or reviewer agent) handles commit so the message is consistent.
- **READY report format**. Files changed grouped by package, approach summary, tests added, deferred items, anything escalated.

## Step 4: Dispatch the QA Agent

After Dev returns READY, dispatch a one-shot QA. The full skeleton is in [`prompt-templates.md#qa-agent-phase-b`](prompt-templates.md#qa-agent-phase-b).

Critical content:

- **"Trust nothing — verify by reading code and running tests yourself."** Without this opener, QA tends to rubber-stamp.
- **Mental-revert clause**: "For each new test, ask: if you reverted the fix to its previous form, which assertions would fail? If none, the tests are theater. Flag that."
- **Bullet-by-bullet verification.** For each remediation bullet from the spec, find the code that addresses it, verify the implementation actually achieves the bullet's intent (not log-only, not partial).
- **Canonical checks**. The exact commands the operator expects to be green (typecheck, lint, the specific package test suites, integration tests if applicable).
- **PASSED / FAILED return format.** On FAILED, itemize: `file:line — severity — proposed remediation`. Nits-only findings → PASSED with nits noted.

On FAILED return: re-dispatch the Dev with the QA's itemized findings as additional context. This is cycle 2. Cap at 3.

## Step 5: Dispatch the Reviewer Agent

After QA PASSED, dispatch a one-shot Reviewer. For trivial tickets, combine QA and Reviewer into one agent. The skeleton is in [`prompt-templates.md#reviewer--commit-agent-phase-b`](prompt-templates.md#reviewer--commit-agent-phase-b).

Critical content:

- **Read the diff first.** Not the dev's claims, the actual diff.
- **Code-review skill**: use `superpowers:requesting-code-review` if available.
- **Manual checklist**: correctness, security, style per CLAUDE.md, no new deps, no back-compat shims, imports clean.
- **APPROVED → commit.** The reviewer is the agent that creates the commit. Conventional commit message; subject ≤72 chars; body lists what changed and why + deferred items + Closes link.
- **REJECTED → itemized list of changes needed.** Back to Dev (cycle 2/3).

## Step 6: Push the commit (and open the PR if appropriate)

After the Reviewer returns APPROVED & COMMITTED (with a SHA), the orchestrator pushes. **Whether to open the PR right now depends on the mode.**

### Mode A — Single PR

Push the commit to the shared branch. **Do not open a PR after each subtask** — Mode A opens one PR at the end of the whole run (or once, as a draft, at the start with subsequent pushes appending commits).

```bash
git -C <worktree> push -u origin <branch>
```

If a draft PR was opened at the start of the run, the push will appear as a new commit on it; no further action. If not, defer the PR open until after the last subtask is committed.

### Mode B — Stacked PRs

Push, then open a PR with `--base <stack-parent>`:

```bash
git -C <worktree> push -u origin <branch>
gh pr create \
  --base <stack-parent-branch> \
  --head <branch> \
  --title "<conventional-commit-style subject>" \
  --body "$(cat <<'EOF'
## Summary
<1–3 bullets>

## What was implemented
<bullets from the spec — IN-SCOPE only>

## Deferred (proposed follow-ups)
- <bullet> — <new-ticket-id-if-any>

## Stack position
- Base: <stack-parent>
- Next in stack: <next-subtask> (or "none — top of stack")

## Test plan
- [ ] <command 1>
- [ ] <command 2>
EOF
)"
```

`--base <stack-parent>` is what makes this PR base on the prior subtask's branch instead of `main`. GitHub auto-rebases children when the parent merges.

### Mode C — Independent PRs with selective stacking

Push, then open with `--base` set per the Phase A plan — `main` for independent subtasks, the dependency's branch for dependent ones.

```bash
git -C <worktree> push -u origin <branch>
gh pr create \
  --base <parent-branch-from-plan> \
  --head <branch> \
  --title "..." \
  --body "$(cat <<'EOF'
## Summary
<1–3 bullets>

## What was implemented
<bullets from the spec — IN-SCOPE only>

## Dependency
<"This PR is independent and bases on main." OR
 "This PR depends on PR #<N> (<subtask-id>) and bases on its branch. Merge that PR first.">

## Test plan
- [ ] <command 1>
EOF
)"
```

Be explicit in the PR body when the PR has a non-`main` base — reviewers won't intuit dependency relationships from branch names alone.

## Step 7: Close the loop on the ticket

After the commit lands (and the PR is open, if appropriate for the mode), comment on the source ticket with the addressing artifacts and mark complete.

For Mode A, the ticket comment goes up after each subtask commit, even though the PR doesn't exist yet:

```
Implemented in <full-sha> on <branch>; PR pending (Mode A: single-PR run).
```

For Mode B / Mode C:

```
Resolved in <full-sha> on <branch>, PR: <url>
```

Then update status to `complete` (or equivalent). The ticket now records SHA + branch + PR URL (or pending status, for Mode A), which lets future archaeology re-find the work.

## Step 8: Advance

The next subtask's parent depends on the mode:

| Mode | Next subtask's parent |
|---|---|
| A | Same branch as this subtask. Same worktree. |
| B | This subtask's branch (stack continues). |
| C | Looked up in the Phase A plan's "Depends on" column. |

Don't re-fetch the parent or re-derive the queue — both are already in the Phase A plan. Move on.

## Step 9 (Mode A only): Open the PR after the final subtask

For Mode A, when the last subtask in the run has been committed and pushed, open one PR covering the whole batch:

```bash
gh pr create \
  --base main \
  --head <feat-prefix>/<task-slug> \
  --title "<conventional-commit-style subject describing the whole batch>" \
  --body "$(cat <<'EOF'
## Summary
<one-sentence description of the spec being implemented>

## What was implemented
<one bullet per subtask, in commit order, each linking to the source ticket>
- <subtask-1>: <one-line description> (<ticket-url>)
- <subtask-2>: ...
- ...

## Deferred (proposed follow-ups)
- ...

## Test plan
- [ ] <command 1>
- [ ] <command 2>
EOF
)"
```

Then go back to the tracker and update each subtask's "PR pending" comment with the now-known PR URL.

## Escalations

These conditions mean STOP and report to the operator. Do not silently retry:

- **Cycle cap exceeded** (3 Dev → QA → Reviewer iterations on the same subtask). Report: current diff, the failing tests, the reviewer's last feedback, what cycle 4 might try.
- **Stack-broken conflict** (the rebase from prior subtasks introduced a real conflict the dev can't trivially resolve). Surface the conflicting hunks.
- **Spec ambiguity** (the remediation bullets contradict each other or the audit's stated impact doesn't match the proposed fix). Don't guess; ask.
- **Out-of-scope infrastructure required for the minimum credible fix** (e.g., the bullet says "create a new GitHub App" — that's an operator action, not an in-repo edit). Surface and decide together.

## Collapsing roles for smaller subtasks

The table from SKILL.md, repeated for convenience:

| Subtask signal | Pattern | Agent calls per ticket |
|---|---|---|
| Architectural change, multi-package, type changes, new infrastructure | Separate Dev, QA, Reviewer+commit | 3 |
| Single package, 2–5 files, no API change | Dev → combined QA+Reviewer+commit | 2 |
| One file, one comment, trivial fix | Single Dev+verify+commit agent | 1 |
| Cycle 2+ on any subtask | Always keep Dev separate so it can see the specific feedback | n |

Don't pre-commit to one pattern across the whole stack. Decide per subtask based on the spec's complexity.

## What this phase produces

- One commit per subtask on its own branch.
- One open PR per subtask, each based on the prior subtask's branch.
- The source ticket marked complete with SHA + branch + PR URL.
- Updated orchestrator memory: progress queue, any cycle-2 events, any deferred items captured as proposed follow-ups.

Hand off to Phase C (`phase-c-review-response.md`) once all subtasks have open PRs and you (or the user) are ready to start the review-response sweep.
