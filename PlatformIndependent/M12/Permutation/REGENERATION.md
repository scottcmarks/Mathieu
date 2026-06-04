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

## Open items (deferred)

- **M12 not yet byte-identical:** the regenerated `Perms.bin` matches the golden
  in size but differs in ~132 of 4,561,920 bytes — almost certainly struct
  padding or minor find-order nondeterminism, not the permutation data. Needs a
  short follow-up (zero-init the structs / sort before dump) to get a bit-exact
  match before trusting regeneration as authoritative.
- **M24:** builds and runs past the crash, but its search space is large
  (~244M permutations) and a full generation was not completed here. The golden
  predates this work (`m24.cc` even notes "Haven't generated M24 permutations").

Until the above are closed, treat the LFS-stored goldens as the source of truth.
