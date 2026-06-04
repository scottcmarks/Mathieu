import SwiftUI

// Ball palette (RGB), matching the iOS app's BALL_COLORS order.
let ballRGB: [(Double, Double, Double)] = [
    (1, 1, 1),                          // white
    (0x77 / 255, 0xAA / 255, 1),        // light azure blue
    (1, 0x99 / 255, 0x33 / 255),        // light hard orange
    (1, 1, 0),                          // yellow
    (0, 0xCC / 255, 0),                 // dark hard green
    (1, 0, 0),                          // red
]

func ballColor(_ i: Int) -> Color {
    let c = ballRGB[((i % ballRGB.count) + ballRGB.count) % ballRGB.count]
    return Color(red: c.0, green: c.1, blue: c.2)
}

// 0.6x brightness, for the marble rim.
func ballDark(_ i: Int) -> Color {
    let c = ballRGB[((i % ballRGB.count) + ballRGB.count) % ballRGB.count]
    return Color(red: c.0 * 0.6, green: c.1 * 0.6, blue: c.2 * 0.6)
}

// Map index -> palette colour from a swap permutation: each disjoint 2-cycle
// gets the next colour, so a swapped pair shares a colour.
func colorIndices(_ swapPerm: [Int]) -> [Int] {
    let n = swapPerm.count
    var c = [Int](repeating: -1, count: n)
    var next = 0
    for i in 0..<n where c[i] == -1 {
        c[i] = next
        c[swapPerm[i]] = next
        next += 1
    }
    return c
}
