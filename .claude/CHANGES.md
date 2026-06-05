# Mathieu — Change Log

## 2026-06-04 — The big rebuild: M12 revived across platforms

Goal: get **M12** building in multiple variants, linked from a landing page
analogous to sudokux4.com. Approach chosen: a **Flutter port reusing the C++
`PlatformIndependent` engine over FFI** (the SudokuX4 model), since the old
native cross-platform code was Apple-only and bit-rotted. Native iOS kept as a
fallback; macOS-native AppKit port deliberately not pursued.

### Engine / FFI
- New C ABI shim `flutter/native/mathieu_ffi.{cpp,h}` over
  `MathieuPermutationWithHistory` (new/free/reset/left/right/swap/random/undo/
  revert, arrangement, swap-index + swap-permutation, macros A..E, history,
  moves/steps, is_solved). Include via `m12.h` (nBalls=12, nSwaps=341).
- FFI entry points marked `__attribute__((used))` to survive dead-strip and
  resolve via `DynamicLibrary.process()` on Apple. (Tried
  `-exported_symbols_list` — broke dyld; reverted.)
- Compiles `mathieu_ffi.cpp` + `m12.cc` + `~/Toolbox/.../rand_utils.c`.

### Flutter app (`flutter/`)
- Full port on **iOS, macOS, web, Android** (Windows/Linux wired for CI).
- `lib/main.dart`: black bg; **fixed coloured spheres** (colour = position's swap
  pairing) with **moving number labels**; rotations spin labels along the arc,
  swaps exchange in straight lines; continuous finger-drag with **flick/momentum**
  + speed slider; marble gradient from `BallView.mm`; flat Shake/Home controls;
  A/A⁻¹/Alt macros; status line + counters; Settings flip page with
  swap-permutation **preview + picker**; applause only on first solve of a
  scramble; portrait-locked.
- Per-platform native build: `native/CMakeLists.txt` (libmathieu_engine),
  android gradle `externalNativeBuild` (minSdk 28), linux/windows
  `add_subdirectory(../native)`; web via `native/build_wasm.sh` (emcc) +
  `web/mathieu_glue.js` + js_interop, conditional-import barrel
  `lib/mathieu_ffi.dart`; `emscripten_compat.c`/`win32_compat.c` for arc4random.
- Runner pbxproj wired programmatically with the ruby `xcodeproj` gem (mod-pbxproj
  choked on Flutter 3.44 SPM build files).
- **Display name M₁₂**, bundle id `com.magnoliaheights.SporadicM12` (replaces the
  original native app), swap-ring icon.
- Audio: one **WAV** master set in `assets/sounds/` (left/right/swap/combo/
  combo_set/success/applause/shake/home/restart).

### Native iOS
- Revived the original `Apple/iPhone/Mathieu.xcodeproj` under Xcode 26
  (`neg<T>()`, `#else` typo, `CISwipeTransition`, IB SystemTarget); fixed the
  **permutation-selector modal** UI bug. Kept as a fallback.

### Apple Watch (`watch/`)
- New standalone SwiftUI watchOS app reusing the same engine (xcodegen from
  `project.yml`). Crown rotates the ring; A / A⁻¹ peer buttons; Double-Tap → A.
- Installed + launched on a real Apple Watch (team 23JBC9D428). Simulator install
  is buggy on this Mac (CoreSimulator IXUserPresentableError) — device only.
  Sidecar for now; TestFlight/landing tile later.

### Engine bug fix
- `PlatformIndependent/M12/Permutation/M12PermTable.h`: added missing
  `return *this;` to `perm_info & operator=(Perm p)` — falling off the end was UB
  that modern clang -O2 turned into a **segfault** in `find_all_permutations`.
  Documented the generator build in `REGENERATION.md`.

### Hosting (live)
- **Web is live:** https://magnolia-heights.com/sporadicgames/m12/
- `web/index.html` landing page + `web/deploy.sh` (build web with base-href
  `/sporadicgames/m12/app/`, **additive** rsync over SSH to magnol9@…:2222).
- Backed up the server's existing `sporadicgames/` tree before deploy; old SVN
  landing pages left in place but **unlinked** (to be rewritten later).

### Goldens / Git LFS
- Migrated the large permutation tables (`Perms.bin.golden`, M24 ~477 MB) into
  **Git LFS** (history rewrite) to unblock push. Static blob → uploaded once.
- Regeneration: segfault root-caused/fixed; M12 regenerates to correct size but
  ~132/4.56M bytes off golden (padding/order); M24 not fully generated. **Goldens
  remain the source of truth** until bit-exact.

### CI
- `.github/workflows/desktop.yml` — Linux + Windows builds, **`workflow_dispatch`
  only** (never on push/PR, per requirement). Needs repo secret `TOOLBOX_PAT`.

### Repo
- Active branch **`develop`** on `git@github.com:scottcmarks/Mathieu.git`, pushed
  over SSH (gh auth dead on this machine).
- Deferred (manual, Scott): set default branch to `develop`; add `TOOLBOX_PAT`;
  un-pause Actions; bump home-repo submodule pointer via wapex recipe.
