# lcad

This project is a Lua / LÖVE (Love2D) application — a minimal 3D modeling and texturing tool. See `README.md` for the concept and current status, and `docs/prd/` for the PRD-based changelog.

## Testing

Run the test suite with:

```
make test
```

Do not invoke `lua`, `love`, or test files directly — always go through `make test`.

## Commands

The user will always refuse to approve a shell command that isn't already allowed. Do not retry a denied command with different flags or wrapping, and do not look for workarounds to run it anyway. Stick to `make test`, `make run`, and `make build` for build/test/run tasks.
