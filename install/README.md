# Initial Installation

- [Sublime Text 3](#sublime-text-3)
- [Homebrew packages](#homebrew)
- [`npm` packages](#npm)
- [Chrome Extensions](#chrome-extensions)

## Volta

```
curl https://get.volta.sh | bash
```

### Sublime Text 3

- [See: `Package Control.sublime-preferences`](../files/Package\ Control.sublime-preferences)

### `Homebrew`

**Install packages**
```
./install/brew
```

Notable:
- `ccat`

### `npm`

**Install packages**
```
./install/npm
```

Notable:
- `forever`
- `json`
- `vbump`
- `git-semver2-tag`

### Chrome Extensions

- [Earth View from Google Maps](https://chrome.google.com/webstore/detail/earth-view-from-google-ma/bhloflhklmhfpedakmangadcdofhnnoh/related)([Source](https://chrome.google.com/webstore/detail/earth-view-from-google-ma/bhloflhklmhfpedakmangadcdofhnnoh/related))

## Docker

- Docker Desktop: https://www.docker.com/products/docker-desktop/


# Future Maybes

- https://fig.io/

# Known issues

1. ~/.zshrc installation clobbers any newer zim installation from original zim install command (which must be run prior to `./install/setup.sh`) 

2. `.npmrc` configs for local installation not set as part of `./install/npm`:
``` sh
npm c set prefix $HOME/.local
```
3. `./install/git` requires `sudo`, should we use `--force`? 
```
+./install/git:9> git lfs install --system
warning: current user is not root/admin, system install is likely to fail.
warning: error running /Library/Developer/CommandLineTools/usr/libexec/git-core/git 'config' '--includes' '--system' '--replace-all' 'filter.lfs.process' 'git-lfs filter-process': 'error: could not lock config file /etc/gitconfig: Permission denied' 'exit status 255'
Run `git lfs install --force` to reset Git configuration.
```