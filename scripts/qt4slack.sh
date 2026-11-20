#!/bin/bash
# Convert QuickTime/MOV to MP4 optimized for Slack (no audio unless --audio)

set -e

usage() {
    echo "Usage: qt4slack [--audio] <input> [output]"
    echo "Convert video to MP4 optimized for Slack"
    echo ""
    echo "Options:"
    echo "  --audio    Keep the audio track (default: audio is stripped)"
    exit 1
}

AUDIO=false
ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --audio) AUDIO=true ;;
        -h|--help) usage ;;
        --) shift; ARGS+=("$@"); break ;;
        -*) echo "Unknown option: $1" >&2; usage ;;
        *) ARGS+=("$1") ;;
    esac
    shift
done

[[ ${#ARGS[@]} -lt 1 || ${#ARGS[@]} -gt 2 ]] && usage

INPUT="${ARGS[0]}"
OUTPUT="${ARGS[1]:-${INPUT%.*}.mp4}"

if [[ "$AUDIO" == true ]]; then
    AUDIO_OPTS=(-c:a aac -b:a 128k)
else
    AUDIO_OPTS=(-an)
fi

ffmpeg -i "$INPUT" -c:v libx264 -preset slow -crf 23 "${AUDIO_OPTS[@]}" -movflags +faststart -pix_fmt yuv420p "$OUTPUT" -y

echo "Done: $OUTPUT"
