---
name: address-pr-comments
description: >
  Review and address unresolved GitHub PR comments on the current branch.
  Fetches comments from automated review tools (Claude Code Review, CodeRabbit, etc.)
  and human reviewers, filters to actionable items, creates a plan, and addresses them
  after user approval. After commit, replies to each comment on GitHub with the commit
  reference and resolves the thread. Use when the user says /address-pr-comments.
user_invocable: true
---

# Address PR Comments

Systematically review, plan, and resolve unresolved pull request comments on the current branch — in
**one interactive pass**, with you in control of when to edit and when to commit.

This skill owns the *control flow* (discover → plan → get approval → address → let you review → reply
and resolve). The *mechanics* — how to fetch all three comment sources, classify them, reply, resolve
threads, and re-request the right reviewers — live in a shared reference so they stay consistent with
the other PR skills in this plugin:

**Read `${CLAUDE_PLUGIN_ROOT}/references/pr-review-mechanics.md` first** (if that path doesn't
resolve, it's at the plugin root, two levels up from this skill:
`../../references/pr-review-mechanics.md`). The phases below tell you *when* to apply each section of
it; that file tells you *how*.

If you want a hands-off version that loops across multiple review rounds — committing, pushing, and
re-requesting review on its own until the reviews settle — use `pr-autopilot` instead. This skill
is the single-pass, ask-first counterpart.

## Phase 1: Discover the PR and its comments

Apply **§1 (Discover the PR)** and **§2 (Fetch all three comment sources)** of the mechanics
reference. If there's no open PR for the current branch, tell the user and stop.

Then apply **§3 (Determine what is unaddressed)** to narrow down to the threads and comments that
still need attention.

## Phase 2: Classify and filter

Apply **§4 (Classify: actionable vs. not)**. Skip the not-actionable items.

When a comment is ambiguous — it might be actionable but you're not sure — include it in the plan
marked "needs clarification" so the user can decide. (That's this skill's interactive answer to the
ambiguity question the reference leaves to the caller.)

## Phase 3: Present the plan

Show the user a numbered list. For each actionable comment include:

1. **File and location** — file path and line number
2. **Reviewer** — who left it (note if it's an automated tool)
3. **Comment** — the text, abbreviated if long
4. **Proposed fix** — what you intend to do

Example format:
```
## Plan to address 4 PR comments

### 1. lib/data/user_repo.dart:42
**Reviewer:** coderabbitai[bot]
**Comment:** "Consider using DB.users constant instead of hardcoded string"
**Proposed fix:** Replace `'users'` with `DB.users`

### 2. lib/ui/pages/profile_page.dart:118
**Reviewer:** jsmith
**Comment:** "This widget tree is getting deep — extract the card into a private widget"
**Proposed fix:** Extract the card subtree into a `_ProfileCard` widget class

---

### Skipped (not actionable):
- **@jsmith** (profile_page.dart): "Looks good overall!" — praise
- **@coderabbitai[bot]** (general): summary comment — informational
```

Then ask: **"Does this plan look right? Should I proceed, adjust anything, or skip any items?"**

Wait for explicit approval before making changes. This gate is the point of this skill — don't skip
it. (The autonomous `pr-autopilot` skill is the one that proceeds without asking.)

## Phase 4: Address the comments

Work through each approved item:

1. Read the relevant file and understand the surrounding context.
2. Make the change as described in the plan.
3. After all changes, run the project's linter/formatter if applicable (e.g. `flutter analyze` +
   `dart format .` for Flutter, or whatever the project uses).
4. Track which comment maps to which file change.

Group related comments that touch the same file or function — address them together in one pass
rather than repeatedly re-reading the same code.

## Phase 5: User review

After all changes are complete:

1. Summarize what changed, mapping each plan item to the actual change made.
2. Let the user review the diff.
3. **Do NOT commit automatically** — the user decides when to commit.
4. When the user commits (or asks you to commit), capture the commit hash.

## Phase 6: Reply, resolve, and re-request

Once the commit exists, apply **§5 (Reply and resolve)** to reply `Addressed in <hash>` on each
addressed thread and resolve the inline threads, then apply **§6 (Re-request review)** to ping only
the bots whose change requests you actually addressed, using each bot's correct trigger.

### After all replies are posted

Tell the user which comments were replied to, which bots (if any) were asked to re-review, and the PR
URL so they can verify.
