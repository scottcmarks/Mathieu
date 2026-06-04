import Foundation

/// Swift wrapper over the C M12 engine (the same ABI Flutter uses via FFI).
final class MathieuEngine: ObservableObject {
    private let h: UnsafeMutableRawPointer
    let n: Int

    @Published private(set) var arrangement: [Int] = []
    @Published private(set) var colorOf: [Int] = []   // slot/position -> palette index
    @Published private(set) var solving = false
    @Published private(set) var solvedNow = false      // pulse for applause/animation

    private var notedSuccess = true

    init() {
        h = mathieu_new()
        n = Int(mathieu_num_balls())
        recolor()
        refresh()
    }
    deinit { mathieu_free(h) }

    static var swapCount: Int { Int(mathieu_num_swaps()) }
    static var swapIndex: Int {
        get { Int(mathieu_get_swap_index()) }
        set { mathieu_set_swap_index(Int32(newValue)) }
    }

    var isSolved: Bool { mathieu_is_solved(h) != 0 }
    var moves: Int { Int(mathieu_moves(h)) }
    var steps: Int { Int(mathieu_steps(h)) }
    var macroDefined: Bool { mathieu_macro_defined(h, 65) != 0 }

    private func readInts(_ count: Int, _ fill: (UnsafeMutablePointer<Int32>) -> Void) -> [Int] {
        var buf = [Int32](repeating: 0, count: count)
        buf.withUnsafeMutableBufferPointer { fill($0.baseAddress!) }
        return buf.map { Int($0) }
    }

    private func refresh() { arrangement = readInts(n) { mathieu_get_arrangement(h, $0) } }
    private func recolor() {
        colorOf = colorIndices(readInts(n) { mathieu_get_swap_permutation($0) })
    }

    // A "play" move that can solve the puzzle.
    private func afterMove() {
        refresh()
        let solved = isSolved
        solvedNow = (solving && solved && !notedSuccess)
        if solvedNow { notedSuccess = true }
    }

    func left()  { mathieu_left(h, 1);  afterMove() }
    func right() { mathieu_right(h, 1); afterMove() }
    func swap()  { mathieu_swap(h);     afterMove() }
    func undo()  { _ = mathieu_undo(h, 1); afterMove() }
    func runMacro(inverted: Bool) { mathieu_run_macro(h, 65, inverted ? 1 : 0); afterMove() }

    func setMacro() { mathieu_set_macro(h, 65); refresh() }

    func scramble() {
        mathieu_random(h)
        solving = true
        notedSuccess = false
        solvedNow = false
        refresh()
    }
    func home() {
        mathieu_reset(h)
        solving = false
        notedSuccess = true
        solvedNow = false
        refresh()
    }

    func selectSwap(_ i: Int) {
        MathieuEngine.swapIndex = i
        mathieu_reset(h)
        mathieu_erase_all_macros(h)
        solving = false
        notedSuccess = true
        recolor()
        refresh()
    }

    // For the preview/picker: colour map for an arbitrary swap permutation index.
    static func colorsFor(_ index: Int, _ n: Int) -> [Int] {
        var buf = [Int32](repeating: 0, count: n)
        buf.withUnsafeMutableBufferPointer { mathieu_get_swap_permutation_at(Int32(index), $0.baseAddress!) }
        return colorIndices(buf.map { Int($0) })
    }
}
