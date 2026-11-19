# gitcmp: prove two git refs have the same content

Use this when you rewrite history and need to know that nothing moved: a big branch split into a stack of small branches, a squash, a rebase, a filter-branch, a cherry-pick series. The question is always the same. Does the tip of the new history hold the same files, bytes and modes as the tip of the old one?

Three commands answer three different questions. Keep them apart.

| Question | Command | What it proves |
| --- | --- | --- |
| Is the content the same? | `git rev-parse A^{tree}` equals `git rev-parse B^{tree}` | every path, every byte, every file mode, every symlink target |
| What differs? | `git diff-tree -r --no-renames A B` | the mode and blob hash of each path that differs |
| Did the commits keep their story? | `git range-diff base..A base..B` | how each patch moved; nothing about the end trees |

## 1. The one that settles it

```sh
test "$(git rev-parse A^{tree})" = "$(git rev-parse B^{tree})" && echo EQUAL || echo DIFFERENT
```

A tree object names, recursively, every path, its mode (`100644`, `100755`, `120000` symlink, `160000` submodule) and its blob hash. Two refs with the same tree hash have the same committed content, to the strength of the hash. There is no stronger check in git, and no third-party tool adds one.

What a tree hash does not cover, and why that is fine:

- Commit messages, authors, dates, parents. Those are the history, not the content.
- Untracked and ignored files, build output, `node_modules`. Not committed, so not content.
- Empty directories. Git cannot store them, so they cannot differ.
- Submodule and LFS contents. The tree holds the gitlink or the pointer, and that is what gets compared.
- What lands on disk after checkout under a local `core.autocrlf`. A `.gitattributes` change is in the tree and is caught; a local config difference is not a property of the branch.

A CRLF line ending inside a blob changes the blob, so it changes the tree. That one is caught.

## 2. The one that explains a difference

```sh
git diff-tree -r --no-renames A B
```

This is plumbing. It skips the pager, `textconv`, external diff drivers and rename guessing, and it prints one line per path that differs, with both modes and both blob hashes:

```
:100644 100755 3b18e5... 3b18e5... M lib/foo.js      # mode flip, same bytes
:100644 100644 3b18e5... 9ae747... M lib/bar.js      # bytes changed
:000000 100644 000000... c1a2b3... A lib/new.js      # added on B
```

Add `--exit-code` to use it in a script: exit 0 means no difference. Add `-p` to see the hunks.

## 3. The one that checks the story

```sh
git range-diff main..A main..B
```

It pairs each commit of one series with its closest match in the other and shows how the patch moved. Use it when you rewrote commit messages or reordered commits and want to see what changed per commit. After a split, most commits change shape, so it reports many mismatches even when the tips are equal. It never compares the end trees. Neither do `git cherry`, `git log --cherry-pick` or `jj interdiff`.

## The traps

Each of these was tested in a throwaway repo. Each one returned "equal" on trees that were not.

| Check | What it missed |
| --- | --- |
| `diff -rq` on two checkouts | a `100644` to `100755` mode flip, exit 0. It also follows symlinks, so a link and a file with the same bytes look equal, and it sees untracked files |
| `git diff --ignore-cr-at-eol A B`, or `-w`, or any `--ignore-*` | a CRLF-only change, exit 0 |
| `git diff --stat A B` | a mode-only change shows as `\| 0`. Add `--summary` to print `mode change 100644 => 100755` |
| `git diff --name-status A B` | rename detection is on by default and hides that the old path is gone. Add `--no-renames` |
| `git merge-tree --write-tree A B` | a clean merge of two different trees exits 0. A merge result says nothing about equality |
| `git diff --no-index dirA dirB` on two worktrees | compares the disk, not the commits. The `.git` file of each worktree always differs |
| `git diff A B` with the repo's pager | `diff-so-fancy` or `delta` rewrites the output. Use `git --no-pager` or `--quiet` in scripts |

## Before you compare

- Pin the base. If `main` moves between the old branch and the new one, the trees differ by exactly the new `main` commits. Build the new history on the same base commit, or rebase the old branch onto the new base before comparing.
- List the modes once. `git ls-tree -r A | awk '{print $1}' | sort | uniq -c` shows whether the branch has any `100755`, `120000` or `160000` entries. If it is all `100644`, nothing in the tree hash can surprise you.
- On macOS, `core.ignorecase` is true on APFS. A case-only path difference is in the tree but can collapse on disk. The tree hash still catches it.

## After a rewrite

`git filter-branch` and friends update the branch refs, not the worktrees that have those branches checked out. A worktree then shows the rewritten file as a staged modification, because its index still holds the old blob. Reset the index and the file, nothing else:

```sh
git reset -q -- README.md && git checkout -q -- README.md
```

Then drop the backup refs that `filter-branch` leaves behind, or they show up in `--all`:

```sh
git for-each-ref --format='%(refname)' refs/original | xargs -n1 git update-ref -d
```

## The script

`scripts/gitcmp A B` runs the first check and prints the diff-tree when the trees differ. `--explain` prints it on demand, `--commits` adds the range-diff from the merge base, `--base REF` sets that base, and `--quiet` leaves only the exit code: 0 equal, 1 different, 2 usage or a bad ref.

## The function, if you want it inline

```sh
# gitcmp A B [base]: tree equality, the differing paths, and the commit story when a base is given
gitcmp() {
  local a="$1" b="$2" base="$3"
  local ta tb
  ta="$(git rev-parse "$a^{tree}")" || return 1
  tb="$(git rev-parse "$b^{tree}")" || return 1
  if [[ "$ta" == "$tb" ]]; then
    echo "EQUAL  $a $b  tree $ta"
  else
    echo "DIFFERENT  $a $b"
    git --no-pager diff-tree -r --no-renames "$a" "$b"
  fi
  if [[ -n "$base" ]]; then
    git --no-pager range-diff "$base..$a" "$base..$b"
  fi
}
```