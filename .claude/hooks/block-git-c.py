#!/usr/bin/env python3
"""
Hook PreToolUse : refuse les commandes `git -C <path> ...`.
Force Claude à travailler dans le repo courant (cwd) plutôt que de
pointer vers un autre chemin par excès de précaution.
"""
import json
import re
import sys

# Repère `git -C <quelque chose>` sous ses formes courantes :
#   git -C /path/to/repo status
#   git -C ../foo commit -m "x"
#   git --git-dir=... --work-tree=... (variante équivalente à surveiller aussi)
GIT_DASH_C = re.compile(r"\bgit\s+(?:\S+\s+)*-C\s+\S+")
GIT_DIR_FLAGS = re.compile(r"\bgit\s+(?:\S+\s+)*--(git-dir|work-tree)=\S+")


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    if payload.get("tool_name") != "Bash":
        return 0

    command = payload.get("tool_input", {}).get("command", "")

    if GIT_DASH_C.search(command) or GIT_DIR_FLAGS.search(command):
        print(
            "BLOCKED: do not use `git -C <path>` or --git-dir/--work-tree.\n"
            "Work directly in the current directory: just rerun the git "
            "command without the -C option (the cwd is already the "
            "correct repo).",
            file=sys.stderr,
        )
        return 2

    return 0


if __name__ == "__main__":
    sys.exit(main())
