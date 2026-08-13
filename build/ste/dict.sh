#!/usr/bin/env zsh
#
# dict.sh — build styles/STE/DictionaryFull.yml from the ASD-STE100 PDF.
#
# Pipeline:  ASD-STE100_ISSUE9.pdf
#              -> pdftotext -layout (fixed-width, preserves the 4-column table)
#              -> per-page split on form feed
#              -> column parse  [0:19] word | [19:46] meaning-or-alternative
#              -> Vale `substitution` rule
#
# The PDF is NOT redistributable and is NOT checked in. Download your own copy,
# free, from https://www.asd-ste100.org/request.html and pass its path.
#
# The generated DictionaryFull.yml is a derivative of ASD's copyrighted
# dictionary. `settings/vale/.gitignore` ignores `styles/` wholesale, so the
# output is untracked by default. Keep it that way in any public repo.
#
# Usage:
#   build/ste/dict.sh /path/to/ASD-STE100_ISSUE9.pdf
#   build/ste/dict.sh --out /tmp/DictionaryFull.yml ~/Downloads/ASD-STE100.pdf
#   STE_PDF=~/Downloads/ASD-STE100.pdf build/ste/dict.sh
#
# Requires: pdftotext (poppler), python3

set -euo pipefail

DOTFILES="$(cd "${0:A:h}/../.." && pwd)"
OUT="$DOTFILES/settings/vale/styles/STE/DictionaryFull.yml"
POS_OUT=""
PDF="${STE_PDF:-}"
KEEP_TEXT=""

usage() { sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--out)      OUT="$2"; shift 2 ;;
    --pos-report)  POS_OUT="$2"; shift 2 ;;
    --keep-text)   KEEP_TEXT="$2"; shift 2 ;;
    -h|--help)     usage 0 ;;
    -*)            echo "unknown flag: $1" >&2; usage 2 ;;
    *)             PDF="$1"; shift ;;
  esac
done

[ -n "$PDF" ] || { echo "error: no PDF given. Pass a path or set STE_PDF." >&2; usage 2; }
[ -f "$PDF" ] || { echo "error: no such file: $PDF" >&2; exit 1; }

for dep in pdftotext python3; do
  command -v "$dep" >/dev/null 2>&1 || {
    echo "error: missing dependency '$dep'." >&2
    [ "$dep" = pdftotext ] && echo "  brew install poppler" >&2
    exit 1
  }
done

WORK="${KEEP_TEXT:-$(mktemp -d)}"
[ -n "$KEEP_TEXT" ] && mkdir -p "$WORK"
cleanup() { [ -z "$KEEP_TEXT" ] && rm -rf "$WORK"; }
trap cleanup EXIT

echo "==> pdftotext -layout"
echo "    $PDF"
# -layout is REQUIRED. Without it the four columns interleave into garbage and
# every word maps to the wrong alternative.
pdftotext -layout -enc UTF-8 -eol unix "$PDF" "$WORK/full.txt"

PAGES=$(grep -c $'\f' "$WORK/full.txt" || true)
echo "    extracted $(wc -c <"$WORK/full.txt" | tr -d ' ') chars, ~$PAGES page breaks"

mkdir -p "$(dirname "$OUT")"

echo "==> parsing dictionary"
python3 - "$WORK/full.txt" "$OUT" "$POS_OUT" <<'PYTHON'
import re, sys, pathlib, datetime

src, out, pos_out = sys.argv[1], sys.argv[2], (sys.argv[3] or None)

# Column geometry, measured from the Issue 9 layout:
#   Word (part of speech)   Approved meaning / ALTERNATIVES   STE EXAMPLE   Non-STE example
#   0                       19                                46            ~65
WORD, ALT = slice(0, 19), slice(19, 46)

POS = r"n|v|adj|adv|prep|conj|pron|art|int|abbr|pref"
HEAD = re.compile(rf"^([A-Za-z][A-Za-z0-9\-'’/.& ]*?)\s*\(({POS})\)")
ALTP = re.compile(rf"^([A-Z][A-Z0-9\-'’/.& ]*?)\s*\(({POS})\)")
INFLECT = re.compile(r"^([A-Z][A-Z0-9\-'’/ ]*),?$")

pages = pathlib.Path(src).read_text(encoding="utf-8", errors="replace").split("\f")

approved: dict[str, set] = {}   # base word -> {pos}
inflections: set = set()        # ATTACHES, ATTACHED, ...
nonapproved: dict = {}          # (word, pos) -> [alternatives]
dict_pages = 0

for page in pages:
    lines = page.splitlines()
    # A dictionary page has at least two headwords in the word column.
    if sum(1 for l in lines if HEAD.match(l[WORD].strip())) < 2:
        continue
    dict_pages += 1
    cur = None
    for l in lines:
        w, a = l[WORD].strip(), l[ALT].strip()
        m = HEAD.match(w)
        if m:
            base, pos = m.group(1).strip(), m.group(2)
            cur = (base, pos)
            if base.isupper():
                approved.setdefault(base.lower(), set()).add(pos)
            else:
                nonapproved.setdefault((base.lower(), pos), [])
        elif w and cur and cur[0].isupper():
            # continuation of an approved entry: an inflected form
            im = INFLECT.match(w)
            if im:
                inflections.add(im.group(1).strip().rstrip(",").lower())
        if cur and not cur[0].isupper():
            am = ALTP.match(a)
            if am:
                alt = am.group(1).strip().lower()
                bucket = nonapproved[(cur[0].lower(), cur[1])]
                if alt not in bucket:
                    bucket.append(alt)

# ---- build the swap table -------------------------------------------------
# Guard 1 (upstream doc): multi-word keys need \s+ — the PDF and the target
# markdown are both hard-wrapped, so a literal space silently fails to match.
# Guard 2 (upstream doc): never swap a word STE itself approves. A word can be
# approved as one part of speech and non-approved as another ("check" is an
# approved noun and a non-approved verb). `ignorecase: true` cannot tell them
# apart, so the whole entry is skipped and reported separately.
swaps: dict = {}
skipped_pos: dict = {}
approved_forms = set(approved) | inflections

for (word, pos), alts in sorted(nonapproved.items()):
    if not alts:
        continue
    if word in approved_forms:
        skipped_pos.setdefault(word, []).append((pos, alts[0]))
        continue
    key = re.escape(word).replace(r"\ ", r"\s+") if " " in word else word
    swaps.setdefault(key, alts[0])

stamp = datetime.date.today().isoformat()
body = [
    "# STE.DictionaryFull — GENERATED. Do not edit by hand.",
    "#",
    f"# Built {stamp} by build/ste/dict.sh from ASD-STE100 Issue 9.",
    "#",
    "# DERIVATIVE OF A COPYRIGHTED WORK. The ASD-STE100 Dictionary is copyright",
    "# ASD (AeroSpace, Security and Defence Industries Association of Europe).",
    "# The specification is free to download and is NOT free to redistribute.",
    "# Keep this file out of any public repository.",
    "#",
    f"# {len(swaps)} substitutions from {len(nonapproved)} non-approved entries.",
    f"# {len(skipped_pos)} entries skipped: the word is also STE-approved under",
    "# another part of speech, which a substitution rule cannot disambiguate.",
    "extends: substitution",
    'message: "STE: use \'%s\' instead of \'%s\'."',
    "link: https://www.asd-ste100.org/",
    "level: error",
    "ignorecase: true",
    "swap:",
]
# Single-quote every key and value. Two reasons, both load-bearing:
#   1. YAML resolves bare `true`, `false`, `on`, `off`, `yes`, `no` as booleans.
#      The dictionary contains all of them ("true -> correct", "exempt -> no").
#      Unquoted, those entries are silently dropped — verified against vale.
#   2. Single quotes, not double: YAML processes backslash escapes inside
#      double-quoted scalars, which would mangle the \s+ in multi-word keys.
def q(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"

for k, v in sorted(swaps.items()):
    body.append(f"  {q(k)}: {q(v)}")

pathlib.Path(out).write_text("\n".join(body) + "\n", encoding="utf-8")

# ---- the part no substitution rule can do ---------------------------------
if pos_out:
    rep = [
        "# STE part-of-speech restrictions — GENERATED, ADVISORY, not a Vale rule.",
        f"# Built {stamp} by build/ste/dict.sh. Derivative of copyrighted ASD content.",
        "#",
        "# Each word below is APPROVED as one part of speech and NON-APPROVED as",
        "# another. A `substitution` rule with ignorecase cannot tell them apart, so",
        "# these are excluded from DictionaryFull.yml. Enforcing them needs a POS",
        "# tagger (see Vale `sequence` rules) or a human.",
        "",
    ]
    for word in sorted(skipped_pos):
        ok = ",".join(sorted(approved.get(word, {"—"})))
        bad = "; ".join(f"{p} -> {a}" for p, a in skipped_pos[word])
        rep.append(f"{word}: approved as ({ok}); non-approved as {bad}")
    pathlib.Path(pos_out).write_text("\n".join(rep) + "\n", encoding="utf-8")

print(f"    dictionary pages     : {dict_pages}")
print(f"    approved headwords   : {len(approved)} (+{len(inflections)} inflected forms)")
print(f"    non-approved entries : {len(nonapproved)}")
print(f"    substitutions written: {len(swaps)}")
print(f"    skipped (POS clash)  : {len(skipped_pos)}")
PYTHON

echo "==> wrote $OUT"
[ -n "$POS_OUT" ] && echo "==> wrote $POS_OUT"

if command -v vale >/dev/null 2>&1; then
  echo "==> validating with vale"
  TMPMD="$WORK/validate.md"
  printf 'Attempt to ascertain the defect.\n' >"$TMPMD"
  vale --config "$DOTFILES/settings/vale/.vale.ini" "$TMPMD" 2>&1 | tail -8 || true
else
  echo "==> vale not installed; skipped validation"
fi

cat <<EOF

Done. To enable the rule, add STE.DictionaryFull to your BasedOnStyles, or
leave it — Vale loads every .yml in the STE style dir when STE is enabled.

The output is gitignored by settings/vale/.gitignore (it ignores styles/).
That is deliberate. If you want it tracked in THIS private repo, add:

    !styles/STE/DictionaryFull.yml

to settings/vale/.gitignore. Do not do that in a public repo.
EOF
