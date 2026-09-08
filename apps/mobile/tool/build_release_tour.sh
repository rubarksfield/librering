#!/usr/bin/env bash
# Build a silent screenshot tour from actual, synthetic-data Flutter captures.
# No phone recordings, personal readings, or generated UI artwork are used.
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
media_dir="$project_dir/docs/media/v1.3.2"
screens=(today vitals sleep heart trends hrv-explained syncing refresh)
input_args=()
filter_graph=""

for index in "${!screens[@]}"; do
  capture="$media_dir/${screens[$index]}.png"
  test -f "$capture"
  input_args+=(-loop 1 -framerate 24 -t 3.5 -i "$capture")
  filter_graph+="[$index:v]scale=390:844:flags=lanczos,setsar=1,format=yuv420p,settb=AVTB[v$index];"
done

# Seven 0.35-second crossfades between eight 3.5-second screen holds.
offsets=(3.15 6.30 9.45 12.60 15.75 18.90 22.05)
previous=v0
for index in 1 2 3 4 5 6 7; do
  filter_graph+="[$previous][v$index]xfade=transition=fade:duration=0.35:offset=${offsets[$((index-1))]}[x$index];"
  previous="x$index"
done

ffmpeg -hide_banner -loglevel warning -y "${input_args[@]}" \
  -filter_complex_threads 1 -filter_complex "${filter_graph%;}" \
  -map '[x7]' -an -c:v libx264 -threads 2 -preset medium -crf 18 \
  -pix_fmt yuv420p -movflags +faststart \
  -metadata title='LibreRing 1.3.2 — fictional-data screenshot tour' \
  -metadata comment='Actual Flutter UI; synthetic readings and simulated sync. Not a live device recording.' \
  "$media_dir/librering-tour.mp4"

ffmpeg -hide_banner -loglevel warning -y -i "$media_dir/librering-tour.mp4" \
  -filter_complex_threads 1 \
  -filter_complex 'fps=8,scale=320:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96[p];[b][p]paletteuse=dither=bayer:bayer_scale=3' \
  -loop 0 "$media_dir/librering-tour.gif"

ffprobe -v error -show_entries format=duration,size:stream=codec_name,width,height \
  -of json "$media_dir/librering-tour.mp4"
