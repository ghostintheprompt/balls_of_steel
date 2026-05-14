import SwiftUI

// MARK: - Arrow Signal UI Components (v3.0)
// UI components for displaying arrow signals with volume validation

// MARK: - Arrow Signal Badge
struct ArrowSignalBadgeView: View {
    let signal: ArrowSignal

    var body: some View {
        HStack(spacing: 8) {
            // Arrow icon
            Image(systemName: signal.direction.icon)
                .font(.title3)
                .foregroundColor(directionColor)

            VStack(alignment: .leading, spacing: 4) {
                // Signal strength
                Text(signal.strength.displayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(directionColor)

                // Volume confirmation
                HStack(spacing: 4) {
                    Image(systemName: volumeIcon)
                        .font(.caption2)
                    Text(signal.volumeConfirmation.displayName)
                        .font(.caption)
                }
                .foregroundColor(volumeColor)
            }

            Spacer()

            // Time window indicator
            VStack(alignment: .trailing, spacing: 4) {
                Text(signal.timeWindow.displayName.components(separatedBy: " ").first ?? "")
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(Int(signal.timeWindow.reliability * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(directionColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(directionColor, lineWidth: 2)
                )
        )
    }

    private var directionColor: Color {
        signal.direction == .bullish ? DesignSystem.long : DesignSystem.short
    }

    private var volumeIcon: String {
        switch signal.volumeConfirmation {
        case .majorInstitution:
            return "chart.bar.fill"
        case .institutional:
            return "chart.bar"
        case .standard:
            return "arrow.up.circle"
        case .none:
            return "xmark.circle"
        }
    }

    private var volumeColor: Color {
        signal.volumeConfirmation.isValid ? DesignSystem.long : DesignSystem.short
    }
}

// MARK: - Signal Validation Matrix View
struct SignalValidationMatrixView: View {
    let signal: ArrowSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.blue)
                Text("Signal Validation")
                    .font(.headline)
                Spacer()
                validationBadge
            }

            Divider()

            // Volume Confirmation (Gate Keeper)
            ValidationRow(
                title: "Volume Confirmation",
                value: signal.volumeConfirmation.displayName,
                isValid: signal.volumeConfirmation.isValid,
                priority: "REQUIRED"
            )

            // Technical Confluence
            if !signal.technicalConfluence.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technical Confluence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(signal.technicalConfluence, id: \.self.displayName) { confluence in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(DesignSystem.long)
                            Text(confluence.displayName)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
            }

            Divider()

            // Time Window Context
            ValidationRow(
                title: "Time Window",
                value: signal.timeWindow.displayName,
                isValid: signal.timeWindow.reliability >= 0.70,
                priority: "Priority #\(signal.timeWindow.priority)"
            )

            Divider()

            // Probability Bonus
            HStack {
                Text("Total Probability")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(signal.totalProbabilityBonus * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(probabilityColor)
            }

            // Entry Strategy
            if signal.isValid {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Entry Strategy:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(signal.strength.entryStrategy)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .italic()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.panelTop)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(DesignSystem.hairline, lineWidth: 1))
        )
    }

    private var validationBadge: some View {
        Group {
            if signal.isValid {
                Text("VALID (Confirmed)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.long)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.long.opacity(0.10))
                    .cornerRadius(2)
            } else {
                Text("SKIP (X)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(DesignSystem.short)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignSystem.short.opacity(0.10))
                    .cornerRadius(2)
            }
        }
    }

    private var probabilityColor: Color {
        if signal.totalProbabilityBonus >= 0.80 {
            return DesignSystem.long
        } else if signal.totalProbabilityBonus >= 0.60 {
            return DesignSystem.amber
        } else {
            return DesignSystem.short
        }
    }
}

struct ValidationRow: View {
    let title: String
    let value: String
    let isValid: Bool
    let priority: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isValid ? DesignSystem.long : DesignSystem.short)
                Text(priority)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Institutional Flow Window Alert
struct InstitutionalFlowAlertView: View {
    let minutesUntil: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Rectangle()
                    .fill(DesignSystem.amber.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: "building.columns.fill")
                    .font(.title2)
                    .foregroundColor(DesignSystem.amber)
            }
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isActive)

            VStack(alignment: .leading, spacing: 4) {
                Text("Institutional Flow Window")
                    .font(.headline)
                    .foregroundColor(DesignSystem.text)

                if isActive {
                    Text("WINDOW OPEN")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.amber)
                } else {
                    Text("Opens in \(minutesUntil) minutes")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.muted)
                }

                Text("Wait for 300%+ volume")
                    .font(.caption)
                    .foregroundColor(DesignSystem.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("3:45-4:10 PM")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.amber)
                Text("Priority")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.muted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignSystem.amber.opacity(0.10))
            .cornerRadius(2)
        }
        .padding()
        .background(
            Rectangle()
                .fill(isActive ? DesignSystem.amber.opacity(0.08) : DesignSystem.panel)
                .overlay(
                    Rectangle()
                        .stroke(isActive ? DesignSystem.amber : DesignSystem.hairline, lineWidth: 1)
                )
        )
    }
}

// MARK: - Event Day Alert View
struct EventDayAlertView: View {
    let event: EventDay

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: event.type.icon)
                    .font(.title2)
                    .foregroundColor(impactColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.type.displayName)
                        .font(.headline)
                    Text(event.impactLevel.displayName)
                        .font(.caption)
                        .foregroundColor(impactColor)
                }

                Spacer()

                if event.shouldExitPositions {
                    Text("EXIT NOW!")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(DesignSystem.short)
                        .cornerRadius(2)
                }
            }

            Divider()

            // Strategy recommendation
            VStack(alignment: .leading, spacing: 4) {
                Text("Strategy:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(event.strategy.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            // Position sizing
            HStack {
                Text("Position Size:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(event.impactLevel.positionSizeAdjustment * 100))% of normal")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(impactColor)
            }

            // Time until event
            if event.minutesUntilEvent > 0 {
                HStack {
                    Text("Time Until Event:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(event.minutesUntilEvent) minutes")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(impactColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(impactColor, lineWidth: 2)
                )
        )
    }

    private var impactColor: Color {
        switch event.impactLevel {
        case .high:
            return DesignSystem.short
        case .medium:
            return DesignSystem.amber
        case .low:
            return DesignSystem.amber
        }
    }
}

// MARK: - Dynamic Position Sizing Display
struct DynamicPositionSizingView: View {
    let result: DynamicPositionSizer.PositionSizingResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(.blue)
                Text("Position Sizing")
                    .font(.headline)
                Spacer()
                Text(result.displaySize)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(sizeColor)
            }

            Divider()

            // Reasoning
            VStack(alignment: .leading, spacing: 8) {
                Text("Calculation Factors:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(result.reasoning, id: \.self) { reason in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(reason)
                            .font(.caption)
                    }
                }
            }

            // Greed control reminder
            if result.size >= 1.0 {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(DesignSystem.amber)
                    Text("Greed Control: 1 contract maximum")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.amber)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignSystem.panelTop)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(DesignSystem.hairline, lineWidth: 1))
        )
    }

    private var sizeColor: Color {
        if result.size >= 1.0 {
            return DesignSystem.long
        } else if result.size >= 0.5 {
            return DesignSystem.amber
        } else if result.size > 0 {
            return DesignSystem.amber
        } else {
            return DesignSystem.short
        }
    }
}
