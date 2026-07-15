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
3. Push the current branch to origin with upstream tracking.
   (This will ask for my approval — that is intentional; wait for it.)
4. Open a PR with `gh pr create`, filling every section of that template:
   - title aligned with the primary commit
   - a summary of what changed and why
   - the testing you performed
   - `Closes #ISSUE` in the body
   (Opening the PR will also ask for my approval — wait for it.)
5. Reply with the PR URL.
