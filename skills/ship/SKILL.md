---
name: ship
description: Push the current branch and open a PR for the issue it addresses. Invoke explicitly with /ship <issue-number>.
argument-hint: "[issue-number]"
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git branch:*), Read
---

## Current state
!`git status -sb`
!`git log main..HEAD --oneline`

## Your task
1. Read the PR body template bundled with this skill at `pr-template.md`.
2. Push the current branch to origin with upstream tracking.
   (This will ask for my approval — that is intentional; wait for it.)
3. Open a PR with `gh pr create`, filling every section of that template:
   - title aligned with the primary commit
   - a summary of what changed and why
   - the testing you performed
   - `Closes #$ARGUMENTS` in the body
   (Opening the PR will also ask for my approval — wait for it.)
4. Reply with the PR URL.
