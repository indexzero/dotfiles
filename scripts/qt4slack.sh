#!/bin/bash
# Convert QuickTime/MOV to MP4 optimized for Slack (no audio)

set -e

usage() {
    echo "Usage: qt4slack <input> [output]"
    echo "Convert video to MP4 optimized for Slack"
    exit 1
}

[[ -z "$1" ]] && usage

INPUT="$1"
OUTPUT="${2:-${INPUT%.*}.mp4}"

ffmpeg -i "$INPUT" -c:v libx264 -preset slow -crf 23 -an -movflags +faststart -pix_fmt yuv420p "$OUTPUT" -y

echo "Done: $OUTPUT"
