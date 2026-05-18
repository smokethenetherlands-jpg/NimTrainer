import SwiftUI

struct TrainingView: View {
    let settings: GameSettings

    @State private var piles: [Int]      = []
    @State private var selectedPile: Int? = nil
    @State private var takeAmount: Int    = 1
    @State private var result: TrainingResult? = nil
    @State private var taskNum: Int       = 1

    struct TrainingResult {
        let pilesBefore: [Int]
        let pilesAfter:  [Int]
        let xorBefore:   Int
        let xorAfter:    Int
        let wasGood:     Bool
        let wasOptimal:  Bool
        let optimalMove: (pileIndex: Int, amount: Int)?
    }

    var body: some View {
        ZStack {
            Color.nimBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                taskHeader
                ScrollView {
                    VStack(spacing: 16) {
                        pilesSection
                        analysisSection
                        if let res = result { resultSection(res) } else { moveControls }
                        if result != nil { nextButton } else { EmptyView() }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Тренировка")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { generatePosition() }
    }

    // MARK: Task header

    var taskHeader: some View {
        HStack {
            Text("Задача \(taskNum)").font(.headline).foregroundColor(.yellow)
            Spacer()
            Text("Ур. \(settings.trainingLevel) · до \(settings.trainingMaxSize)")
                .font(.caption).foregroundColor(.gray)
        }
        .padding(.horizontal).padding(.vertical, 10)
        .background(Color.nimCard)
    }

    // MARK: Piles

    var pilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Позиция")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(piles.indices, id: \.self) { i in
                        PileView(
                            size: piles[i], index: i,
                            isSelected: selectedPile == i,
                            isHinted: false,
                            isBotThinking: result != nil
                        ) {
                            if result == nil { tap(pile: i) }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: Analysis

    var analysisSection: some View {
        let xor    = NimBot.nimXOR(piles: piles)
        let isGood = NimBot.isGoodPosition(piles: piles, isMisere: settings.isMisere)
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Анализ позиции")

            VStack(spacing: 4) {
                HStack {
                    Text("Кучка").frame(width: 55, alignment: .leading)
                    Text("Размер").frame(width: 50, alignment: .trailing)
                    Spacer()
                    Text("Двоичная")
                }
                .font(.caption.bold()).foregroundColor(.gray)

                ForEach(piles.indices, id: \.self) { i in
                    HStack {
                        Text("К\(i + 1)").frame(width: 55, alignment: .leading)
                        Text("\(piles[i])").frame(width: 50, alignment: .trailing)
                        Spacer()
                        Text(NimBot.binaryString(piles[i]))
                    }
                    .font(.system(.caption, design: .monospaced)).foregroundColor(.white)
                }

                Divider().background(Color.gray.opacity(0.4))

                HStack {
                    Text("XOR").frame(width: 55, alignment: .leading)
                    Text("\(xor)").frame(width: 50, alignment: .trailing)
                    Spacer()
                    Text(NimBot.binaryString(xor))
                }
                .font(.system(.caption, design: .monospaced).bold()).foregroundColor(.yellow)
            }
            .padding(10).background(Color.nimBackground).cornerRadius(10)

            Text(isGood
                 ? "✅ Позиция хорошая — есть выигрышный ход"
                 : "❌ Позиция плохая — нет выигрышного хода")
                .font(.subheadline.bold())
                .foregroundColor(isGood ? .green : .red)
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background((isGood ? Color.green : Color.red).opacity(0.1))
                .cornerRadius(10)
        }
        .padding(14).background(Color.nimCard).cornerRadius(16)
    }

    // MARK: Move controls

    var moveControls: some View {
        VStack(spacing: 12) {
            if let idx = selectedPile {
                HStack {
                    Text("Кучка \(idx + 1) выбрана").foregroundColor(.gray)
                    Spacer()
                    Stepper(value: Binding(
                        get: { takeAmount },
                        set: { takeAmount = min(max(1, $0), piles[idx]) }
                    ), in: 1...max(1, piles[idx])) {
                        Text("Взять: \(takeAmount)").font(.headline).foregroundColor(.yellow)
                    }
                }
                Button { makeMove() } label: {
                    Text("Подтвердить ход").font(.headline).frame(maxWidth: .infinity)
                        .padding(.vertical, 14).background(Color.yellow).foregroundColor(.black).cornerRadius(14)
                }
            } else {
                Text("Выберите кучку и сделайте ход").foregroundColor(.gray)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(Color.nimCard).cornerRadius(14)
            }
        }
        .padding(14).background(Color.nimCard).cornerRadius(16)
    }

    // MARK: Result

    func resultSection(_ res: TrainingResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !res.wasGood {
                Text("ℹ️ Позиция была проигрышной").font(.headline).foregroundColor(.blue)
            } else if res.wasOptimal {
                Text("✅ Оптимальный ход!").font(.headline).foregroundColor(.green)
            } else {
                Text("⚠️ Ход сделан, но не оптимальный").font(.headline).foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("XOR до хода:").foregroundColor(.gray)
                    Text("\(res.xorBefore)").bold()
                        .foregroundColor(res.xorBefore == 0 ? .red : .green)
                    Text("(\(NimBot.binaryString(res.xorBefore)))")
                        .font(.system(.caption, design: .monospaced)).foregroundColor(.gray)
                }
                HStack {
                    Text("XOR после:").foregroundColor(.gray)
                    Text("\(res.xorAfter)").bold()
                        .foregroundColor(res.xorAfter == 0 ? .green : .orange)
                    Text("(\(NimBot.binaryString(res.xorAfter)))")
                        .font(.system(.caption, design: .monospaced)).foregroundColor(.gray)
                }
            }

            if !res.wasGood {
                Text("Выигрышного хода нет — XOR = 0. Любой ход передаёт выигрышную позицию сопернику.")
                    .font(.subheadline).foregroundColor(.blue)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !res.wasOptimal {
                if let opt = res.optimalMove {
                    Text("Оптимальный ход: взять \(opt.amount) из кучки \(opt.pileIndex + 1) → останется \(res.pilesBefore[opt.pileIndex] - opt.amount)")
                        .font(.subheadline).foregroundColor(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14).background(Color.nimCard).cornerRadius(16)
    }

    // MARK: Next button

    var nextButton: some View {
        Button {
            generatePosition()
            result = nil; selectedPile = nil; takeAmount = 1
            taskNum += 1
        } label: {
            Text("Следующая задача").font(.headline).frame(maxWidth: .infinity)
                .padding(.vertical, 14).background(Color.yellow).foregroundColor(.black).cornerRadius(14)
        }
    }

    // MARK: Logic

    func generatePosition() {
        let count   = Int.random(in: 2...5)
        let maxSize = max(1, settings.trainingMaxSize)
        piles = (0..<count).map { _ in Int.random(in: 1...maxSize) }
    }

    func tap(pile: Int) {
        if selectedPile == pile { selectedPile = nil } else { selectedPile = pile; takeAmount = 1 }
    }

    func makeMove() {
        guard let idx = selectedPile, takeAmount > 0, takeAmount <= piles[idx] else { return }
        let xorBefore = NimBot.nimXOR(piles: piles)
        let isGood    = NimBot.isGoodPosition(piles: piles, isMisere: settings.isMisere)
        let optimal   = NimBot.smartMove(piles: piles, isMisere: settings.isMisere)
        let before    = piles
        var after     = piles; after[idx] -= takeAmount
        let xorAfter  = NimBot.nimXOR(piles: after)
        let wasOptimal = isGood ? xorAfter == 0 : true

        result = TrainingResult(pilesBefore: before, pilesAfter: after,
                                xorBefore: xorBefore, xorAfter: xorAfter,
                                wasGood: isGood, wasOptimal: wasOptimal, optimalMove: optimal)
        withAnimation(.spring(response: 0.3)) { piles = after }
    }

    func sectionLabel(_ text: String) -> some View {
        Text(text).font(.subheadline.bold()).foregroundColor(.secondary)
            .textCase(.uppercase).frame(maxWidth: .infinity, alignment: .leading)
    }
}
