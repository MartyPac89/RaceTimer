//
//  FinishedRacesView.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import SwiftUI

struct FinishedRacesView: View {
    @EnvironmentObject var raceManager: RaceManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRace: Race?
    
    private var completedRaces: [Race] {
        raceManager.races
            .filter { $0.isCompleted }
            .sorted { $0.dateCreated > $1.dateCreated } // Sort by most recent first
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if completedRaces.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "trophy")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("No Finished Races")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Complete a race to see it here")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Races List
                    List(completedRaces) { race in
                        RaceRowView(race: race) {
                            selectedRace = race
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Finished Races")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(item: $selectedRace) { race in
            RaceDetailView(race: race)
        }
    }
}

struct RaceRowView: View {
    let race: Race
    let onTap: () -> Void
    
    private var completedCount: Int {
        race.completedRunners.count
    }
    
    private var totalRunners: Int {
        race.runners.count
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(race.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(race.dateCreated, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("\(race.distance, specifier: "%.1f") km", systemImage: "location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(completedCount)/\(totalRunners)", systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let winner = race.sortedRunners.first {
                    HStack {
                        Text("Winner: #\(winner.runnerNumber)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if let finishTime = winner.finishTime {
                            Text(formatElapsedTime(finishTime, raceStartTime: race.raceStartTime))
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatElapsedTime(_ finishTime: Date, raceStartTime: Date?) -> String {
        guard let startTime = raceStartTime else {
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct RaceDetailView: View {
    let race: Race
    @EnvironmentObject var raceManager: RaceManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    @State private var isEditMode = false
    
    // Get the current race data from RaceManager to ensure we have the latest updates
    private var currentRace: Race? {
        raceManager.races.first { $0.id == race.id }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let currentRace = currentRace {
                    // Header
                    VStack(spacing: 8) {
                        Text(currentRace.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(currentRace.distance, specifier: "%.1f") km • \(currentRace.dateCreated, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                
                    // Results Table
                    VStack(spacing: 0) {
                        // Table Header
                        HStack(spacing: 0) {
                            Text("Place")
                                .font(.headline)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            
                            Text("Time")
                                .font(.headline)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            
                            Text("PACE/KM")
                                .font(.headline)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            
                            Text("Runner #")
                                .font(.headline)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                            
                            Text("Runner Name")
                                .font(.headline)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        }
                        .padding()
                        .background(Color(.systemGray5))
                        
                        // Results
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(currentRace.sortedRunners.enumerated()), id: \.element.id) { index, runner in
                                    if isEditMode {
                                        EditableResultRowView(
                                            runner: runner, 
                                            place: index + 1, 
                                            raceStartTime: currentRace.raceStartTime, 
                                            raceDistance: currentRace.distance,
                                            raceId: currentRace.id
                                        )
                                    } else {
                                        ResultRowView(runner: runner, place: index + 1, raceStartTime: currentRace.raceStartTime, raceDistance: currentRace.distance)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Race not found
                    VStack {
                        Text("Race not found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            isEditMode.toggle()
                        }) {
                            Image(systemName: isEditMode ? "checkmark" : "pencil")
                                .foregroundColor(isEditMode ? .green : .blue)
                        }
                        
                        Button(action: {
                            generatePDF()
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .alert("Delete Race", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRace()
            }
        } message: {
            Text("Are you sure you want to delete this race? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(activityItems: [pdfData])
            }
        }
    }
    
    private func generatePDF() {
        if let currentRace = currentRace {
            pdfData = raceManager.generatePDF(for: currentRace)
            showingShareSheet = true
        }
    }
    
    private func deleteRace() {
        if let currentRace = currentRace {
            raceManager.deleteRace(currentRace)
            dismiss()
        }
    }
}

struct ResultRowView: View {
    let runner: Runner
    let place: Int
    let raceStartTime: Date?
    let raceDistance: Double
    
    var body: some View {
        HStack(spacing: 0) {
            // Place
            Text("\(place)")
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(placeColor)
            
            // Time
            Text(timeText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(.primary)
            
            // Pace
            Text(paceText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
            
            // Runner Number
            Text(runner.runnerNumber.isEmpty ? "—" : runner.runnerNumber)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(.primary)
            
            // Runner Name
            Text(runner.runnerName.isEmpty ? "—" : runner.runnerName)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(backgroundColor)
    }
    
    private var timeText: String {
        guard let finishTime = runner.finishTime,
              let startTime = raceStartTime else {
            print("DEBUG: Missing finishTime or startTime for runner \(runner.runnerName)")
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        print("DEBUG: Runner \(runner.runnerName) - finishTime: \(finishTime), startTime: \(startTime), elapsedTime: \(elapsedTime)")
        
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private var paceText: String {
        guard let finishTime = runner.finishTime,
              let startTime = raceStartTime,
              raceDistance > 0 else {
            print("DEBUG: Pace calculation failed - finishTime: \(runner.finishTime != nil), startTime: \(raceStartTime != nil), distance: \(raceDistance)")
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        let pacePerKm = elapsedTime / raceDistance
        
        print("DEBUG: Pace calculation - elapsedTime: \(elapsedTime), distance: \(raceDistance), pacePerKm: \(pacePerKm)")
        
        // Check for invalid values
        guard pacePerKm.isFinite && pacePerKm > 0 else {
            print("DEBUG: Invalid pacePerKm value: \(pacePerKm)")
            return "—"
        }
        
        let minutes = Int(pacePerKm) / 60
        let seconds = Int(pacePerKm) % 60
        let milliseconds = Int((pacePerKm.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private var placeColor: Color {
        switch place {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }
    
    private var backgroundColor: Color {
        switch place {
        case 1: return Color.yellow.opacity(0.1)
        case 2: return Color.gray.opacity(0.1)
        case 3: return Color.orange.opacity(0.1)
        default: return Color.clear
        }
    }
}

struct EditableResultRowView: View {
    let runner: Runner
    let place: Int
    let raceStartTime: Date?
    let raceDistance: Double
    let raceId: UUID
    @EnvironmentObject var raceManager: RaceManager
    @State private var editingRunnerNumber = false
    @State private var editingRunnerName = false
    @State private var tempRunnerNumber = ""
    @State private var tempRunnerName = ""
    
    // Get the current runner data from RaceManager to ensure we have the latest updates
    private var currentRunner: Runner? {
        raceManager.races.first { $0.id == raceId }?.runners.first { $0.id == runner.id }
    }
    
    // Use current runner data for display
    private var displayRunner: Runner {
        let runner = currentRunner ?? runner
        print("DisplayRunner - Number: '\(runner.runnerNumber)', Name: '\(runner.runnerName)'")
        return runner
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Place
            Text("\(place)")
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(placeColor)
            
            // Time
            Text(timeText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(.primary)
            
            // Pace
            Text(paceText)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                .foregroundColor(.secondary)
            
            // Runner Number - Editable
            if editingRunnerNumber {
                HStack {
                    TextField("Runner #", text: $tempRunnerNumber)
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        .onSubmit {
                            print("Saving runner number: '\(tempRunnerNumber)' for runner ID: \(displayRunner.id)")
                            raceManager.updateCompletedRaceRunnerNumber(for: raceId, runnerId: displayRunner.id, number: tempRunnerNumber)
                            editingRunnerNumber = false
                            print("Save completed")
                        }
                    
                    Button("Save") {
                        print("Saving runner number: '\(tempRunnerNumber)' for runner ID: \(displayRunner.id)")
                        raceManager.updateCompletedRaceRunnerNumber(for: raceId, runnerId: displayRunner.id, number: tempRunnerNumber)
                        editingRunnerNumber = false
                        print("Save completed")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                Button(action: {
                    editingRunnerNumber = true
                    tempRunnerNumber = displayRunner.runnerNumber
                }) {
                    Text(displayRunner.runnerNumber.isEmpty ? "Tap to add #" : displayRunner.runnerNumber)
                        .font(.system(.body, design: .monospaced))
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        .foregroundColor(displayRunner.runnerNumber.isEmpty ? .secondary : .primary)
                }
            }
            
            // Runner Name - Editable
            if editingRunnerName {
                HStack {
                    TextField("Runner Name", text: $tempRunnerName)
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        .onSubmit {
                            print("Saving runner name: '\(tempRunnerName)' for runner ID: \(displayRunner.id)")
                            raceManager.updateCompletedRaceRunnerName(for: raceId, runnerId: displayRunner.id, name: tempRunnerName)
                            editingRunnerName = false
                            print("Save completed")
                        }
                    
                    Button("Save") {
                        print("Saving runner name: '\(tempRunnerName)' for runner ID: \(displayRunner.id)")
                        raceManager.updateCompletedRaceRunnerName(for: raceId, runnerId: displayRunner.id, name: tempRunnerName)
                        editingRunnerName = false
                        print("Save completed")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                Button(action: {
                    editingRunnerName = true
                    tempRunnerName = displayRunner.runnerName
                }) {
                    Text(displayRunner.runnerName.isEmpty ? "Tap to add name" : displayRunner.runnerName)
                        .font(.system(.body, design: .monospaced))
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        .foregroundColor(displayRunner.runnerName.isEmpty ? .secondary : .primary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(backgroundColor)
    }
    
    private var timeText: String {
        guard let finishTime = runner.finishTime,
              let startTime = raceStartTime else {
            print("DEBUG: Missing finishTime or startTime for runner \(runner.runnerName)")
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        print("DEBUG: Runner \(runner.runnerName) - finishTime: \(finishTime), startTime: \(startTime), elapsedTime: \(elapsedTime)")
        
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private var paceText: String {
        guard let finishTime = runner.finishTime,
              let startTime = raceStartTime,
              raceDistance > 0 else {
            print("DEBUG: Pace calculation failed - finishTime: \(runner.finishTime != nil), startTime: \(raceStartTime != nil), distance: \(raceDistance)")
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        let pacePerKm = elapsedTime / raceDistance
        
        print("DEBUG: Pace calculation - elapsedTime: \(elapsedTime), distance: \(raceDistance), pacePerKm: \(pacePerKm)")
        
        // Check for invalid values
        guard pacePerKm.isFinite && pacePerKm > 0 else {
            print("DEBUG: Invalid pacePerKm value: \(pacePerKm)")
            return "—"
        }
        
        let minutes = Int(pacePerKm) / 60
        let seconds = Int(pacePerKm) % 60
        let milliseconds = Int((pacePerKm.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private var placeColor: Color {
        switch place {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .primary
        }
    }
    
    private var backgroundColor: Color {
        switch place {
        case 1: return Color.yellow.opacity(0.1)
        case 2: return Color.gray.opacity(0.1)
        case 3: return Color.orange.opacity(0.1)
        default: return Color.clear
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    FinishedRacesView()
        .environmentObject(RaceManager())
}
