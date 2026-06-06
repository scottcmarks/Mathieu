#!/bin/bash
# Build + deploy the Sporadic M12 landing site to
# https://magnolia-heights.com/sporadicgames/m12/
#
# ADDITIVE at the m12/ level (never --delete) so the legacy pages
# (manual.html, hints.html, the .svn working copy, images/, ...) are preserved.
# Only app/ is mirrored with --delete (it is wholly ours).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"        # repo root (~/Mathieu)
WEB="$ROOT/web"
DEST_HOST="magnol9@magnolia-heights.com"
DEST_PORT="2222"
DEST="$DEST_HOST:public_html/sporadicgames/m12"
SSH="ssh -p $DEST_PORT"

cd "$ROOT/flutter"
./tool/stamp_build.sh                            # refresh the beta build tell
source "$HOME/emsdk/emsdk_env.sh" >/dev/null 2>&1 || true
./native/build_wasm.sh
# base-href MUST match the deploy subfolder or the app's assets 404.
# --dart-define=BETA=true keeps the build tell visible even in release builds.
flutter build web --base-href /sporadicgames/m12/app/ --dart-define=BETA=true
flutter build apk --release --dart-define=BETA=true

rm -rf "$WEB/app" && cp -R build/web "$WEB/app"
cp build/app/outputs/flutter-apk/app-release.apk "$WEB/mathieu.apk"

echo "Deploying to $DEST (additive) ..."
rsync -az --delete -e "$SSH" "$WEB/app/" "$DEST/app/"
rsync -az -e "$SSH" \
  "$WEB/index.html" "$WEB/m12_icon.png" "$WEB/sporadic_games_logo.png" "$WEB/mathieu.apk" \
  "$DEST/"
echo "Done: https://magnolia-heights.com/sporadicgames/m12/"
