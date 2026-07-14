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
