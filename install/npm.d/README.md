# Global npm-ecosystem packages

Durable record of globally-installed packages across **npm**, **pnpm**, and
**bun**, organized by concern. The npm-world analogue of `brew.d/`.

## Format

Each `globals.<set>` file lists one package per line as `<manager> <pkg>`:

```
# Documentation & diagrams
pnpm @mermaid-js/mermaid-cli
npm  json
```

- The first `# ` line is the set's description (shown by `npmwr sets`).
- `manager` is one of `npm` | `pnpm` | `bun`.
- Blank lines and `#` comments are ignored.

## Sets

- `globals.cli`  — command-line utilities
- `globals.dev`  — development & release tooling
- `globals.llms` — AI / LLM tooling
- `globals.docs` — documentation & diagrams
- `globals.devops` — cloud & devops tooling

## Usage

Add / remove entries with `scripts/npmwr` — it installs (or uninstalls) the
package with the chosen manager, updates the right `globals.<set>` file, and
auto-commits a `dist(npm) …` change:

```bash
npmwr install @mermaid-js/mermaid-cli --set docs --manager pnpm
npmwr install vbump            # prompts for set + manager via gum
npmwr install some-tool --no-install --set cli --manager npm   # record only
npmwr uninstall vbump
npmwr sets                     # table of sets
npmwr sets docs                # entries in one set, grouped by manager
```

Reinstall everything (e.g. on a fresh machine) with the runner:

```bash
install/npm              # all sets
install/npm --set docs   # one set
```
