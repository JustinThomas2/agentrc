# skills/

My own skills live here, one folder per skill in [agentskills.io](https://agentskills.io) format:

```
skills/
  my-skill/
    SKILL.md
  external/        # gitignored — third-party skills fetched by scripts/fetch-skills.sh
```

Third-party skills are never committed here. They are pinned in the top-level
`skills.txt` and fetched into `skills/external/` at install time. Everything in
`skills/external/` retains its upstream license.

`scripts/fetch-skills.sh` symlinks every skill folder (own + external) into
`~/.claude/skills/` and `~/.codex/skills/`.

## Writing model-agnostic skills

Every skill here is linked into every harness, so skill **bodies** must not
rely on harness-specific preprocessing:

- No `` !`command` `` dynamic-context injection — instead, instruct the agent
  to run the command as a step.
- Don't assume `$ARGUMENTS` is substituted. Define a placeholder up front,
  e.g. `ISSUE = $ARGUMENTS`, with a fallback instruction for harnesses that
  pass the literal text through.
- Reference `AGENTS.md` (the shared instructions), not `CLAUDE.md`, and say
  "invoke the skill" rather than `/slash` syntax.

Harness-specific **frontmatter** extras (`argument-hint`, `allowed-tools`,
`disable-model-invocation`, …) are fine: unknown fields are ignored, so they
enhance one harness without breaking another.

## Show before posting

Any skill that posts content to an external service (GitHub issues, PRs,
review replies, …) must show the exact content as plain text in the
conversation and get approval BEFORE the call that posts it. Command
approval prompts only display the command — often just a `--body-file`
path — so the chat text is the only real review surface.
