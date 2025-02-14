import SwiftUI
import Foundation

// MARK: - Models
struct RiskEvent: Identifiable {
    let id = UUID()
    var description: String
    var possibleLoss: Double
    var probability: Double
    var possibleWim: Double
    
    // Validate probability is between 0 and 1
    var validatedProbability: Double {
        min(max(probability, 0), 1)
    }
}

// MARK: - Risk Calculator
class RiskCalculator: ObservableObject {
    @Published var events: [RiskEvent] = []
    
    init() {
        addDefaultEvents()
    }
    
    private func addDefaultEvents() {
        events = [
            RiskEvent(description: "Equipment failure", possibleLoss: 50000, probability: 0.15),
            RiskEvent(description: "Data breach", possibleLoss: 100000, probability: 0.1),
            RiskEvent(description: "Natural disaster", possibleLoss: 200000, probability: 0.05),
            RiskEvent(description: "Employee injury", possibleLoss: 75000, probability: 0.08),
            RiskEvent(description: "Supply chain disruption", possibleLoss: 80000, probability: 0.12),
            RiskEvent(description: "Everything will be fine", possibleLoss: 0, probability: 0.5)
        ]
    }
    
    // MARK: - Risk Management Functions
    func addRiskEvent(_ event: RiskEvent) {
        events.append(event)
        normalizeEventProbabilities()
    }
    
    func removeRiskEvent(at index: Int) {
        events.remove(at: index)
        normalizeEventProbabilities()
    }
    
    func updateRiskEvent(_ event: RiskEvent, at index: Int) {
        guard events.indices.contains(index) else { return }
        events[index] = event
        normalizeEventProbabilities()
    }
    
    // MARK: - Calculation Methods
    private func normalizeEventProbabilities() {
        let totalProb = events.reduce(0) { $0 + $1.validatedProbability }
        guard totalProb != 0 else { return }
        
        for i in events.indices {
            let normalizedProb = events[i].validatedProbability / totalProb
            events[i] = RiskEvent(
                description: events[i].description,
                possibleLoss: events[i].possibleLoss,
                probability: normalizedProb
            )
        }
    }
    
    var totalProbability: Double {
        events.reduce(0) { $0 + $1.validatedProbability }
    }
    
    var averageLoss: Double {
        events.reduce(0) { $0 + ($1.possibleLoss * $1.validatedProbability) }
    }
    
    var variance: Double {
        let mean = averageLoss
        return events.reduce(0) { 
            $0 + pow($1.possibleLoss - mean, 2) * $1.validatedProbability 
        }
    }
    
    var standardDeviation: Double {
        sqrt(variance)
    }
    
    var rmsLoss: Double {
        sqrt(events.reduce(0) { $0 + pow($1.possibleLoss, 2) * $1.validatedProbability })
    }
    
    var integralRisk: Double {
        averageLoss + rmsLoss
    }
    
    var coefficientOfVariation: Double {
        guard averageLoss != 0 else { return 0 }
        return standardDeviation / averageLoss
    }
    
    // MARK: - Risk Analysis
    func getRiskLevel() -> RiskLevel {
        let cv = coefficientOfVariation
        switch cv {
        case ..<0.25:
            return .low
        case 0.25..<0.75:
            return .medium
        default:
            return .high
        }
    }
    
    func getDetailedAnalysis() -> RiskAnalysis {
        RiskAnalysis(
            totalRiskEvents: events.count,
            averageLoss: averageLoss,
            standardDeviation: standardDeviation,
            integralRisk: integralRisk,
            riskLevel: getRiskLevel(),
            coefficientOfVariation: coefficientOfVariation
        )
    }
}

// MARK: - Supporting Types
enum RiskLevel: String {
    case low = "Low Risk"
    case medium = "Medium Risk"
    case high = "High Risk"
}

struct RiskAnalysis {
    let totalRiskEvents: Int
    let averageLoss: Double
    let standardDeviation: Double
    let integralRisk: Double
    let riskLevel: RiskLevel
    let coefficientOfVariation: Double
}

// MARK: - Preview Helper
extension RiskCalculator {
    static var preview: RiskCalculator {
        let calculator = RiskCalculator()
        // Preview data is already added in init()
        return calculator
    }
}

// MARK: - Views
struct RiskCalculationView: View {
    @StateObject private var calculator = RiskCalculator()
    @State private var showingAddSheet = false
    @State private var selectedEvent: RiskEvent?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(calculator.events) { event in
                        RiskEventRow(event: event)
                            .contentShape(Rectangle()) // Improves tap target
                            .onTapGesture {
                                selectedEvent = event
                            }
                    }
                    .onDelete(perform: deleteItems)
                } header: {
                    Text("Risk Events")
                        .font(.headline)
                        .textCase(nil)
                        .foregroundColor(.primary)
                        .padding(.bottom, 8)
                }
                
                Section {
                    VStack(spacing: 16) {
                        CalculationRow(
                            title: "Total Probability",
                            value: calculator.totalProbability,
                            format: "%.2f"
                        )
                        
                        CalculationRow(
                            title: "Average Loss",
                            value: calculator.averageLoss,
                            format: "$%.2f",
                            valueColor: .blue
                        )
                        
                        CalculationRow(
                            title: "RMS Loss",
                            value: calculator.rmsLoss,
                            format: "$%.2f",
                            valueColor: .blue
                        )
                        
                        CalculationRow(
                            title: "Integral Risk",
                            value: calculator.integralRisk,
                            format: "$%.2f",
                            valueColor: .blue
                        )
                        
                        RiskLevelIndicator(level: calculator.getRiskLevel())
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Risk Analysis")
                        .font(.headline)
                        .textCase(nil)
                        .foregroundColor(.primary)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("Risk Calculator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("Add Risk Event")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRiskEventView(calculator: calculator)
            }
            .sheet(item: $selectedEvent) { event in
                EditRiskEventView(calculator: calculator, event: event)
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        offsets.forEach { index in
            calculator.removeRiskEvent(at: index)
        }
    }
}

struct RiskEventRow: View {
    let event: RiskEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.description)
                .font(.system(size: 17, weight: .semibold))
            
            HStack(spacing: 12) {
                Label {
                    Text("$\(Int(event.possibleLoss))")
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.blue)
                }
                
                Label {
                    Text(event.probability, format: .percent.precision(.fractionLength(1)))
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: "percent")
                        .foregroundColor(.blue)
                }
            }
            .font(.system(size: 15))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct CalculationRow: View {
    let title: String
    let value: Double
    let format: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 16))
            
            Spacer()
            
            Text(String(format: format, value))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

struct RiskLevelIndicator: View {
    let level: RiskLevel
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Risk Level")
                .font(.system(size: 16))
            
            Text(level.rawValue)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(riskLevelColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(riskLevelColor.opacity(0.15))
                )
        }
    }
    
    private var riskLevelColor: Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct AddRiskEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var calculator: RiskCalculator
    @State private var description = ""
    @State private var possibleLoss = ""
    @State private var probability = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Description", text: $description)
                        .textInputAutocapitalization(.sentences)
                    
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Possible Loss", text: $possibleLoss)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        TextField("Probability", text: $probability)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Event Details")
                        .textCase(nil)
                        .font(.headline)
                }
            }
            .navigationTitle("Add Risk Event")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    addEvent()
                }
                .font(.body.weight(.semibold))
                .disabled(!isValidInput)
            )
        }
    }
    
    private var isValidInput: Bool {
        !description.isEmpty && 
        !possibleLoss.isEmpty && 
        !probability.isEmpty &&
        Double(possibleLoss) != nil &&
        Double(probability) != nil
    }
    
    private func addEvent() {
        guard let loss = Double(possibleLoss),
              let prob = Double(probability) else { return }
        
        let event = RiskEvent(
            description: description,
            possibleLoss: loss,
            probability: prob / 100 // Convert from percentage
        )
        calculator.addRiskEvent(event)
        dismiss()
    }
}

struct EditRiskEventView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var calculator: RiskCalculator
    let event: RiskEvent
    
    @State private var description: String
    @State private var possibleLoss: String
    @State private var probability: String
    @State private var showingDeleteAlert = false
    
    init(calculator: RiskCalculator, event: RiskEvent) {
        self.calculator = calculator
        self.event = event
        _description = State(initialValue: event.description)
        _possibleLoss = State(initialValue: String(format: "%.0f", event.possibleLoss))
        _probability = State(initialValue: String(format: "%.1f", event.probability * 100))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Event Description", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 17))
                            .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Possible Loss")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text("$")
                                .foregroundColor(.secondary)
                                .font(.system(size: 17))
                            
                            TextField("Amount", text: $possibleLoss)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .font(.system(size: 17))
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Probability")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            TextField("Percentage", text: $probability)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                                .font(.system(size: 17))
                            
                            Text("%")
                                .foregroundColor(.secondary)
                                .font(.system(size: 17))
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } header: {
                    Text("Event Details")
                        .font(.headline)
                        .textCase(nil)
                        .foregroundColor(.primary)
                        .padding(.bottom, 8)
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Event")
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .navigationTitle("Edit Risk Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 17))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEvent()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .disabled(!isValidInput)
                }
            }
            .alert("Delete Risk Event", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let index = calculator.events.firstIndex(where: { $0.id == event.id }) {
                        calculator.removeRiskEvent(at: index)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this risk event? This action cannot be undone.")
            }
        }
        .interactiveDismissDisabled()
    }
    
    private var isValidInput: Bool {
        // Validate all required fields are filled and have valid values
        let hasValidText = !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasValidLoss = !possibleLoss.isEmpty && Double(possibleLoss) != nil
        let hasValidProbability = !probability.isEmpty && 
            Double(probability) != nil &&
            (Double(probability) ?? 0) >= 0 &&
            (Double(probability) ?? 0) <= 100
        
        return hasValidText && hasValidLoss && hasValidProbability
    }
    
    private func saveEvent() {
        // Convert string inputs to numeric values
        guard let loss = Double(possibleLoss.trimmingCharacters(in: .whitespaces)),
              let prob = Double(probability.trimmingCharacters(in: .whitespaces)) else {
            // Show error alert if conversion fails
            return
        }
        
        // Create updated event with validated data
        let updatedEvent = RiskEvent(
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            possibleLoss: loss,
            probability: prob / 100 // Convert percentage to decimal
        )
        
        // Update existing event in calculator
        if let index = calculator.events.firstIndex(where: { $0.id == event.id }) {
            calculator.updateRiskEvent(updatedEvent, at: index)
        }
        
        // Dismiss view after successful save
        dismiss()
        print("Event saved")
        
    }
}
