---
name: respond-feedback
description: Reply to reviewers on a pull request after triage — draft a response per comment thread, show every draft for my approval, then post. Invoke explicitly with a PR number, typically after address-feedback.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[pr-number]"
disable-model-invocation: true
allowed-tools: Bash(gh pr view:*), Bash(gh api --method GET:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*), Read, Grep, Glob
---

PR = $ARGUMENTS — if that reads as a literal placeholder instead of a
number, use the PR number I gave when invoking this skill. If I gave
none, ask for it before doing anything else.

This closes the loop that address-feedback leaves open: reviewers should
never see their comments silently addressed or ignored. Replies go to
people, so they are drafted honestly and respectfully, and nothing is
posted before I have read it.

## Your task

1. Gather the PR's feedback and what happened to it:
   - `gh pr view PR --comments` for reviews and discussion comments
   - `gh api --method GET repos/{owner}/{repo}/pulls/PR/comments` for
     inline threads (always the exact `--method GET` form)
   - `git log` on the PR branch for the commits that addressed items,
     so replies can cite real SHAs
   If a triage summary exists earlier in this conversation (from
   address-feedback), work from it; otherwise reconstruct per thread
   from the commits and code.
2. Draft one reply per thread that warrants a response — don't pad
   threads that need nothing:
   - applied items: "addressed in `<sha>`" plus a one-line what/why
   - declined items: the reasoning, stated respectfully and concretely
   - escalated items: the decision made, or an honest "still discussing"
3. STOP — show me every draft reply in the conversation, mapped to its
   thread, and wait for my approval; revise until I approve. Never post
   anything I have not seen in chat.
4. Post only the approved replies. (Each posting call will ask for my
   approval — that is intentional; wait for it.) Use
   `gh api repos/{owner}/{repo}/pulls/PR/comments/{comment-id}/replies`
   for inline threads and `gh pr comment` for top-level responses.
5. Never resolve threads, never add reactions, never push — replies
   only. Resolving is the reviewer's call, not ours.
6. Reply with a summary of what was posted, with links.
