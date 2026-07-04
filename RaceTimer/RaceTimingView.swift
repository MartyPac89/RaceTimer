import SwiftUI

struct RaceTimingView: View {
    @Binding var raceFinished: Bool
    @EnvironmentObject var raceManager: RaceManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentRunnerIndex = 0
    @State private var showingFinishAlert = false
    @State private var showingSaveAlert = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isValidationComplete = false
    @State private var tempRunners: [Runner] = []
    
    private var currentRace: Race? {
        raceManager.currentRace
    }
    
    private var allRunnersHaveFinishTimes: Bool {
        return tempRunners.allSatisfy { $0.finishTime != nil }
    }
    
    private var sortedRunners: [Runner] {
        if isValidationComplete {
            return tempRunners.sorted { ($0.finishTime ?? Date.distantFuture) < ($1.finishTime ?? Date.distantFuture) }
        } else {
            return tempRunners
        }
    }
    
    private var assignedRunners: [Runner] {
        currentRace?.runners ?? []
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(currentRace?.name ?? "Race")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(currentRace?.distance ?? 0, specifier: "%.1f") km")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if raceManager.isRaceStarted {
                        Text(formatTimeInterval(elapsedTime))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(allRunnersHaveFinishTimes ? .green : .blue)
                            .monospacedDigit()
                        
                        if allRunnersHaveFinishTimes {
                            Text("All runners finished!")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Table Header
                HStack {
                    Text("Place")
                        .font(.headline)
                        .frame(width: 60, alignment: .center)
                    Text("Time")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Runner No.")
                        .font(.headline)
                        .frame(width: 80, alignment: .center)
                    Text("Runner Name")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                
                // Scrollable Content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedRunners.indices, id: \.self) { index in
                            let runner = sortedRunners[index]
                            RunnerRowView(
                                runner: runner, 
                                index: index, 
                                raceStartTime: raceManager.raceStartTime,
                                isValidationComplete: isValidationComplete
                            ) { newNumber in
                                if let tempIndex = tempRunners.firstIndex(where: { $0.id == runner.id }) {
                                    tempRunners[tempIndex].runnerNumber = newNumber
                                }
                            }
                        }
                    }
                }
                
                // Fixed Bottom Controls
                VStack(spacing: 16) {
                    if !raceManager.isRaceStarted {
                        Button(action: {
                            raceManager.startRace()
                            startTimer()
                        }) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("START RACE")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.horizontal, 20)
                    }
                    
                    // Record Time Button
                    Button(action: recordTime) {
                        HStack {
                            Image(systemName: "stopwatch.fill")
                            Text("RECORD A TIME")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((allRunnersHaveFinishTimes || !raceManager.isRaceStarted) ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(allRunnersHaveFinishTimes || !raceManager.isRaceStarted)
                    .padding(.horizontal, 20)
                    
                    // Finish Race Button
                    if !isValidationComplete {
                        Button(action: {
                            showingFinishAlert = true
                        }) {
                            HStack {
                                Image(systemName: "flag.checkered")
                                Text("FINISH RACE")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.horizontal, 20)
                    }
                    
                    // Save Report Button
                    if isValidationComplete {
                        Button(action: {
                            showingSaveAlert = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("SAVE REPORT")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Finish Race", isPresented: $showingFinishAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Validate & Finish", role: .destructive) {
                validateAndFinishRace()
            }
        } message: {
            Text("This will validate race numbers against assigned racers and auto-fill names. Continue?")
        }
        .alert("Save Report", isPresented: $showingSaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Save", role: .destructive) {
                saveRaceReport()
            }
        } message: {
            Text("Save this race report to finished races?")
        }
        .onAppear(perform: setupView)
        .onDisappear(perform: stopTimer)
        .onChange(of: allRunnersHaveFinishTimes) { oldValue, newValue in
            if newValue && raceManager.isRaceStarted {
                stopTimer()
            }
        }
    }
    
    private func recordTime() {
        guard raceManager.isRaceStarted else { return }
        
        for (index, runner) in tempRunners.enumerated() {
            if runner.finishTime == nil {
                // Record the time directly in tempRunners
                let elapsedTime = Date().timeIntervalSince(raceManager.raceStartTime!)
                tempRunners[index].finishTime = raceManager.raceStartTime!.addingTimeInterval(elapsedTime)
                break
            }
        }
    }
    
    private func setupView() {
        // Initialize tempRunners with empty names and numbers
        if let race = currentRace {
            tempRunners = race.runners.map { runner in
                var tempRunner = runner
                tempRunner.runnerName = ""  // Clear name - will be filled after validation
                tempRunner.runnerNumber = ""  // Clear number - user will enter this
                return tempRunner
            }
        }
        
        if raceManager.isRaceStarted {
            startTimer()
        }
    }
    
    private func validateAndFinishRace() {
        print("=== SIMPLE VALIDATION ===")
        print("Original race runners: \(assignedRunners.map { "\($0.runnerNumber): \($0.runnerName)" })")
        print("Temp runners before validation: \(tempRunners.map { "\($0.runnerNumber): \($0.runnerName) - finishTime: \($0.finishTime != nil)" })")
        
        // Simple approach: Only update names based on entered numbers, preserve everything else
        for (index, tempRunner) in tempRunners.enumerated() {
            if let assignedRunner = assignedRunners.first(where: { $0.runnerNumber == tempRunner.runnerNumber }) {
                // Match found - only update the name
                tempRunners[index].runnerName = assignedRunner.runnerName
                print("Updated name for number \(tempRunner.runnerNumber): \(assignedRunner.runnerName)")
            } else {
                // No match found - set unknown
                tempRunners[index].runnerName = "Unknown Runner"
                print("No match for number \(tempRunner.runnerNumber), set to Unknown Runner")
            }
        }
        
        print("Temp runners after validation: \(tempRunners.map { "\($0.runnerNumber): \($0.runnerName) - finishTime: \($0.finishTime != nil)" })")
        
        // Update the race manager with validated runners
        if var race = currentRace {
            race.runners = tempRunners
            raceManager.currentRace = race
        }
        
        isValidationComplete = true
        raceManager.finishRace()
    }
    
    private func saveRaceReport() {
        // The race is already saved in finishRace() method
        // Just dismiss the view
        raceFinished = true
        dismiss()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if let startTime = raceManager.raceStartTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct RunnerRowView: View {
    let runner: Runner
    let index: Int
    let raceStartTime: Date?
    let isValidationComplete: Bool
    let onNumberChange: (String) -> Void
    @State private var runnerNumber: String
    @State private var runnerName: String
    
    init(runner: Runner, index: Int, raceStartTime: Date?, isValidationComplete: Bool, onNumberChange: @escaping (String) -> Void) {
        self.runner = runner
        self.index = index
        self.raceStartTime = raceStartTime
        self.isValidationComplete = isValidationComplete
        self.onNumberChange = onNumberChange
        _runnerNumber = State(initialValue: runner.runnerNumber)
        _runnerName = State(initialValue: runner.runnerName)
    }
    
    private var displayTime: String {
        guard let finishTime = runner.finishTime, let startTime = raceStartTime else {
            return "--:--.--"
        }
        let interval = finishTime.timeIntervalSince(startTime)
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    var body: some View {
        HStack {
            Text("\(index + 1)")
                .frame(width: 60, alignment: .center)
                .font(.body)
                .foregroundColor(.primary)
            
            Text(displayTime)
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.body)
                .foregroundColor(.secondary)
            
            TextField("No.", text: $runnerNumber)
                .frame(width: 80, alignment: .center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .disabled(isValidationComplete)
                .onChange(of: runnerNumber) { oldValue, newValue in
                    onNumberChange(newValue)
                }
            
            Text(runnerName.isEmpty ? "Enter number above" : runnerName)
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.body)
                .foregroundColor(runnerName.isEmpty ? .secondary : .primary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 5)
        .onAppear {
            runnerNumber = runner.runnerNumber
            runnerName = runner.runnerName
        }
        .onChange(of: runner.runnerNumber) { newValue in
            runnerNumber = newValue
        }
        .onChange(of: runner.runnerName) { newValue in
            runnerName = newValue
        }
    }
}
