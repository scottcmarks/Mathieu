# Regenerating the permutation tables (Perms.bin.golden)

The golden tables are large binary lookup tables produced by `AnalyzeM12` /
`AnalyzeM24` (`table.dump("Perms.bin")`). They are stored in the repo via **Git
LFS** (see `.gitattributes`). Status of making them regenerable on modern
macOS/clang (2026-06):

## Root-cause fix (M12) — applied

`M12PermTable.h`: `perm_info & operator=(Perm p)` returned a reference but never
executed `return *this;`. Falling off the end of a non-void function is
undefined behaviour; modern clang at -O2 turned it into a **segfault** during
`find_all_permutations`. Fixed by adding `return *this;`. (M24's `table_group`
path doesn't share this bug — `AnalyzeM24` runs without it.)

## Build + run on macOS

`AnalyzeM12.cpp` builds cleanly once you supply include paths and force-include
the POSIX I/O headers it assumes (`<sys/stat.h> <unistd.h> <fcntl.h>`):

```
MR=$HOME/Mathieu; TB=$HOME/Toolbox/PlatformIndependent
clang -c "$TB/rand_utils.c" -I"$TB" -o rand_utils.o
clang++ -std=c++17 -w -O2 -DMATHIEU_GROUP_PERMUTATION_SIZE=12 \
  -include sys/types.h -include sys/stat.h -include unistd.h -include fcntl.h \
  -I"$MR/PlatformIndependent/M12/Permutation" -I"$MR/PlatformIndependent/Permutation" \
  -I"$MR/PlatformIndependent/View" -I"$MR/PlatformIndependent" \
  -I"$MR/Apple" -I"$MR/Apple/iPhone" -I"$MR/Apple/iPhone/M12" \
  -I"$TB" -I"$TB/Permutation" \
  "$MR/PlatformIndependent/M12/Permutation/AnalyzeM12.cpp" \
  "$MR/PlatformIndependent/M12/Permutation/M12PermTable.cpp" \
  "$MR/PlatformIndependent/M12/Permutation/m12.cc" \
  "$MR/PlatformIndependent/View/view.cc" "$TB/point.cc" rand_utils.o -o AnalyzeM12
./AnalyzeM12      # writes Perms.bin (95040 entries, 4,561,920 bytes)
```

## Search fix (M12) — applied 2026-08-24, golden regenerated

`find_all_permutations` stopped as soon as every permutation had been SEEN.
That is too early: an s-swap word has at least 2s-1 moves (the rotation
between consecutive swaps is mandatory), so 6-swap words with no end
rotations have exactly 11 moves and can tie the moves-11 entries while
using fewer steps.  292 of the 95040 rows carried solutions 1-7 steps
longer than optimal.  The loop now runs until no deeper level could match
the deepest recorded moves count (`max_moves_recorded < 2*max_swaps - 1`).
`Perms.bin.golden` and `perms.lst` are regenerated: exactly those 292 rows
changed (steps column and solution word; every `moves` value and both
30-step attainers were already optimal, so the (11, 30) maxima stand).
Verified independently: an external BFS/Dijkstra reproduces every row's
(moves, steps), and all 95040 solution words replay to their permutations
with the stated counts.

Also fixed: `view.cc`'s narrow `insert_count` streamed `wchar_t`
superscripts into a narrow `ostream`, which prints code points as integers
("L2" came out "L178").  Narrow streams now emit ASCII digits; with that,
the rebuilt `PrintPerms` reproduces the pre-fix `perms.lst` byte-for-byte
from the pre-fix golden — the regeneration pipeline is round-trip clean.

## Open items (deferred)

- **M12 byte-identity (historical):** before the search fix, a regenerated
  `Perms.bin` differed from the old golden in ~132 bytes (struct padding /
  find-order nondeterminism).  The golden is now produced by this pipeline
  on macOS/clang, so regeneration matches it by construction; revisit only
  if another platform must reproduce it bit-exactly.
- **`Linux/M12/M12Tests/optimized/src/Perms.bin`** is a checked-in build
  artifact predating the search fix; regenerate or drop it if that build
  tree is ever revived.
- **M24:** builds and runs past the crash, but its search space is large
  (~244M permutations) and a full generation was not completed here. The golden
  predates this work (`m24.cc` even notes "Haven't generated M24 permutations").

Until the above are closed, treat the LFS-stored goldens as the source of truth.
