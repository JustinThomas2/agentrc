---
name: file-issue
description: Turn a rough idea into a well-formed GitHub issue — clarify scope, check for duplicates, draft, then STOP for my approval before filing. Invoke explicitly with a description of the problem or idea.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[rough description]"
disable-model-invocation: true
allowed-tools: Bash(gh issue list:*), Bash(gh search issues:*), Bash(gh label list:*), Read, Write, Grep, Glob
---

IDEA = $ARGUMENTS — if that reads as a literal placeholder instead of a
description, use the description I gave when invoking this skill. If I
gave none, ask what the issue is about before doing anything else.

Issues drive the rest of the workflow: the `work-issue` skill reads them and
works from their acceptance criteria. A vague issue degrades everything
downstream, so the goal here is a draft concrete enough that `work-issue` can
act on it without guessing.

## Your task

1. Pin down the idea. If the scope, motivation, or acceptance criteria
   can't be determined from what I gave, ask me BEFORE drafting — don't
   pad thin input into an official-looking issue.
2. Check for duplicates with `gh issue list` and `gh search issues`
   (read-only). If a near-match exists — open or recently closed — show
   it to me and ask whether to proceed, extend that issue instead, or
   drop it. Never file over an existing issue.
3. Draft the issue in this shape:
   - **Title** — imperative and specific
   - **Problem** — why this matters, what breaks or is missing today
   - **Proposal** — the intended change, concrete enough to implement
   - **Guardrails** — constraints and non-goals; omit if none apply
   - **Acceptance criteria** — a `- [ ]` checklist of verifiable
     outcomes the `work-issue` skill can work from and check off
   - End the body with the AI-attribution footer from AGENTS.md as its
     last line.
4. STOP — show me the full draft (title and body) and wait for my
   approval. Revise per my feedback until I approve.
5. Only after approval, file it with `gh issue create`.
   (This will ask for my approval — that is intentional; wait for it.)
6. Reply with the issue URL. When you're satisfied, invoke `work-issue`
   with issue N.
