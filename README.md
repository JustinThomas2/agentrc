# agentrc

Portable dev environment from one source of truth: zsh, git aliases, and cross-agent config (Claude Code, Codex) via symlink.

This repo is **public**. Everything private or machine-specific lives in a separate private repo that layers on top via `.local` companion files (see [Public/private layering](#publicprivate-layering)).

## Layout

```
zsh/            .zshrc (symlinked to ~/.zshrc)
git/            .gitconfig (symlinked to ~/.gitconfig)
  .githooks/    global git hooks (symlinked to ~/.githooks, used via core.hooksPath)
agents/         AGENTS.md — shared agent instructions, single source of truth
  mcp/          servers.json.example (real servers.json is gitignored — often holds tokens)
claude/         CLAUDE.md + settings.json (symlinked into ~/.claude/)
codex/          config.toml.example (real config.toml is gitignored)
skills/         my own skills, one folder per skill (agentskills.io format)
  external/     gitignored — third-party skills fetched at install time
skills.txt      manifest of external skills, pinned as URL@version
scripts/        install.sh, fetch-skills.sh
.githooks/      pre-commit secret checks (no third-party tools)
```

## Symlink strategy

Nothing is copied. `scripts/install.sh` symlinks each file from this repo into its live location (`~/.zshrc`, `~/.gitconfig`, `~/.claude/…`, `~/.codex/…`), so editing a config here takes effect immediately and every machine stays in sync with `git pull`. The installer is idempotent, creates target directories as needed, backs up any pre-existing real file to `*.bak` before replacing it, and never touches `.local` files.

## One AGENTS.md for every agent

`agents/AGENTS.md` is the single source of truth for AI-agent instructions:

- **Codex** reads it natively — it is symlinked to `~/.codex/AGENTS.md`.
- **Claude Code** reads `claude/CLAUDE.md` (symlinked to `~/.claude/CLAUDE.md`), which pulls the shared file in via an `@AGENTS.md` import and adds a section for Claude-only overrides.

Shared guidance goes in `AGENTS.md`; anything agent-specific goes in that agent's own file.

## Skills: referenced, not vendored

My own skills live in `skills/`, one folder per skill with a `SKILL.md` ([agentskills.io](https://agentskills.io) format). Third-party skills are **not** committed to this repo. Instead:

- `skills.txt` pins each external skill as `URL@version` (tag or commit SHA).
- `scripts/fetch-skills.sh` clones each pin into `skills/external/<name>/` (gitignored), then symlinks every skill folder — mine and fetched — into `~/.claude/skills/` and `~/.codex/skills/`.

Why referenced instead of vendored: vendoring would republish other people's code under this repo (a licensing problem), and pinned references make updates an explicit, reviewable one-line change instead of silent drift. **Everything under `skills/external/` retains its own upstream license and is never committed here.**

## Public/private layering

Base files in this repo are safe to publish and end by including a `.local` companion if one exists. The private layer (a separate repo, not part of this one) provides those companions:

| Public (this repo)     | Private companion         |
| ---------------------- | ------------------------- |
| `zsh/.zshrc`           | `~/.zshrc.local`          |
| `git/.gitconfig`       | `~/.gitconfig.local`      |
| `claude/settings.json` | `~/.claude/settings.local.json` |
| `codex/config.toml.example` | real `codex/config.toml` (gitignored) |
| `agents/mcp/servers.json.example` | real `agents/mcp/servers.json` (gitignored) |

Codex's `config.toml` and MCP `servers.json` cannot be layered, so only `.example` files are committed and the real files are gitignored. `.local` files, `settings.local.json`, `.env*`, keys, and tokens are all gitignored; the installer will never overwrite an existing `.local` file.

## Install

```sh
git clone https://github.com/JustinThomas2/agentrc.git
cd agentrc
./scripts/install.sh        # symlink zsh/git/claude/codex files, enable git hooks
./scripts/fetch-skills.sh   # fetch pinned external skills + link all skills
```

Re-running either script is safe. To pick up new external skill pins later, edit `skills.txt` and re-run `fetch-skills.sh`.

## Secret hygiene

No third-party scanning tools — the safety rails are deliberately self-contained:

1. **`.gitignore` is the primary rail.** Real configs that can hold tokens (`codex/config.toml`, `agents/mcp/servers.json`), `.local` files, `.env*`, keys, and `secrets/` are all ignored; only `*.example` placeholders are committed.
2. **`.githooks/pre-commit`** (own script, zero dependencies) refuses to commit any staged file that `.gitignore` says to ignore (catches accidental `git add -f`), and scans added lines for high-signal secret formats — private keys and AWS/GitHub/Slack/Anthropic/OpenAI/Google token shapes. Extend its patterns array as needed. `install.sh` enables it via `git config core.hooksPath .githooks`.
3. Enable **GitHub push protection** on the repo (Settings → Code security → Secret scanning → Push protection) as a server-side backstop — hooks can be bypassed, push protection can't.

## License

MIT (see [LICENSE](LICENSE)). Does not apply to fetched contents of `skills/external/`, which keep their own licenses.
