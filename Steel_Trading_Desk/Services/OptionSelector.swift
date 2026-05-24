import Foundation

// MARK: - OptionSelector
//
// Picks a single tightened contract suggestion that sits NEXT TO the doc
// default on the entry card. Never replaces the doc default, never widens
// its own bounds silently, never gates the trade. If nothing qualifies the
// caller gets `nil` and the card stays silent on the suggestion line.
//
// Rule it implements (sits alongside, does not replace, the doc rule of
// 0-4 DTE / 1-2 OTM by price from thinkorswim_complete_setup_2026.md):
//   - DTE 3-7
//   - |delta| within 0.50–0.60, closest to 0.55
//   - reject if bid/ask spread > max($0.05, 5% of mid)
//   - size = floor(budget / (ask * 100)), clamped to
//     StrategySpec.absoluteMaxContracts
//
// Pure value-type. No instance state, no shared singletons → thread-safe by
// construction. Safe to call from any actor / websocket loop.

enum OptionSelector {

    // MARK: - Tightened-suggestion bounds
    //
    // These are intentionally separate from StrategySpec. The spec governs
    // the doc default (which is unchanged). These constants govern the
    // optional tightened pick that the card surfaces alongside it.

    static let targetDelta: Double = 0.55
    static let deltaBandHalfWidth: Double = 0.05    // |Δ| in 0.50…0.60
    static let dteMin: Int = 3
    static let dteMax: Int = 7
    static let maxSpreadAbsolute: Double = 0.05     // $0.05 floor
    static let maxSpreadPercent: Double = 0.05      // 5% of mid

    // MARK: - Public API

    static func suggest(
        side: OptionType,
        chain: OptionsChain,
        budget: Double,
        now: Date = Date()
    ) -> ContractSuggestion? {
        let pool = side == .call ? chain.calls : chain.puts
        let qualified = pool
            .filter { $0.type == side }
            .filter { isWithinDTE($0.expiration, now: now) }
            .filter { isWithinDeltaBand($0.delta) }
            .filter { passesSpreadGate($0) }

        guard let best = qualified.min(by: { distanceFromTarget($0) < distanceFromTarget($1) }) else {
            return nil
        }

        let costPerContract = best.ask * 100
        guard costPerContract > 0, budget > 0 else { return nil }

        let rawCount = Int((budget / costPerContract).rounded(.down))
        let count = min(rawCount, StrategySpec.absoluteMaxContracts)
        guard count > 0 else { return nil }

        let spread = max(0, best.ask - best.bid)
        let mid = best.midPrice

        return ContractSuggestion(
            contract: best,
            contractCount: count,
            estimatedCost: Double(count) * costPerContract,
            spread: spread,
            spreadPercent: mid > 0 ? spread / mid : Double.infinity,
            daysToExpiration: daysUntil(best.expiration, now: now)
        )
    }

    // MARK: - Bounds (internal — exposed for StrategyAuditor)

    static func isWithinDTE(_ expiration: Date, now: Date) -> Bool {
        let d = daysUntil(expiration, now: now)
        return d >= dteMin && d <= dteMax
    }

    static func isWithinDeltaBand(_ delta: Double) -> Bool {
        let magnitude = abs(delta)
        return magnitude >= (targetDelta - deltaBandHalfWidth)
            && magnitude <= (targetDelta + deltaBandHalfWidth)
    }

    static func passesSpreadGate(_ contract: OptionContract) -> Bool {
        let spread = contract.ask - contract.bid
        let mid = contract.midPrice
        guard mid > 0 else { return false }
        return spread <= max(maxSpreadAbsolute, mid * maxSpreadPercent)
    }

    // MARK: - Helpers

    private static func distanceFromTarget(_ contract: OptionContract) -> Double {
        abs(abs(contract.delta) - targetDelta)
    }

    static func daysUntil(_ expiration: Date, now: Date) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let a = cal.startOfDay(for: now)
        let b = cal.startOfDay(for: expiration)
        return cal.dateComponents([.day], from: a, to: b).day ?? -1
    }
}

// MARK: - ContractSuggestion

struct ContractSuggestion: Equatable {
    let contract: OptionContract
    let contractCount: Int
    let estimatedCost: Double
    let spread: Double
    let spreadPercent: Double
    let daysToExpiration: Int

    static func == (lhs: ContractSuggestion, rhs: ContractSuggestion) -> Bool {
        let sameContract = lhs.contract.symbol == rhs.contract.symbol
            && lhs.contract.strike == rhs.contract.strike
            && lhs.contract.expiration == rhs.contract.expiration
            && lhs.contract.type == rhs.contract.type
        return sameContract && lhs.contractCount == rhs.contractCount
    }
}
