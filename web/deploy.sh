#!/bin/bash
# Assemble + (optionally) deploy the Sporadic M12 landing site.
set -euo pipefail
DIR="$(cd "$(dirname "$0")/.." && pwd)"   # repo root
cd "$DIR/flutter"
source "$HOME/emsdk/emsdk_env.sh" >/dev/null 2>&1 || true
./native/build_wasm.sh
flutter build web
flutter build apk --release
rm -rf "$DIR/web/app" && cp -R build/web "$DIR/web/app"
cp build/app/outputs/flutter-apk/app-release.apk "$DIR/web/mathieu.apk"
echo "Assembled $DIR/web (app/, mathieu.apk). rsync to magnolia-heights.com when ready."
