---
name: ticket
description: Start work on a GitHub issue — read it, create a branch, implement the change, commit, then STOP for my review. Invoke explicitly with /ticket <issue-number>.
argument-hint: "[issue-number]"
disable-model-invocation: true
allowed-tools: Bash(gh issue view:*), Bash(git fetch:*), Bash(git pull:*), Bash(git switch:*), Bash(git checkout:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git status:*), Bash(git diff:*), Read, Edit, Write, Grep, Glob
---

## Issue

!`gh issue view $ARGUMENTS`

## Your task

1. Summarize the issue and its acceptance criteria in your own words.
   If anything is ambiguous, ask me BEFORE writing any code.
2. Make sure main is current (`git fetch`, then fast-forward), and create a
   branch named `<type>/$ARGUMENTS-<short-slug>` off it, following the branch
   naming and commit conventions in my CLAUDE.md.
3. Implement the change. Add or adjust tests where they apply. Run the
   project's linter and test suite and get them passing.
4. Commit in logical units using Conventional Commit messages.
5. STOP — do not push and do not open a PR. Show me:
   - the branch name
   - a short summary of what changed and why
   - `git diff main...HEAD --stat` plus the key hunks
     Then wait for my review. When I'm satisfied I'll run `/ship $ARGUMENTS`.
