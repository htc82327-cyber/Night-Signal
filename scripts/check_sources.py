#!/usr/bin/env python3
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
files = [
    root / "Tweak.xm",
    root / "NightSignal" / "RootViewController.m",
    root / "PovoZka" / "ChatViewController.m",
]

def brace_depth(text):
    state = "code"
    esc = False
    depth = 0
    i = 0
    while i < len(text):
        c = text[i]
        n = text[i:i+2]
        if state == "code":
            if n == "//":
                state = "line"
                i += 2
                continue
            if n == "/*":
                state = "block"
                i += 2
                continue
            if c == '"':
                state = "string"
                esc = False
            elif c == "'":
                state = "char"
                esc = False
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth < 0:
                    return depth
        elif state == "line":
            if c == "\n":
                state = "code"
        elif state == "block":
            if n == "*/":
                state = "code"
                i += 2
                continue
        elif state in ("string", "char"):
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif state == "string" and c == '"':
                state = "code"
            elif state == "char" and c == "'":
                state = "code"
        i += 1
    return depth

errors = []

for path in files:
    if not path.exists():
        errors.append(f"missing: {path.relative_to(root)}")
        continue
    text = path.read_text(encoding="utf-8")
    d = brace_depth(text)
    if d != 0:
        errors.append(f"brace depth {d}: {path.relative_to(root)}")

tweak = (root / "Tweak.xm").read_text(encoding="utf-8")

# Logos hooks should never contain method body + %orig compressed onto one line.
bad_hook_lines = []
for lineno, line in enumerate(tweak.splitlines(), 1):
    if re.search(r"^[+-]\s*\([^)]*\).*\{\s*%orig", line):
        bad_hook_lines.append(lineno)
if bad_hook_lines:
    errors.append(f"compressed Logos hook syntax on lines: {bad_hook_lines}")

# Validate group/hook/end structure.
stack = []
for lineno, raw in enumerate(tweak.splitlines(), 1):
    line = raw.strip()
    if line.startswith("%group "):
        stack.append(("group", lineno, line))
    elif line.startswith("%hook "):
        stack.append(("hook", lineno, line))
    elif line == "%end":
        if not stack:
            errors.append(f"unmatched %end on line {lineno}")
        else:
            stack.pop()
if stack:
    errors.append("unclosed Logos blocks: " + repr(stack))

if errors:
    print("SOURCE CHECK FAILED")
    for e in errors:
        print("-", e)
    sys.exit(1)

print("SOURCE CHECK OK")
print("- braces balanced")
print("- no compressed Logos hook bodies")
print("- %group / %hook / %end balanced")
