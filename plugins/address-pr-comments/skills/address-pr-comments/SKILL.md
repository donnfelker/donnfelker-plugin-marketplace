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

Systematically review, plan, and resolve unresolved pull request comments on the current branch.

## Phase 1: Discover the PR and Its Comments

### Get the PR

```bash
gh pr view --json number,url,headRefName,baseRefName
```

If this fails, the current branch has no open PR. Tell the user and stop.

### Fetch PR review comments

Get all review comments (inline code comments from reviews):

```bash
gh pr view --json reviews,reviewThreads
```

If `reviewThreads` is not available, fall back to:

```bash
gh pr view --json comments,reviews
```

Also fetch inline review comments via:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

This returns all inline review comments with `path`, `line`, `body`, `user.login`, `html_url`, `id`, and `in_reply_to_id`. Comments with `in_reply_to_id` are replies in a thread — group them by that field.

### Fetch general PR conversation comments

These are top-level comments on the PR (not inline code review comments):

```bash
gh pr view --json comments --jq '.comments'
```

### Determine which comments are unresolved

Use the `gh pr view` output to identify unresolved threads. If the CLI output includes thread resolution status, use that. Otherwise, treat any inline review comment thread that has no reply containing "Addressed" as unresolved.

For general PR comments, treat them as unresolved unless there is a reply indicating the comment was addressed.

## Phase 2: Classify and Filter

Not every comment needs a code change. Read each comment and classify it:

**Actionable — address these:**
- Requests for a specific code change ("use a constant here", "add null check", "rename this")
- Bug reports or logic issues ("this will fail when X is null", "off-by-one error")
- Style or formatting requests ("add trailing comma", "rename variable to camelCase")
- Suggestions from automated tools (CodeRabbit, Claude Code Review) that request concrete changes

**Not actionable — skip these:**
- Praise or acknowledgment ("Nice!", "LGTM", "Good catch")
- Open-ended questions ("Why did you choose this approach?")
- Discussions or opinions without a clear ask ("We might want to consider...")
- Informational comments ("FYI, this module was refactored last week")
- Summary comments from bots (CodeRabbit walkthrough, review summary headers)

When a comment is ambiguous — it might be actionable but you're not sure — include it in the plan marked as "needs clarification" so the user can decide.

## Phase 3: Present the Plan

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

Wait for explicit approval before making changes.

## Phase 4: Address the Comments

Work through each approved item:

1. Read the relevant file and understand the surrounding context
2. Make the change as described in the plan
3. After all changes, run the project's linter/formatter if applicable (e.g., `flutter analyze` + `dart format .` for Flutter projects, or whatever the project uses)
4. Track which comment maps to which file change

Group related comments that touch the same file or function — address them together in one pass rather than repeatedly re-reading the same code.

## Phase 5: User Review

After all changes are complete:

1. Summarize what was changed, mapping each plan item to the actual change made
2. Let the user review the diff
3. Do NOT commit automatically — the user decides when to commit
4. When the user commits (or asks you to commit), capture the commit hash

## Phase 6: Reply and Resolve on GitHub

After the commit exists, reply to each addressed comment and resolve the thread.

### Reply format

```
Addressed in [`<short-hash>`](<commit-url>)
```

Where `<short-hash>` is the first 7 characters and `<commit-url>` is the full commit URL:
`https://github.com/{owner}/{repo}/commit/{full-hash}`

### For inline review comments

Reply to the review comment thread:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -f body='Addressed in [`abcdef0`](https://github.com/owner/repo/commit/abcdef0123456789)'
```

The `comment_id` is the `id` of the first comment in the thread (the one that started the review thread).

Then resolve the thread. Use `gh pr review` or the REST API to mark the thread as resolved:

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id} \
  -X PATCH \
  -f body="$(gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id} --jq '.body')"
```

If `gh` supports resolving threads directly (e.g., `gh pr thread resolve`), prefer that. Otherwise, the reply with "Addressed" is sufficient — the reviewer can resolve on their end.

### For general PR comments

Reply in the PR conversation:

```bash
gh pr comment {number} --body 'Addressed [this comment](comment-url) in [`abcdef0`](https://github.com/owner/repo/commit/abcdef0123456789)'
```

Include a link back to the original comment so the reply has clear context.

### After all replies are posted

Tell the user which comments were replied to and provide the PR URL so they can verify.
