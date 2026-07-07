# Global cargo crates

Durable record of globally-installed Rust crates (`cargo install`), organized
by concern. The cargo-world analogue of `brew.d/` and `npm.d/`.

## Format

Each `crates.<set>` file lists one crate per line as `<crate> [install flags]`:

```
# Command-line utilities (cargo install)
cship
cargo-outdated --locked
```

- The first `# ` line is the set's description.
- Anything after the crate name is passed through to `cargo install`.
- Blank lines and `#` comments are ignored. Source-built tools installed with
  `cargo install --path .` are recorded as comments, not entries.

## Sets

- `crates.cli` — command-line utilities

## Usage

Reinstall everything (e.g. on a fresh machine) with the runner:

```bash
install/cargo              # all sets
install/cargo --set cli    # one set
```

The runner skips crates already present in `cargo install --list`, so re-runs
are cheap. Rust itself is managed by mise (`install/mise`), not this runner.
