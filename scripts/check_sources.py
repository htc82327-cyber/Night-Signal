#!/usr/bin/env python3
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]

source_files = [
    root / "Tweak.xm",
    root / "NightSignal" / "RootViewController.m",
    root / "PovoZka" / "ChatViewController.m",
]

errors = []

for path in source_files:
    if not path.exists():
        errors.append(f"missing source: {path.relative_to(root)}")

def strip_strings_and_comments(text):
    out = []
    i = 0
    state = "code"
    while i < len(text):
        c = text[i]
        two = text[i:i+2]
        if state == "code":
            if two == "//":
                state = "line"; out.extend("  "); i += 2; continue
            if two == "/*":
                state = "block"; out.extend("  "); i += 2; continue
            if c == '"':
                state = "string"; out.append(" "); i += 1; continue
            if c == "'":
                state = "char"; out.append(" "); i += 1; continue
            out.append(c); i += 1; continue
        if state == "line":
            if c == "\n":
                state = "code"; out.append("\n")
            else:
                out.append(" ")
            i += 1; continue
        if state == "block":
            if two == "*/":
                state = "code"; out.extend("  "); i += 2
            else:
                out.append("\n" if c == "\n" else " "); i += 1
            continue
        if state in ("string","char"):
            if c == "\\":
                out.append(" ")
                if i+1 < len(text):
                    out.append(" ")
                    i += 2
                else:
                    i += 1
                continue
            if (state == "string" and c == '"') or (state == "char" and c == "'"):
                state = "code"
            out.append("\n" if c == "\n" else " ")
            i += 1
    return "".join(out)

def brace_depth(text):
    clean = strip_strings_and_comments(text)
    depth = 0
    for c in clean:
        if c == "{": depth += 1
        elif c == "}":
            depth -= 1
            if depth < 0:
                return depth
    return depth

for path in source_files:
    if path.exists():
        d = brace_depth(path.read_text(encoding="utf-8"))
        if d != 0:
            errors.append(f"brace depth {d}: {path.relative_to(root)}")

# Catch Objective-C method bodies accidentally placed inside @interface blocks.
for path in [
    root / "NightSignal" / "RootViewController.m",
    root / "PovoZka" / "ChatViewController.m",
]:
    text = path.read_text(encoding="utf-8")
    for m in re.finditer(r"@interface\b.*?@end", text, flags=re.S):
        block = m.group(0)
        if re.search(r"^[+-]\s*\([^)]*\)[^{;\n]*\{", block, flags=re.M):
            errors.append(f"method implementation inside @interface: {path.relative_to(root)}")
            break

# APIs known to break this SDK build under -Werror.
for path in [
    root / "NightSignal" / "RootViewController.m",
    root / "PovoZka" / "ChatViewController.m",
]:
    text = path.read_text(encoding="utf-8")
    forbidden = {
        "contentEdgeInsets": "deprecated UIButton contentEdgeInsets",
        "progressViewWithProgressViewStyle": "invalid UIProgressView factory selector",
    }
    for token, reason in forbidden.items():
        if token in text:
            errors.append(f"{reason}: {path.relative_to(root)}")

# Logos structural checks.
tweak = (root / "Tweak.xm").read_text(encoding="utf-8")
logos_stack = []
for lineno, raw in enumerate(tweak.splitlines(), 1):
    line = raw.strip()
    if line.startswith("%group "):
        logos_stack.append(("group", lineno))
    elif line.startswith("%hook "):
        logos_stack.append(("hook", lineno))
    elif line == "%end":
        if logos_stack:
            logos_stack.pop()
        else:
            errors.append(f"unmatched %end at Tweak.xm:{lineno}")

    if re.search(r"^[+-]\s*\([^)]*\).*\{\s*%orig", line):
        errors.append(f"compressed Logos hook body at Tweak.xm:{lineno}")

if logos_stack:
    errors.append(f"unclosed Logos blocks: {logos_stack}")

# Catch direct property access on forward-declared private classes.
private_hooks = {"CSCoverSheetViewController","SBIconView","SBRootFolderView","SpringBoard"}
current_hook = None
for lineno, raw in enumerate(tweak.splitlines(), 1):
    line = raw.strip()
    m = re.match(r"%hook\s+([A-Za-z0-9_]+)", line)
    if m:
        current_hook = m.group(1)
    elif line == "%end" and current_hook:
        current_hook = None
    elif current_hook in private_hooks and re.search(r"\bself\.[A-Za-z_]", raw):
        errors.append(
            f"direct property access on forward private class {current_hook} at Tweak.xm:{lineno}"
        )

# Required files/resources.
required = [
    "Makefile", "control", "NightSignalTweak.plist",
    "NightSignal/Makefile", "NightSignal/Info.plist",
    "NightSignal/entitlements.plist", "NightSignal/Resources/scream.wav",
    "PovoZka/Makefile", "PovoZka/Info.plist", "PovoZka/entitlements.plist",
    ".github/workflows/build.yml",
]
for rel in required:
    if not (root / rel).exists():
        errors.append(f"missing required file: {rel}")

if errors:
    print("PREFLIGHT FAILED")
    for error in errors:
        print("-", error)
    sys.exit(1)

print("PREFLIGHT OK")
print("- Objective-C braces balanced")
print("- no method bodies inside @interface")
print("- no known deprecated/invalid UIKit calls")
print("- Logos blocks balanced")
print("- no direct private-class self.property access")
print("- required files/resources present")
