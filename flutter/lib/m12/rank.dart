// A perfect hash of M12 into [0, 95040).
//
// Direct port of MathieuPermutation::compute_indices (m.h:126-152): invert the
// permutation, then run a factoradic truncated to the first five images. M12 is
// sharply 5-transitive, so an element is determined by where it sends the first
// five seats — the truncated factoradic is therefore injective on the group and
// lands exactly on 12·11·10·9·8 = 95040 values, one per element.
//
// This is the same numbering as the offline table in
// PlatformIndependent/M12/Permutation/perms.lst, which the tests check against.

import 'perm.dart';

/// |M12| — and the number of distinct ranks.
const int kM12Order = 12 * 11 * 10 * 9 * 8; // 95040

/// Rank of [p]. Only meaningful for elements of M12.
int m12Rank(List<int> p) {
  // f = inverse(p), computed by hand as the C++ does.
  final f = List<int>.filled(kBalls, 0);
  for (var i = 0; i < kBalls; i++) {
    f[p[i]] = i;
  }

  var i = 0;
  var fi = f[0];
  var r = fi;
  while (true) {
    for (var j = i + 1; j < 5; j++) {
      if (fi < f[j]) f[j]--;
    }
    i++;
    if (i >= 5) break;
    fi = f[i];
    r = r * (kBalls - i) + fi;
  }
  return r;
}
