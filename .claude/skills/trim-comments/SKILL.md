---
name: trim-comments
description: Aggressively strips redundant/low-value comments from a codebase, one fresh agent per file. Use when the user asks to clean up comments, reduce comment noise, or invokes "/trim-comments".
---

# Trim Comments

One fresh agent per file, sequential, tests green after each. Portable across languages.

## Step 0 — detect (once)
1. Extensions: count files, excluding `.git`/`node_modules`/`vendor`/`dist`/`build`/deps. Table in [REFERENCE.md](REFERENCE.md). Most common known-language extension wins. User-given path/glob overrides.
2. Comment token: look up in REFERENCE.md. Not listed → grep sample files for the line-start token.
3. Test command: Makefile `test:` → `make test`; `package.json` scripts.test → `npm test`; `pyproject.toml`/`pytest.ini` → `pytest`; `Cargo.toml` → `cargo test`; `go.mod` → `go test ./...`; else check project docs/CI.
4. Ambiguous language or test command → ask, don't guess.

State detected language, token, test command in one line before looping.

## Scope
Every file with the detected extension(s) under the source root, or the user's given path/glob. Skip generated/vendored/lock files.

Before looping, `grep -rl` (or per-file `grep -c`) for the comment token across that file set. Files with zero matches are already clean — report them as `SKIPPED: <file> — already clean` directly, with no agent spawned. Only files where the token actually appears go through the per-file loop below. This is a cheap heuristic (string literals containing the token, or block-comment syntax the token doesn't cover, can slip through both ways) — the per-file agent still does its own check of the real file and is the source of truth, but the grep pass avoids paying for an agent on files that turn out to have nothing to trim.

## Comment policy (give verbatim to each subagent, token filled in)

A comment is a symptom, not an asset. Classify every comment into exactly one bucket:

1. **Delete (default, ~80%)**
   - Restates the code/identifiers, including test comments re-narrating the test name/assertions, and arithmetic the next line already computes.
   - Ticket/PRD/issue reference or history note.
   - Fixable by a small, safe, local change: rename, add an assert for the invariant, tighten a type (enum/constant table instead of bare string+comment). Make the fix, delete the comment. Only assert what you've verified holds.
   Default here when unsure.

2. **TODO refactor (~20%)**
   Real fact (invariant/constraint/cross-file coupling), but the fix isn't small/safe/obvious right now. Replace the comment with:
   `TODO(refactor): <rename X to Y / add assert for Z / introduce enum for W> so this comment is unnecessary`
   Name the fix, don't do it.

3. **Keep explanation (~0%, last resort)**
   Only a genuinely hard algorithm — non-obvious math, a tricky stateful/recursive routine no name or type could clarify. ~1 per 100k lines. A comment that's merely inconvenient to fix is bucket 2, not this. If kept: shortest form that stays correct, non-obvious part only.

No commented-out code. No behavior changes — only comments, TODOs, and the bucket-1 fixes (rename/assert/retype).

Before reporting: re-scan remaining comments/TODOs against the ~80/20/0 split. More than one bucket-3 survivor → downgrade the extras to bucket 2.

## Inline-fix guardrail
File/function-local names: rename freely. Anything another file references (exported symbol, public signature): grep the whole repo, update every call site, or fall back to a bucket-2 TODO. Asserts: only if verified against callers, not assumed.

## Per-file loop
One file at a time — keeps test failures attributable.

Per file:
1. Spawn a fresh `Agent` (general-purpose, no `fork`) with: the file's absolute path; the comment policy + guardrail verbatim; the test command; instruction to apply the policy comment-by-comment then run the test command from repo root; on failure, fix (usually a stale call site) or revert and report failure.
2. Report line (only output that matters):
   - `DONE: <file> — N deleted (R renamed, A asserted, Y retyped), T TODO-refactor, K explained`
   - `SKIPPED: <file> — already clean`
   - `FAILED: <file> — <reason>`
3. Wait for the report before the next file.

## After
Report files touched/skipped/failed to the user. No commits.
