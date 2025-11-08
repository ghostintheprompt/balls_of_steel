# Balls of Steel Trading Algorithm

> **Professional Algorithmic Trading System for macOS**
> 
> A sophisticated trading application implementing 11 proven strategies with real-time market monitoring, risk management, and automated signal generation.

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/swift-FA7343?style=for-the-badge&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0D96F6?style=for-the-badge&logo=swift&logoColor=white)

## 🎯 Overview

The Balls of Steel Trading Algorithm is a comprehensive macOS application that implements 11 professional trading strategies with a documented success rate of 65-78%. The system provides real-time market monitoring, automated signal generation, and sophisticated risk management based on volatility conditions.

### Key Features

- **11 Proven Trading Strategies** with documented success rates
- **Real-time Market Monitoring** with 30-second scan intervals
- **VIX-Based Risk Management** with dynamic position sizing
- **Schwab API Integration** for live market data and order execution
- **Advanced Signal Filtering** with setup quality assessment
- **Professional UI** with trading dashboard and notifications

## 📈 Trading Strategies

### Core Strategies (72.7% - 78% Success Rate)

| Strategy | Success Rate | Description |
|----------|--------------|-------------|
| **Earnings Volatility Crush** | 72.7% | Iron condors on high IV stocks before earnings |
| **Gap Fill Trading** | 78% | Technical gap fills within 0.5-2% range |
| **0DTE Iron Butterfly** | 66.8% | Same-day expiration premium collection |
| **VIX Spike Premium Selling** | 68% | Defined risk selling during volatility spikes |
| **Momentum Breakout** | 65% | VWAP breaks with volume confirmation |
| **Pre-Market Institutional Flow** | 70% | Following institutional options activity |
| **Weekly Options Expiration** | 75% | Premium selling to retail lottery buyers |

### Legacy Strategies (Updated)

- **Gap and Go** → Integrated with Gap Fill strategy
- **VWAP Reversal** → Enhanced with volume filters
- **Power Hour** → Refined momentum criteria  
- **Panic Reversal** → Optimized entry conditions

## 🏗 Architecture

### Core Components

```
Balls_of_Steel/
├── Models/           # Data structures and strategy logic
├── Services/         # Market data, signals, and API integration
├── Views/           # SwiftUI user interface
├── Config/          # Strategy parameters and thresholds
├── Extensions/      # Utility extensions
└── Documentation/   # Strategy specifications
```

### Key Services

- **SignalScanner**: Real-time strategy validation and signal generation
- **MarketDataService**: Live market data processing via Schwab API
- **SignalMonitor**: Trade lifecycle management and monitoring
- **NotificationService**: Alert system for high-quality setups
- **OptionsCalculator**: Advanced options pricing and Greeks

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+ (Ventura)
- Xcode 14.0+
- Swift 5.7+
- Schwab Trading Account with API access

### Installation

1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd BALLS_OF_STEEL_ALGO_5_8_2025
   ```

2. **Open in Xcode**
   ```bash
   open Balls_of_Steel.xcodeproj
   ```

3. **Configure API Keys**
   - Set up Schwab API credentials in `SchwabService.swift`
   - Update API endpoints in `AppConfig.swift`

4. **Build and Run**
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

### Schwab API Setup

1. Register for Schwab Developer Account
2. Create OAuth application
3. Configure redirect URI: `ballsofsteel://api.schwab.com`
4. Update `SchwabService.swift` with your credentials

## 📊 Risk Management

### Position Sizing Matrix

| VIX Level | Max Position Size | Risk Adjustment |
|-----------|------------------|-----------------|
| < 20 | 2.0% | Normal |
| 20-30 | 1.5% | Reduced |
| 30-40 | 1.0% | Conservative |
| > 40 | 0.5% | Minimal |

### Setup Quality Assessment

- **Perfect Setup**: All conditions met → 2% position
- **Good Setup**: Most conditions met → 1% position  
- **Marginal Setup**: Few conditions met → 0.5% position

### Portfolio Limits

- Maximum 10% total options exposure
- Maximum 3 earnings positions simultaneously
- Maximum 5% in any single underlying

## 🔧 Configuration

### Strategy Parameters

Edit `AppConfig.swift` to customize strategy thresholds:

```swift
// Example: Earnings Volatility Crush
static let earningsVolatilityCrush = EarningsVolatilityCrushParams(
    minIVRank: 75.0,
    optimalIVRank: 85.0,
    maxDaysToEarnings: 3,
    creditTarget: 2.00...2.80,
    profitTarget: 0.50...0.80
)
```

### Market Hours

```swift
// Trading windows defined in TimeManager
let preMarketWindow = "04:00-09:30"
let regularHours = "09:30-16:00"
let afterHours = "16:00-20:00"
```

## 📱 User Interface

### Trading Dashboard

- **Market Status**: Real-time market phase indicator
- **Active Signals**: Live strategy alerts with confidence scores
- **Active Trades**: Position monitoring and P&L tracking
- **Strategy Performance**: Historical success rates and metrics

### Widget Support

- macOS Today Widget for quick market overview
- Signal notifications with customizable alerts
- Background monitoring during market hours

## 🔍 Monitoring & Alerts

### Signal Generation

The system continuously scans for trading opportunities:

```swift
// Real-time scanning every 30 seconds
func performScan() async {
    let marketData = try await marketData.getCurrentMarketData()
    await validateStrategies(marketData)
}
```

### Notification System

- **High-Quality Signals**: Immediate push notifications
- **Setup Alerts**: Configurable strategy-specific alerts
- **Risk Warnings**: Position size and portfolio limit notifications

## 📈 Performance Tracking

### Key Metrics

- **Win Rate by Strategy**: Historical success rates
- **Risk-Adjusted Returns**: Sharpe ratio calculation
- **Maximum Drawdown**: Portfolio risk assessment
- **Expected Value**: Per-trade profit expectation

### Analytics Dashboard

Track performance across all strategies with detailed metrics:

- Average return per winning trade
- Average loss per losing trade
- Consecutive losing streak analysis
- Monthly consistency tracking

## 🔒 Security & Compliance

### Data Protection

- Secure API key storage using Keychain
- Encrypted local data storage
- No sensitive data in plain text

### Trading Compliance

- Position size limits enforcement
- Risk management rule validation
- Audit trail for all trading decisions

## 🛠 Development

### Project Structure

```
Models/
├── Strategy.swift          # Core strategy definitions
├── Signal.swift           # Signal data structures
├── MarketData.swift       # Market data models
└── StrategyParams.swift   # Configuration parameters

Services/
├── SignalScanner.swift    # Real-time strategy validation
├── MarketDataService.swift # API integration
├── SignalMonitor.swift    # Trade management
└── SchwabService.swift    # Broker API

Views/
├── TradingDashboard.swift # Main interface
├── SettingsView.swift     # Configuration
└── Components/            # Reusable UI components
```

### Adding New Strategies

1. **Define Strategy Enum**
   ```swift
   case newStrategy = "New Strategy Name"
   ```

2. **Add Validation Logic**
   ```swift
   func validateCriteria(_ data: MarketData) -> Bool {
       // Strategy-specific conditions
   }
   ```

3. **Configure Parameters**
   ```swift
   static let newStrategy = NewStrategyParams(...)
   ```

### Testing

```bash
# Run unit tests
xcodebuild test -scheme Balls_of_Steel

# Run UI tests  
xcodebuild test -scheme Balls_of_Steel -testPlan UITests
```

## 📋 Requirements

### System Requirements

- **Operating System**: macOS 13.0+ (Ventura)
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 2GB available space
- **Network**: Reliable internet connection for real-time data

### Trading Requirements

- Active Schwab trading account
- Options trading approval (Level 2+)
- API access approval from Schwab
- Sufficient account balance for position sizing

## 🔄 Updates & Maintenance

### Version History

- **v1.0**: Initial release with 11 strategies
- **v1.1**: Enhanced risk management
- **v1.2**: Widget support and notifications

### Maintenance Schedule

- **Daily**: Market data validation
- **Weekly**: Strategy performance review
- **Monthly**: Parameter optimization
- **Quarterly**: Full system audit

## 📞 Support

### Documentation

- [Strategy Implementation Status](./STRATEGY_IMPLEMENTATION_STATUS.md)
- [Trading Strategies Documentation](./Balls_of_Steel/Documentation/trading_strategies_algo.md)
- [API Integration Guide](./docs/api-integration.md)

### Contact

For technical support or strategy questions:
- **Email**: 
- **Issues**: Create GitHub issue for bugs
- **Discussions**: GitHub Discussions for strategy questions

## ⚖️ Disclaimer

**Risk Warning**: Trading involves substantial risk of loss. Past performance does not guarantee future results. The strategies implemented in this software are for educational and informational purposes. Always consult with a qualified financial advisor before making trading decisions.

**Software License**: This software is provided "as is" without warranty. Users are responsible for their own trading decisions and risk management.

## 🏆 Success Metrics

Based on historical backtesting and documented performance:

- **Overall Portfolio Success Rate**: 65-78%
- **Risk-Adjusted Return**: Optimized via VIX-based sizing
- **Maximum Drawdown**: Controlled via portfolio limits
- **Strategy Diversification**: 11 uncorrelated approaches

---

*Built with ❤️ for professional traders who demand precision, reliability, and performance.*
