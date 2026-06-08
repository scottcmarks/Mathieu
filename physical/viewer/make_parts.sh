#!/bin/bash
# Regenerate the STL parts the web viewer loads, from swap_toy_render.scad.
# The STLs are large (~18 MB) and fully derived, so they are .gitignored;
# run this once after cloning (needs the native OpenSCAD snapshot).
#   brew install --cask openscad@snapshot   # if 'openscad' is missing
set -euo pipefail
cd "$(dirname "$0")"
OSC="${OPENSCAD:-/opt/homebrew/bin/openscad}"
SRC=../swap_toy_render.scad
"$OSC" -o disc.stl -D 'MODE="disc"' "$SRC"
for n in $(seq 0 11); do "$OSC" -o "ball$n.stl"    -D 'MODE="ball"'    -D BALL=$n  "$SRC"; done
for i in $(seq 0 5);  do "$OSC" -o "carrier$i.stl" -D 'MODE="carrier"' -D PAIR=$i  "$SRC"; done
echo "Done. Start the viewer with: ./view.sh"
