# lcad

This project is a Lua / LÖVE (Love2D) application — a minimal 3D modeling and texturing tool. See `README.md` for the concept and current status, and `docs/prd/` for the PRD-based changelog.

## Testing

Run the test suite with:

```
make test
```

Do not invoke `lua`, `love`, or test files directly — always go through `make test`.

## Imports

A Lua file may only `require` sibling files, or files inside a sibling folder of its own directory — never anything from an ancestor directory. Concretely: `game/lib/xxx.lua` may require anything under `game/lib/*` (siblings like `game/lib/colors.lua`, or sibling folders like `game/lib/scene/*`, `game/lib/view/*`), but must never require `game/main.lua`, `game/screen.lua`, `game/const.lua`, or anything else directly in `game/`. This keeps `lib/` self-contained and prevents upward/circular dependencies on app-level files.

## Commands

The user will always refuse to approve a shell command that isn't already allowed. Do not retry a denied command with different flags or wrapping, and do not look for workarounds to run it anyway. Stick to `make test`, `make run`, and `make build` for build/test/run tasks.
