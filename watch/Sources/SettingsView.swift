import SwiftUI

struct SettingsView: View {
    @ObservedObject var game: MathieuEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    PermPickerView(game: game)
                } label: {
                    VStack(alignment: .leading) {
                        Text("Swap Permutation")
                        Text("#\(MathieuEngine.swapIndex + 1)")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Button { game.home(); dismiss() } label: {
                    Label("Home", systemImage: "house")
                }
                Button { game.undo() } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                Button { game.scramble(); dismiss() } label: {
                    Label("Scramble", systemImage: "shuffle")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// Crown scrolls through the swap permutations; each is shown as the home ring
// coloured by that swap; Confirm applies it.
struct PermPickerView: View {
    @ObservedObject var game: MathieuEngine
    @Environment(\.dismiss) private var dismiss
    @State private var idx: Double
    let n: Int

    init(game: MathieuEngine) {
        self.game = game
        self.n = game.n
        _idx = State(initialValue: Double(MathieuEngine.swapIndex))
    }

    var body: some View {
        let i = max(0, min(MathieuEngine.swapCount - 1, Int(idx.rounded())))
        VStack(spacing: 4) {
            Text("Swap #\(i + 1)").font(.footnote).foregroundStyle(.secondary)
            RingView(arrangement: Array(0..<n), colorOf: MathieuEngine.colorsFor(i, n))
                .frame(maxHeight: .infinity)
            Button("Confirm") {
                game.selectSwap(i)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .focusable()
        .digitalCrownRotation($idx, from: 0, through: Double(MathieuEngine.swapCount - 1),
                              by: 1, sensitivity: .low, isContinuous: false,
                              isHapticFeedbackEnabled: true)
        .navigationTitle("Permutation")
    }
}
