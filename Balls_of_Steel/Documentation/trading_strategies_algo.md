# Trading Strategies Algorithm Implementation

## 1. Earnings Volatility Crush Strategy

### Entry Conditions
- IV Rank > 75% (optimal > 85%)
- 2-3 days before earnings announcement
- Historical earnings move < current implied move
- Options pricing movement > historical average by 15%+

### Trade Structure
- Iron Condor: Sell ATM calls/puts, buy wings 2-3 strikes out
- Target strikes: Within 1 standard deviation of expected move
- Maximum risk: $2.60 per $5 wide spread
- Credit target: $2.00-$2.80 per spread

### Position Sizing
- Perfect setup (IV > 85%): 2% of account
- Good setup (IV > 75%): 1% of account  
- Marginal setup (IV > 65%): 0.5% of account

### Exit Rules
- Take profit at 50-80% of maximum credit
- Close day after earnings announcement
- Stop loss at 50% of credit received

### Success Rate: 72.7% (based on 187 trade sample)

---

## 2. Gap Fill Trading Strategy

### Entry Conditions
- Gap size between 0.5% - 2% (optimal range)
- No fundamental news driving gap
- Volume declining on gap move
- Technical gap (algorithmic/overnight driven)

### Gap Fill Probabilities
- Small gaps (0.5-2%): 78% fill rate within 2 weeks
- Large gaps (2%+): 45% fill rate within 2 weeks
- Same-day fills: 45-60% regardless of size

### Trade Structure
- Buy calls/puts in direction of gap fill
- Target: 50-100% of gap distance
- Time horizon: 1-2 weeks maximum

### Position Sizing
- High-probability setup: 2% of account
- Moderate setup: 1% of account
- Low-conviction: 0.5% of account

### Avoid
- Gaps > 2%
- Fundamental news gaps
- Biotech/FDA gaps
- Merger announcement gaps

---

## 3. 0DTE Iron Butterfly Strategy

### Entry Conditions
- Entry time: 10:15 AM (after opening volatility settles)
- SPY/QQQ expiring same day
- Low volatility environment (VIX < 25)
- No major news scheduled

### Trade Structure
- Sell ATM call and put at current price
- Buy wings $2 away for protection
- Target credit: $0.40-$0.80 per butterfly
- Maximum loss: Wing width minus credit

### Entry Example (SPY at $594)
- Sell $594 call for $0.65
- Sell $594 put for $0.60
- Buy $592 put for $0.40  
- Buy $596 call for $0.45
- Net credit: $0.40

### Success Parameters
- Profit if underlying stays within breakevens
- SPY daily movement < $2: 78% probability
- Target 50% profit if reached before 2 PM

### Position Sizing
- Perfect conditions: 1% of account
- Uncertain conditions: 0.5% of account
- High volatility days: No trade

### Success Rate: 66.76% (based on professional analysis)

---

## 4. VIX Spike Premium Selling

### Entry Conditions
- VIX spike > 15% intraday
- VIX absolute level > 30
- SPY down > 1.5% on session
- Put/call ratio > 1.2

### Trade Structure (Defined Risk Only)
- Sell put spreads 10-15% below current price
- 5-point wide spreads optimal
- Target credit: $1.50-$2.50 per spread
- Never sell naked options during spikes

### Position Sizing (Conservative)
- VIX 30-40: 1% of account maximum
- VIX 40-50: 0.5% of account maximum  
- VIX > 50: 0.25% of account maximum

### Exit Rules
- Take profit at 75% of credit
- Close within 3-5 days
- Stop loss at 200% of credit (rare but defined)

### Risk Management
- Only use defined risk strategies
- Account for correlation increases during volatility spikes
- Position size inversely to VIX level

---

## 5. Momentum Breakout Strategy

### Entry Conditions
- VWAP break with conviction
- Volume > 2x average (adjusted from 2.5x)
- RSI crossing 60 from below
- 8 EMA crossing above 21 EMA
- No major overhead resistance

### Options Flow Confirmation
- Call volume > 3x normal
- Put/call ratio declining
- Strike concentration 2-3 points OTM
- Open interest building systematically

### Trade Structure
- Buy calls 1-2 strikes OTM
- Target 100-200% returns
- Time horizon: Intraday to 3 days

### Entry Timing Windows
- 9:30-10:30 AM: Opening drive momentum
- 10:15 AM: Post-volatility settlement
- 2:00-3:00 PM: Afternoon positioning

### Position Sizing
- All signals aligned: 2% of account
- Partial confirmation: 1% of account
- Weak signals: 0.5% of account

### Exit Conditions
- Volume declining on push higher
- RSI divergence at resistance
- VWAP acting as resistance instead of support

---

## 6. Pre-Market Institutional Flow

### Time Windows
- 8:00-9:00 AM: Primary institutional positioning window
- 8:15-8:45 AM: Peak activity period
- Avoid 6:00-7:30 AM: Algorithmic noise

### Signal Confirmation
- Options volume > 3x normal in target strikes
- Multiple strike prices activating simultaneously
- Put/call ratio shifting meaningfully
- Volume patterns consistent with accumulation

### Trade Structure
- Follow institutional direction through options
- Buy calls/puts in accumulation direction
- Size based on signal strength

### Success Indicators
- Systematic volume patterns
- Strategic strike selection
- Time window concentration
- Multiple venue activity (when visible)

---

## 7. Weekly Options Expiration

### Premium Selling Opportunities
- Sell premium to retail lottery ticket buyers
- Target OTM options with < 20% probability
- Focus on Friday expiration cycles

### 0DTE Daily Cycles
- Monday, Wednesday, Friday SPY/QQQ expirations
- Tuesday, Thursday for ETF rotations
- Avoid earnings weeks and Fed meetings

### Iron Condor Optimal Strikes
- Short strikes: +/- 1% from current price
- Wing protection: +/- 2% from current price
- Target credit: 25-40% of wing width

---

## Risk Management Rules (All Strategies)

### Position Sizing Matrix
- VIX < 20: Normal sizing up to 2%
- VIX 20-30: Reduce to 1.5% maximum
- VIX 30-40: Reduce to 1% maximum
- VIX > 40: Reduce to 0.5% maximum

### Portfolio Limits
- Maximum 10% total options exposure
- Maximum 3 earnings positions simultaneously
- Maximum 5% in any single underlying

### Stop Loss Rules
- Defined risk strategies: 50% of credit received
- Long options: 30% of premium paid
- Never average down on losing positions

### Profit Taking
- Take 50% profits on premium selling strategies
- Take 100-200% profits on momentum plays
- Close all positions day before major events

---

## Market Condition Filters

### Optimal Trading Environment
- VIX 15-30 range
- SPY > 200 day moving average
- No major economic events same day
- Normal correlation environment

### Avoid Trading When
- VIX > 50 (extreme volatility)
- Major Fed announcements day-of
- Quarterly options expiration (monthly)
- Low volume holiday weeks

### Signal Quality Matrix
- Perfect: All conditions met, high conviction
- Good: Most conditions met, moderate conviction  
- Poor: Few conditions met, low conviction
- No Trade: Conflicting signals or high risk events

---

## Performance Tracking Metrics

### Strategy Success Rates
- Earnings volatility crush: 72.7%
- Gap fill (small gaps): 78%
- 0DTE iron butterflies: 66.8%
- Momentum breakouts: 65%
- VIX spike selling: 68%

### Key Performance Indicators
- Win rate by strategy
- Average return per winning trade
- Average loss per losing trade
- Maximum drawdown periods
- Risk-adjusted returns (Sharpe ratio)

### Portfolio Metrics
- Total return
- Maximum equity drawdown
- Consecutive losing streaks
- Monthly consistency
- Risk per trade vs account size