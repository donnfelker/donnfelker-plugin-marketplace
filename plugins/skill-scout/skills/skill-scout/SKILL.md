---
name: skill-scout
description: Scouts an agent conversation for skill opportunities and produces a markdown report of recommended new skills and edits to existing ones, then hands off to /skill-creator or edits the affected SKILL.md directly. Use this skill when the user says "skill scout", "scout this conversation", "scout for skills", "audit this conversation for skills", "what skills would have helped here", "extract skills from this chat", or "any skill gaps from this session". Also use it to mine a PAST session — "recommend skills from a previous conversation", "scout my last session", "what skills would have helped in that earlier session" — in which case it scans saved transcripts under ~/.claude/projects/. Looks for five signals: manual workflows worth packaging, skill output that had to be corrected, repeated user corrections, reusable multi-step research, and skill content to simplify or remove. To draft skills see /skill-creator; to verify quality see /plugin-dev:skill-reviewer.
---

# Skill Scout

Scout an agent conversation for skill opportunities before the lessons evaporate.

## When to use this skill

Trigger when the user asks for a retrospective on the agent conversation itself — extracting skills from it, finding skill gaps, learning from how the session went. Do **not** trigger for general code retrospectives, work summaries, or PR descriptions. This skill is specifically about turning conversation behavior into reusable skill content.

## The process

1. **Source the conversation** — current one by default, or a past `.jsonl` transcript under `~/.claude/projects/` when the user asks to scout a previous session
2. **Inventory available skills** — repo plugins, then user-level skills, then any marketplaces the user names
3. **Detect signals** — five categories, described below
4. **Produce a report** — structured markdown, output directly in chat
5. **Hand off** — to `/skill-creator` for new skills, or Edit the affected SKILL.md for existing ones

## Step 1 — Source the conversation

There are three ways in. Pick based on what the user asked for.

**Default — the current conversation.** Claude already has the turns in context; just read them as you would any other context — no file I/O needed. This is the common case, used whenever the user says "scout this conversation", "this session", or doesn't specify.

**Explicit past-session request.** When the user points at an earlier conversation — "recommend skills from my previous session", "scout yesterday's chat", "what skills would have helped in that earlier session" — the turns are not in context, so read them from the saved transcripts under `~/.claude/projects/`. Claude Code stores one directory per project (the working-directory path with every `/` replaced by `-`) holding one `.jsonl` per session.

Start with the **current project** unless the user clearly means a different repo:

```bash
ENCODED=$(pwd | sed 's|/|-|g')
ls -lt ~/.claude/projects/$ENCODED/*.jsonl 2>/dev/null | head -10
```

If the user means a session from **another project**, or isn't sure which project it was in, search across all of them by recency:

```bash
ls -lt ~/.claude/projects/*/*.jsonl 2>/dev/null | head -20
```

The parent directory name is the encoded project path — reverse the `-`→`/` substitution to show the user a readable repo path alongside each session's modified time, then ask which one to analyze. (Note that the most recent file for the current project is usually *this* session; skip it when the user wants a prior one.) If the user already gave a distinguishing detail — a topic, an error message, a date — and you can't tell the sessions apart from filenames alone: if the `/find-past-conversation` skill is available, it is built for exactly that recall step, so use it to pin down the right transcript and then come back here to audit it; otherwise `grep` the candidate `.jsonl` files for the detail to narrow them down before reading.

**Fallback — empty current session.** If the user invoked this in a fresh session with no substantive history and didn't name a past one, tell them there's nothing in context to audit and offer the past-session search above.

**Reading the transcript:** each line in a `.jsonl` file is a JSON object with a `type` field (`user`, `assistant`, `tool_use`, `tool_result`) and a `content` payload. To reconstruct the dialogue, focus on `user` and `assistant` turns first; pull tool calls only when a signal seems to depend on what was actually invoked. Files can be tens of thousands of lines — use Read with `offset`/`limit` and walk the file in chunks rather than trying to load it whole.

Do not silently switch sources. If you fall back to a past session, name the file you ended up reading in the report header.

## Step 2 — Inventory available skills

Build a list of skills that already exist. For each, capture name, description, path, **and origin** (described below). Origin determines whether an edit can be applied in place or has to be staged — getting it wrong means producing a suggestion that fails when the user tries to act on it.

Inventory from the following sources:

1. **Repo-local skills (origin: `repo-local`, editable).** Glob `plugins/*/skills/*/SKILL.md` and `.claude/skills/*/SKILL.md` from the repo root. These are the source of truth — edits land directly in the file via the Edit tool. If you sourced a transcript from a *different* project (Step 1's cross-project search), glob from that project's root — recovered by reversing the encoded directory name — not the current working directory, or the inventory will describe the wrong repo's skills. That project may not be a plugins repo at all; an empty result there is a valid answer (no repo-local skills), not an error.

2. **User's personal skills (origin: `user-editable`).** Glob `~/.claude/skills/*/SKILL.md`. These are the user's own skills, hand-authored not downloaded. Editable in place.

3. **Plugin caches (origin: `cache`, read-only by policy).** Glob `~/.claude/plugins/**/skills/*/SKILL.md`. These are downloaded artifacts from plugin marketplaces. Editing the cached file is pointless — the next sync overwrites it. The real source of truth is the upstream repo.

4. **Cowork / agent-environment mounts (origin: `mounted-readonly`).** If the paths exist, glob `/mnt/skills/**/SKILL.md` and `/mnt/user-data/skills/**/SKILL.md`. These are read-only mounts — write attempts return `EROFS`. Edits must be staged to a workspace file the user can re-upload through their environment's skill management UI.

5. **Other marketplaces (optional, origin: `cache`).** If you suspect a particular cached marketplace prefix is especially relevant to this conversation (e.g., the plugin family the corrected skill came from), and want to scope the audit to it, ask the user once whether to include it. Treat any results as `cache`.

**Deduplicate by canonical absolute path** (`realpath` or equivalent). The globs above can overlap; a single skill matched by more than one of them is one skill in the inventory, not two.

For each SKILL.md found, parse the YAML frontmatter for `name` and `description`. Read the full body **only** for skills implicated by Signal B (poor output), Signal C (repeated correction), or Signal E (simplification) — the body is needed to identify the section to edit and the rule to change, but loading every skill body is waste.

## Step 3 — Detect signals

There are five signal types to look for. They are not mutually exclusive — one event can match more than one. Read the full conversation before deciding what counts; signals usually only become clear in retrospect.

### Signal A — Manual workflow that could be a skill

**What it looks like:** The user walked Claude through a multi-step process step-by-step ("first do X, then Y, then verify Z"), or Claude executed a coherent multi-step workflow without skill assistance. The test is whether the workflow has a name and is likely to recur, not how many tool calls it took — a tight three-step "read config, edit, restart service" workflow is just as skill-worthy as a sprawling one.

**Why it matters:** If a workflow happened once, it will probably happen again. Capturing it as a skill means the next session does not need the same hand-holding.

**What to capture:** The triggering ask, the sequence of steps, the inputs and outputs, and any gotchas the user pointed out mid-flow.

### Signal B — Existing skill triggered but produced poor output

**What it looks like:** A skill was invoked (look for `Launching skill: X` lines or explicit `Skill` tool calls), it produced something, and the user then corrected it — *"no, do it this way"*, *"that is wrong because..."*, or a substantive rewrite of the skill's output.

**Why it matters:** This is the most actionable signal in the audit. The skill already triggers; it just needs better content. Editing an existing skill is cheaper and lower-risk than creating a new one.

**What to capture:** Which skill triggered, what it produced, what the user wanted instead, and — most importantly — the *generalizable rule* the skill should learn. Not "do exactly what we did this one time" but "in situations like this, do X".

Then check whether the rule was missing or just ignored:

- **Genuinely missing rule:** Recommend adding it as new content — a section, anti-pattern, or example. This is the simple case.
- **Rule was already there but the model ignored it:** Do not propose rewriting it louder with more MUSTs — that rarely changes behavior. Recommend converting the rule from narrative guidance into *structural enforcement*: a checklist line the model verifies before delivering output, a step in the workflow it cannot skip, or a checkpoint at the moment of decision. The rule has to reach the point where output is produced, not just live in the prose.

### Signal C — Repeated corrections from the user

**What it looks like:** The user said similar things twice or more — *"I told you not to italicize text"*, *"stop adding emoji"*, *"use the existing pattern, not a new one"*. One correction is normal; two is a pattern.

**Why it matters:** A repeated correction means the agent is not internalizing something the user thinks should be obvious. That belongs somewhere durable — an existing skill, a new skill, or CLAUDE.md — so the user does not have to say it again.

**What to capture:** The rule in the user's own words if possible, the contexts where it applies, and a recommendation for where it should live. Calibrate confidence to recurrence: a rule supported by **one** correction is a tentative candidate — flag it as needing validation by future recurrence and recommend a lighter-touch edit (a note or example, not a hard MUST). A rule supported by **two or more** corrections in the same session is a strong signal — recommend a definitive edit. Skills should not accumulate permanent rules from single observations that never recur.

### Signal D — Multi-step research that could be packaged

**What it looks like:** Claude performed a sustained exploration (Grep, Glob, Read sequences) to figure out *how* to do something in this codebase — where a system lives, what pattern to follow, which config to touch — and the knowledge gained is reusable. The signal is the *reusability of the conclusion*, not the length of the search; one well-placed Grep that surfaced a non-obvious pattern still counts.

**Why it matters:** Repeated discovery is pure waste. Packaging the conclusions ("the X system lives at A/B/C and follows pattern D") into a skill or reference file means the next agent starts from the answer, not the question.

**What to capture:** The question being answered, the answer in one or two sentences, and the file paths or patterns the research uncovered.

### Signal E — Skill content that should be simplified or removed

**What it looks like:** A skill triggered, but parts of it were dead weight — sections the user skipped past, rules that contradict other rules in the same skill, "just in case" complexity that didn't apply, or a rule that was added from a single past observation and has never recurred since. Also a strong tell: the user shortcutting an elaborate workflow the skill prescribes, or telling the model to "just do X" instead of following the documented steps.

**Scope:** Signal E proposes changes *within* a skill — removing or restructuring sections, rules, examples, or workflow steps. It does **not** propose deleting or deprecating entire skills; that remains out of scope (see "What this skill explicitly does not do" at the bottom). If a whole skill seems unused or obsolete, surface that as a brief note in the report rather than a Signal E finding.

**Why it matters:** This audit is biased toward adding content — four of the five signals propose growth. Without an opposing force, skills bloat over time and the agent loads dead context every time they trigger. Healthy maintenance prunes as deliberately as it adds. A short decisive skill outperforms a long one with three half-conflicting rules.

**What to capture:** Which skill, which section or rule, and *why* it should go: never-triggered, contradicts another rule, single-instance origin, or "the user ignored this elaborate workflow and took a shortcut." If the recommendation is to remove the section or rule outright, propose the deletion explicitly. If the recommendation is to *convert* the content rather than remove it (a rule the model keeps ignoring is often better as a checklist line than gone entirely — see Signal B's structural-enforcement framing), name the target form.

### What to ignore

- Single-turn Q&A with no workflow
- One-off edits with no broader pattern
- Conversational chit-chat
- Anything the user explicitly framed as a one-off ("just for today, do X")

## Step 4 — Produce the report

**Length is earned, not assumed.** If the conversation yielded one finding, write one finding. If it yielded zero, say so in one sentence and stop. The report's value is *decisiveness* — extra prose, recaps, or meta-commentary actively hurt it. The baseline failure mode of this kind of audit is padding; resist it.

Output the report as markdown directly in the chat. Do not write it to a file unless the user asks. The heading `# Skill Scout Report` and the `## Summary` block are **mandatory and exact** — do not substitute "Conversation Skill Audit", "Skill Audit Report", or any other name; downstream tooling and human reviewers anchor on the title. The opportunity / improvement / simplification / CLAUDE.md sections that follow the Summary are **conditional** — omit any section entirely when its count is zero. A report with zero improvements should not include an empty `## Improvements to existing skills` heading; drop the whole section. Empty headings are padding by another name.

```markdown
# Skill Scout Report

**Source:** <current conversation | path to .jsonl>
**Skills inventoried:** N skills across M plugins
- Repo: <names>
- User: <names>
- Marketplaces: <names or "none requested">

## Summary
- New skills to create: X
- Existing skills to improve: Y
- Existing skills to simplify: S
- Rules for CLAUDE.md: Z

## New skill opportunities

### 1. <proposed-skill-name>
**Signal:** Manual workflow | Multi-step research
**Suggested home:** <existing plugin name, or "new plugin: X">

**What happened:**
- <2–4 bullets, with rough quotes from the conversation>

**Why it deserves its own skill:**
- <reason — likely to recur, non-obvious knowledge, codebase-specific>

**Sketch:**
- Trigger phrases: "...", "..."
- Inputs: <what the user provides>
- Output: <what the skill produces>
- Key steps: <numbered list>

(repeat for each)

## Improvements to existing skills

### 1. `<skill-name>` (in `<plugin>`)
**Signal:** Poor output | Repeated correction

**What happened:**
- <quote what the skill produced or failed to catch>

**The generalizable rule:**
- <stated as a rule the skill should follow next time>

**Suggested edit:**
- File: `<full path to SKILL.md or reference file>`
- Origin: <repo-local | user-editable | cache | mounted-readonly>
- Section: <heading or "new section">
- Change: <proposed wording, ideally a diff or quoted block>
- Form: <add new content | convert existing narrative rule to a checklist/verification step | other>
- Confidence: <high (two+ corroborations) | medium | tentative (single observation)>
- Apply via: <direct Edit (repo-local/user-editable) | send to skill author (mounted-readonly: re-upload after editing your source copy, or contact the upstream author) | PR to upstream `<repo-url>` (cache, when upstream is identifiable) | blocker: upstream unknown — ask user where this skill came from>

(repeat for each)

## Simplifications to existing skills

### 1. `<skill-name>` (in `<plugin>`)
**Signal:** Simplification

**What to remove or convert:**
- File: `<full path to SKILL.md or reference file>`
- Origin: <repo-local | user-editable | cache | mounted-readonly>
- Section/rule: <heading or rule text>
- Reason: <never triggered | contradicts <other rule> | single-instance origin that never recurred | user shortcut the prescribed workflow>
- Action: <delete | convert to checklist line | merge with <other section>>
- Apply via: <direct Edit (repo-local/user-editable) | send to skill author (mounted-readonly) | PR to upstream `<repo-url>` (cache) | blocker: upstream unknown>

(repeat for each)

## Rules for CLAUDE.md
(only if Signal C produced rules that do not fit any skill)
- <rule>

## Next step
- (a) Hand off to /skill-creator to draft new skill: <name>
- (b) Edit <skill-path> directly with the suggested change (improve or simplify)
- (c) Add rule(s) to CLAUDE.md

Which would you like?
```

If all four counts (new skills, improvements, simplifications, CLAUDE.md rules) are zero, say *"Nothing significant to extract from this conversation."* and stop — no Transcript summary, no Findings recap, no meta-commentary about the audit itself. That terse output is the correct outcome, not a failure to find something.

## Step 5 — Hand off

Wait for the user to pick. Then act on their choice using the right mechanism — these are different tools, and getting them wrong wastes the audit's value.

### (a) Create a new skill

Invoke the `skill-creator` skill via the **Skill tool** (`Skill({skill: "skill-creator"})`). Slash commands like `/skill-creator` are the user's way of triggering it; from inside another skill, the Skill tool is the model's equivalent. After invoking, prime it with the audit's sketch — pass through the proposed name, trigger phrases, inputs/outputs, and key steps — so the user does not have to re-explain anything.

If for some reason the Skill tool is unavailable, fall back to telling the user: *"Run `/skill-creator` and paste this as your first message: ..."* followed by the sketch as a code block.

### (b) Edit an existing skill

**Branch on the target skill's origin** (captured during Step 2). Edit-in-place only works for editable sources; everything else needs a different hand-off, or the recommendation looks done but is unactionable.

**Origin `repo-local` or `user-editable`:** Use the **Edit tool** directly on the target SKILL.md or reference file. The audit already identified the path, section, and proposed wording — apply that.

**Origin `mounted-readonly` (e.g., Cowork's `/mnt/skills/`) or `cache` (e.g., `~/.claude/plugins/cache/...`):** Do **not** use the Edit tool, and do **not** write any file to the user's working directory. Reasons:
- `mounted-readonly` mounts return `EROFS` on write.
- `cache` files are downloaded artifacts; the next plugin sync overwrites them.
- A file staged under the current working directory can be accidentally committed by a downstream `git add .` — even `.context/` is environment-specific and not safe to assume gitignored everywhere.

The foolproof route is **print the change in chat and tell the user where to send it**. Concretely:

1. **Print the proposed change inline.** A unified diff against the current SKILL.md, or the full new section as a code block. Make it copy-paste ready — no truncation, no "for brevity..." — the user will paste this verbatim into the source.

2. **Identify the right human to apply it.** Two cases:
   - *User is the skill's author* (they uploaded it themselves as a personal/user skill, or they maintain the upstream repo): tell them to apply the change in their source copy and re-upload (for personal skills) or commit + sync (for marketplace skills they own). If the upstream is recoverable from `.claude-plugin/plugin.json`, `marketplace.json`, or a `repository` field, name the URL.
   - *Someone else authored the skill*: tell the user to send the proposed change to the skill's author — open an issue or PR upstream if a public repo is identifiable, otherwise contact the author directly. Quote any author name or contact info found in the SKILL.md header.

3. **Never edit the mount or cache in place**, and never offer a "staged file" workaround. If the upstream cannot be identified at all (no repo metadata, no author info, no clue where the skill came from), surface that as a blocker — ask the user where the skill came from and pause until they answer. A change that the user has nowhere to apply is worse than no recommendation.

After any direct edit (origin `repo-local` or `user-editable`):
1. Run `bash validate-skills.sh` from the repo root if the script exists. This catches frontmatter and naming regressions.
2. If the change is substantial, spawn the reviewer via `Agent({subagent_type: "plugin-dev:skill-reviewer", prompt: "<context + path to edited SKILL.md>"})` and surface its findings back to the user. If the `plugin-dev:skill-reviewer` agent is not available in this environment (check the available agent types before spawning), fall back to a manual review pass against four criteria: trigger clarity (does the description reliably fire on the intended phrases without obvious over-trigger risks?), progressive disclosure (do reference files load only when needed, and is the SKILL.md under the line-count target?), internal duplication (are any rules or sections restated in multiple places?), and testable workflow steps (can each step actually be executed by a model with the listed tools?). Surface the manual review findings the same way you would surface the agent's.

For `mounted-readonly` / `cache` routes, the validation and review steps land with whoever applies the change upstream — note that in the chat output so the upstream maintainer knows to run their own checks.

### (c) Add to CLAUDE.md

Find the nearest CLAUDE.md by globbing from the current working directory upward to the repo root — but if you audited a transcript from a *different* project (Step 1's cross-project search), target that project's CLAUDE.md instead, since a rule learned there belongs in that repo, not this one. Note that some repos split rules into a root `CLAUDE.md` that `@`-imports an `AGENTS.md` — if you see `@AGENTS.md` in CLAUDE.md, the rule probably belongs in `AGENTS.md` instead. Show the proposed change first and confirm before editing. CLAUDE.md is durable and opinionated; one bad rule there outlives the agent that wrote it.

The user may pick more than one. Work through them in the order they listed.

## How to reason while drafting the report

- **Be specific.** Quote or paraphrase the conversation. *"Around when the user said 'no, use the existing helper'"* is useful; *"the skill could be better"* is not.
- **Generalize beyond this one conversation.** A skill that only helps this one task is dead weight. If you cannot articulate when it would trigger again, it should not be a skill.
- **Bias toward editing existing skills over creating new ones.** A new skill has a cold-start triggering problem; an edit to an existing skill rides on machinery already in production. Propose a new skill only when the topic genuinely does not fit anywhere existing.
- **Do not pad.** A short, decisive report beats a long, equivocating one. If only one thing is worth extracting, say one thing.

## What this skill explicitly does not do

- Edit skills without user approval — every change goes through Step 5.
- Optimize skill descriptions for triggering accuracy — use `/skill-creator` for that.
- Run evals against test cases — also `/skill-creator`'s job.
- Delete or deprecate skills — out of scope.
