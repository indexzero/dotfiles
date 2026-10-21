Seemed like the thing to do

* [🔧 Setup](#setup)
  * [🥾 Bootstrap](#bootstrap)
  * [🚀 Install](#install)
  * [🎹 Peripherals](#peripherals)
* [📂 Structure](#structure)
  * [⚙️  Configuration](#configuration)
  * [📜 Scripts](#scripts)
  * [🪟 Hammerspoon](#hammerspoon)
  * [🍺 Brewfiles](#brewfiles)

Setup
-----

> [!CAUTION]
> __DO NOT__ run the setup scripts if you do not fully understand
> what they do. Seriously, __DON'T__!

### Bootstrap

On a fresh Apple Silicon Mac, one line:

```zsh
curl -fsSL https://raw.githubusercontent.com/indexzero/dotfiles/main/install/bootstrap.zsh | zsh
```

It installs the Command Line Tools and Homebrew, clones this repo to
`~/Git/indexzero/dotfiles`, runs `./install/dotfiles install`, then every
installer in the table below in order, and finishes with Nix and the
`workstation/` devenv machine. Every step is idempotent, so re-running is
how you resume. `BOOTSTRAP_SKIP="brew nix"` skips steps;
`BOOTSTRAP_ONLY=nix` runs one. `editors` and `hammerspoon` are skipped
unless asked for.

A machine without a display takes the `headless` profile, which omits the
brew sets it has no use for (`terminal`, `desktop`, `databases`) and the
ghostty link. The profile is recorded once in
`$XDG_CONFIG_HOME/dotfiles/profile`; `install/brew`, `hostdiff`, and later
bootstrap runs honour it from then on. See `install/brew.d/profiles`.

To try a branch before it merges, in a VM:

```zsh
curl -fsSL https://raw.githubusercontent.com/indexzero/dotfiles/<branch>/install/bootstrap.zsh | DOTFILES_REF=<branch> BOOTSTRAP_PROFILE=headless zsh
```

[Zim] needs no separate install: `.zshrc` downloads `zimfw.zsh` and builds
its modules the first time it runs.

### Install

The pieces, for running one at a time:

| Script | Description |
|:-------|:------------|
| `./install/bootstrap.zsh` | Everything below, from a blank machine |
| `./install/setup.sh` | Base system setup, runs `./install/dotfiles install` |
| `./install/dotfiles` | Clone `main` and symlink dotfiles into `~` |
| `./install/nix` | [Nix] seed via [devenv] machines, see `workstation/` |
| `./install/brew` | [Homebrew] formulae and casks |
| `./install/git` | [Git] configuration |
| `./install/gh` | [GitHub CLI] extensions (stacked PRs, etc.) |
| `./install/npm` | [Node.js] global packages |
| `./install/go` | [Go] toolchain |
| `./install/python` | [Python] environment |
| `./install/editors` | Editor installation and config |
| `./install/hammerspoon` | [Hammerspoon] automation |
| `./install/atuin` | [Atuin] shell history |
| `./install/vale` | [Vale] prose linting with [vale-llm-slop] styles |

### Updating

`$HOME` links into a dedicated clone at `~/.local/share/dotfiles`, never
into a dev checkout. Edits made in a dev checkout reach the machine only
after they merge to `main`:

```zsh
dotfiles pull     # fast-forward the clone to origin/main, then relink
dotfiles status   # branch, local edits, and link health
```

The clone refuses commits and has no push URL. Anything that writes
through a symlink still edits the clone, for example an installer that
appends to `~/.zshrc`. Carry those edits back with `hostdiff`:

```zsh
hostdiff clone            # list local edits in the clone
hostdiff ingest           # print them, plus any copies shadowing a link, as a patch
hostdiff ingest --apply   # apply that patch to $DOTFILES_HOME for review
```

Once the change merges to `main`, `dotfiles pull` returns the clone to clean.

### Peripherals

```zsh
# Peripherals! Peripherals! Peripherals! I mean developers!
./install/bespoke/g915/setup
```

Structure
---------

### Configuration

Core dotfiles that `./install/dotfiles` symlinks into `~` from the installed clone:

| File | Description |
|:-----|:------------|
| [`.zshrc`][zshrc] | Zsh shell configuration |
| [`.gitconfig`][gitconfig] | Git configuration |
| [`.gitignore`][gitignore] | Global gitignore patterns |
| [`.gitattributes`][gitattributes] | Git LFS and binary tracking |
| [`.aliases`][aliases] | Shell aliases |
| [`.functions`][functions] | Shell functions |
| [`.exports`][exports] | Environment variables |
| [`.editorconfig`][editorconfig] | Editor configuration |

### Scripts

Utility scripts in [`scripts/`][scripts dir]:

| Script | Description |
|:-------|:------------|
| `git-fetch-all` | Fetch all remotes in bulk |
| `wtbk` | Copy untracked scratch files from worktrees back to the main repo |
| `ghi` | GitHub issue helper |
| `ghr` | GitHub release helper |
| `gho` | GitHub organization helper |

### Brewfiles

Homebrew packages are organized into modular [Brewfiles][brew dir]:

| Brewfile | Description |
|:---------|:------------|
| `Brewfile` | Core formulae |
| `Brewfile.cli` | CLI tools |
| `Brewfile.databases` | Database engines |
| `Brewfile.dev` | Development tools |
| `Brewfile.docs` | Documentation tools |
| `Brewfile.media` | Media and A/V tools |
| `Brewfile.network` | Network utilities |
| `Brewfile.productivity` | Productivity apps |
| `Brewfile.system` | System utilities |
| `Brewfile.terminals` | Terminal emulators |
| `Brewfile.vcs` | Version control tools |

License
-------

The code is available under the [MIT license][license].

<!-- Link labels: -->

[repo]: https://github.com/indexzero
[Zim]: https://github.com/zimfw/zimfw
[Homebrew]: https://brew.sh
[Git]: https://git-scm.com
[Node.js]: https://nodejs.org
[Go]: https://go.dev
[Python]: https://www.python.org
[Hammerspoon]: https://www.hammerspoon.org
[Atuin]: https://atuin.sh
[Vale]: https://vale.sh
[vale-llm-slop]: https://github.com/Syntaf/vale-llm-slop
[Nix]: https://nixos.org/
[devenv]: https://devenv.sh/machines/

[zshrc]: dotfiles/.zshrc
[gitconfig]: dotfiles/.gitconfig
[gitignore]: dotfiles/.gitignore
[gitattributes]: dotfiles/.gitattributes
[aliases]: dotfiles/.aliases
[functions]: dotfiles/.functions
[exports]: dotfiles/.exports
[editorconfig]: dotfiles/.editorconfig

[scripts dir]: scripts/
[brew dir]: install/brew.d/

