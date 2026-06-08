#!/bin/bash
# Regenerate the STL parts the web viewer loads, from swap_toy_render.scad.
# The STLs are large (~18 MB) and fully derived, so they are .gitignored;
# run this once after cloning (needs the native OpenSCAD snapshot).
#   brew install --cask openscad@snapshot   # if 'openscad' is missing
set -euo pipefail
cd "$(dirname "$0")"
OSC="${OPENSCAD:-/opt/homebrew/bin/openscad}"
SRC=../swap_toy_render.scad
"$OSC" -o disc.stl     -D 'MODE="disc"'     "$SRC"
"$OSC" -o carousel.stl -D 'MODE="carousel"' "$SRC"
"$OSC" -o ringgear.stl -D 'MODE="ringgear"' "$SRC"
"$OSC" -o pinion.stl   -D 'MODE="pinion"'   "$SRC"
"$OSC" -o bearing.stl  -D 'MODE="bearing"'  "$SRC"
for n in $(seq 0 11); do
  "$OSC" -o "ball$n.stl" -D 'MODE="ball"' -D BALL=$n "$SRC"
  "$OSC" -o "num$n.stl"  -D 'MODE="num"'  -D BALL=$n "$SRC"
done
for i in $(seq 0 5);  do "$OSC" -o "carrier$i.stl" -D 'MODE="carrier"' -D PAIR=$i  "$SRC"; done

# --- interference gate: lint every build for parts passing through each other ---
PY="../.venv/bin/python"; [ -x "$PY" ] || PY="$(command -v python3)"
echo
if "$PY" ../check_interference.py; then
  echo "Parts OK. Start the viewer with: ./view.sh"
else
  echo "WARNING: interference clashes above — geometry needs work (viewer still runs: ./view.sh)" >&2
fi
