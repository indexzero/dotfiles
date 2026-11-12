#!/usr/bin/env bash
#
# atuin-inspect.sh - read-only stats for an atuin data directory
#
# Answers "what is taking up the space?" ahead of any compaction:
#   totals     row counts, date range, command-size histogram, rows per month
#   repeats    duplicate commands (by text, and by atuin's own dedup key)
#   authors    who logged each command: you, or an agent (claude-code, codex, ...)
#   locations  where commands ran: cwd, project rollup, hostname
#   storage    bytes on disk per file, per table/index, per sync-record store
#
# Every connection is opened read-only. This script never writes to atuin.
#
# Usage:
#   atuin-inspect.sh [section ...] [--dir DIR] [--top N] [--me NAME] [--depth N]
#
#   section      any of: totals repeats authors locations storage (default: all)
#   --dir DIR    atuin data dir (default: asks `atuin info`). Point this at a
#                backup to inspect it, or at a scratch copy to measure a
#                compaction before and after.
#   --top N      rows in each "top" table (default: 15)
#   --me NAME    the author value that means "typed by a human" (default: $USER)
#   --depth N    path components kept in the project rollup (default: 5,
#                i.e. /Users/you/Git/org/repo). "repo-worktrees" folds into "repo".

set -euo pipefail

TOP=15
ME="${USER:-$(id -un)}"
DEPTH=5
DIR=""
SECTIONS=()

usage() { sed -n '3,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)   DIR="$2"; shift 2 ;;
    --top)   TOP="$2"; shift 2 ;;
    --me)    ME="$2"; shift 2 ;;
    --depth) DEPTH="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    totals|repeats|authors|locations|storage) SECTIONS+=("$1"); shift ;;
    all) shift ;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done
[ ${#SECTIONS[@]} -gt 0 ] || SECTIONS=(totals repeats authors locations storage)

case "$TOP$DEPTH" in *[!0-9]*) echo "--top and --depth take integers" >&2; exit 2 ;; esac
command -v sqlite3 >/dev/null || { echo "sqlite3 not found" >&2; exit 1; }

if [ -z "$DIR" ]; then
  if command -v atuin >/dev/null; then
    dbpath=$(atuin info 2>/dev/null | sed -n 's/^client db path: "\(.*\)"$/\1/p')
    [ -n "$dbpath" ] && DIR=$(dirname "$dbpath")
  fi
  [ -n "$DIR" ] || DIR="$HOME/.local/share/atuin"
fi
[ -f "$DIR/history.db" ] || { echo "no history.db in $DIR" >&2; exit 1; }

# Run SQL against one of the atuin databases, read-only.
# A WAL-mode database with no -wal file beside it (a backup, say) cannot be
# opened with -readonly, so those are opened as immutable instead.
db() {
  local file="$DIR/$1" sql="$2"; shift 2
  if [ -f "$file-wal" ]; then
    sqlite3 -readonly "$@" "$file" "$sql"
  else
    sqlite3 "$@" "file:$file?immutable=1" "$sql"
  fi
}
table() { db "$1" "$2" -header -column; }
title() { printf '\n== %s ==\n' "$1"; }
sub()   { printf '\n-- %s\n' "$1"; }

ME_SQL=${ME//\'/\'\'}
# Shared SQL fragments. Timestamps are nanoseconds since the epoch.
BYTES="length(cast(command as blob))"
mb()  { printf "printf('%%.1f', (%s) / 1048576.0)" "$1"; }
pct() { printf "printf('%%.1f', 100.0 * (%s) / (%s))" "$1" "$2"; }
DAY="date(timestamp / 1000000000, 'unixepoch')"
SHOW="substr(replace(replace(command, char(10), ' '), char(9), ' '), 1, 72)"
AUTHOR="coalesce(nullif(author, ''), '<none>')"
IS_AGENT="($AUTHOR <> '$ME_SQL')"

totals() {
  title "totals ($DIR/history.db)"
  table history.db "
    select printf('%,d', count(*))                    as commands,
           printf('%,d', count(distinct command))     as distinct_commands,
           printf('%,d', count(deleted_at))           as soft_deleted,
           printf('%,d', count(distinct session))     as sessions,
           $(mb "sum($BYTES)")                        as command_mb,
           min($DAY)                                  as first,
           max($DAY)                                  as last
      from history;"

  sub "command size histogram"
  table history.db "
    with h as (select $BYTES as b from history),
         t as (select count(*) n, sum(b) b from h)
    select case when b <= 100 then '1) <= 100 B'
                when b <= 1000 then '2) <= 1 KB'
                when b <= 10000 then '3) <= 10 KB'
                else '4) > 10 KB' end                 as size,
           printf('%,d', count(*))                    as commands,
           $(pct 'count(*)' '(select n from t)')      as pct_rows,
           $(mb 'sum(b)')                             as mb,
           $(pct 'sum(b)' '(select b from t)')        as pct_bytes
      from h group by 1 order by 1;"

  sub "per month (agent = any author other than '$ME')"
  table history.db "
    select strftime('%Y-%m', timestamp / 1000000000, 'unixepoch') as month,
           printf('%,d', count(*))                                as commands,
           printf('%,d', sum(not $IS_AGENT))                      as by_me,
           printf('%,d', sum($IS_AGENT))                          as by_agents,
           $(mb "sum($BYTES)")                                    as mb,
           $(mb "sum(case when $IS_AGENT then $BYTES else 0 end)") as agent_mb
      from history group by 1 order by 1;"
}

repeats() {
  title "repeats"
  sub "redundant = rows beyond the first copy of each key"
  table history.db "
    with t as (select count(*) n, sum($BYTES) b from history),
         by_text as (select count(*) c, $BYTES b from history group by command),
         by_key  as (select count(*) c, $BYTES b from history group by command, cwd, hostname)
    select 'same command text' as dedup_key,
           printf('%,d', count(*)) as distinct_keys,
           printf('%,d', sum(c > 1)) as keys_repeated,
           printf('%,d', sum(c - 1)) as redundant_rows,
           $(pct 'sum(c - 1)' '(select n from t)') as pct_rows,
           $(mb 'sum((c - 1) * b)') as redundant_mb
      from by_text
    union all
    select 'command + cwd + hostname (atuin history dedup)',
           printf('%,d', count(*)), printf('%,d', sum(c > 1)), printf('%,d', sum(c - 1)),
           $(pct 'sum(c - 1)' '(select n from t)'), $(mb 'sum((c - 1) * b)')
      from by_key;"

  sub "repeats by author (same command text, within that author)"
  table history.db "
    with g as (select $AUTHOR as author, count(*) c, $BYTES b from history group by 1, command)
    select author,
           printf('%,d', sum(c))     as commands,
           printf('%,d', count(*))   as distinct_commands,
           printf('%,d', sum(c - 1)) as redundant_rows,
           $(pct 'sum(c - 1)' 'sum(c)') as pct_redundant,
           $(mb 'sum((c - 1) * b)')  as redundant_mb
      from g group by 1 order by sum(c) desc;"

  sub "top $TOP repeated commands by count"
  table history.db "
    select count(*) as n, count(distinct $AUTHOR) as authors, count(distinct cwd) as cwds,
           $SHOW as command
      from history group by command having count(*) > 1 order by 1 desc limit $TOP;"

  sub "top $TOP repeated commands by redundant bytes"
  table history.db "
    select (count(*) - 1) * $BYTES / 1024 as redundant_kb, count(*) as n, $BYTES as bytes,
           group_concat(distinct $AUTHOR) as authors, substr($SHOW, 1, 48) as command
      from history group by command having count(*) > 1
     order by (count(*) - 1) * $BYTES desc limit $TOP;"
}

authors() {
  title "authors (the history.author column; '$ME' is treated as you)"
  table history.db "
    with t as (select count(*) n, sum($BYTES) b from history)
    select $AUTHOR                                    as author,
           printf('%,d', count(*))                    as commands,
           $(pct 'count(*)' '(select n from t)')      as pct_rows,
           $(mb "sum($BYTES)")                        as mb,
           $(pct "sum($BYTES)" '(select b from t)')   as pct_bytes,
           cast(avg($BYTES) as integer)               as avg_bytes,
           max($BYTES)                                as max_bytes,
           printf('%,d', count(intent))               as with_intent,
           $(pct 'sum(exit <> 0)' 'count(*)')         as pct_failed,
           min($DAY)                                  as first,
           max($DAY)                                  as last
      from history group by 1 order by count(*) desc;"

  sub "top $TOP agent intents (history.intent)"
  table history.db "
    select count(*) as n, group_concat(distinct $AUTHOR) as authors, substr(intent, 1, 72) as intent
      from history where intent is not null group by intent order by 1 desc limit $TOP;"
}

locations() {
  title "locations"
  sub "top $TOP working directories ($(db history.db 'select count(distinct cwd) from history') distinct)"
  table history.db "
    with t as (select count(*) n from history)
    select printf('%,d', count(*))                 as commands,
           $(pct 'count(*)' '(select n from t)')   as pct_rows,
           $(pct "sum($IS_AGENT)" 'count(*)')      as pct_agent,
           $(mb "sum($BYTES)")                     as mb,
           cwd
      from history group by cwd order by count(*) desc limit $TOP;"

  sub "top $TOP projects (first $DEPTH path components, '-worktrees' folded in)"
  db history.db "
    select cwd, count(*), sum($IS_AGENT), sum($BYTES) from history group by cwd;" -separator $'\t' |
    awk -F'\t' -v depth="$DEPTH" '
      {
        n = split($1, part, "/"); key = ""
        for (i = 2; i <= n && i <= depth + 1; i++) {
          p = part[i]; if (i == depth + 1) sub(/-worktrees$/, "", p)
          key = key "/" p
        }
        if ($1 !~ /^\//) key = $1
        rows[key] += $2; agent[key] += $3; bytes[key] += $4; dirs[key]++; total += $2
      }
      END {
        for (k in rows)
          printf "%d\t%.1f\t%.1f\t%.1f\t%d\t%s\n", rows[k], 100 * rows[k] / total,
                 100 * agent[k] / rows[k], bytes[k] / 1048576, dirs[k], k
      }' | sort -t$'\t' -k1,1nr | head -n "$TOP" |
    awk -F'\t' 'BEGIN { printf "%-9s %-8s %-9s %-7s %-5s %s\n", "commands", "pct_rows", "pct_agent", "mb", "cwds", "project" }
                { printf "%-9d %-8s %-9s %-7s %-5d %s\n", $1, $2, $3, $4, $5, $6 }'

  sub "hostnames (atuin stores these as host:user)"
  table history.db "
    select printf('%,d', count(*)) as commands, min($DAY) as first, max($DAY) as last,
           replace(replace(hostname, char(10), '\n'), char(13), '\r') as hostname
      from history group by hostname order by count(*) desc limit $TOP;"
}

storage() {
  title "storage ($DIR)"
  sub "files"
  ( cd "$DIR" && { ls -l -- *.db *.db-wal 2>/dev/null || true; } |
      awk '{ printf "%8.1f MB  %s\n", $5 / 1048576, $NF; t += $5 } END { printf "%8.1f MB  total\n", t / 1048576 }' )

  for f in history.db records.db; do
    [ -f "$DIR/$f" ] || continue
    sub "$f by table and index"
    table "$f" "
      select $(mb 'sum(pgsize)') as mb, $(mb 'sum(unused)') as unused_mb, name
        from dbstat group by name having sum(pgsize) >= 1048576 order by sum(pgsize) desc;" 2>/dev/null ||
      echo "(this sqlite3 build has no dbstat table)"
    table "$f" "
      select $(mb 'page_count * page_size') as file_mb,
             $(mb 'freelist_count * page_size') as free_mb_reclaimed_by_vacuum
        from pragma_page_count, pragma_page_size, pragma_freelist_count;"
  done

  [ -f "$DIR/records.db" ] || return 0
  sub "sync record store (records.db: encrypted, append-only; this is what syncs)"
  local host_id=""
  [ -f "$DIR/meta.db" ] && host_id=$(db meta.db "select value from meta where key = 'host_id';" 2>/dev/null || true)
  table records.db "
    select tag, version, printf('%,d', count(*)) as records,
           $(mb 'sum(length(data) + length(cek))') as mb,
           cast(avg(length(data) + length(cek)) as integer) as avg_bytes,
           date(min(timestamp) / 1000000000, 'unixepoch') as first,
           date(max(timestamp) / 1000000000, 'unixepoch') as last,
           host || case when replace(host, '-', '') = '$host_id' then '  (this machine)' else '' end as host
      from store group by tag, version, host order by sum(length(data) + length(cek)) desc;"
}

for s in "${SECTIONS[@]}"; do "$s"; done
