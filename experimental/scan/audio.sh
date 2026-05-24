#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scan-audio.sh [--install-brew-deps] [--output-dir DIR] [--type auto|flac|mp3] [--decode-test] FILE_OR_DIR...

Examples:
  scan-audio.sh --type auto ~/Downloads/suspect-audio
  scan-audio.sh --type flac ./album-dir
  scan-audio.sh --type mp3 --decode-test ./track.mp3
  scan-audio.sh --install-brew-deps --type auto ./music

Notes:
  - This script is Bash 3.2 compatible.
  - It does not use process substitution.
  - It uses a NUL-delimited temp manifest.
  - summary.tsv does not contain raw paths; use files/<id>/path.shq or path.nul.
  - For a path beginning with '-', pass it as ./-name or after --.
USAGE
}

log() { printf '%s\n' "$*" >&2; }
warn() { printf 'warning: %s\n' "$*" >&2; }
err() { printf 'error: %s\n' "$*" >&2; }
need_cmd() { command -v "$1" >/dev/null 2>&1; }

install_deps=0
output_root=""
scan_type="auto"
decode_test=0
inputs=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-brew-deps) install_deps=1; shift ;;
    --output-dir)
      [ "$#" -ge 2 ] || { err "--output-dir requires an argument"; exit 2; }
      output_root="$2"
      shift 2
      ;;
    --type)
      [ "$#" -ge 2 ] || { err "--type requires an argument"; exit 2; }
      scan_type="$2"
      shift 2
      ;;
    --decode-test) decode_test=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --)
      shift
      while [ "$#" -gt 0 ]; do
        inputs+=("$1")
        shift
      done
      ;;
    -*)
      err "unknown option: $1"
      exit 2
      ;;
    *)
      inputs+=("$1")
      shift
      ;;
  esac
done

[ "${#inputs[@]}" -gt 0 ] || { usage; exit 2; }

case "$scan_type" in
  auto|flac|mp3) ;;
  *)
    err "--type must be auto, flac, or mp3"
    exit 2
    ;;
esac

if [ "$install_deps" -eq 1 ]; then
  need_cmd brew || { err "Homebrew not found"; exit 1; }
  brew install flac mp3val ffmpeg media-info exiftool clamav
fi

for cmd in ffprobe mediainfo exiftool shasum awk find mktemp; do
  need_cmd "$cmd" || { err "missing required command: $cmd"; exit 1; }
done

case "$scan_type" in
  auto|flac)
    for cmd in flac metaflac; do
      need_cmd "$cmd" || { err "missing required command: $cmd"; exit 1; }
    done
    ;;
esac

case "$scan_type" in
  auto|mp3)
    need_cmd mp3val || { err "missing required command: mp3val"; exit 1; }
    ;;
esac

if [ "$decode_test" -eq 1 ]; then
  need_cmd ffmpeg || { err "--decode-test requires ffmpeg"; exit 1; }
fi

if [ -z "$output_root" ]; then
  output_root="./audio-scan-$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "$output_root"
mkdir -p "$output_root/files"

manifest="$(mktemp "${TMPDIR:-/tmp}/scan-audio.manifest.XXXXXX")"
seen_dir="$(mktemp -d "${TMPDIR:-/tmp}/scan-audio.seen.XXXXXX")"

cleanup() {
  rm -f "$manifest"
  rm -rf "$seen_dir"
}
trap cleanup EXIT HUP INT TERM

have_clam=0
if need_cmd clamscan; then
  have_clam=1
fi

if need_cmd freshclam; then
  freshclam >/dev/null 2>&1 || warn "freshclam failed; continuing with current signatures"
fi

file_id() {
  printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
}

kind_for_file() {
  lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$scan_type" in
    flac) printf 'flac' ;;
    mp3) printf 'mp3' ;;
    auto)
      case "$lower" in
        *.flac|*.fla) printf 'flac' ;;
        *.mp3|*.mpeg3) printf 'mp3' ;;
        *) printf 'skip' ;;
      esac
      ;;
  esac
}

scan_arg_path() {
  case "$1" in
    -*) printf './%s' "$1" ;;
    *) printf '%s' "$1" ;;
  esac
}

append_input_files_0() {
  input="$1"
  manifest_file="$2"
  scan_input="$(scan_arg_path "$input")"

  if [ -d "$scan_input" ]; then
    case "$scan_type" in
      flac)
        find "$scan_input" -type f \( -iname '*.flac' -o -iname '*.fla' \) -print0 >> "$manifest_file"
        ;;
      mp3)
        find "$scan_input" -type f \( -iname '*.mp3' -o -iname '*.mpeg3' \) -print0 >> "$manifest_file"
        ;;
      auto)
        find "$scan_input" -type f \( -iname '*.flac' -o -iname '*.fla' -o -iname '*.mp3' -o -iname '*.mpeg3' \) -print0 >> "$manifest_file"
        ;;
    esac
  elif [ -f "$scan_input" ]; then
    printf '%s\0' "$scan_input" >> "$manifest_file"
  else
    warn "skipping missing path: $input"
  fi
}

write_path_sidecars() {
  path_value="$1"
  stem="$2"
  printf '%s\0' "$path_value" > "$stem/path.nul"
  printf '%q\n' "$path_value" > "$stem/path.shq"
}

scan_common() {
  raw_path="$1"
  tool_path="$2"
  stem="$3"

  clam_status="SKIP"
  ffprobe_status="ERR"
  mediainfo_status="ERR"
  exiftool_status="ERR"
  decode_status="SKIP"

  if [ "$have_clam" -eq 1 ]; then
    if clamscan --infected --no-summary "$tool_path" >"$stem/clamav.txt" 2>&1; then
      clam_status="OK"
    else
      rc=$?
      if [ "$rc" -eq 1 ]; then
        clam_status="FOUND"
      else
        clam_status="ERR($rc)"
      fi
    fi
  fi

  if ffprobe -v error -show_format -show_streams -of json "$tool_path" >"$stem/ffprobe.json" 2>"$stem/ffprobe.stderr"; then
    ffprobe_status="OK"
  else
    rc=$?
    ffprobe_status="ERR($rc)"
  fi

  if mediainfo --Output=JSON "$tool_path" >"$stem/mediainfo.json" 2>"$stem/mediainfo.stderr"; then
    mediainfo_status="OK"
  else
    rc=$?
    mediainfo_status="ERR($rc)"
  fi

  if exiftool -j -G1 -a -s "$tool_path" >"$stem/exiftool.json" 2>"$stem/exiftool.stderr"; then
    exiftool_status="OK"
  else
    rc=$?
    exiftool_status="ERR($rc)"
  fi

  if [ "$decode_test" -eq 1 ]; then
    if ffmpeg -v error -nostdin -i "$tool_path" -map 0:a:0 -f null /dev/null >"$stem/decode.stdout" 2>"$stem/decode.stderr"; then
      decode_status="OK"
    else
      rc=$?
      decode_status="ERR($rc)"
    fi
  fi

  printf '%s\t%s\t%s\t%s\t%s' "$clam_status" "$ffprobe_status" "$mediainfo_status" "$exiftool_status" "$decode_status"
}

scan_flac() {
  tool_path="$1"
  stem="$2"

  check_status="ERR"
  meta_status="ERR"

  if flac -t --totally-silent "$tool_path" >"$stem/flac_test.stdout" 2>"$stem/flac_test.stderr"; then
    check_status="OK"
  else
    rc=$?
    check_status="ERR($rc)"
  fi

  if metaflac \
      --show-md5sum \
      --show-sample-rate \
      --show-channels \
      --show-bps \
      --show-total-samples \
      "$tool_path" >"$stem/flac_meta.txt" 2>"$stem/flac_meta.stderr"; then
    meta_status="OK"
  else
    rc=$?
    meta_status="ERR($rc)"
  fi

  printf '%s\t%s' "$check_status" "$meta_status"
}

scan_mp3() {
  tool_path="$1"
  stem="$2"

  check_status="ERR"
  meta_status="NA"

  if mp3val "$tool_path" >"$stem/mp3val.txt" 2>"$stem/mp3val.stderr"; then
    check_status="OK"
  else
    rc=$?
    check_status="ERR($rc)"
  fi

  printf '%s\t%s' "$check_status" "$meta_status"
}

for input in "${inputs[@]}"; do
  append_input_files_0 "$input" "$manifest"
done

summary_tsv="$output_root/summary.tsv"
printf 'id\tkind\tclamav\tffprobe\tmediainfo\texiftool\tdecode\tcodec_check\tcodec_meta\n' > "$summary_tsv"

processed=0
skipped_dupe=0

while IFS= read -r -d '' f; do
  kind="$(kind_for_file "$f")"
  [ "$kind" = "skip" ] && continue

  id="$(file_id "$f")"

  if [ -e "$seen_dir/$id" ]; then
    skipped_dupe=$((skipped_dupe + 1))
    continue
  fi
  : > "$seen_dir/$id"

  stem="$output_root/files/$id"
  mkdir -p "$stem"
  write_path_sidecars "$f" "$stem"

  tool_path="$(scan_arg_path "$f")"

  common_statuses="$(scan_common "$f" "$tool_path" "$stem")"

  case "$kind" in
    flac) codec_statuses="$(scan_flac "$tool_path" "$stem")" ;;
    mp3) codec_statuses="$(scan_mp3 "$tool_path" "$stem")" ;;
    *)
      continue
      ;;
  esac

  printf '%s\t%s\t%s\t%s\n' "$id" "$kind" "$common_statuses" "$codec_statuses" >> "$summary_tsv"
  processed=$((processed + 1))
done < "$manifest"

printf 'Report written to %s\n' "$output_root"
printf 'Summary: %s\n' "$summary_tsv"
printf 'Processed: %s\n' "$processed"
printf 'Skipped duplicates: %s\n' "$skipped_dupe"
printf 'Resolve an id to its original path via: %s/files/<id>/path.shq\n' "$output_root"