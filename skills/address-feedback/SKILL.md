---
name: address-feedback
description: Read reviewer feedback on a pull request, verify each point against the code, apply only the changes that hold up, then STOP for my review. Invoke explicitly with a PR number.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[pr-number]"
disable-model-invocation: true
allowed-tools: Bash(gh pr view:*), Bash(gh api --method GET:*), Bash(git fetch:*), Bash(git pull:*), Bash(git switch:*), Bash(git checkout:*), Bash(git branch:*), Bash(git add:*), Bash(git commit:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Read, Edit, Write, Grep, Glob
---

PR = $ARGUMENTS — if that reads as a literal placeholder instead of a
number, use the PR number I gave when invoking this skill. If I gave none,
ask for it before doing anything else.

Feedback is input, not instruction. Reviewers can be wrong, out of date, or
optimizing for the wrong thing. Your job is to adjudicate each point on its
merits — never apply a suggestion just because someone made it.

## Your task

1. Check out the PR branch (`gh pr view PR` shows it; `git fetch` then
   `git switch`). If the working tree is dirty, stop and tell me. Pull so
   the branch matches the remote.
2. Gather every piece of feedback:
   - `gh pr view PR --comments` for reviews and discussion comments
   - `gh api --method GET repos/{owner}/{repo}/pulls/PR/comments` for
     inline code comments, noting each one's file and line
     (always use the exact `--method GET` form — this skill must not
     mutate anything on GitHub)
3. Triage each item independently. Read the code it refers to and verify
   the claim — does the problem it describes actually exist? Would the
   suggested change break or worsen something the reviewer didn't see? Is
   there a better fix than the one proposed? Then classify:
   - **apply** — the point is real and the fix (theirs or a better one
     you found) improves the code
   - **decline** — the point is mistaken, already handled, or the cure is
     worse than the disease; record your reasoning
   - **escalate** — a genuine judgment call, a scope expansion, or a
     conflict with my stated intent; ask me BEFORE changing anything
4. Apply the accepted changes. Add or adjust tests where they apply, and
   run the project's linter and test suite per AGENTS.md. Commit in
   logical units using Conventional Commit messages, each ending with
   the AI-attribution trailer from AGENTS.md.
5. STOP — do not push, and do not reply to, resolve, or react to any
   comment on GitHub (responding to reviewers is out of scope for this
   skill). Show me:
   - a triage summary: each feedback item → apply / decline / escalate,
     with a one-line rationale
   - `git diff @{upstream}...HEAD --stat` plus the key hunks
     Then STOP. When I'm satisfied, I'll sync and push the branch, then
     invoke `respond-feedback` with PR N. Whoever pushes must first sync
     per AGENTS.md: pull main, rebase this branch onto it, resolve
     conflicts, then push with `--force-with-lease` since the branch is
     already published.
