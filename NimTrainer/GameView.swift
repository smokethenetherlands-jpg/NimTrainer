import SwiftUI

// MARK: - GameView

struct GameView: View {
    @StateObject private var game: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var showAnalysis = false
    @State private var showHistory  = false

    init(settings: GameSettings) {
        _game = StateObject(wrappedValue: GameState(settings: settings))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            VStack(spacing: 0) {
                pilesArea
                movePanel
                Spacer(minLength: 0)
            }
            .overlay(alignment: .bottom) { expandablePanel }
            .clipped()
            tabBarView
        }
        .background(Color.nimBackground.ignoresSafeArea())
        .overlay { if game.isGameOver { gameOverOverlay } }
        .navigationTitle("Nim")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { game.triggerBotIfNeeded() }
    }

    @ViewBuilder
    var expandablePanel: some View {
        if showAnalysis {
            AnalysisPanelView(game: game)
                .transition(.opacity)
        } else if showHistory {
            HistoryView(history: game.history)
                .transition(.opacity)
        }
    }

    // MARK: Top bar

    var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                if game.isBotThinking {
                    HStack(spacing: 6) {
                        ProgressView().tint(.cyan).scaleEffect(0.75)
                        Text("\(game.currentPlayer.name) думает…")
                            .font(.headline).foregroundColor(.cyan)
                    }
                } else {
                    Text("Ход: \(game.currentPlayer.name)")
                        .font(.headline).foregroundColor(.yellow)
                }
                Text(game.settings.isMisere ? "Обратный Ним" : "Обычный Ним")
                    .font(.caption).foregroundColor(.gray)
            }
            Spacer()
            xorBadge
        }
        .padding(.horizontal).padding(.vertical, 10)
        .background(Color.nimCard)
    }

    var xorBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("XOR = \(game.nimXOR)").font(.caption.bold())
                .foregroundColor(game.isGoodPosition ? .green : .red)
            Text(game.isGoodPosition ? "Выигрышная" : "Проигрышная")
                .font(.caption2)
                .foregroundColor(game.isGoodPosition ? .green : .red)
        }
        .padding(8)
        .background((game.isGoodPosition ? Color.green : Color.red).opacity(0.12))
        .cornerRadius(8)
    }

    // MARK: Piles

    var pilesArea: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(0..<game.piles.count, id: \.self) { i in
                    PileView(
                        size: game.piles[i], index: i,
                        isSelected: game.selectedPile == i,
                        isHinted:   game.lastHint?.pileIndex == i,
                        isBotThinking: game.isBotThinking
                    ) {
                        withAnimation(.spring(response: 0.25)) { game.selectPile(i) }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
        }
        .frame(maxHeight: 300)
        .background(Color.nimBackground)
    }

    // MARK: Move panel

    @ViewBuilder
    var movePanel: some View {
        Divider().background(Color.gray.opacity(0.3))
        if game.isGameOver {
            EmptyView()
        } else if game.isBotThinking {
            Text("Бот делает ход…").font(.subheadline).foregroundColor(.gray)
                .frame(maxWidth: .infinity).padding(14).background(Color.nimCard)
        } else if let idx = game.selectedPile {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Кучка \(idx + 1)").font(.caption).foregroundColor(.gray)
                    Text("Осталось: \(game.piles[idx])").font(.subheadline).foregroundColor(.white)
                }
                Stepper(value: Binding(
                    get: { game.takeAmount },
                    set: { game.setTakeAmount($0) }
                ), in: 1...max(1, game.piles[idx])) {
                    Text("Взять: \(game.takeAmount)").font(.title3.bold()).foregroundColor(.yellow)
                        .frame(width: 110)
                }
                Spacer()
                Button { game.confirmMove() } label: {
                    Text("Взять").font(.headline).foregroundColor(.black)
                        .padding(.horizontal, 22).padding(.vertical, 10)
                        .background(Color.yellow).cornerRadius(12)
                }
                .disabled(game.takeAmount < 1 || game.takeAmount > game.piles[idx])
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.nimCard)
        } else {
            Text("Выберите кучку").font(.subheadline).foregroundColor(.gray)
                .frame(maxWidth: .infinity).padding(14).background(Color.nimCard)
        }
    }

    // MARK: Bottom section

    var tabBarView: some View {
        VStack(spacing: 0) {
            Divider().background(Color.gray.opacity(0.25))
            HStack(spacing: 0) {
                tabBtn("Анализ",   icon: "chart.bar.fill",   active: showAnalysis) {
                    withAnimation { showAnalysis.toggle(); if showAnalysis { showHistory = false } }
                }
                tabBtn("История",  icon: "list.bullet",      active: showHistory) {
                    withAnimation { showHistory.toggle(); if showHistory { showAnalysis = false } }
                }
                tabBtn("Подсказка", icon: "lightbulb.fill",  active: game.lastHint != nil) {
                    game.showHint(); showAnalysis = true; showHistory = false
                }
            }
            .background(Color.nimCard)
        }
    }

func tabBtn(_ title: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 17))
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            .foregroundColor(active ? .yellow : .gray)
        }
    }

    // MARK: Game over overlay

    var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("🏆").font(.system(size: 72))
                Text(game.winnerMessage).font(.title.bold()).foregroundColor(.yellow)
                    .multilineTextAlignment(.center)
                VStack(spacing: 12) {
                    Button {
                        game.resetGame()
                        game.triggerBotIfNeeded()
                        showAnalysis = false; showHistory = false
                    } label: {
                        Text("Играть ещё").font(.headline).frame(maxWidth: .infinity)
                            .padding(.vertical, 16).background(Color.yellow).foregroundColor(.black).cornerRadius(16)
                    }
                    Button { dismiss() } label: {
                        Text("К настройкам").font(.headline).frame(maxWidth: .infinity)
                            .padding(.vertical, 16).background(Color.nimCard).foregroundColor(.white).cornerRadius(16)
                    }
                }
            }
            .padding(32).background(Color.nimBackground).cornerRadius(24).padding(24)
        }
    }
}

// MARK: - PileView

struct PileView: View {
    let size: Int
    let index: Int
    let isSelected: Bool
    let isHinted: Bool
    let isBotThinking: Bool
    let onTap: () -> Void

    private let maxVisible = 15
    private let itemW: CGFloat = 40
    private let itemH: CGFloat = 14
    private let colHeight: CGFloat = 240

    var body: some View {
        VStack(spacing: 4) {
            // Column of items aligned to bottom
            ZStack(alignment: .bottom) {
                Color.clear.frame(width: itemW + 14, height: colHeight)
                VStack(spacing: 2) {
                    if size > maxVisible {
                        Text("+\(size - maxVisible)").font(.caption2).foregroundColor(.yellow.opacity(0.7))
                        ForEach(0..<maxVisible, id: \.self) { _ in item }
                    } else {
                        ForEach(0..<max(size, 0), id: \.self) { _ in item }
                    }
                }
            }
            Text("\(size)").font(.headline.bold())
                .foregroundColor(size == 0 ? .gray : .white)
            Text("К\(index + 1)").font(.caption2).foregroundColor(.gray)
        }
        .padding(.vertical, 8).padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(bgColor)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: isSelected || isHinted ? 2 : 0))
        )
        .opacity(size == 0 ? 0.45 : 1.0)
        .onTapGesture { if size > 0 && !isBotThinking { onTap() } }
    }

    var item: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(isHinted ? Color.orange : (isSelected ? Color(red: 1, green: 0.92, blue: 0.2) : Color.yellow))
            .frame(width: itemW, height: itemH)
    }

    var bgColor: Color { isSelected ? Color.nimCard : Color.nimCard.opacity(0.6) }
    var borderColor: Color { isHinted ? .orange : (isSelected ? .yellow : .clear) }
}

// MARK: - AnalysisPanelView

struct AnalysisPanelView: View {
    @ObservedObject var game: GameState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(game.isGoodPosition
                     ? "✅ Позиция хорошая — есть выигрышный ход"
                     : "❌ Позиция плохая — нет выигрышного хода")
                    .font(.subheadline.bold())
                    .foregroundColor(game.isGoodPosition ? .green : .red)
                    .fixedSize(horizontal: false, vertical: true)

                binaryTable

                if let hint = game.lastHint {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill").foregroundColor(.yellow)
                        Text("Взять \(hint.amount) из кучки \(hint.pileIndex + 1) → останется \(game.piles[hint.pileIndex] - hint.amount)")
                            .font(.subheadline).foregroundColor(.white)
                    }
                    .padding(10).background(Color.yellow.opacity(0.1)).cornerRadius(10)
                }
            }
            .padding()
        }
        .frame(maxHeight: 250)
        .background(Color.nimCard)
    }

    var binaryTable: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Кучка").frame(width: 55, alignment: .leading)
                Text("Размер").frame(width: 50, alignment: .trailing)
                Spacer()
                Text("Двоичная")
            }
            .font(.caption.bold()).foregroundColor(.gray)

            ForEach(0..<game.piles.count, id: \.self) { i in
                HStack {
                    Text("К\(i + 1)").frame(width: 55, alignment: .leading)
                    Text("\(game.piles[i])").frame(width: 50, alignment: .trailing)
                    Spacer()
                    Text(NimBot.binaryString(game.piles[i]))
                }
                .font(.system(.caption, design: .monospaced)).foregroundColor(.white)
            }

            Divider().background(Color.gray.opacity(0.4))

            HStack {
                Text("XOR").frame(width: 55, alignment: .leading)
                Text("\(game.nimXOR)").frame(width: 50, alignment: .trailing)
                Spacer()
                Text(NimBot.binaryString(game.nimXOR))
            }
            .font(.system(.caption, design: .monospaced).bold()).foregroundColor(.yellow)
        }
        .padding(10).background(Color.nimBackground).cornerRadius(10)
    }
}

// MARK: - HistoryView

struct HistoryView: View {
    let history: [MoveRecord]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(history.reversed()) { rec in
                    HStack(spacing: 8) {
                        Image(systemName: rec.isBot ? "cpu" : "person.fill")
                            .font(.caption).foregroundColor(rec.isBot ? .cyan : .yellow)
                        Text("\(rec.playerName) взял \(rec.amount) из кучки \(rec.pileIndex + 1)")
                            .font(.subheadline).foregroundColor(.white)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.nimBackground).cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxHeight: 200)
        .background(Color.nimCard)
    }
}
