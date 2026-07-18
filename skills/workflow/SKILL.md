---
name: workflow
description: Show the issue-to-PR skill pipeline and report the current GitHub workflow position from read-only local and PR status. Invoke without arguments.
# The fields below are Claude Code extras; other harnesses ignore them.
disable-model-invocation: true
allowed-tools: Bash(git status -sb:*), Bash(gh pr status:*)
---

## Your task

This skill is read-only. Run only:

- `git status -sb`
- `gh pr status`

Do not branch, commit, push, post comments, edit files, or run mutating
GitHub commands.

## Pipeline Map

Print this compact map first, one line per skill:

- `file-issue`: rough idea -> GitHub issue draft or filed issue; stops before filing for approval.
- `work-issue`: issue number -> local branch with committed implementation; stops before push or PR.
- `open-pr`: issue number -> pushed branch and opened PR; stops after reporting the PR URL.
- `address-feedback`: PR number -> committed review fixes; stops before push or reviewer replies.
- `respond-feedback`: PR number -> posted approved reviewer replies; ends the workflow.

## State Detection

Use `git status -sb` to identify:

- current branch
- whether the branch is ahead of, behind, or diverged from its upstream
- whether there are uncommitted changes

Use `gh pr status` to identify:

- whether the current branch already has a PR
- the PR number when present
- whether the visible review decision is approved, changes requested, or review required

Then print:

- **You are here**: one concise sentence describing the current state.
- **Next**: the exact next skill invocation.

Choose the next invocation this way:

- On `main` with no feature branch context: `file-issue` with the rough idea.
- On a non-main branch with uncommitted changes: finish or discard the local changes before invoking another pipeline skill.
- On a non-main branch with commits ahead of main and no PR: `open-pr` with issue N. Infer N from a branch segment like `16` in `refactor/16-workflow-skill-names`; if no issue number is clear, say that the issue number is needed.
- On a branch with an open PR and changes requested: `address-feedback` with PR N.
- After review-fix commits are ready on a PR branch: `respond-feedback` with PR N once the fixes have been pushed and reviewed by Justin.
- If the state is ambiguous, say what is missing instead of guessing.
