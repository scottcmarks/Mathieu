#!/bin/bash
# Disclosure belt #2: prove no device-derived skin pack made it into a build
# artifact. The Flat-Pack / Marbles / Transfer-Ring mechanisms are patent-
# sensitive; the app is distributed (web, .apk, App Store), so shipping one is a
# public disclosure. The compile-time gate should already have tree-shaken them
# out — this checks the actual bytes rather than trusting that.
#
#   tool/check_no_device_skins.sh [artifact ...]     check built bytes
#   tool/check_no_device_skins.sh --source           check the tracked source
#
# With no arguments it checks whatever of the usual outputs exist:
#   build/web/main.dart.js  build/web/main.dart.wasm
#   build/app/outputs/flutter-apk/app-release.apk
#   build/macos/Build/Products/Release/*.app
#   build/ios/iphoneos/Runner.app
#
# --source is the other half, and it is the one that would have caught the real
# incident: the generated registry was tracked while hard-importing the ignored
# packs_private/, which both broke every clean clone and spelled the pack names
# out in the public tree. Artifact grepping cannot see that — the names were in
# source, not in any build. --source greps what git would actually commit.
#
# Exit 1 on any hit. web/deploy.sh calls both as aborting preconditions.
set -euo pipefail

cd "$(dirname "$0")/.."                       # flutter/

# Ids to look for. Taken from the private pack directory when it is present, so
# a newly-added pack is covered automatically; otherwise the documented list, so
# the check still works in a clean clone that has no packs_private/.
ids=()
for f in lib/skin/packs_private/*_pack.dart; do
  [ -e "$f" ] || continue
  ids+=("$(basename "$f" _pack.dart)")
done
if [ ${#ids[@]} -eq 0 ]; then
  # The documented private pack ids. NOTE: a pack id must be a distinctive token
  # — a bare dictionary word makes this check useless. "transfer" alone already
  # occurs twice in a clean Flutter web bundle and six times in a clean .apk,
  # which is why the transfer-ring pack is "transfer_ring".
  ids=(flatpack marbles transfer_ring)
fi

# --- --source: nothing git would commit may name a private pack ---------------

if [ "${1:-}" = "--source" ]; then
  # Everything git tracks or would track, minus what it ignores. Run from the
  # repo root so a file outside flutter/ (a script, a doc) is covered too.
  root="$(git rev-parse --show-toplevel)"
  fail=0

  # Files whose job IS to describe or create the private directory. They name
  # the path and the flags on purpose; that is the documentation of the rule,
  # not a breach of it. Keep this list short and justified.
  allowed_path_ref='^(flutter/tool/(check_no_device_skins|gen_skin_registry)\.sh|flutter/\.gitignore|flutter/SKINS\.md|flutter/lib/skin/README\.md|flutter/lib/main\.dart|web/deploy\.sh)$'

  files=$(cd "$root" && git ls-files --cached --others --exclude-standard)

  # 1. THE invariant, and the one that caused the real incident: no tracked file
  #    may RESOLVE anything in the private directory. A tracked import of an
  #    ignored file compiles here and nowhere else — it broke analyze, test, the
  #    web build and the Xcode archive on every clone that had no packs_private/.
  #
  #    Prose that merely mentions the directory is fine and wanted: the comment
  #    in registry_packs.g.dart explaining why the packs are NOT there is the
  #    documentation of this very rule. Match the directive, not the word.
  while IFS= read -r f; do
    [ -f "$root/$f" ] || continue
    [[ "$f" =~ $allowed_path_ref ]] && continue
    if grep -qE "^\s*(import|export|part)\s+'[^']*packs_private" "$root/$f" 2>/dev/null; then
      echo "FAIL: tracked file imports from packs_private/: $f" >&2
      grep -nE -m3 "^\s*(import|export|part)\s+'[^']*packs_private" "$root/$f" >&2
      fail=1
    fi
  done <<< "$files"

  # 2. No tracked file may REGISTER a gated pack, and nothing in the
  #    always-ships pack directory may declare itself sensitive. These are the
  #    two ways a private pack could actually reach a default build.
  #
  #    Deliberately NOT a blanket grep for the ids: they are ordinary English
  #    ("marbles" is what the classic skin's balls are called, in web/index.html
  #    and in default_pack.dart's marbleShader), so a substring search reports
  #    the default skin as a leak and gets switched off. Match the registration
  #    call instead, which is unambiguous.
  for id in "${ids[@]}"; do
    while IFS= read -r f; do
      [ -f "$root/$f" ] || continue
      [[ "$f" =~ $allowed_path_ref ]] && continue
      if grep -qE "SkinRegistry\.register\(\s*'$id'" "$root/$f" 2>/dev/null; then
        echo "FAIL: tracked file registers gated pack '$id': $f" >&2
        grep -nE -m3 "SkinRegistry\.register\(\s*'$id'" "$root/$f" >&2
        fail=1
      fi
    done <<< "$files"
  done

  while IFS= read -r f; do
    case "$f" in flutter/lib/skin/packs/*) ;; *) continue ;; esac
    [ -f "$root/$f" ] || continue
    if grep -qE 'get sensitive\s*=>\s*true' "$root/$f" 2>/dev/null; then
      echo "FAIL: a pack in the always-ships directory is sensitive: $f" >&2
      fail=1
    fi
  done <<< "$files"

  if [ "$fail" != "0" ]; then
    echo "" >&2
    echo "A patent-sensitive pack has reached the tracked source tree." >&2
    echo "The tracked tree must compile — and read — as if packs_private/ did" >&2
    echo "not exist. See flutter/SKINS.md, 'The registry'." >&2
    exit 1
  fi
  echo "check_no_device_skins --source: PASS (ids: ${ids[*]})"
  exit 0
fi

targets=("$@")
if [ ${#targets[@]} -eq 0 ]; then
  for t in build/web/main.dart.js \
           build/web/main.dart.wasm \
           build/app/outputs/flutter-apk/app-release.apk \
           build/ios/iphoneos/Runner.app \
           build/macos/Build/Products/Release; do
    [ -e "$t" ] && targets+=("$t")
  done
fi

if [ ${#targets[@]} -eq 0 ]; then
  echo "check_no_device_skins: no build artifacts found — build first." >&2
  exit 1
fi

fail=0
for t in "${targets[@]}"; do
  for id in "${ids[@]}"; do
    # -r walks .app bundles; -a treats binaries/archives as text.
    if grep -r -a -q -- "$id" "$t" 2>/dev/null; then
      echo "FAIL: device skin id '$id' found in $t" >&2
      grep -r -a -o -m3 -- ".\{0,30\}$id.\{0,30\}" "$t" 2>/dev/null | head -3 >&2
      fail=1
    fi
  done
  [ "$fail" = "0" ] && echo "ok: $t clean of (${ids[*]})"
done

if [ "$fail" != "0" ]; then
  echo "" >&2
  echo "A patent-sensitive skin pack is present in a build artifact." >&2
  echo "Do not publish. Rebuild without the SKIN_* dart-defines." >&2
  echo "(If the artifact is stale from an older build, delete build/ and rebuild.)" >&2
  exit 1
fi
echo "check_no_device_skins: PASS"
