# Detection reference

## Counting source files

```
find . -type f \
  -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/vendor/*' \
  -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/.venv/*' -not -path '*/target/*' \
  | sed -n 's/.*\.\([a-zA-Z0-9]*\)$/\1/p' | sort | uniq -c | sort -rn | head -20
```

Match the top extensions against the table below. Ignore non-code extensions that show up in most repos (`md`, `json`, `yaml`, `yml`, `lock`, `txt`, `png`, `svg`, `jpg`, `toml` unless it's the only signal, `.env`, `.gitignore`).

## Extension → language → single-line comment token

| Extension(s) | Language | Comment token |
|---|---|---|
| `.lua` | Lua | `--` |
| `.py` | Python | `#` |
| `.rb` | Ruby | `#` |
| `.sh`, `.bash`, `.zsh` | Shell | `#` |
| `.js`, `.jsx`, `.mjs`, `.cjs` | JavaScript | `//` |
| `.ts`, `.tsx` | TypeScript | `//` |
| `.go` | Go | `//` |
| `.rs` | Rust | `//` |
| `.java` | Java | `//` |
| `.kt`, `.kts` | Kotlin | `//` |
| `.c`, `.h` | C | `//` |
| `.cpp`, `.cc`, `.hpp` | C++ | `//` |
| `.cs` | C# | `//` |
| `.swift` | Swift | `//` |
| `.php` | PHP | `//` or `#` |
| `.sql` | SQL | `--` |
| `.yaml`, `.yml` | YAML config (usually not app code) | `#` |
| `.el` | Emacs Lisp | `;;` |
| `.clj`, `.cljs` | Clojure | `;` |
| `.hs` | Haskell | `--` |
| `.ex`, `.exs` | Elixir | `#` |

If the extension isn't listed, grep a couple of sample files for whichever token (`//`, `#`, `--`, `;`, `;;`) appears at the start of a line most often, and use that.

## Test command detection

Check in this order, use the first that matches:

1. `Makefile` / `makefile` at repo root with a `test:` target → `make test`
2. `package.json` with a `scripts.test` entry → `npm test` (or `yarn test` / `pnpm test` if a matching lockfile is present)
3. `pyproject.toml` or `pytest.ini` or `setup.cfg` with a `[tool:pytest]`/`[pytest]` section → `pytest`
4. `Cargo.toml` → `cargo test`
5. `go.mod` → `go test ./...`
6. `Gemfile` with rspec/minitest in it → `bundle exec rspec` or `rake test`
7. An existing project skill/doc (e.g. a `tdd` or `tests` skill, a CONTRIBUTING.md, a CI config like `.github/workflows/*.yml`) that names the test invocation explicitly

If more than one of these applies (e.g. both a Makefile test target and package.json test script) or none apply, ask the user for the exact command instead of guessing — running the wrong or a partial suite would silently defeat the "always run tests after touching a file" rule this skill depends on.
