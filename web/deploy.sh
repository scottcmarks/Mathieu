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
./tool/gen_skin_registry.sh                      # refresh the skin pack table

# Aborting precondition #1, before anything is built: the tracked tree must not
# import or register a gated pack. This is the check that would have caught the
# generated registry importing the gitignored packs_private/ — a break that only
# ever showed up on OTHER machines, because deploy.sh regenerates and so healed
# it here every time.
./tool/check_no_device_skins.sh --source

source "$HOME/emsdk/emsdk_env.sh" >/dev/null 2>&1 || true
./native/build_wasm.sh
# base-href MUST match the deploy subfolder or the app's assets 404.
# --dart-define=BETA=true keeps the build tell visible even in release builds.
# NOTE: no --dart-define=SKIN_* here, and the default entry point (lib/main.dart)
# is used, not the private one — the device-derived skins are patent-sensitive
# and this is a public host, so a gated pack must never be built into what is
# deployed. See flutter/SKINS.md.
flutter build web --base-href /sporadicgames/m12/app/ --dart-define=BETA=true
flutter build apk --release --dart-define=BETA=true

# Aborting precondition #2: prove no device skin made it into the bytes we are
# about to publish. Greps the artifacts rather than trusting the build flags.
./tool/check_no_device_skins.sh \
  build/web/main.dart.js \
  build/app/outputs/flutter-apk/app-release.apk

rm -rf "$WEB/app" && cp -R build/web "$WEB/app"
cp build/app/outputs/flutter-apk/app-release.apk "$WEB/mathieu.apk"

echo "Deploying to $DEST (additive) ..."
rsync -az --delete -e "$SSH" "$WEB/app/" "$DEST/app/"
rsync -az -e "$SSH" \
  "$WEB/index.html" "$WEB/m12_icon.png" "$WEB/sporadic_games_logo.png" "$WEB/mathieu.apk" \
  "$DEST/"
echo "Done: https://magnolia-heights.com/sporadicgames/m12/"
