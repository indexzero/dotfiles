# Git Status Tools - Emulated Output for ~/Git/indexzero

> **Note**: This is an approximation of what each tool would output.
> These tools were NOT installed or run - output is emulated based on actual `git status` data.

---

## 1. multi-git-status (mgitstatus)

```
$ mgitstatus ~/Git/indexzero -e

./dotfiles.private     : Untracked files  Needs push (final-setup)
./_all_docs            : Uncommitted changes  Needs upstream (custom-remote)  Stash (3)
./milkshakes           : Uncommitted changes  Untracked files
./spectree             : Untracked files  Needs upstream (protract-2)
./flatlock             : Untracked files  Needs upstream (timetravel)  Stash (3)
./bangten              : Uncommitted changes
./dotvibes             : Uncommitted changes  Untracked files  Needs upstream (2026)
./dotfiles             : Uncommitted changes  Needs upstream (2026)  Stash (1)
./slop.store           : Uncommitted changes  Untracked files
./robbinshinds.family  : Uncommitted changes  Untracked files  Needs upstream (install.2)  Stash (1)
./.notes               : Untracked files
./.skunkworks          : Untracked files  Needs push (main)  Stash (1)
./hjsm                 : Untracked files
./vlurp                : Untracked files  Stash (2)
./localbest            : Untracked files
./presentations        : Uncommitted changes  Needs upstream (master)
./errs                 : Untracked files  Needs upstream (ES2026)
./frost-discuss        : Untracked files  Needs upstream (talk-feedback)
./mono                 : Untracked files  Needs upstream (js-logs/bq)  Stash (1)
./.online              : Uncommitted changes  Untracked files  Needs upstream (oss-for-earth)  Stash (1)
./socket-packageurl-js : Untracked files  Needs upstream (fix/encodeComponent)
./npm-diff-worker      : Uncommitted changes  Needs upstream (examples/isolate)
./settercase           : Uncommitted changes  Untracked files
```

---

## 2. reposcan

```
$ reposcan -r ~/Git/indexzero --filter dirty

REPOSITORY              BRANCH                           STATUS
----------------------  -------------------------------  ------------------
dotfiles.private        final-setup                      +1 unpushed
_all_docs               custom-remote                    dirty, no upstream
milkshakes              main                             dirty
spectree                protract-2                       dirty, no upstream
flatlock                timetravel                       dirty, no upstream
bangten                 main                             dirty
dotvibes                2026                             dirty, no upstream
dotfiles                2026                             dirty, no upstream
slop.store              main                             dirty
robbinshinds.family     install.2                        dirty, no upstream
.notes                  main                             dirty
.skunkworks             main                             +5 unpushed
hjsm                    main                             dirty
vlurp                   vnext                            dirty
localbest               initial                          dirty
presentations           master                           dirty, no upstream
errs                    ES2026                           dirty, no upstream
frost-discuss           talk-feedback                    dirty, no upstream
mono                    js-logs/bq                       dirty, no upstream
.online                 oss-for-earth                    dirty, no upstream
socket-packageurl-js    fix/encodeComponent              dirty, no upstream
npm-diff-worker         examples/isolate                 dirty, no upstream
settercase              main                             dirty

Found 23 dirty repositories out of 41 total.
```

**JSON output (`--output json`):**
```json
{
  "dirty": [
    {"path": "dotfiles.private", "branch": "final-setup", "uncommitted": 0, "untracked": 3, "unpushed": 1},
    {"path": "_all_docs", "branch": "custom-remote", "uncommitted": 1, "untracked": 0, "unpushed": 0, "no_upstream": true},
    {"path": "milkshakes", "branch": "main", "uncommitted": 1, "untracked": 1, "unpushed": 0},
    {"path": "dotvibes", "branch": "2026", "uncommitted": 6, "untracked": 13, "no_upstream": true}
  ],
  "clean": 18,
  "total": 41
}
```

---

## 3. gits

```
$ gits status ~/Git/indexzero

 dotfiles.private        final-setup                 ? 3   ↑ 1
 _all_docs               custom-remote               * 1   ⚠ no upstream
 milkshakes              main                        * 1  ? 1
 spectree                protract-2                  ? 1   ⚠ no upstream
 flatlock                timetravel                  ? 7   ⚠ no upstream
 career-chip             main                        ✓
 bangten                 main                        * 1
 dotvibes                2026                        + 6  ? 13  ⚠ no upstream
 enterprise-packages     issue-2110/npm-10.8.2-...   ⚠ no upstream
 dotfiles                2026                        * 3   ⚠ no upstream
 melange                 fetch-into-directory        ✓
 cgr.career              int-dev/14086               ⚠ no upstream
 slop.store              main                        * 1  ? 6
 robbinshinds.family     install.2                   + 2  ? 3   ⚠ no upstream
 .notes                  main                        ? 1
 .skunkworks             main                        ? 2   ↑ 5
 undtils                 main                        ✓
 contextbook             initial                     ⚠ no upstream
 hjsm                    main                        ? 6
 vlurp                   vnext                       ? 5
 vbump                   master                      ✓
 infra-images            fix/js-dev-backfiller       ⚠ no upstream
 sigstore-js-issuer-bug  main                        ✓
 images-private          js-squad                    ⚠ no upstream
 localbest               initial                     ? 1
 footage                 undici                      ⚠ no upstream
 nerf-gun                main                        ✓
 presentations           master                      * 4   ⚠ no upstream
 npm-high-impact         script-params               ⚠ no upstream
 ecosystems-wheel-...    rfo/argo-dags               ⚠ no upstream
 errs                    ES2026                      ? 4   ⚠ no upstream
 frost-discuss           talk-feedback               ? 1   ⚠ no upstream
 mono                    js-logs/bq                  ? 5   ⚠ no upstream
 mikeal                  economist                   ⚠ no upstream
 .nbwat                  main                        ⚠ no upstream
 .online                 oss-for-earth               * 4  ? 1   ⚠ no upstream
 sigstore-js             main                        ✓
 socket-packageurl-js    fix/encodeComponent         ? 10  ⚠ no upstream
 baltar                  main                        ✓
 npm-diff-worker         examples/isolate            + 8   ⚠ no upstream
 settercase              main                        * 2  ? 12

Legend: ✓ clean  + staged  * modified  ? untracked  ↑ ahead  ↓ behind  ⚠ warning
```

---

## 4. gita

```
$ gita ll

dotfiles.private        final-setup                       ?3   ↑1
_all_docs               custom-remote                *1        $3  ⚠
milkshakes              main                         *1   ?1
spectree                protract-2                        ?1        ⚠
flatlock                timetravel                        ?7        $3  ⚠
career-chip             main
bangten                 main                         *1
dotvibes                2026                         +6   ?13       ⚠
enterprise-packages     issue-2110/npm-10.8.2-pa...                 ⚠
dotfiles                2026                         *3        $1  ⚠
melange                 fetch-into-directory
cgr.career              int-dev/14086                               ⚠
slop.store              main                         *1   ?6
robbinshinds.family     install.2                    +2   ?3   $1  ⚠
.notes                  main                              ?1
.skunkworks             main                              ?2   ↑5  $1
undtils                 main
contextbook             initial                                     ⚠
hjsm                    main                              ?6
vlurp                   vnext                             ?5        $2
vbump                   master
infra-images            fix/js-dev-backfiller                       ⚠
sigstore-js-issuer-bug  main
images-private          js-squad                                    ⚠
localbest               initial                           ?1
footage                 undici                                      ⚠
nerf-gun                main
presentations           master                       *4             ⚠
npm-high-impact         script-params                          $1  ⚠
ecosystems-wheel-reb... rfo/argo-dags                          $1  ⚠
errs                    ES2026                            ?4        ⚠
frost-discuss           talk-feedback                     ?1        ⚠
mono                    js-logs/bq                        ?5   $1  ⚠
mikeal                  economist                               ⚠
.nbwat                  main                                        ⚠
.online                 oss-for-earth                *4   ?1   $1  ⚠
sigstore-js             main
socket-packageurl-js    fix/encodeComponent               ?10       ⚠
baltar                  main
npm-diff-worker         examples/isolate             +8             ⚠
settercase              main                         *2   ?12

Legend: + staged  * unstaged  ? untracked  $ stash  ↑ ahead  ↓ behind  ⚠ no upstream
```

---

## 5. git-summary (npm)

```
$ git-summary -d

┌─────────────────────────┬─────────────────────────┬────────┬──────────┬───────────┬───────┐
│ Repository              │ Branch                  │ Staged │ Modified │ Untracked │ Stash │
├─────────────────────────┼─────────────────────────┼────────┼──────────┼───────────┼───────┤
│ dotfiles.private        │ final-setup ↑1          │      0 │        0 │         3 │     0 │
│ _all_docs               │ custom-remote           │      0 │        1 │         0 │     3 │
│ milkshakes              │ main                    │      0 │        1 │         1 │     0 │
│ spectree                │ protract-2              │      0 │        0 │         1 │     0 │
│ flatlock                │ timetravel              │      0 │        0 │         7 │     3 │
│ bangten                 │ main                    │      0 │        1 │         0 │     0 │
│ dotvibes                │ 2026                    │      6 │        0 │        13 │     0 │
│ dotfiles                │ 2026                    │      0 │        3 │         0 │     1 │
│ slop.store              │ main                    │      0 │        1 │         6 │     0 │
│ robbinshinds.family     │ install.2               │      2 │        0 │         3 │     1 │
│ .notes                  │ main                    │      0 │        0 │         1 │     0 │
│ .skunkworks             │ main ↑5                 │      0 │        0 │         2 │     1 │
│ hjsm                    │ main                    │      0 │        0 │         6 │     0 │
│ vlurp                   │ vnext                   │      0 │        0 │         5 │     2 │
│ localbest               │ initial                 │      0 │        0 │         1 │     0 │
│ presentations           │ master                  │      0 │        4 │         0 │     0 │
│ errs                    │ ES2026                  │      0 │        0 │         4 │     0 │
│ frost-discuss           │ talk-feedback           │      0 │        0 │         1 │     0 │
│ mono                    │ js-logs/bq              │      0 │        0 │         5 │     1 │
│ .online                 │ oss-for-earth           │      0 │        4 │         1 │     1 │
│ socket-packageurl-js    │ fix/encodeComponent     │      0 │        0 │        10 │     0 │
│ npm-diff-worker         │ examples/isolate        │      8 │        0 │         0 │     0 │
│ settercase              │ main                    │      0 │        2 │        12 │     0 │
└─────────────────────────┴─────────────────────────┴────────┴──────────┴───────────┴───────┘

23 repositories need attention, 18 clean (41 total)
```

---

## 6. uncommitted

```
$ uncommitted ~/Git/indexzero

/Users/cjr/Git/indexzero/_all_docs - uncommitted changes
/Users/cjr/Git/indexzero/milkshakes - uncommitted changes
/Users/cjr/Git/indexzero/bangten - uncommitted changes
/Users/cjr/Git/indexzero/dotvibes - uncommitted changes
/Users/cjr/Git/indexzero/dotfiles - uncommitted changes
/Users/cjr/Git/indexzero/slop.store - uncommitted changes
/Users/cjr/Git/indexzero/robbinshinds.family - uncommitted changes
/Users/cjr/Git/indexzero/presentations - uncommitted changes
/Users/cjr/Git/indexzero/.online - uncommitted changes
/Users/cjr/Git/indexzero/npm-diff-worker - uncommitted changes
/Users/cjr/Git/indexzero/settercase - uncommitted changes

11 repositories with uncommitted changes found.
```

> **Note**: uncommitted only checks for uncommitted changes (staged/unstaged),
> not untracked files or unpushed commits.

---

## 7. myrepos (mr)

```
$ mr status

mr status: /Users/cjr/Git/indexzero/dotfiles.private
 M  ?? file1.txt
 M  ?? file2.txt
 M  ?? file3.txt

mr status: /Users/cjr/Git/indexzero/_all_docs
 M config.json

mr status: /Users/cjr/Git/indexzero/milkshakes
 M package.json
?? new-file.js

mr status: /Users/cjr/Git/indexzero/dotvibes
M  src/app.ts
M  src/index.ts
M  src/utils.ts
M  tsconfig.json
M  package.json
M  README.md
?? (13 untracked files)

mr status: /Users/cjr/Git/indexzero/dotfiles
 M dotfiles/.gitignore
 M dotfiles/.zshrc
 M install/npm

mr status: /Users/cjr/Git/indexzero/robbinshinds.family
M  src/config.ts
M  package.json
?? (3 untracked files)

mr status: /Users/cjr/Git/indexzero/.skunkworks
?? file1.txt
?? file2.txt

mr status: /Users/cjr/Git/indexzero/npm-diff-worker
M  examples/basic.js
M  examples/advanced.js
M  examples/config.json
(8 staged files)

... (and 14 more repositories with changes)

mr status: finished (23 dirty, 18 ok)
```

---

## 8. git-status-all

```
$ git-status-all ~/Git/indexzero

dotfiles.private [final-setup] 3 untracked, 1 ahead
_all_docs [custom-remote] 1 modified
milkshakes [main] 1 modified, 1 untracked
spectree [protract-2] 1 untracked
flatlock [timetravel] 7 untracked
bangten [main] 1 modified
dotvibes [2026] 6 staged, 13 untracked
dotfiles [2026] 3 modified
slop.store [main] 1 modified, 6 untracked
robbinshinds.family [install.2] 2 staged, 3 untracked
.notes [main] 1 untracked
.skunkworks [main] 2 untracked, 5 ahead
hjsm [main] 6 untracked
vlurp [vnext] 5 untracked
localbest [initial] 1 untracked
presentations [master] 4 modified
errs [ES2026] 4 untracked
frost-discuss [talk-feedback] 1 untracked
mono [js-logs/bq] 5 untracked
.online [oss-for-earth] 4 modified, 1 untracked
socket-packageurl-js [fix/encodeComponent] 10 untracked
npm-diff-worker [examples/isolate] 8 staged
settercase [main] 2 modified, 12 untracked

23 repositories with changes
```

---

## 9. mu-repo

```
$ mu st

--------------------------------------------------------------------------------
Executing "git status -s" on:
  _all_docs, bangten, dotfiles, dotfiles.private, dotvibes, flatlock,
  frost-discuss, hjsm, localbest, milkshakes, mono, .notes, .online,
  presentations, robbinshinds.family, settercase, .skunkworks, slop.store,
  socket-packageurl-js, spectree, vlurp, errs, npm-diff-worker

--------------------------------------------------------------------------------
_all_docs:
 M config.json

bangten:
 M src/index.ts

dotfiles:
 M dotfiles/.gitignore
 M dotfiles/.zshrc
 M install/npm

dotfiles.private:
?? file1.txt
?? file2.txt
?? file3.txt

dotvibes:
M  src/app.ts
M  src/index.ts
M  src/utils.ts
M  tsconfig.json
M  package.json
M  README.md
?? (13 untracked)

npm-diff-worker:
M  examples/basic.js
M  examples/advanced.js
M  examples/config.json
M  examples/runner.js
M  examples/util.js
M  examples/test1.js
M  examples/test2.js
M  examples/test3.js

... (output continues for remaining repos)
--------------------------------------------------------------------------------
```

---

## 10. ghq + scripting

```
$ for repo in $(ghq list -p | grep indexzero); do
    echo "=== $repo ==="
    git -C "$repo" status -s
  done

=== /Users/cjr/Git/indexzero/dotfiles.private ===
?? file1.txt
?? file2.txt
?? file3.txt

=== /Users/cjr/Git/indexzero/_all_docs ===
 M config.json

=== /Users/cjr/Git/indexzero/milkshakes ===
 M package.json
?? new-file.js

=== /Users/cjr/Git/indexzero/spectree ===
?? untracked.txt

=== /Users/cjr/Git/indexzero/flatlock ===
?? file1.txt
?? file2.txt
?? file3.txt
?? file4.txt
?? file5.txt
?? file6.txt
?? file7.txt

=== /Users/cjr/Git/indexzero/career-chip ===

=== /Users/cjr/Git/indexzero/bangten ===
 M src/index.ts

=== /Users/cjr/Git/indexzero/dotvibes ===
M  src/app.ts
M  src/index.ts
M  src/utils.ts
M  tsconfig.json
M  package.json
M  README.md
?? (13 untracked files)

=== /Users/cjr/Git/indexzero/dotfiles ===
 M dotfiles/.gitignore
 M dotfiles/.zshrc
 M install/npm

... (continues for all 41 repositories)
```

---

## Summary Comparison

| Tool | Discovers Repos | Shows Uncommitted | Shows Unpushed | Shows Untracked | Shows Stash | Output Formats |
|------|-----------------|-------------------|----------------|-----------------|-------------|----------------|
| mgitstatus | Auto (depth) | Yes | Yes | Yes | Yes | Text |
| reposcan | Auto (config) | Yes | Yes | Yes | No | Table/JSON |
| gits | Auto/Config | Yes | Yes | Yes | No | Table/Tree/JSON |
| gita | Registration | Yes | Yes | Yes | Yes | Text (colored) |
| git-summary | Auto (-d) | Yes | Yes | Yes | Yes | Table |
| uncommitted | Auto | Yes | No | No | No | Text |
| myrepos | Registration | Yes | No | Yes | No | Text |
| git-status-all | Auto | Yes | Yes | Yes | No | Text |
| mu-repo | Registration | Yes | No | Yes | No | Text |
| ghq + script | ghq list | Yes | Manual | Yes | Manual | Raw git |

---

## Repos Needing Attention (~/Git/indexzero)

### Has Uncommitted Changes (staged or unstaged)
- `_all_docs`, `milkshakes`, `bangten`, `dotvibes`, `dotfiles`, `slop.store`
- `robbinshinds.family`, `presentations`, `.online`, `npm-diff-worker`, `settercase`

### Has Unpushed Commits
- `dotfiles.private` (1 ahead)
- `.skunkworks` (5 ahead)

### Has Untracked Files Only
- `spectree`, `flatlock`, `.notes`, `hjsm`, `vlurp`, `localbest`
- `errs`, `frost-discuss`, `mono`, `socket-packageurl-js`

### Missing Upstream (local branch not tracking remote)
- 24 repositories have no upstream configured

### Has Stashes
- `_all_docs` (3), `flatlock` (3), `vlurp` (2)
- `dotfiles`, `robbinshinds.family`, `.skunkworks`, `npm-high-impact`
- `ecosystems-wheel-rebuilder`, `mono`, `.online` (1 each)

### Clean Repos
- `career-chip`, `melange`, `undtils`, `vbump`, `sigstore-js-issuer-bug`
- `nerf-gun`, `sigstore-js`, `baltar`
