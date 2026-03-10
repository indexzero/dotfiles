#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scan-mp3.sh [--install-brew-deps] [--output-dir DIR] FILE_OR_DIR...
USAGE
}

need_cmd() { command -v "$1" >/dev/null 2>&1; }
err() { printf 'error: %s\n' "$*" >&2; }
log() { printf '%s\n' "$*" >&2; }

install_deps=0
output_root=""
inputs=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-brew-deps) install_deps=1; shift ;;
    --output-dir) output_root="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; while [[ $# -gt 0 ]]; do inputs+=("$1"); shift; done ;;
    *) inputs+=("$1"); shift ;;
  esac
done

if [[ ${#inputs[@]} -eq 0 ]]; then
  usage
  exit 2
fi

if (( install_deps )); then
  if ! need_cmd brew; then
    err "Homebrew not found"
    exit 1
  fi
  brew install mp3val ffmpeg media-info exiftool clamav
fi

for cmd in mp3val ffprobe mediainfo exiftool; do
  if ! need_cmd "$cmd"; then
    err "missing required command: $cmd"
    exit 1
  fi
done

if [[ -z "$output_root" ]]; then
  output_root="./mp3-scan-$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$output_root"

have_clam=0
if need_cmd clamscan; then
  have_clam=1
fi
if need_cmd freshclam; then
  if ! freshclam >/dev/null 2>&1; then
    log "warning: freshclam failed; continuing with current signatures"
  fi
fi

sanitize() {
  local s="$1"
  s="${s//\//__}"
  s="${s//$'\n'/ }"
  printf '%s' "$s"
}

collect_files() {
  local p
  for p in "$@"; do
    if [[ -d "$p" ]]; then
      find "$p" -type f \( -iname '*.mp3' -o -iname '*.mpeg3' \) -print
    elif [[ -f "$p" ]]; then
      printf '%s\n' "$p"
    else
      log "warning: skipping missing path: $p"
    fi
  done
}

mapfile -t files < <(collect_files "${inputs[@]}" | awk '!seen[$0]++')

if [[ ${#files[@]} -eq 0 ]]; then
  err "no MP3 files found"
  exit 1
fi

summary_tsv="$output_root/summary.tsv"
printf 'file\tclamav\tffprobe\tmediainfo\texiftool\tmp3val\n' > "$summary_tsv"

for f in "${files[@]}"; do
  base="$(sanitize "$f")"
  stem="$output_root/$base"
  mkdir -p "$stem"

  clam_status="SKIP"
  if (( have_clam )); then
    if clamscan --infected --no-summary -- "$f" >"$stem/clamav.txt" 2>&1; then
      clam_status="OK"
    else
      rc=$?
      if [[ $rc -eq 1 ]]; then
        clam_status="FOUND"
      else
        clam_status="ERR($rc)"
      fi
    fi
  fi

  if ffprobe -v error -show_format -show_streams -of json -- "$f" >"$stem/ffprobe.json" 2>"$stem/ffprobe.stderr"; then
    ffprobe_status="OK"
  else
    ffprobe_status="ERR"
  fi

  if mediainfo --Output=JSON -- "$f" >"$stem/mediainfo.json" 2>"$stem/mediainfo.stderr"; then
    mediainfo_status="OK"
  else
    mediainfo_status="ERR"
  fi

  if exiftool -j -G1 -a -s -- "$f" >"$stem/exiftool.json" 2>"$stem/exiftool.stderr"; then
    exiftool_status="OK"
  else
    exiftool_status="ERR"
  fi

  if mp3val -- "$f" >"$stem/mp3val.txt" 2>"$stem/mp3val.stderr"; then
    mp3val_status="OK"
  else
    mp3val_status="ERR"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$f" "$clam_status" "$ffprobe_status" "$mediainfo_status" "$exiftool_status" "$mp3val_status" >> "$summary_tsv"
done

printf 'Report written to %s\n' "$output_root"