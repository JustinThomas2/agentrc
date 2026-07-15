---
name: ship
description: Push the current branch and open a PR for the issue it addresses. Invoke explicitly with an issue number.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[issue-number]"
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git branch:*), Read
---

ISSUE = $ARGUMENTS — if that reads as a literal placeholder instead of a
number, use the issue number I gave when invoking this skill. If I gave
none, ask for it before doing anything else.

## Your task

1. Run `git status -sb` and `git log main..HEAD --oneline` to see what is
   being shipped. If the working tree is dirty or there are no commits
   ahead of main, stop and tell me instead of pushing.
2. Read the PR body template bundled with this skill at `pr-template.md`.
3. Compose the PR title and body, filling every section of that template:
   - title aligned with the primary commit
   - a summary of what changed and why
   - the testing you performed
   - `Closes #ISSUE` in the body
4. STOP — show me the complete title and body as plain text in the
   conversation and wait for my approval; revise until I approve. Command
   approval prompts only show the command (often just a `--body-file`
   path), so this chat text is my only chance to actually read what is
   about to be posted.
5. Push the current branch to origin with upstream tracking.
   (This will ask for my approval — that is intentional; wait for it.)
6. Open the PR with `gh pr create`, using the approved title and body
   exactly. (This will also ask for my approval — wait for it.)
7. Reply with the PR URL.
