---
name: ticket
description: Start work on a GitHub issue — read it, create a branch, implement the change, commit, then STOP for my review. Invoke explicitly with an issue number.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[issue-number]"
disable-model-invocation: true
allowed-tools: Bash(gh issue view:*), Bash(git fetch:*), Bash(git pull:*), Bash(git switch:*), Bash(git checkout:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git status:*), Bash(git diff:*), Read, Edit, Write, Grep, Glob
---

ISSUE = $ARGUMENTS — if that reads as a literal placeholder instead of a
number, use the issue number I gave when invoking this skill. If I gave
none, ask for it before doing anything else.

## Your task

1. Run `gh issue view ISSUE` and read the issue. Summarize it and its
   acceptance criteria in your own words. If anything is ambiguous, ask me
   BEFORE writing any code.
2. Switch to main - if the working tree has WIP, stash it or commit it
   first, never carry it along silently - then `git pull`. Create a branch
   named `<type>/ISSUE-<short-slug>` off the freshly pulled main (never off
   another feature branch), following the branch naming and commit
   conventions in my agent instructions (AGENTS.md).
3. Implement the change. Add or adjust tests where they apply. Run the
   project's linter and test suite and get them passing.
4. Commit in logical units using Conventional Commit messages.
5. STOP — do not push and do not open a PR. Show me:
   - the branch name
   - a short summary of what changed and why
   - `git diff main...HEAD --stat` plus the key hunks
     Then wait for my review. When I'm satisfied I'll invoke the `ship`
     skill with this issue number.
