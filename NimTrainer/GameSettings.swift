import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case vsBot       = "Против бота"
    case multiplayer = "Несколько игроков"
    case training    = "Тренировка"
    var id: String { rawValue }
}

enum BotDifficulty: String, CaseIterable, Identifiable {
    case random = "Случайный бот"
    case smart  = "Умный бот"
    var id: String { rawValue }
}

struct PlayerConfig: Identifiable {
    let id: Int
    var name: String
    var isBot: Bool          = false
    var botDifficulty: BotDifficulty = .smart
}

struct GameSettings {
    var gameMode:    GameMode = .vsBot
    var isMisere:    Bool     = false

    var pileCount:   Int      = 3
    var pileSizes:   [Int]    = [3, 5, 7]
    var randomMin:   Int      = 1
    var randomMax:   Int      = 15

    var playerCount: Int      = 2
    var players: [PlayerConfig] = [
        PlayerConfig(id: 1, name: "Игрок 1"),
        PlayerConfig(id: 2, name: "Бот", isBot: true, botDifficulty: .smart)
    ]

    var trainingLevel: Int = 2

    var trainingMaxSize: Int {
        switch trainingLevel {
        case 1:  return 7
        case 2:  return 15
        case 3:  return 31
        default: return 63
        }
    }

    mutating func setPileCount(_ count: Int) {
        pileCount = count
        let hi = max(randomMin, randomMax)
        while pileSizes.count < count {
            pileSizes.append(Int.random(in: randomMin...hi))
        }
        pileSizes = Array(pileSizes.prefix(count))
    }

    mutating func randomizePiles() {
        let hi = max(randomMin, randomMax)
        pileSizes = (0..<pileCount).map { _ in Int.random(in: randomMin...hi) }
    }

    mutating func setPlayerCount(_ count: Int) {
        playerCount = count
        while players.count < count {
            let i = players.count + 1
            players.append(PlayerConfig(id: i, name: "Игрок \(i)"))
        }
        players = Array(players.prefix(count))
    }

    var activePlayers: [PlayerConfig] {
        gameMode == .training
            ? [PlayerConfig(id: 1, name: "Вы")]
            : Array(players.prefix(playerCount))
    }
}
