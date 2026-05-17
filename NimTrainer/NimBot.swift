import Foundation

enum NimBot {

    // MARK: - Public API

    static func smartMove(piles: [Int], isMisere: Bool) -> (pileIndex: Int, amount: Int)? {
        guard piles.contains(where: { $0 > 0 }) else { return nil }
        return isMisere ? misereMove(piles: piles) : normalMove(piles: piles)
    }

    static func randomMove(piles: [Int]) -> (pileIndex: Int, amount: Int)? {
        let nonEmpty = piles.enumerated().filter { $0.element > 0 }
        guard let chosen = nonEmpty.randomElement() else { return nil }
        return (pileIndex: chosen.offset, amount: Int.random(in: 1...chosen.element))
    }

    static func nimXOR(piles: [Int]) -> Int {
        piles.reduce(0, ^)
    }

    static func isGoodPosition(piles: [Int], isMisere: Bool) -> Bool {
        if isMisere {
            let nonEmpty = piles.filter { $0 > 0 }
            if nonEmpty.allSatisfy({ $0 == 1 }) {
                return nonEmpty.count % 2 == 0
            }
        }
        return nimXOR(piles: piles) != 0
    }

    static func binaryString(_ n: Int) -> String {
        guard n > 0 else { return "0" }
        var bits = "", val = n
        while val > 0 { bits = (val & 1 == 1 ? "1" : "0") + bits; val >>= 1 }
        return bits
    }

    // MARK: - Strategy

    private static func normalMove(piles: [Int]) -> (pileIndex: Int, amount: Int)? {
        let xor = nimXOR(piles: piles)
        if xor == 0 { return anyMove(piles: piles) }
        for (i, pile) in piles.enumerated() {
            let target = pile ^ xor
            if target < pile { return (i, pile - target) }
        }
        return anyMove(piles: piles)
    }

    private static func misereMove(piles: [Int]) -> (pileIndex: Int, amount: Int)? {
        let nonEmpty = piles.filter { $0 > 0 }

        // Endgame: all piles are 1
        if nonEmpty.allSatisfy({ $0 == 1 }) {
            guard let idx = piles.firstIndex(where: { $0 > 0 }) else { return nil }
            return (idx, 1)
        }

        // One large pile + some 1s
        if nonEmpty.filter({ $0 > 1 }).count == 1 {
            guard let bigIdx = piles.firstIndex(where: { $0 > 1 }) else { return nil }
            let bigSize  = piles[bigIdx]
            let oneCount = piles.filter { $0 == 1 }.count
            // Leave opponent with odd count of 1s (they lose in misere endgame)
            if oneCount % 2 == 0 {
                return (bigIdx, bigSize - 1)   // reduce to 1 → total ones = oneCount+1 (odd)
            } else {
                return (bigIdx, bigSize)        // take all  → total ones = oneCount   (odd)
            }
        }

        // Multiple large piles: play normal XOR strategy
        let xor = nimXOR(piles: piles)
        if xor == 0 { return anyMove(piles: piles) }
        for (i, pile) in piles.enumerated() {
            let target = pile ^ xor
            if target < pile { return (i, pile - target) }
        }
        return anyMove(piles: piles)
    }

    private static func anyMove(piles: [Int]) -> (pileIndex: Int, amount: Int)? {
        guard let idx = piles.firstIndex(where: { $0 > 0 }) else { return nil }
        return (idx, 1)
    }
}
