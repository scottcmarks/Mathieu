# Sporadic M12 — Flutter app

The M12 puzzle: twelve numbered pieces on a ring, two moves, and the sporadic
Mathieu group **M₁₂** underneath. A Flutter UI over the same C++ engine the
Apple and watch targets use, through `dart:ffi` natively and a WASM build on the
web.

This is the app half of the project. The physical toy designs live in a separate
private repo and are **not** here.

## Documentation

| | |
|---|---|
| **[SKINS.md](SKINS.md)** | the skin system: the six facets, authoring a pack, the registry and its two generated files, the disclosure gate |
| **[MACROS.md](MACROS.md)** | macros and the tutorial: the lesson curriculum, the workshop, the library, and the booklet deep-link formats |
| `lib/skin/README.md` | pointer to SKINS.md |
| `../PlatformIndependent/M12/Permutation/REGENERATION.md` | regenerating the permutation tables |

## Layout

    lib/main.dart            the board, the controls, settings
    lib/ball_ring.dart       the ring renderer
    lib/m12/                 the group-theory layer (Word, analysis, BFS table, search, library)
    lib/tutor/               Learn: lessons, workshop, macro library
    lib/skin/                the skin system
    lib/deeplink.dart        one parser for both booklet-QR carriers
    native/                  the C++ engine wrapper + WASM build
    tool/                    build-time scripts (see below)

## Building

    flutter run                       # debug
    flutter build web --release
    flutter build apk --release

`tool/gen_skin_registry.sh` regenerates the skin pack table. It is safe and
idempotent; run it after adding or removing a pack.

**Do not run `../web/deploy.sh` casually — it publishes to a public host.**

## Testing

    flutter analyze
    flutter test

Five infos from `curly_braces_in_flow_control_structures` are pre-existing and
expected.

The FFI and widget-driver tests need the engine as a shared library, and skip
without it:

    ./tool/build_native_test_lib.sh
    MATHIEU_ENGINE_LIB="$PWD/build/native-test/libmathieu_engine.dylib" flutter test

Goldens under `test/goldens/` were captured from the **pre-skin** renderer and
must keep matching — they are the guarantee that the default skin still looks
exactly like the original app. Regenerate only when a change to the default look
is intended:

    flutter test --update-goldens test/ball_ring_golden_test.dart

## Disclosure

Some skin packs are derived from patent-sensitive physical toy designs. They are
gitignored, gated behind compile-time flags that default off, and reached only
through a separate generated entry point that the tracked tree never references.

    tool/check_no_device_skins.sh --source    # the tracked tree is clean
    tool/check_no_device_skins.sh             # the built artifacts are clean

Both are aborting preconditions in `../web/deploy.sh`. See **SKINS.md** for the
full gate and the decision that is still open.
