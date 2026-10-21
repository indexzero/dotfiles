#!/usr/bin/env zsh
#
# bootstrap.zsh - set up a fresh Apple Silicon Mac from nothing.
#
#   curl -fsSL https://raw.githubusercontent.com/indexzero/dotfiles/main/install/bootstrap.zsh | zsh
#
# Runs, in order: Command Line Tools, Homebrew, a dev checkout of this repo,
# the installed clone + symlinks (install/dotfiles), every Brewfile set, mise
# and the runtimes, the per-tool installers, then Nix + the devenv machine
# (install/nix). Every step is idempotent, so re-running after a failure is
# the resume mechanism; BOOTSTRAP_SKIP trims steps you know are done.
#
# Knobs (environment):
#   DOTFILES_REF    branch to check out and to clone into the install dir.
#                   Default main. Set to a PR branch to test it in a VM:
#                     curl -fsSL .../<branch>/install/bootstrap.zsh | DOTFILES_REF=<branch> zsh
#   DOTFILES_HOME   dev checkout          (default ~/Git/indexzero/dotfiles)
#   DOTFILES_DIR    installed clone       (default ~/.local/share/dotfiles)
#   BOOTSTRAP_SKIP  space-separated steps to skip (default "editors hammerspoon")
#   BOOTSTRAP_ONLY  space-separated steps to run, and nothing else
#
# The whole script is one function called on the last line. zsh then parses
# everything before running anything, so a child that reads stdin (sudo, gum,
# the go installer's upgrade prompt) cannot swallow the rest of the pipe.

bootstrap_main() {
  set -euo pipefail

  # ── config ──────────────────────────────────────────────────────────────────
  : "${DOTFILES_REF:=main}"
  : "${DOTFILES_HOME:=$HOME/Git/indexzero/dotfiles}"
  : "${DOTFILES_DIR:=$HOME/.local/share/dotfiles}"
  : "${DOTFILES_REMOTE:=https://github.com/indexzero/dotfiles.git}"
  : "${BOOTSTRAP_SKIP:=editors hammerspoon}"
  : "${BOOTSTRAP_ONLY:=}"
  export DOTFILES_HOME DOTFILES_DIR DOTFILES_REMOTE
  export DOTFILES_BRANCH="$DOTFILES_REF"   # install/dotfiles clones this branch

  local -a STEPS=(
    preflight clt homebrew checkout dotfiles brew mise runtimes git
    settings editors hammerspoon nix doctor
  )

  # ── output ──────────────────────────────────────────────────────────────────
  local BOLD=$'\e[1m' DIM=$'\e[2m' RED=$'\e[31m' YEL=$'\e[33m' GRN=$'\e[32m' RST=$'\e[0m'
  say()  { print -r -- "$*"; }
  hdr() { print -r -- "${BOLD}==> $*${RST}"; }
  note() { print -r -- "    ${DIM}$*${RST}"; }
  warn() { print -u2 -r -- "${YEL}bootstrap:${RST} $*"; }
  die()  { print -u2 -r -- "${RED}bootstrap:${RST} $*"; exit 1; }

  # Prompts (sudo, gum, read) need a terminal. Under `curl | zsh` stdin is the
  # pipe, so hand the children the tty instead.
  if [[ -r /dev/tty ]]; then exec </dev/tty; fi

  # ── steps ───────────────────────────────────────────────────────────────────
  step_preflight() {
    [[ "$(uname -s)" == Darwin ]] || die "macOS only"
    [[ "$(uname -m)" == arm64 ]]  || die "Apple Silicon only (uname -m: $(uname -m))"
    [[ $EUID -ne 0 ]] || die "run as your user, not root; sudo is requested where needed"
    note "ref=$DOTFILES_REF  checkout=$DOTFILES_HOME  clone=$DOTFILES_DIR"
    note "macOS $(sw_vers -productVersion)  $(uname -m)  user=$USER"
    [[ "$DOTFILES_REF" == main ]] || warn "DOTFILES_REF=$DOTFILES_REF: the clone will track that branch; 'hostdiff clone' reports it until you re-clone from main"
  }

  # Command Line Tools give us git, make, and the SDK. The softwareupdate
  # route is non-interactive; xcode-select --install is the GUI fallback.
  step_clt() {
    if xcode-select -p >/dev/null 2>&1 && /usr/bin/git --version >/dev/null 2>&1; then
      note "present at $(xcode-select -p)"; return 0
    fi
    if xcode-select -p >/dev/null 2>&1; then
      # Developer dir exists but /usr/bin/git refuses: the Xcode license gate.
      # See gotchas/macos.md "/usr/bin/git and the Xcode license".
      die "/usr/bin/git refuses to run (Xcode license?). Fix: sudo xcodebuild -license accept, or sudo xcode-select --switch /Library/Developer/CommandLineTools"
    fi
    say "Installing Command Line Tools"
    local flag=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress label
    touch "$flag"
    label="$(softwareupdate -l 2>/dev/null | grep -o 'Command Line Tools for Xcode-[0-9.]*' | sort -V | tail -1 || true)"
    if [[ -n "$label" ]]; then
      sudo softwareupdate -i "$label" --verbose
    else
      warn "softwareupdate found no CLT label; falling back to the GUI installer"
      xcode-select --install 2>/dev/null || true
      say "Waiting for the Command Line Tools installer to finish"
      until xcode-select -p >/dev/null 2>&1; do sleep 10; done
    fi
    rm -f "$flag"
    xcode-select -p >/dev/null 2>&1 || die "Command Line Tools still missing"
  }

  step_homebrew() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
      note "present"
    else
      say "Installing Homebrew"
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    eval "$(/opt/homebrew/bin/brew shellenv)"
  }

  # The dev checkout: where edits are authored. Nothing in $HOME links here.
  step_checkout() {
    if [[ -d "$DOTFILES_HOME/.git" ]]; then
      note "present at $DOTFILES_HOME; fetching $DOTFILES_REF"
      git -C "$DOTFILES_HOME" fetch -q origin "$DOTFILES_REF"
      git -C "$DOTFILES_HOME" checkout -q "$DOTFILES_REF"
      git -C "$DOTFILES_HOME" merge -q --ff-only "origin/$DOTFILES_REF" || warn "$DOTFILES_HOME has diverged from origin/$DOTFILES_REF; leaving it"
    else
      say "Cloning $DOTFILES_REMOTE ($DOTFILES_REF) into $DOTFILES_HOME"
      mkdir -p "${DOTFILES_HOME:h}"
      git clone -q --branch "$DOTFILES_REF" "$DOTFILES_REMOTE" "$DOTFILES_HOME"
    fi
  }

  # The installed clone + symlinks. This is install/setup.sh minus the
  # `source ~/.zshrc`, which a non-interactive script has no business doing;
  # the shell at the end of this run does that. .zshrc bootstraps zim itself
  # (downloads zimfw.zsh and builds init.zsh), so the separate zim installer
  # the README used to ask for is not needed.
  step_dotfiles() {
    mkdir -p "$HOME/.backup"
    zsh "$DOTFILES_HOME/install/dotfiles" install
    [[ -L "$HOME/.zshrc" ]] || die "install/dotfiles did not link ~/.zshrc"
  }

  step_brew() {
    zsh "$DOTFILES_HOME/install/brew"
  }

  # Links settings/mise from the clone, installs the runtimes in
  # settings/mise/config.toml (node, python, go, bun, deno, rust). Everything
  # after this step needs those on PATH, so activate shims for this process.
  step_mise() {
    zsh "$DOTFILES_HOME/install/mise"
    export MISE_DATA_DIR="${MISE_DATA_DIR:-$HOME/.local/share/mise}"
    export MISE_STATE_DIR="${MISE_STATE_DIR:-$HOME/.local/state/mise}"
    eval "$(mise activate zsh --shims)"
    export PATH="$HOME/.local/bin:$PATH"
  }

  # Per-ecosystem global tool sets. Each is a runner over a durable list
  # (npm.d/, GO_TOOLS, cargo.d/) and skips what is already installed.
  step_runtimes() {
    zsh "$DOTFILES_HOME/install/npm"
    zsh "$DOTFILES_HOME/install/go"
    zsh "$DOTFILES_HOME/install/cargo"
    zsh "$DOTFILES_HOME/install/gh"
    zsh "$DOTFILES_HOME/install/python"
  }

  # git-lfs, user and system (sudo).
  step_git() {
    zsh "$DOTFILES_HOME/install/git"
  }

  # Each links a settings/ directory from the clone, or installs a tool that
  # keeps its config elsewhere (atuin).
  step_settings() {
    local s
    for s in starship worktrunk ghostty vale; do
      zsh "$DOTFILES_HOME/install/$s"
    done
    bash "$DOTFILES_HOME/install/atuin"
  }

  # Skipped by default: hardcodes a Sublime Text path and a sudo ln.
  step_editors() {
    zsh "$DOTFILES_HOME/install/editors"
  }

  # Skipped by default: wants Hammerspoon.app and accessibility permissions.
  step_hammerspoon() {
    zsh "$DOTFILES_HOME/install/hammerspoon"
  }

  # Nix via the Determinate installer (multi-user daemon, APFS volume, survives
  # macOS updates), then the devenv machine from the installed clone. See
  # workstation/README.md. devenv.lock is generated into the clone's
  # workstation/ on first deploy; carry it back with `hostdiff ingest`.
  step_nix() {
    if command -v nix >/dev/null 2>&1 || [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
      note "nix present"
    else
      say "Installing Nix (Determinate installer)"
      curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
    fi
    local daemon=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    [[ -r "$daemon" ]] && { set +u; source "$daemon"; set -u; }
    command -v nix >/dev/null 2>&1 || die "nix installed but not on PATH; open a new shell and re-run with BOOTSTRAP_ONLY=nix"
    if [[ ! -d "$DOTFILES_DIR/workstation" ]]; then
      warn "no workstation/ in the clone ($DOTFILES_REF); skipping the devenv machine"
      return 0
    fi
    zsh "$DOTFILES_HOME/install/nix" --yes
  }

  step_doctor() {
    local hd="$DOTFILES_DIR/scripts/hostdiff"
    if [[ -x "$hd" ]]; then
      zsh "$hd" || warn "hostdiff reports drift (see above)"
    fi
    print
    hdr "Done. Next, by hand:"
    note "open a new terminal: zim builds its modules on the first .zshrc"
    note "restore the gitignored private files: dotfiles/.private, dotfiles/.ssh, .gitconfig-git*"
    note "git config --show-origin --get user.email   # confirm the identity include"
    note "dotfiles status                              # clone on $DOTFILES_REF, links healthy"
    note "hostdiff ingest                              # devenv.lock and any installer edits, back to $DOTFILES_HOME"
    [[ "$DOTFILES_REF" == main ]] || note "DOTFILES_DIR=$DOTFILES_DIR tracks $DOTFILES_REF; re-run 'dotfiles clone' from main after it merges"
  }

  # ── runner ──────────────────────────────────────────────────────────────────
  local -a skip=(${=BOOTSTRAP_SKIP}) only=(${=BOOTSTRAP_ONLY})
  local s t0 t1 finished=()
  for s in $STEPS; do
    # (I) yields an index, 0 when absent; (r) yields an empty match, which
    # set -u reports as an unset parameter.
    if (( ${#only} )) && (( ! ${only[(I)$s]} )); then continue; fi
    if (( ${skip[(I)$s]} )); then hdr "$s ${DIM}(skipped)${RST}"; continue; fi
    hdr "$s"
    t0=$SECONDS
    if ! "step_$s"; then
      print
      die "step '$s' failed. Fix it, then resume with:
  BOOTSTRAP_SKIP='${finished[*]} $BOOTSTRAP_SKIP' DOTFILES_REF=$DOTFILES_REF zsh $DOTFILES_HOME/install/bootstrap.zsh"
    fi
    t1=$SECONDS
    note "$s ok ($((t1 - t0))s)"
    finished+=("$s")
  done

  print
  hdr "${GRN}bootstrap complete${RST}"
  note "exec zsh -l   # or open a new terminal"
}

bootstrap_main "$@"
