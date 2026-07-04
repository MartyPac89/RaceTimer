import SwiftUI

struct RaceTimingView: View {
    @Binding var raceFinished: Bool
    @EnvironmentObject var raceManager: RaceManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFinishAlert = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isRaceFinished = false
    @State private var tempRunners: [Runner] = []
    
    private var currentRace: Race? {
        raceManager.currentRace
    }
    
    private var allRunnersHaveFinishTimes: Bool {
        tempRunners.allSatisfy { $0.finishTime != nil }
    }
    
    private var sortedRunners: [Runner] {
        if isRaceFinished {
            return tempRunners.sorted { ($0.finishTime ?? Date.distantFuture) < ($1.finishTime ?? Date.distantFuture) }
        }
        return tempRunners
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                
                HStack {
                    Text("Place")
                        .font(.headline)
                        .frame(width: 60, alignment: .center)
                    Text("Time")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Runner No.")
                        .font(.headline)
                        .frame(width: 100, alignment: .center)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sortedRunners.indices, id: \.self) { index in
                            let runner = sortedRunners[index]
                            RunnerRowView(
                                runner: runner,
                                index: index,
                                raceStartTime: raceManager.raceStartTime,
                                isRaceFinished: isRaceFinished
                            ) { newNumber in
                                if let tempIndex = tempRunners.firstIndex(where: { $0.id == runner.id }) {
                                    tempRunners[tempIndex].runnerNumber = newNumber
                                }
                            }
                        }
                    }
                }
                
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
                    
                    if !isRaceFinished {
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
                    } else {
                        Button(action: {
                            raceFinished = true
                            dismiss()
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
            Button("Finish", role: .destructive) {
                finishRace()
            }
        } message: {
            Text("Save race results with entered runner numbers?")
        }
        .onAppear(perform: setupView)
        .onDisappear(perform: stopTimer)
        .onChange(of: allRunnersHaveFinishTimes) { _, newValue in
            if newValue && raceManager.isRaceStarted {
                stopTimer()
            }
        }
    }
    
    private func recordTime() {
        guard raceManager.isRaceStarted else { return }
        
        for (index, runner) in tempRunners.enumerated() {
            if runner.finishTime == nil {
                let elapsedTime = Date().timeIntervalSince(raceManager.raceStartTime!)
                tempRunners[index].finishTime = raceManager.raceStartTime!.addingTimeInterval(elapsedTime)
                break
            }
        }
    }
    
    private func setupView() {
        if let race = currentRace {
            tempRunners = race.runners
        }
        
        if raceManager.isRaceStarted {
            startTimer()
        }
    }
    
    private func finishRace() {
        if var race = currentRace {
            race.runners = tempRunners
            raceManager.currentRace = race
        }
        
        isRaceFinished = true
        raceManager.finishRace()
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
    let isRaceFinished: Bool
    let onNumberChange: (String) -> Void
    @State private var runnerNumber: String
    
    init(runner: Runner, index: Int, raceStartTime: Date?, isRaceFinished: Bool, onNumberChange: @escaping (String) -> Void) {
        self.runner = runner
        self.index = index
        self.raceStartTime = raceStartTime
        self.isRaceFinished = isRaceFinished
        self.onNumberChange = onNumberChange
        _runnerNumber = State(initialValue: runner.runnerNumber)
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
            
            Text(displayTime)
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.body)
                .foregroundColor(.secondary)
            
            TextField("No.", text: $runnerNumber)
                .frame(width: 100, alignment: .center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .disabled(isRaceFinished)
                .onChange(of: runnerNumber) { _, newValue in
                    onNumberChange(newValue)
                }
        }
        .padding(.vertical, 5)
        .onAppear {
            runnerNumber = runner.runnerNumber
        }
        .onChange(of: runner.runnerNumber) { _, newValue in
            runnerNumber = newValue
        }
    }
}
