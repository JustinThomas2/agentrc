---
name: open-pr
description: Push the current branch and open a PR for the issue it addresses, then STOP with the PR URL. Invoke explicitly with an issue number.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[issue-number]"
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git log:*), Bash(git branch:*), Bash(git fetch:*), Bash(git pull:*), Bash(git switch:*), Bash(git checkout:*), Bash(git rebase:*), Bash(git diff:*), Read
---

ISSUE = $ARGUMENTS — if that reads as a literal placeholder instead of a
number, use the issue number I gave when invoking this skill. If I gave
none, ask for it before doing anything else.

## Your task

1. Run `git status -sb` and `git log main..HEAD --oneline` to see what is
   being opened for review. If the working tree is dirty or there are no commits
   ahead of main, stop and tell me instead of pushing.
2. Sync with main per AGENTS.md: switch to main, `git pull`, switch back
   to this branch, then rebase it onto main and resolve any conflicts.
   Re-run the step 1 checks afterwards. If this branch was pushed before,
   the coming push needs `--force-with-lease`, never bare `--force`.
3. Read the PR body template bundled with this skill at `pr-template.md`.
4. Compose the PR title and body, filling every section of that template:
   - title aligned with the primary commit
   - the AI-attribution marker (per AGENTS.md) at the top of the body,
     exactly as it appears in the template - any hand-written sections
     I add during review go above it
   - a summary of what changed and why
   - the testing you performed
   - `Closes #ISSUE` in the body
5. STOP — show me the complete title and body as plain text in the
   conversation and wait for my approval; revise until I approve. Command
   approval prompts only show the command (often just a `--body-file`
   path), so this chat text is my only chance to actually read what is
   about to be posted.
6. Push the current branch to origin with upstream tracking.
   (This will ask for my approval — that is intentional; wait for it.)
7. Open the PR with `gh pr create`, using the approved title and body
   exactly. (This will also ask for my approval — wait for it.)
8. Reply with the PR URL. When you're satisfied, invoke `address-feedback`
   with PR N.
