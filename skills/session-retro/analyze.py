#!/usr/bin/env python3
"""Summarize token usage of a Claude Code session transcript.

Usage: analyze.py [path-to-session.jsonl]

Without an argument, picks the most recently modified transcript for the
current working directory's project under ~/.claude/projects/. Prints a
compact plain-text breakdown; never prints raw transcript content beyond
short tool-target labels (file paths, command prefixes).
"""

import glob
import json
import os
import sys
from typing import TypedDict, cast

TOP_N: int = 10


class Usage(TypedDict, total=False):
    """Per-API-call token usage as recorded on assistant transcript lines."""
    input_tokens: int
    output_tokens: int
    cache_creation_input_tokens: int
    cache_read_input_tokens: int


def project_dir_for_cwd() -> str:
    slug = "".join(c if (c.isascii() and c.isalnum()) else "-" for c in os.getcwd())
    return os.path.expanduser(os.path.join("~/.claude/projects", slug))


def find_transcript(arg: str | None) -> str:
    if arg:
        return arg
    proj = project_dir_for_cwd()
    files = glob.glob(os.path.join(proj, "*.jsonl"))
    if not files:
        sys.exit(f"error: no transcripts under {proj} - pass the .jsonl path explicitly")
    return max(files, key=os.path.getmtime)


def tool_target(inp: object) -> str:
    """Short human label for what a tool call touched. Keep it terse."""
    if not isinstance(inp, dict):
        return ""
    for key in ("file_path", "path", "url", "skill", "pattern"):
        if key in inp:
            return str(inp[key])
    if "command" in inp:
        return " ".join(str(inp["command"]).split())[:80]
    if "prompt" in inp:
        return str(inp["prompt"])[:80]
    return ""


def block_chars(content: object) -> int:
    """Approximate size in characters of a message content field."""
    if isinstance(content, str):
        return len(content)
    total = 0
    if isinstance(content, list):
        for item in content:
            if isinstance(item, dict):
                total += len(str(item.get("text", "") or item.get("content", "") or ""))
            else:
                total += len(str(item))
    return total


def est_tokens(chars: int) -> int:
    """Rough chars->tokens estimate."""
    return chars // 4


def main() -> None:
    path = find_transcript(sys.argv[1] if len(sys.argv) > 1 else None)

    usage_by_msg: dict[str, Usage] = {}            # message id -> usage (first seen)
    last_usage: Usage | None = None
    tools: dict[str, tuple[str, str]] = {}         # tool_use id -> (name, target)
    tool_counts: dict[str, int] = {}               # tool name -> call count
    result_sizes: list[tuple[int, str, str]] = []  # (chars, tool name, target)
    target_counts: dict[tuple[str, str], int] = {} # (name, target) -> count, to spot repeats
    user_prompts = 0
    assistant_text = 0
    lines = 0

    with open(path) as f:
        for raw in f:
            lines += 1
            try:
                parsed: object = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if not isinstance(parsed, dict):
                continue
            rec: dict[str, object] = parsed
            rtype = rec.get("type")
            msg_field = rec.get("message")
            msg: dict[str, object] = msg_field if isinstance(msg_field, dict) else {}

            if rtype == "assistant":
                mid = msg.get("id")
                usage_field = msg.get("usage")
                if isinstance(usage_field, dict):
                    # The shape comes from the harness and is stable;
                    # TypedDicts cannot be isinstance-checked, so cast at
                    # this one boundary after confirming it is a dict.
                    usage = cast(Usage, usage_field)
                    if isinstance(mid, str) and mid not in usage_by_msg:
                        usage_by_msg[mid] = usage
                    last_usage = usage
                content_field = msg.get("content")
                for block in content_field if isinstance(content_field, list) else []:
                    if not isinstance(block, dict):
                        continue
                    btype = block.get("type")
                    if btype == "text":
                        assistant_text += len(str(block.get("text") or ""))
                    elif btype == "tool_use":
                        name = str(block.get("name") or "?")
                        target = tool_target(block.get("input"))
                        tools[str(block.get("id"))] = (name, target)
                        tool_counts[name] = tool_counts.get(name, 0) + 1
                        if target:
                            key = (name, target)
                            target_counts[key] = target_counts.get(key, 0) + 1

            elif rtype == "user":
                content_field = msg.get("content")
                if isinstance(content_field, str):
                    user_prompts += 1
                    continue
                blocks = content_field if isinstance(content_field, list) else []
                saw_result = False
                for block in blocks:
                    if isinstance(block, dict) and block.get("type") == "tool_result":
                        saw_result = True
                        name, target = tools.get(str(block.get("tool_use_id")), ("?", ""))
                        result_sizes.append((block_chars(block.get("content")), name, target))
                if not saw_result and blocks:
                    user_prompts += 1

    out_tokens = sum(u.get("output_tokens", 0) for u in usage_by_msg.values())
    cache_create = sum(u.get("cache_creation_input_tokens", 0) for u in usage_by_msg.values())
    cache_read = sum(u.get("cache_read_input_tokens", 0) for u in usage_by_msg.values())
    fresh_in = sum(u.get("input_tokens", 0) for u in usage_by_msg.values())
    final_ctx = 0
    if last_usage is not None:
        final_ctx = (last_usage.get("input_tokens", 0)
                     + last_usage.get("cache_read_input_tokens", 0)
                     + last_usage.get("cache_creation_input_tokens", 0))

    print(f"transcript      {path}")
    print(f"lines           {lines}   user prompts ~{user_prompts}   api calls {len(usage_by_msg)}")
    print(f"tokens          output {out_tokens:,}   fresh input {fresh_in:,}")
    print(f"cache           created {cache_create:,}   read {cache_read:,} (re-served, cheap)")
    print(f"final context   ~{final_ctx:,} tokens")
    # thinking content is not stored in transcripts (blocks are empty on
    # disk); its cost is already inside output_tokens, so report text only.
    print(f"assistant text  ~{est_tokens(assistant_text):,} tok (est from chars; thinking counted in output)")

    total_result_chars = sum(c for c, _, _ in result_sizes)
    print(f"\ntool calls      {sum(tool_counts.values())} total, results ~{est_tokens(total_result_chars):,} tok (est)")
    for name, count in sorted(tool_counts.items(), key=lambda kv: -kv[1]):
        chars = sum(c for c, n, _ in result_sizes if n == name)
        print(f"  {name:<18} x{count:<4} results ~{est_tokens(chars):,} tok")

    print(f"\ntop {TOP_N} largest tool results (est tokens)")
    for chars, name, target in sorted(result_sizes, reverse=True)[:TOP_N]:
        print(f"  ~{est_tokens(chars):>7,}  {name:<12} {target[:70]}")

    repeats = {k: v for k, v in target_counts.items() if v > 1}
    if repeats:
        print("\nrepeated calls to the same target")
        for (name, target), count in sorted(repeats.items(), key=lambda kv: -kv[1])[:TOP_N]:
            print(f"  x{count}  {name:<12} {target[:70]}")


if __name__ == "__main__":
    main()
