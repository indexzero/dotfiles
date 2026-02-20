[indexzero][repo]'s dotfiles
==========================

Seemed like the thing to do. My dotfiles.

Table of Contents
-----------------

* [🔧 Setup](#setup)
  * [📦 Prerequisites](#prerequisites)
  * [🚀 Install](#install)
  * [🎹 Peripherals](#peripherals)
* [📂 Structure](#structure)
  * [⚙️  Configuration](#configuration)
  * [📜 Scripts](#scripts)
  * [🪟 Hammerspoon](#hammerspoon)
  * [🍺 Brewfiles](#brewfiles)
* [🛠️  Tools of Note](#tools-of-note)
* [📱 Apps](#apps)
* [💄 Customize](#customize)
  * [🌐 Local Settings](#local-settings)
* [📑 License](#license)

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
| `git-changelog-all` | Generate changelogs across repos |
| `git-fetch-all` | Fetch all remotes in bulk |
| `gtrbk` | Git worktree backup utility |
| `ghi` | GitHub issue helper |
| `ghr` | GitHub release helper |
| `gho` | GitHub organization helper |
| `qt4slack.sh` | Convert QuickTime video to Slack-ready MP4 |
| `grype-explainer.sh` | Security vulnerability explainer |
| `sploy` | Deploy utility |
| `lsync` | Sync utility |

### Hammerspoon

macOS automation and window management via [Hammerspoon],
configured in [`hammerspoon/faces/`][faces]:

* Window management and layout persistence
* Custom keybindings
* Sleep/wake recovery

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

Tools of Note
-------------

| Tool | Description |
|:-----|:------------|
| [Streamhut](https://streamhut.io/) | Stream your terminal to the web |
| [Mermaid Live](https://mermaid.live) | Live diagram editor |
| [ActivityWatch](https://activitywatch.net/) | Automated time tracker |
| [asciinema](https://asciinema.org/) | Record terminal sessions |
| [IsoFlow](https://isoflow.io/) | Isometric infrastructure diagrams |
| [Floobits](https://floobits.com/) | Collaborative editing |
| [Social Grep](https://www.socialgrep.com/) | Reddit search and analysis |
| [D2](https://d2lang.com/) | Declarative diagramming language |

Apps
----

| App | Description |
|:---|:------------|
| [Obsidian](https://obsidian.md) | Knowledge base and note-taking |

Customize
---------

### Local Settings

The dotfiles can be easily extended to suit additional local
requirements by using the following files:

#### `~/.gitconfig.local`

The `~/.gitconfig.local` file will be automatically included after
the configurations from `~/.gitconfig`, thus, allowing its content
to overwrite or add to the existing Git configurations.

__Note:__ Use `~/.gitconfig.local` to store sensitive information
such as the Git user credentials, e.g.:

```gitconfig
[commit]

    # Sign commits using GPG.
    # https://help.github.com/articles/signing-commits-using-gpg/

    gpgSign = true

[user]

    name = Your Name
    email = account@example.com
    signingKey = XXXXXXXX
```

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
[faces]: hammerspoon/faces/
[brew dir]: install/brew.d/

[license]: LICENSE.txt
