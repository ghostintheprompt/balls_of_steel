import Foundation

struct VWAPBands {
    let vwap: Double
    let upper1: Double
    let lower1: Double
    let upper2: Double
    let lower2: Double
    let standardDeviation: Double
}

class VWAPCalculator {
    static let shared = VWAPCalculator()
    private init() {}

    private var volumePriceSum: Double = 0
    private var volumeSquaredPriceSum: Double = 0
    private var volumeSum: Int = 0

    func calculate(price: Double, volume: Int) -> Double {
        accumulate(price: price, volume: volume)
        return volumePriceSum / Double(volumeSum)
    }

    func calculateBands(price: Double, volume: Int) -> VWAPBands {
        accumulate(price: price, volume: volume)
        return currentBands()
    }

    func currentBands() -> VWAPBands {
        let vol = max(Double(volumeSum), 1)
        let vwap = volumePriceSum / vol
        let variance = max((volumeSquaredPriceSum / vol) - (vwap * vwap), 0)
        let sd = sqrt(variance)
        return VWAPBands(
            vwap: vwap,
            upper1: vwap + sd,
            lower1: vwap - sd,
            upper2: vwap + 2 * sd,
            lower2: vwap - 2 * sd,
            standardDeviation: sd
        )
    }

    func reset() {
        volumePriceSum = 0
        volumeSquaredPriceSum = 0
        volumeSum = 0
    }

    private func accumulate(price: Double, volume: Int) {
        let v = Double(volume)
        volumePriceSum += price * v
        volumeSquaredPriceSum += price * price * v
        volumeSum += volume
    }
} 