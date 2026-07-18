# Justin's Agent Instructions

<!--
Single source of truth for all AI coding agents. Claude Code imports this via
claude/CLAUDE.md (@AGENTS.md); Codex reads it natively at ~/.codex/AGENTS.md.
Agent-specific overrides go in that agent's own file, not here.
-->

## General Guidelines

- Prefer simple, maintainable solutions over clever abstractions.
- Do not change architecture just for style. Make changes only when they solve a real problem.
- When uncertain, explain the tradeoff before editing.
- For non-trivial changes, make a short plan before implementation.
- For bugs, reproduce the issue before fixing when practical.
- Prefer functional TypeScript patterns over classes unless the project clearly uses classes.
- Always use type annotations where the language supports them (Python type
  hints, TypeScript over untyped JavaScript, etc.). Untyped code is
  acceptable only where the language offers no typing. Prefer precise types
  over escape hatches like `Any` (narrow unknown data with runtime checks
  instead); whether to strictly enforce that is each project's own call.
- Avoid regular expressions in code that gets saved, executed, or read by
  humans; prefer explicit string operations. A one-off regex inside an
  ad-hoc shell command an agent runs is fine. Committing a regex requires
  an extremely strong justification - state it in a comment, or don't use one.
- Do not add dependencies without explaining why the existing stack is insufficient.
- Keep responses concise unless Justin asks for deeper explanation.
- Avoid em dashes in prose. Use plain dashes instead.

## Project Work Style

- Preserve the user's learning. Do not over-automate when Justin is practicing.
- When Justin is building portfolio/interview projects, prioritize understanding and explain decisions.
- When working autonomously, validate with lint, typecheck, tests, or a runnable smoke test.

## Git workflow (personal defaults)
These are my defaults across all projects. If a project's own instructions
file (AGENTS.md / CLAUDE.md) defines different conventions, follow the
project's.

- Branch naming: `<type>/<issue-number>-<short-slug>` (e.g. `feat/142-dark-mode`)
- Commits: Conventional Commits (feat:, fix:, chore:, docs:, refactor:)
- Starting new work: switch to main (stash or commit WIP only if needed),
  pull, then create the feature branch off the fresh main. Never branch off
  another feature branch unless I explicitly say to.
- Push plainly by default - no pre-push sync ritual. Rebase onto freshly
  pulled main only when there is an actual reason: the PR reports merge
  conflicts, or main moved meaningfully while the branch was open. When a
  rebase rewrites an already-pushed branch, push with
  `git push --force-with-lease`, never bare `--force`.
- NEVER push or open a PR without my explicit go-ahead.
- PR bodies must include `Closes #<issue-number>`.

## AI attribution

Anything an agent publishes under my name must disclose that an LLM
drafted it and I reviewed it. Canonical phrasings - use these verbatim,
one per medium:

- Git commits - final trailer line, after any other trailers:
  `Drafted-by: LLM (reviewed by Justin)`
- Issue bodies and PR/review comments - last line:
  `*Drafted by an LLM; reviewed and approved by Justin.*`
- PR bodies - at the top, a `---` horizontal rule followed by:
  `*Everything below this line was drafted by an LLM and reviewed by Justin.*`
  My hand-written sections go above the rule. The rule must come BEFORE
  the text; text immediately followed by `---` renders as a heading.

Keep harness built-in attribution (e.g. Claude Code's `attribution`
settings) disabled so published content never carries two disclosures.
