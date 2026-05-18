import Foundation

struct MoveRecord: Identifiable {
    let id = UUID()
    let playerName: String
    let pileIndex: Int
    let amount: Int
    let isBot: Bool
}

struct NimHint {
    let pileIndex: Int
    let amount: Int
}

class GameState: ObservableObject {
    @Published var piles: [Int]
    @Published var currentPlayerIndex: Int = 0
    @Published var history: [MoveRecord]  = []
    @Published var isGameOver: Bool       = false
    @Published var winnerMessage: String  = ""
    @Published var selectedPile: Int?     = nil
    @Published var takeAmount: Int        = 1
    @Published var isBotThinking: Bool    = false
    @Published var lastHint: NimHint?     = nil

    let settings: GameSettings
    let players: [PlayerConfig]

    init(settings: GameSettings) {
        self.settings = settings
        self.players  = settings.activePlayers
        self.piles    = settings.pileSizes
    }

    var currentPlayer: PlayerConfig { players[currentPlayerIndex] }
    var nimXOR: Int { NimBot.nimXOR(piles: piles) }
    var isGoodPosition: Bool { NimBot.isGoodPosition(piles: piles, isMisere: settings.isMisere) }

    // MARK: - Input

    func selectPile(_ index: Int) {
        guard !isBotThinking, !isGameOver, index < piles.count, piles[index] > 0 else { return }
        if selectedPile == index { selectedPile = nil } else { selectedPile = index; takeAmount = 1 }
        lastHint = nil
    }

    func setTakeAmount(_ val: Int) {
        guard let pile = selectedPile else { return }
        takeAmount = min(max(1, val), piles[pile])
    }

    func confirmMove() {
        guard let pile = selectedPile, !isGameOver,
              takeAmount > 0, takeAmount <= piles[pile] else { return }
        executeMove(pileIndex: pile, amount: takeAmount)
    }

    func showHint() {
        guard let m = NimBot.smartMove(piles: piles, isMisere: settings.isMisere) else { return }
        lastHint     = NimHint(pileIndex: m.pileIndex, amount: m.amount)
        selectedPile = m.pileIndex
        takeAmount   = m.amount
    }

    // MARK: - Core

    func executeMove(pileIndex: Int, amount: Int) {
        let mover = players[currentPlayerIndex]
        withAnimation(.spring(response: 0.3)) { piles[pileIndex] -= amount }
        history.append(MoveRecord(playerName: mover.name, pileIndex: pileIndex,
                                  amount: amount, isBot: mover.isBot))
        selectedPile = nil; takeAmount = 1; lastHint = nil

        if piles.allSatisfy({ $0 == 0 }) {
            isGameOver    = true
            winnerMessage = buildWinnerMessage(mover: mover)
        } else {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
            triggerBotIfNeeded()
        }
    }

    private func buildWinnerMessage(mover: PlayerConfig) -> String {
        if settings.isMisere {
            if players.count == 2 {
                let winnerIdx = currentPlayerIndex == 0 ? 1 : 0
                return "\(players[winnerIdx].name) победил!"
            }
            return "Все кроме \(mover.name) победили!"
        }
        return "\(mover.name) победил!"
    }

    func triggerBotIfNeeded() {
        guard !isGameOver, currentPlayer.isBot, !isBotThinking else { return }
        isBotThinking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self, !self.isGameOver else {
                self?.isBotThinking = false
                return
            }
            let move: (pileIndex: Int, amount: Int)?
            switch self.currentPlayer.botDifficulty {
            case .random: move = NimBot.randomMove(piles: self.piles)
            case .smart:  move = NimBot.smartMove(piles: self.piles, isMisere: self.settings.isMisere)
            }
            self.isBotThinking = false
            if let m = move { self.executeMove(pileIndex: m.pileIndex, amount: m.amount) }
        }
    }

    func resetGame() {
        piles              = settings.pileSizes
        currentPlayerIndex = 0
        history            = []
        isGameOver         = false
        winnerMessage      = ""
        selectedPile       = nil
        takeAmount         = 1
        isBotThinking      = false
        lastHint           = nil
    }
}
