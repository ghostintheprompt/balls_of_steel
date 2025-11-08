import Foundation

class VWAPCalculator {
    static let shared = VWAPCalculator()
    private init() {}
    
    private var volumePriceSum: Double = 0
    private var volumeSum: Int = 0
    
    func calculate(price: Double, volume: Int) -> Double {
        volumePriceSum += price * Double(volume)
        volumeSum += volume
        return volumePriceSum / Double(volumeSum)
    }
    
    func reset() {
        volumePriceSum = 0
        volumeSum = 0
    }
} 