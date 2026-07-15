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
- Before the final push of a branch (opening a PR, or pushing review
  fixes): switch to main, pull, return to the branch, rebase it onto main,
  and resolve any conflicts. If the branch was already pushed, push with
  `git push --force-with-lease`, never bare `--force`.
- NEVER push or open a PR without my explicit go-ahead.
- PR bodies must include `Closes #<issue-number>`.
