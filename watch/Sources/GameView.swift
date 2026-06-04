import SwiftUI

// Ring layout, scaled to fit the watch screen (ball 0 sits above the ring).
struct RingGeom {
    let center: CGPoint
    let ballR: CGFloat
    let circleR: CGFloat
    let n: Int

    init(_ size: CGSize, n: Int) {
        self.n = n
        // total extents (as multiples of nominal width W): horiz 0.8625, vert 1.034
        let w = min(size.width / 0.8625, size.height / 1.034) * 0.98
        let halfW = w / 2
        ballR = 0.1375 * halfW
        circleR = halfW - 2 * ballR
        let topRoom = circleR + 2.5 * ballR + ballR
        let extentH = topRoom + circleR + ballR
        let offY = (size.height - extentH) / 2
        center = CGPoint(x: size.width / 2, y: offY + topRoom)
    }

    func slot(_ i: Int) -> CGPoint {
        if i == 0 { return CGPoint(x: center.x, y: center.y - (circleR + 2.5 * ballR)) }
        let a = (2 * Double.pi / Double(n - 1)) * Double(i - 1) - Double.pi / 2
        return CGPoint(x: center.x + circleR * cos(a), y: center.y + circleR * sin(a))
    }
}

// A fixed marble: dark rim brightening to a highlight near the top.
struct Sphere: View {
    let colorIndex: Int
    let r: CGFloat
    var body: some View {
        Circle()
            .fill(RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: ballColor(colorIndex), location: 0.0),
                    .init(color: ballColor(colorIndex), location: 0.45),
                    .init(color: ballDark(colorIndex), location: 1.0),
                ]),
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 0, endRadius: r))
            .frame(width: r * 2, height: r * 2)
    }
}

// Fixed coloured spheres + number labels (labels show the current arrangement).
struct RingView: View {
    let arrangement: [Int]
    let colorOf: [Int]
    var body: some View {
        GeometryReader { geo in
            let g = RingGeom(geo.size, n: arrangement.count)
            ZStack {
                ForEach(0..<arrangement.count, id: \.self) { slot in
                    Sphere(colorIndex: colorOf[slot], r: g.ballR).position(g.slot(slot))
                }
                ForEach(0..<arrangement.count, id: \.self) { slot in
                    Text("\(arrangement[slot])")
                        .font(.system(size: g.ballR * 0.95, weight: .bold))
                        .foregroundColor(.black)
                        .position(g.slot(slot))
                }
            }
        }
    }
}

struct GameView: View {
    @StateObject private var game = MathieuEngine()
    @State private var crown = 0.0
    @State private var lastCrown = 0.0
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 3) {
                RingView(arrangement: game.arrangement, colorOf: game.colorOf)
                    .focusable()
                    .digitalCrownRotation($crown, from: -1_000_000, through: 1_000_000,
                                          by: 1, sensitivity: .low,
                                          isContinuous: true, isHapticFeedbackEnabled: true)
                    .onChange(of: crown) { _, v in
                        let d = Int((v - lastCrown).rounded())
                        if d > 0 {
                            lastCrown = v
                            for _ in 0..<d { game.right() }
                        } else if d < 0 {
                            lastCrown = v
                            for _ in 0..<(-d) { game.left() }
                        }
                    }
                HStack(spacing: 6) {
                    macroButton("A⁻¹") { game.runMacro(inverted: true) }
                    plainButton("Swap") { game.swap() }
                    macroButton("A") { game.runMacro(inverted: false) }
                        .handGestureShortcut(.primaryAction)
                }
                .padding(.bottom, 2)
            }
            .navigationTitle("M12")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { game.scramble() } label: { Image(systemName: "shuffle") }
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView(game: game) }
        }
    }

    private func plainButton(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 15, weight: .semibold)).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    // A/A⁻¹: tap runs the macro (dim until one is defined); long-press defines it.
    private func macroButton(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .foregroundStyle(game.macroDefined ? Color.yellow : Color.secondary)
        }
        .buttonStyle(.bordered)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in
            game.setMacro()
        })
    }
}
