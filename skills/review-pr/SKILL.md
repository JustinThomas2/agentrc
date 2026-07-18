---
name: review-pr
description: Review a pull request and give feedback on it - gather the PR read-only, verify findings against the actual diff, show the draft feedback, then post only what I approve. Invoke explicitly with a PR number.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[pr-number]"
disable-model-invocation: true
allowed-tools: Bash(gh pr view:*), Bash(gh pr diff:*), Bash(gh issue view:*), Bash(gh api --method GET:*), Bash(gh pr comment:*), Bash(git log:*), Bash(git diff:*), Read, Grep, Glob
---

PR = $ARGUMENTS - if that reads as a literal placeholder instead of a
number, use the PR number I gave when invoking this skill. If I gave
none, ask for it before doing anything else.

A review is only useful if its findings are true. Never report a
problem you have not verified against the actual diff, and never pad a
review to look thorough - a clean PR deserves a short review saying
so. Rank what you do find so the author knows what matters.

## Your task

1. Gather context, read-only:
   - `gh pr view PR` for the metadata, body, and linked issue
   - `gh pr diff PR --patch` for the full diff
   - `gh pr view PR --comments` for existing discussion, so you don't
     repeat feedback already given
   - `gh issue view N` for the issue the PR closes, so findings can be
     checked against its acceptance criteria and guardrails
2. Review the diff on its merits:
   - verify every candidate finding against the diff (and surrounding
     files if needed) before it may appear in the draft; drop anything
     you cannot confirm
   - check the change against the linked issue's acceptance criteria
     and the conventions in AGENTS.md and `skills/README.md`
   - classify each finding: blocking, should-fix, or nit
3. Draft the feedback: findings ranked most severe first, each tied to
   a specific file and hunk, each with a concrete suggested fix. If
   nothing survived verification, the draft says the PR looks good and
   why.
4. STOP - show me the complete draft as plain text in the conversation
   and wait for my approval; revise until I approve. Never post
   anything I have not seen in chat.
5. Post only the approved feedback with `gh pr comment PR`, ending the
   comment with the AI-attribution footer from AGENTS.md. (The posting
   call will ask for my approval - that is intentional; wait for it.)
   Post plain comments, not formal reviews: `gh pr review` verbs
   (approve / request changes) fail on the invoker's own PRs, which is
   the common case here.
6. Never resolve threads, never approve or request changes, never
   push, never edit the PR or its body - the comment is the only
   mutation this skill makes.
7. Reply with a link to the posted comment. Then STOP. When the
   feedback is on my own PR, I'll invoke `address-feedback` with PR N
   to act on it.
