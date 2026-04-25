---
name: code-review
description: "Multi-reviewer code-review orchestrator that runs a comprehensive review, a security review, a Codex review, and a Codex adversarial review in parallel, then merges and prioritizes their findings into one timestamped report. Use whenever the user asks for 'a thorough code review,' 'review my changes,' 'multi-reviewer review,' 'run all the reviews,' 'code review with security,' 'pre-PR review,' wants more than a single perspective on pending changes, or invokes the code-review orchestrator. Prefer this over a single reviewer whenever the user wants real coverage before opening a PR."
---

# Code Review Orchestrator

You are the **review lead**. Your job is to coordinate up to four specialized reviewers in parallel, merge their findings into one prioritized report, and save that report to disk so the user (and future-you) can refer back to it.

**Announce at start:** "I'm using the code-review orchestrator skill — let me confirm which reviewers to run."

## Why this skill exists

Single-reviewer passes miss things. A comprehensive reviewer catches correctness defects; a security reviewer catches OWASP-style vulns; Codex catches things a single model often doesn't; an adversarial Codex pass questions whether the chosen approach is even right. Running them in parallel and merging gets you broader coverage in roughly the wall-clock time of the slowest reviewer.

The merged report is saved to a timestamped file so you can re-run later and `diff` against the previous report to see what changed.

## Process flow

```
1. Sanity-check git state
2. Ask which reviewers to run (AskUserQuestion, multi-select)
3. Spawn one subagent per selected reviewer — in parallel, single message
4. Wait for ALL subagents (no partial synthesis)
5. Merge + prioritize findings (conservative dedupe)
6. Write timestamped report to CWD
7. Tell the user where the file is and present top findings
```

## Step 1: Sanity-check git state

Run, in parallel:
- `git rev-parse --is-inside-work-tree` — if it errors, tell the user this skill needs a git repo and stop.
- `git status --short --untracked-files=all`
- `git diff --shortstat` and `git diff --shortstat --cached`
- Resolve a base ref: try `git rev-parse --verify origin/main`; if it fails, try `origin/master`; if both fail, fall back to `HEAD~1` and warn the user.
- `git diff --shortstat <base>...HEAD` to size up the branch diff.

If there is no working-tree change AND no branch diff vs base AND no untracked files, tell the user there is nothing to review and stop.

Capture the resolved base SHA — you'll need it for the report header.

## Step 2: Ask which reviewers to run

Use `AskUserQuestion` exactly once, multi-select, with all four options pre-described as recommended together. Do not assume — let the user pick.

```
question: "Which reviewers should run? All four are recommended for a pre-PR pass."
header: "Reviewers"
multiSelect: true
options:
  - Comprehensive review (review-guidelines rubric)
  - Security review
  - Codex review
  - Codex adversarial review
```

If the user selects zero reviewers, stop and tell them there's nothing to do.

## Step 3: Spawn reviewer subagents in parallel

**Critical:** Launch every selected reviewer in a single message with multiple `Agent` tool calls so they run concurrently. Do NOT spawn one, wait, then spawn the next — that defeats the entire point.

Use `subagent_type: "general-purpose"` for all four. Each subagent's prompt below is a template — **substitute every `<PLACEHOLDER>` with the actual value before sending the prompt**. Subagents start with no context and will not resolve placeholders themselves.

Required substitutions:
- `<CWD>` → absolute path of the current working directory (e.g. `/Users/foo/code/myrepo`)
- `<SKILL_DIR>` → absolute path of this skill's directory. Resolve this from the orchestrator's runtime: it is the directory containing the SKILL.md you are reading. If unsure, run `find ~/.claude/plugins -path '*code-review/skills/code-review/SKILL.md' -print -quit` and use its parent.
- `<BASE_SHA>` → the resolved base SHA from Step 1
- `<HEAD_SHA>` → output of `git rev-parse HEAD`

Verify each prompt contains zero `<...>` markers before dispatching.

### 3a. Comprehensive review subagent

```
description: "Comprehensive code review"
prompt:
You are performing a comprehensive code review of the pending git changes in <CWD>.

Steps:
1. Read the review rubric at: <SKILL_DIR>/references/review-guidelines.md
2. Run `git diff <BASE_SHA>...HEAD` and `git diff HEAD` to see all changes (committed-but-unmerged AND working-tree).
3. Apply the rubric strictly. Only flag what the rubric says is worth flagging.
4. For each finding, classify:
   - severity: critical | high | medium | low
   - category: system (runtime crash, broken flow) | security (vuln) | other (quality, perf, maintainability)
5. Return ONLY a JSON array of findings. Each entry:
   {
     "file": "path/to/file",
     "line": "123" or "120-145",
     "severity": "critical|high|medium|low",
     "category": "system|security|other",
     "title": "short summary, one line",
     "body": "full explanation with reasoning, scenarios that trigger it, and any suggested fix"
   }
   No preamble, no trailing commentary — just the JSON array (use `[]` if nothing).
   Do NOT summarize the body. Include enough detail that the orchestrator can paste it into a report verbatim.
```

### 3b. Security review subagent

```
description: "Security-focused review"
prompt:
You are performing a security-only review of the pending git changes in <CWD>.

Steps:
1. Run `git diff <BASE_SHA>...HEAD` and `git diff HEAD`.
2. Look only for security issues introduced by this change. Use OWASP Top 10 as a checklist:
   command/SQL/template injection, XSS, SSRF, IDOR, path traversal, broken authn/authz,
   insecure deserialization, secret leakage, weak/misused crypto, race conditions on auth
   state, unvalidated redirects, mass assignment, sensitive data in logs.
3. Skip pre-existing issues that the diff didn't touch.
4. Return ONLY a JSON array of findings. Same schema as above. Use category="security" for all entries.
   Severity: critical (exploitable, data exposure, auth bypass), high (clear vuln, exploitation needs preconditions),
   medium (defense-in-depth gap), low (hardening recommendation).
   No preamble — just the JSON array (use `[]` if nothing).
```

### 3c. Codex review subagent

```
description: "Codex review (foreground)"
prompt:
You are running a Codex code review and capturing its full output verbatim.

Steps:
1. Run this exact bash command and capture stdout:
   node "$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs" review --wait
2. If the codex-companion script does not exist, return:
   {"error": "codex plugin not installed", "raw": ""}
3. On success, return JSON of the form:
   {"error": null, "raw": "<full stdout verbatim, do NOT trim or summarize>"}
4. Do not paraphrase. Do not edit. Do not extract findings — the orchestrator will parse the raw output.
```

### 3d. Codex adversarial review subagent

```
description: "Codex adversarial review (foreground, must wait)"
prompt:
You are running a Codex ADVERSARIAL review (questions design, assumptions, tradeoffs) and capturing its full output verbatim. You MUST wait for the result — do not background it.

Steps:
1. Run this exact bash command in the foreground and capture stdout:
   node "$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs" adversarial-review --wait
2. If the codex-companion script does not exist, return:
   {"error": "codex plugin not installed", "raw": ""}
3. On success, return JSON of the form:
   {"error": null, "raw": "<full stdout verbatim>"}
4. Do not paraphrase or edit.
```

After spawning, wait for **every** subagent to return before moving on. Do not start writing the report from partial results.

## Step 4: Merge findings

Combine the JSON arrays from the comprehensive and security subagents. The two Codex outputs come back as raw text — keep them as raw blocks; do NOT try to re-parse them into the structured findings list.

### Conservative dedupe rule

Only merge two findings when **all of the following match**:
- same `file`
- overlapping or identical `line` range
- titles are essentially the same issue (paraphrase-equivalent)

When you merge, keep the most detailed body and add a `flagged_by` list naming each source reviewer (`comprehensive`, `security`). When in doubt, keep the findings separate — the user picked "dedupe only obvious exact matches; otherwise keep separate" for a reason: false dedupe hides multi-perspective signal.

### Priority sort

Order findings into these tiers, top to bottom:

1. `category=system` — runtime crashes, broken critical flow
2. `category=security` — vulns, secret leakage
3. `category=other` — quality, perf, maintainability
4. **Codex adversarial review** — its own dedicated section at the bottom, raw verbatim. Adversarial review questions design choices, not defects, so it doesn't compete for the same priority slots.

Within each of tiers 1–3, sort by `severity`: critical → high → medium → low.

The non-adversarial Codex review's raw output goes into a "Raw Reviewer Output" appendix. If you can identify clearly distinct, structured findings inside the Codex raw output, you may also reference them inline in the merged tiers — but only when they are unambiguous and the file/line is explicit. Otherwise leave them in the raw appendix.

## Step 5: Write the timestamped report

Compute a filename in the **current working directory**:

```
code-review-<YYYY-MM-DD-HHMMSS>.md
```

Use `date +%Y-%m-%d-%H%M%S` for the timestamp (local time is fine; just be consistent).

The file MUST start with this exact header (substitute placeholders):

```markdown
# Code Review Report

> **Created by:** code-review skill (donnfelker-plugins → code-review plugin)
> **Created At:** <ISO 8601 datetime, e.g. 2026-04-25T14:32:11-05:00>
> **Working Directory:** <absolute CWD>
> **Git Base:** <resolved base ref> (`<base SHA>`)
> **HEAD:** `<HEAD SHA>`
> **Reviewers Run:** <comma-separated, e.g. comprehensive, security, codex, codex-adversarial>

---
```

Then these sections in order:

1. `## Summary`
   - Total findings, broken down by severity (critical/high/medium/low) and by category (system/security/other).
   - One-line note about whether the codex adversarial review raised concerns.
2. `## Findings (Prioritized)`
   - One subsection per finding, in the priority order above.
   - Each subsection: `### [SEV][CAT] <title>` then a body that includes file:line, full body, and a `Flagged by:` line.
   - **Do NOT summarize.** Include the full body verbatim.
3. `## Codex Adversarial Review`
   - Full raw stdout from the adversarial reviewer, fenced as a code block. No summarization.
4. `## Raw Reviewer Output`
   - One sub-section per reviewer that ran. Each contains the verbatim return value (JSON array or raw stdout). This is the audit trail — do not omit it.

## Step 6: Present results to the user

After writing the file, in your text response to the user:

1. State the absolute file path written.
2. Show the summary counts (severity × category, plus adversarial concerns yes/no).
3. List the top 3–5 most severe findings inline (just `[SEV][CAT] file:line — title`).
4. If a previous `code-review-*.md` exists in CWD, mention it and suggest:
   `diff <previous> <new>` to see what changed.
5. Remind the user: the full detail is in the report file — they can re-open it any time.

Keep the user-facing message tight — the file is the source of truth.

## Edge cases & failure modes

- **Codex plugin not installed** — the codex subagents will return `{"error": "codex plugin not installed"}`. Note this in the report's Summary section ("Codex review skipped: plugin not installed") and continue with the other reviewers' results. Do not fail the whole run.
- **A subagent times out or crashes** — record the failure under "Raw Reviewer Output" with an explanatory note, continue with the others.
- **No findings from anyone** — still write the report file (with empty findings sections) so the user has the audit trail. The summary should clearly say "No issues found." This is a real result, not a no-op.
- **User runs the skill twice in the same minute** — the seconds in the timestamp prevent collisions. If you somehow get a collision anyway, append `-2` and increment.
- **Working directory is not writable** — fall back to `$TMPDIR` and tell the user where it actually went.

## What NOT to do

- Don't summarize findings before writing the report. Save full detail; summarize only in the user-facing message.
- Don't background the adversarial review. Always pass `--wait`. The user explicitly required this.
- Don't merge findings aggressively. Conservative dedupe only — if you're not sure two findings are the same, leave them separate.
- Don't skip writing the report file even if findings are empty — the audit trail matters.
- Don't run the reviewers serially. They are independent and must run in parallel.
