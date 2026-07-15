#!/usr/bin/env python3
"""PreToolUse hook: pin gh to the current directory's repo.

Blocks any Bash command that runs `gh` with an explicit --repo/-R override,
so gh can only act on the repository inferred from the current working
directory. Uses shlex to tokenize the command and splits it into per-command
segments, so a -R belonging to ls/cp/grep on the same line is never mistaken
for a gh repo flag.
"""
from __future__ import annotations

import json
import shlex
import sys
from dataclasses import dataclass
from typing import Any

# Shell characters that separate one command from the next.
PUNCTUATION: frozenset[str] = frozenset("();<>|&")

# Wrappers and leading keywords that can precede the real command word.
WRAPPERS: frozenset[str] = frozenset({
    "sudo", "doas", "env", "time", "nice", "nohup", "xargs",
    "command", "stdbuf", "setsid", "then", "do", "!",
})


@dataclass(frozen=True)
class Invocation:
    """One command in a shell line: its command word and that word's own args."""
    command: str
    args: list[str]


def tokenize(command: str) -> list[str]:
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    return list(lexer)


def is_operator(token: str) -> bool:
    return bool(token) and all(ch in PUNCTUATION for ch in token)


def is_assignment(token: str) -> bool:
    if "=" not in token:
        return False
    return token.split("=", 1)[0].isidentifier()


def segments(tokens: list[str]) -> list[list[str]]:
    """Split the token stream into command segments on shell operators."""
    result: list[list[str]] = []
    current: list[str] = []
    for token in tokens:
        if is_operator(token):
            if current:
                result.append(current)
                current = []
        else:
            current.append(token)
    if current:
        result.append(current)
    return result


def parse_invocation(segment: list[str]) -> Invocation | None:
    """Find the real command word, skipping VAR= assignments and wrappers."""
    i = 0
    while i < len(segment) and is_assignment(segment[i]):
        i += 1
    while i < len(segment) and segment[i] in WRAPPERS:
        i += 1
        while i < len(segment) and is_assignment(segment[i]):
            i += 1
    if i < len(segment):
        return Invocation(command=segment[i], args=segment[i + 1:])
    return None


def targets_other_repo(args: list[str]) -> bool:
    for arg in args:
        if arg in ("--repo", "-R"):
            return True
        if arg.startswith("--repo=") or arg.startswith("-R="):
            return True
        if arg.startswith("-R") and len(arg) > 2:  # attached: -Rowner/name
            return True
    return False


def is_blocked(command: str) -> bool:
    try:
        tokens = tokenize(command)
    except ValueError:
        return False  # unparseable (e.g. unbalanced quotes): don't block
    for segment in segments(tokens):
        invocation = parse_invocation(segment)
        if invocation is not None and invocation.command == "gh":
            if targets_other_repo(invocation.args):
                return True
    return False


def deny(reason: str) -> None:
    payload: dict[str, Any] = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }
    print(json.dumps(payload))


def main() -> int:
    try:
        data: dict[str, Any] = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    if data.get("tool_name") != "Bash":
        return 0

    tool_input: dict[str, Any] = data.get("tool_input") or {}
    command: str = tool_input.get("command") or ""

    if is_blocked(command):
        deny(
            "gh is pinned to the current directory's repository. This command "
            "targets a different repo with --repo/-R. Re-run it WITHOUT "
            "--repo/-R to act on the current repo, or cd into the target repo "
            "first."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
