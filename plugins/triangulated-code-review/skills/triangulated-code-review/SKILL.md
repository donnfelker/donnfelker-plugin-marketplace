---
name: triangulated-code-review
description: "Triangulated multi-reviewer code-review orchestrator that runs a comprehensive review, a security review, a Codex review, and a Codex adversarial review in parallel, then merges and prioritizes their findings into one timestamped report. Borrows from research methodology: triangulating a finding against multiple independent reviewers reduces blind spots. Use whenever the user asks for 'a thorough code review,' 'triangulated review,' 'review my changes,' 'multi-reviewer review,' 'run all the reviews,' 'code review with security,' 'pre-PR review,' wants more than a single perspective on pending changes, or invokes the triangulated-code-review orchestrator. Prefer this over a single reviewer whenever the user wants real coverage before opening a PR."
---

# Triangulated Code Review Orchestrator

You are the **review lead**. Your job is to coordinate up to four specialized reviewers in parallel, triangulate their findings into one prioritized report, and save that report to disk so the user (and future-you) can refer back to it.

**Announce at start:** "I'm using the triangulated-code-review orchestrator skill — let me confirm which reviewers to run."

## Why this skill exists

Single-reviewer passes miss things. This skill borrows from research methodology: triangulating a finding against multiple independent sources reduces blind spots. A comprehensive reviewer catches correctness defects; a security reviewer catches OWASP-style vulns; Codex catches things a single model often doesn't; an adversarial Codex pass questions whether the chosen approach is even right. Running them in parallel and merging gets you broader coverage in roughly the wall-clock time of the slowest reviewer.

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
- `<SKILL_DIR>` → absolute path of this skill's directory. Resolve this from the orchestrator's runtime: it is the directory containing the SKILL.md you are reading. If unsure, run `find ~/.claude/plugins -path '*triangulated-code-review/skills/triangulated-code-review/SKILL.md' -print -quit` and use its parent.
- `<BASE_SHA>` → the resolved base SHA from Step 1
- `<HEAD_SHA>` → output of `git rev-parse HEAD`

Verify each prompt contains zero `<...>` markers before dispatching.

### 3a. Comprehensive review subagent

```
description: "Comprehensive code review"
prompt:
You are performing a comprehensive code review of the pending git changes in <CWD>.

Steps:
1. Read the review rubric at: <SKILL_DIR>/references/review-guidelines.md — it tells you what counts as a bug, how to write a comment, and how to acquire the diff. Apply the rubric strictly.
2. Acquire the diff using the rubric's "Getting the diff" section. Prefer `mcp__conductor__GetWorkspaceDiff` (start with `stat: true`, then pull specific files). If that tool is unavailable, fall back to:
   - `git diff <BASE_SHA>...HEAD` (committed-but-unmerged)
   - `git diff HEAD` (working-tree, staged + unstaged)
   Use the `<BASE_SHA>` value from this prompt directly — the orchestrator has already resolved the base ref. Ignore the rubric's `git merge-base origin/main HEAD` recipe (it's for standalone use).
3. Only flag what the rubric says is worth flagging. Output every qualifying finding (do not stop at the first one).
4. For each finding, classify:
   - severity: critical | high | medium | low
   - category: system (runtime crash, broken flow) | security (vuln) | other (quality, perf, maintainability)
5. **Output format is overridden by this prompt** (the rubric notes this). Return ONLY a JSON array of findings — do NOT post inline `mcp__conductor__DiffComment` comments; the orchestrator merges findings into a single report instead. Each entry:
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

This subagent delegates to `/security-review`, which is a **built-in slash command shipped inside the Claude Code CLI binary itself** — it is not a plugin and is not separately installable. It is always present when running under Claude Code. The only failure case is the skill running under a non-Claude-Code runtime (Copilot CLI, Gemini CLI, Codex CLI, etc.), where the built-in does not exist.

```
description: "Security review (delegates to the built-in /security-review)"
prompt:
You are running a security-only review of the pending git changes in <CWD> by delegating to `/security-review`.

Context for you, the subagent: `/security-review` is a built-in slash command that ships inside the Claude Code CLI binary. It is not a plugin and not separately installable — under Claude Code it is always available. Do NOT instruct the user to install it; if it's missing, the runtime is not Claude Code and there is nothing the user can install to fix that within this skill.

Steps:
1. Attempt to invoke the `security-review` skill directly via the `Skill` tool with `skill: "security-review"`. Do NOT try to detect availability by parsing system-reminder text — that's brittle. The invocation itself is the probe.
2. If the invocation succeeds:
   a. Let it run to completion and capture its full report text.
   b. Extract its findings into a JSON array using the schema below. Use `category: "security"` for every finding. Map the skill's severity language to: critical (exploitable, data exposure, auth bypass), high (clear vuln, exploitation needs preconditions), medium (defense-in-depth gap), low (hardening recommendation).
   c. Skip any pre-existing issues the diff didn't introduce.
   d. Return JSON of the form:
      {"error": null, "findings": [ ...array of finding objects... ], "raw": "<full skill output verbatim>"}
3. If the invocation fails (Skill tool unavailable, "skill not found"-style error, or any other error), return:
   {
     "error": "security-review not available in this runtime",
     "runtime_hint": "`/security-review` is a built-in slash command that ships inside the Claude Code CLI binary. It is not separately installable. This error means the triangulated-code-review skill is running under a non-Claude-Code runtime (Copilot CLI, Gemini CLI, Codex CLI, etc.). To use the security reviewer, re-run this skill under Claude Code (https://claude.com/claude-code).",
     "findings": [],
     "raw": ""
   }

Finding schema (same as the comprehensive reviewer):
{
  "file": "path/to/file",
  "line": "123" or "120-145",
  "severity": "critical|high|medium|low",
  "category": "security",
  "title": "short summary, one line",
  "body": "full explanation with reasoning, scenarios that trigger it, and any suggested fix"
}

Return ONLY the JSON object — no preamble, no trailing commentary.
```

### 3c. Codex review subagent

This subagent runs the same underlying script that the `/codex:review` slash command runs. (Codex slash commands set `disable-model-invocation: true`, so a subagent cannot invoke them as commands — running the script directly is the supported path and produces identical output.)

```
description: "Codex review (runs the /codex:review companion script in foreground)"
prompt:
You are running the same review that `/codex:review` runs, by invoking its underlying companion script. The `/codex:review` slash command itself sets `disable-model-invocation: true`, so calling the script directly is the supported way to run it from a subagent.

Steps:
1. Resolve the path to the codex-companion script. Try these locations in order, using the first one that exists:
   a. `$CLAUDE_PLUGIN_ROOT/scripts/codex-companion.mjs` (if `CLAUDE_PLUGIN_ROOT` is set in the environment)
   b. The result of `find "$HOME/.claude/plugins" -path '*/codex/scripts/codex-companion.mjs' -print -quit 2>/dev/null`
   If both lookups come up empty, treat as not-installed and skip to step 3 with the error response.
2. Run this exact bash command in the foreground using the resolved path (the orchestrator needs the result before it can write the report — do NOT background):
   node "<resolved-path>" review --wait
3. If the script could not be located, return:
   {
     "error": "codex plugin not installed",
     "install_hint": "The Codex review delegates to the `codex-companion.mjs` script that ships with the Codex plugin (the same script `/codex:review` runs). Install the Codex plugin from its marketplace (see https://github.com/openai/codex for the current install path) and run `/codex:setup` to authenticate.",
     "raw": ""
   }
4. On success, return JSON of the form:
   {"error": null, "raw": "<full stdout verbatim, do NOT trim or summarize>"}
5. Do not paraphrase. Do not edit. Do not extract findings — the orchestrator will parse the raw output.
```

### 3d. Codex adversarial review subagent

Same delegation pattern as 3c: runs the underlying script for `/codex:adversarial-review`.

```
description: "Codex adversarial review (runs the /codex:adversarial-review companion script in foreground, must wait)"
prompt:
You are running the same adversarial review that `/codex:adversarial-review` runs, by invoking its underlying companion script. (The slash command sets `disable-model-invocation: true`; the script is the supported entry point from a subagent.) The adversarial pass questions design, assumptions, and tradeoffs — not just defects. You MUST wait for the result — do not background it.

Steps:
1. Resolve the path to the codex-companion script. Try these locations in order, using the first one that exists:
   a. `$CLAUDE_PLUGIN_ROOT/scripts/codex-companion.mjs` (if `CLAUDE_PLUGIN_ROOT` is set in the environment)
   b. The result of `find "$HOME/.claude/plugins" -path '*/codex/scripts/codex-companion.mjs' -print -quit 2>/dev/null`
   If both lookups come up empty, treat as not-installed and skip to step 3.
2. Run this exact bash command in the foreground using the resolved path:
   node "<resolved-path>" adversarial-review --wait
3. If the script could not be located, return:
   {
     "error": "codex plugin not installed",
     "install_hint": "The adversarial review delegates to the `codex-companion.mjs` script that ships with the Codex plugin (the same script `/codex:adversarial-review` runs). Install the Codex plugin from its marketplace (see https://github.com/openai/codex for the current install path) and run `/codex:setup` to authenticate.",
     "raw": ""
   }
4. On success, return JSON of the form:
   {"error": null, "raw": "<full stdout verbatim>"}
5. Do not paraphrase or edit.
```

After spawning, wait for **every** subagent to return before moving on. Do not start writing the report from partial results.

## Step 4: Merge findings

Return shapes by subagent (the hint fields are present **only when `error != null`**):
- **Comprehensive** — bare JSON array of findings.
- **Security** — JSON object `{error, runtime_hint?, findings, raw}`. On success, use `findings` (the structured list) and keep `raw` for the audit-trail appendix. On error (`error != null`), the security review is treated as skipped — record the `error` and the verbatim `runtime_hint` in the report's Summary section under "Security review skipped" and skip merging. (`/security-review` is built into the Claude Code CLI, so the error only fires under non-Claude-Code runtimes.)
- **Codex** and **Codex adversarial** — JSON object `{error, install_hint?, raw}`. On success, keep `raw` for the appendix and (for adversarial) the dedicated section. On error, note "Codex review skipped" in Summary with the verbatim `install_hint` and continue.

Combine the JSON findings arrays from the comprehensive subagent and the security subagent's `findings` (when present). Keep all Codex `raw` outputs as raw text blocks — do NOT try to re-parse them into the structured findings list. The non-adversarial Codex output lives only in the "Raw Reviewer Output" appendix unless you promote individual items inline per the rule below.

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
triangulated-code-review-<YYYY-MM-DD-HHMMSS>.md
```

Use `date +%Y-%m-%d-%H%M%S` for the timestamp (local time is fine; just be consistent).

The file MUST start with this exact header (substitute placeholders):

```markdown
# Triangulated Code Review Report

> **Created by:** triangulated-code-review skill (donnfelker-plugins → triangulated-code-review plugin)
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
4. If a previous `triangulated-code-review-*.md` exists in CWD, mention it and suggest:
   `diff <previous> <new>` to see what changed.
5. Remind the user: the full detail is in the report file — they can re-open it any time.

Keep the user-facing message tight — the file is the source of truth.

## Edge cases & failure modes

- **Codex plugin not installed** — the Codex subagents will return `{"error": "codex plugin not installed", "install_hint": "..."}`. Note this in the report's Summary section ("Codex review skipped: plugin not installed") along with the verbatim `install_hint`, and continue with the other reviewers' results. Do not fail the whole run.
- **security-review not available in this runtime** — `/security-review` is a built-in slash command inside the Claude Code CLI binary; it is not a plugin and not separately installable. The only time the security subagent returns an error is when this skill is running under a non-Claude-Code runtime (Copilot CLI, Gemini CLI, Codex CLI, etc.). The subagent will return `{"error": "security-review not available in this runtime", "runtime_hint": "..."}`. Note this in the Summary section ("Security review skipped: not running under Claude Code") with the verbatim `runtime_hint`, and continue. Do NOT fall back to an inline OWASP pass — the user explicitly delegated to `/security-review` — and do NOT tell the user to install it; there is nothing to install.
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
