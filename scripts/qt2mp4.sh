#!/bin/bash
# Convert QuickTime/MOV to visually-lossless HEVC MP4 (archival-quality, much smaller)

set -e

usage() {
    echo "Usage: qt2mp4 <input> [output]"
    echo "Convert video to visually-lossless HEVC MP4"
    exit 1
}

[[ -z "$1" ]] && usage

INPUT="$1"
OUTPUT="${2:-${INPUT%.*}.mp4}"

[[ "$INPUT" -ef "$OUTPUT" ]] && { echo "Error: output would overwrite input ($INPUT)"; exit 1; }

# PCM audio → compress losslessly to ALAC; already-compressed audio → copy untouched
ACODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$INPUT")
case "$ACODEC" in
    pcm_*) AUDIO=(-c:a alac) ;;
    "")    AUDIO=(-an) ;;
    *)     AUDIO=(-c:a copy) ;;
esac

ffmpeg -i "$INPUT" -map 0:v:0 -map '0:a:0?' \
    -c:v libx265 -preset slow -crf 18 -pix_fmt yuv420p10le -tag:v hvc1 \
    "${AUDIO[@]}" -movflags +faststart "$OUTPUT" -y

echo "Done: $OUTPUT"
