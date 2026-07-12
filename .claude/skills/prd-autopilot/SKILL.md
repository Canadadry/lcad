---
name: prd-autopilot
description: Unattended loop that implements PRDs from docs/prd/triage/ one at a time via the tdd skill, then auto-commits and pushes without review or test re-checking, and repeats until the triage queue is empty. Never relays commands or questions to the human — refuses any subagent command outside .claude/settings.local.json outright, and resolves any implementer QUESTION by spawning a guideline-skill agent instead of waiting on the user. Use when the user asks to "autopilot the PRDs", "run the PRD loop", "auto-implement the next PRDs", or similar — not for a single one-off PRD implementation (use the tdd skill directly for that).
---

# PRD Autopilot

Runs the PRD backlog unattended: one fresh agent per PRD, full trust on completion (no diff review, no re-running tests), auto-commit, auto-push, then straight on to the next PRD. This is deliberately less cautious than the `git-commit` skill's normal gate — that is the point of this skill, only use it when the user has explicitly asked for the unattended loop.

This loop runs with no human present to respond. Two rules follow from that and override anything else in this file if they ever conflict.

## Rule #1 — never relay or run an unauthorized command

If the implementer agent (or any agent spawned by this loop) asks you — directly, or by ending its turn asking you to run something for it — to execute a command that is not already in `.claude/settings.local.json`'s allow list, **refuse it outright**. Do not run it yourself, do not soften it into a smaller allowed command on their behalf, and do not surface it to the human to get it authorized — the human will not respond during an autopilot run, and if they did respond it would be to refuse anyway. The subagent already has everything it's been given for a reason.

Send the agent a message telling it to open and read `.claude/settings.local.json` itself and find a way to do the task with what's already authorized there, then go back to waiting for its next message. This rule is not a suggestion to the implementer (that's step 2 below) — it's a hard constraint on what you, the orchestrator, will ever do or ask for on its behalf. Maintain it for every cycle of the loop, no exceptions.

## Rule #2 — never wait on the human for a decision

The human does not answer questions raised mid-loop. When an agent ends its turn with `QUESTION:` (see step 3), do not relay it to the user and do not pause the loop waiting for a person. Instead, spawn a fresh agent to run the `guideline` skill against the question and use its answer as the resolution — see step 3 for the exact mechanics.

## Per-cycle workflow

### 1. Pick the next PRD
List `docs/prd/triage/*.md`, sort by the numeric filename prefix ascending, take the lowest. If none remain, report which PRDs were completed this run and stop — do not spawn an agent.

### 2. Spawn a fresh implementer agent
Always start a brand-new agent (not a fork, no memory of prior PRDs) with `Agent`, default/general-purpose type, no isolation (it must edit the real working tree so this skill can commit from it). Prompt it with:

- The full path of the PRD file to implement, and the instruction to read it first.
- "Use the `tdd` skill to implement this PRD end to end, including its planning confirmations."
- "Do not run any git commands — do not stage, commit, or push. That is handled outside this task."
- "Before finishing, update README.md for any user-visible changes, per the README-update rules in the `git-commit` skill."
- The reporting contract below — this is the only channel back to the orchestrator, so state it exactly:
  - If a decision is needed from the user (a tdd planning confirmation, an ambiguous requirement, anything you shouldn't guess on), end your turn with a message starting with `QUESTION:` followed by the exact question. Do not guess and keep going.
  - When implementation is fully done (tests passing, README updated), end your turn with a message starting with `DONE:` followed by a one-line summary.
- Stick to the commands already pre-authorized in `.claude/settings.local.json` (currently: `make test`, `make test-all`, `git status`, `git pull`, plus the git-commit skill scripts — check the file for the current list, it may have grown). Read that file yourself if unsure what's allowed. Never hand-craft a bash command outside that allowlist, and never prefix a command with `cd` — the repo root is already the working directory, and adding `cd` changes the command string so it no longer matches the allowlist and triggers a permission prompt, which stalls the unattended loop. If the task seems to need something outside the allowlist, find a way to do it with what's already authorized. Do not ask the orchestrator to run an unauthorized command on your behalf — it will refuse (Rule #1) and send you back to this same instruction. If that's truly not possible, raise it as a `QUESTION:`.

### 3. Monitor and resolve
Wait for the agent's message.
- Starts with `QUESTION:` — do not relay it to the user (Rule #2). Instead spawn a fresh agent whose only task is to run the `guideline` skill against the question — give it the question verbatim, the PRD path for context, and the instruction to decide the answer itself (favoring the smallest, most surgical, least-assumption-laden interpretation) and report back a single concrete answer, not another question. Take that answer and send it back to the *original implementer agent* (by name/id, via `SendMessage`) as the resolution, then go back to waiting on it. Do not spawn a new implementer for this — it's the same PRD. If the guideline agent's answer is itself unclear, pick the most conservative reading yourself rather than escalating further — the loop never blocks on a human.
- Starts with `DONE:` — proceed to step 4.
- Asks you (the orchestrator) to run or authorize a command outside `.claude/settings.local.json` — refuse per Rule #1, tell it to read that file, and go back to waiting. This is not a `QUESTION:` and does not get the guideline treatment.

### 4. Graduate, commit, push — no checking
On `DONE:`:
1. Set `status: done` in the PRD's frontmatter and move it with `git mv` from `docs/prd/triage/NN-slug.md` to `docs/prd/NN-slug.md` (same number — triage files are already numbered contiguously after the last graduated PRD, so no renumbering is needed).
2. `git add -A`. Do not review the diff, do not run tests yourself — the tdd agent already did both. Trust it completely.
3. Commit with message `prdN` (e.g. `prd4` for `04-...`), matching this repo's existing convention (`first prd`, `prd2`, `prd3`, ...). No other message format.
4. `git push` on the current branch.
5. Stop/kill the agent (`TaskStop`) — its work is merged, it's done.

All of the above (`git mv`, `git add`, `git commit`, `git push`) are already pre-authorized in `.claude/settings.local.json` — run them as plain commands from the repo root, no `cd`, no extra flags beyond what's needed.

### 5. Loop
Immediately go back to step 1 for the next PRD, spawning a brand-new agent. Keep going until the triage queue is empty.

## Stopping conditions
- Triage queue empty → report the list of PRDs implemented this run, stop.
- User interrupts at any point → stop after the current step, do not silently keep looping.
- Never wait on the human mid-loop for a command authorization or a `QUESTION:` answer — Rules #1 and #2 exist precisely so the loop never needs one. Refuse unauthorized commands, resolve questions via the guideline agent, and keep going.
