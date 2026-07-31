Seemed like the thing to do

* [🔧 Setup](#setup)
  * [📦 Prerequisites](#prerequisites)
  * [🚀 Install](#install)
  * [🎹 Peripherals](#peripherals)
* [📂 Structure](#structure)
  * [⚙️  Configuration](#configuration)
  * [📜 Scripts](#scripts)
  * [🪟 Hammerspoon](#hammerspoon)
  * [🍺 Brewfiles](#brewfiles)

Setup
-----

To set up the dotfiles, run the following in order:

### Prerequisites

Install [Zim], a modular Zsh framework:

```zsh
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
```

### Install

> [!CAUTION]
> __DO NOT__ run the setup scripts if you do not fully understand
> what they do. Seriously, __DON'T__!

| Script | Description |
|:-------|:------------|
| `./install/setup.sh` | Base system setup |
| `./install/brew` | [Homebrew] formulae and casks |
| `./install/git` | [Git] configuration |
| `./install/gh` | [GitHub CLI] extensions (stacked PRs, etc.) |
| `./install/npm` | [Node.js] global packages |
| `./install/go` | [Go] toolchain |
| `./install/python` | [Python] environment |
| `./install/editors` | Editor installation and config |
| `./install/hammerspoon` | [Hammerspoon] automation |
| `./install/atuin` | [Atuin] shell history |

### Peripherals

```zsh
# Peripherals! Peripherals! Peripherals! I mean developers!
./install/bespoke/g915/setup
```

Structure
---------

### Configuration

Core dotfiles that get symlinked into `~`:

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

