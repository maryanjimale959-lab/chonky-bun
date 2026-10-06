#!/usr/bin/env bash
# Turn the PNG sequence from test/demo_capture_test.dart into a post-ready clip.
#
#   flutter test test/demo_capture_test.dart        # needs DEMO_OUT=build/demo
#   bash tool/make_video.sh [seconds]
#
# H.264 in an MP4 container, yuv420p, faststart: the combination every social
# platform and every phone accepts without re-encoding surprises.
set -euo pipefail

src="${1:-build/demo}"
secs="${2:-48}"
out="${3:-build/munchi-bun-demo.mp4}"
fps=60

frames=$(( secs * fps ))
echo "encoding $frames frames (${secs}s at ${fps}fps) from $src -> $out"

ffmpeg -hide_banner -loglevel error -y \
  -framerate "$fps" \
  -start_number 0 \
  -i "$src/%05d.png" \
  -frames:v "$frames" \
  -c:v libx264 -preset slow -crf 17 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  "$out"

echo "wrote $out ($(du -h "$out" | cut -f1))"
