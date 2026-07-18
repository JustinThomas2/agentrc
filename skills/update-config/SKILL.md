---
name: update-config
description: Change agent configuration (settings, permissions, hooks) managed by the agentrc repo. Files under ~/.claude and ~/.codex are symlinks into ~/agentrc, so edits must target the repo paths and land through git. Use for any change to settings.json, permission rules, hooks, or env vars.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[what to change]"
---

CHANGE = $ARGUMENTS - if that reads as a literal placeholder instead of a
description, use the description I gave when invoking this skill. If I
gave none, ask what config change I want before doing anything else.

Agent config on this machine is managed by the agentrc repo. What looks
like `~/.claude/settings.json` is a symlink into `~/agentrc/claude/`,
and the same goes for the other agent config files. Two consequences:

- File-editing tools refuse to write through symlinks. Always resolve
  the real path first with `readlink -f <file>` and edit that
  (e.g. `~/agentrc/claude/settings.json`).
- A config edit is a repo change. It goes through the git workflow in
  AGENTS.md, never a silent in-place edit.

## Your task

1. Resolve the target. Run `readlink -f` on the config file to get its
   repo path. If the file is NOT a symlink into `~/agentrc`, stop and
   ask whether it should be added to the repo first.
2. Branch per AGENTS.md: switch to main (stash or commit unrelated WIP,
   never carry it along), pull, then branch off the fresh main.
3. Make the edit in the repo file. Read the file first and merge with
   what is there; never regenerate the whole file.
4. Permission rules must use forms the permission checker actually
   matches. File rules use `Edit(path)` - the `Edit(...)` form covers
   all file-editing tools (Edit, Write, NotebookEdit). Never write
   `Write(path)` rules; they are silently ignored and cause startup
   warnings.
5. Validate JSON files with `jq . <file>`; if `jq` is missing on the
   machine, fall back to `python3 -m json.tool <file>`. For settings
   semantics (hook events, schema fields), defer to the harness's own
   bundled config documentation rather than guessing.
6. Commit with a Conventional Commit message, then STOP. Show me the
   diff and wait - per AGENTS.md, never push or open a PR without my
   explicit go-ahead. New skill folders also need
   `scripts/fetch-skills.sh` re-run to link them; mention it when that
   applies.
