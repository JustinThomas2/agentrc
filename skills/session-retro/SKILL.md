---
name: session-retro
description: Review this session's token usage - run the bundled analyzer on the session transcript, report where tokens went, whether the spend was justified, and how to work cheaper next time. Invoke at the end of a session.
# The fields below are Claude Code extras; other harnesses ignore them.
argument-hint: "[optional path to session .jsonl]"
disable-model-invocation: true
allowed-tools: Bash(python3:*), Bash(ls:*)
---

TRANSCRIPT = $ARGUMENTS - if that reads as a literal placeholder
instead of a file path, treat it as empty: the analyzer will find the
current project's most recent transcript on its own.

The retro must cost a small fraction of the session it analyzes. All
number-crunching happens in the bundled script; NEVER read the raw
transcript into context - not even excerpts. Work only from the
script's printed summary plus what you already remember of this
session. Read-only throughout: analyze and report, change nothing.

## Your task

1. Run the analyzer bundled in this skill's directory:
   `python3 <skill-dir>/analyze.py [TRANSCRIPT]`
   It picks the newest transcript for the current project under
   `~/.claude/projects/` unless a path is given. If it errors (e.g.
   running under a harness that stores transcripts elsewhere), say so
   and ask me for the transcript path instead of guessing.
2. Interpret the summary. The interesting signals:
   - the largest tool results, and whether each was necessary at that
     size (whole-file Read where a range or search would have done?
     verbose command output that could have been filtered?)
   - repeated calls to the same target - re-reads and retry loops
   - cache behavior: `read` is re-served context and cheap; `created`
     plus `fresh input` is what actually grew the bill, and final
     context is how full the window got
   - anything you remember doing the long way (trial-and-error loops,
     work that a subagent or a narrower query could have done cheaper)
3. Report, briefly - the whole retro should be a screenful:
   - a high-level breakdown of where tokens went
   - an honest assessment of which spend was justified and which was
     avoidable, tied to specific entries in the summary
   - 2-3 concrete takeaways for future sessions
   Keep it to observations about this session; do not turn the
   takeaways into config or instruction changes without being asked.

## Notes

- Deliberately manual-only: an automatic end-of-session run (a
  SessionEnd hook, possibly gated to long sessions) was considered and
  deferred - see issue #15. Record a new issue instead of adding a
  hook here.
