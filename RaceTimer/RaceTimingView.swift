import SwiftUI

enum RaceTimingExitAction: Equatable {
    case none
    case createNewRace
    case backToMenu
}

struct RaceTimingView: View {
    @Binding var exitAction: RaceTimingExitAction
    @EnvironmentObject var raceManager: RaceManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingFinishAlert = false
    @State private var showingAbandonAlert = false
    @State private var showingExportOptions = false
    @State private var pendingExportFormat: ExportFormat?
    @State private var shareItem: ExportShareItem?
    @State private var isRaceFinished = false
    @State private var tempRunners: [Runner] = []
    @State private var completedRace: Race?
    
    private var displayedRace: Race? {
        completedRace ?? raceManager.currentRace
    }
    
    private var displayedStartTime: Date? {
        completedRace?.raceStartTime ?? raceManager.raceStartTime
    }
    
    private var allRunnersHaveFinishTimes: Bool {
        !tempRunners.isEmpty && tempRunners.allSatisfy { $0.finishTime != nil }
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
                    Text(displayedRace?.name ?? "Race")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(displayedRace?.distance ?? 0, specifier: "%.1f") km")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isRaceFinished, let startTime = displayedStartTime {
                        RaceElapsedTimeView(startTime: startTime, isComplete: true)
                    } else if raceManager.isRaceStarted, let startTime = raceManager.raceStartTime {
                        // Clock lives in its own view so ticks don't rebuild TextFields.
                        RaceElapsedTimeView(
                            startTime: startTime,
                            isComplete: allRunnersHaveFinishTimes
                        )
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
                        if isRaceFinished {
                            ForEach(Array(sortedRunners.enumerated()), id: \.element.id) { index, runner in
                                RunnerRowView(
                                    place: index + 1,
                                    finishTime: runner.finishTime,
                                    raceStartTime: displayedStartTime,
                                    runnerNumber: .constant(runner.runnerNumber),
                                    isRaceFinished: true
                                )
                            }
                        } else {
                            // Bind directly into tempRunners so focus survives typing + list updates.
                            ForEach($tempRunners) { $runner in
                                RunnerRowView(
                                    place: place(for: runner.id),
                                    finishTime: runner.finishTime,
                                    raceStartTime: raceManager.raceStartTime,
                                    runnerNumber: $runner.runnerNumber,
                                    isRaceFinished: false
                                )
                            }
                        }
                    }
                }
                
                VStack(spacing: 16) {
                    if isRaceFinished {
                        finishedRaceActions
                    } else {
                        activeRaceActions
                    }
                    
                    Spacer()
                        .frame(height: 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isRaceFinished {
                        Button("Back") {
                            handleBack()
                        }
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
        .alert("Leave Race?", isPresented: $showingAbandonAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                abandonAndDismiss()
            }
        } message: {
            Text("The race is still running. Leaving will discard timing for this race.")
        }
        .alert("Save The Report", isPresented: $showingExportOptions) {
            Button("PDF") {
                pendingExportFormat = .pdf
            }
            Button("JPEG") {
                pendingExportFormat = .jpeg
            }
            Button("Cancel", role: .cancel) {
                pendingExportFormat = nil
            }
        } message: {
            Text("Choose a format for this race report.")
        }
        .onChange(of: showingExportOptions) { _, isShowing in
            guard !isShowing, let format = pendingExportFormat else { return }
            pendingExportFormat = nil
            DispatchQueue.main.async {
                exportCompletedRace(as: format)
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
        }
        .onAppear(perform: setupView)
        .onDisappear {
            if !isRaceFinished {
                raceManager.abandonCurrentRace()
            }
        }
    }
    
    @ViewBuilder
    private var activeRaceActions: some View {
        if !raceManager.isRaceStarted {
            Button(action: {
                raceManager.startRace()
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
    
    private var finishedRaceActions: some View {
        VStack(spacing: 16) {
            Button(action: {
                exitAction = .createNewRace
                dismiss()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("CREATE NEW RACE")
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
            
            Button(action: {
                showingExportOptions = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("SAVE THE REPORT")
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
            
            Button(action: {
                // Parent closes the entire new-race stack; don't dismiss timing alone
                // or setup flashes before MainView.
                exitAction = .backToMenu
            }) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("BACK TO MENU")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.horizontal, 20)
        }
    }
    
    private enum ExportFormat {
        case pdf
        case jpeg
    }
    
    private func place(for runnerId: UUID) -> Int {
        (tempRunners.firstIndex(where: { $0.id == runnerId }) ?? 0) + 1
    }
    
    private func handleBack() {
        if raceManager.isRaceStarted {
            showingAbandonAlert = true
        } else {
            abandonAndDismiss()
        }
    }
    
    private func abandonAndDismiss() {
        raceManager.abandonCurrentRace()
        dismiss()
    }
    
    private func recordTime() {
        guard raceManager.isRaceStarted, let startTime = raceManager.raceStartTime else { return }
        
        for (index, runner) in tempRunners.enumerated() {
            if runner.finishTime == nil {
                let elapsed = Date().timeIntervalSince(startTime)
                tempRunners[index].finishTime = startTime.addingTimeInterval(elapsed)
                break
            }
        }
    }
    
    private func setupView() {
        if let race = raceManager.currentRace {
            tempRunners = race.runners
        }
    }
    
    private func finishRace() {
        guard var race = raceManager.currentRace else { return }
        
        race.runners = tempRunners
        let raceId = race.id
        raceManager.currentRace = race
        raceManager.finishRace()
        
        completedRace = raceManager.races.first(where: { $0.id == raceId })
        tempRunners = completedRace?.runners ?? tempRunners
        isRaceFinished = true
    }
    
    private func exportCompletedRace(as format: ExportFormat) {
        guard let race = completedRace else { return }
        
        let safeName = race.name
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fileName = safeName.isEmpty ? "RaceReport" : safeName
        
        let data: Data?
        let fileExtension: String
        
        switch format {
        case .pdf:
            data = raceManager.generatePDF(for: race)
            fileExtension = "pdf"
        case .jpeg:
            data = raceManager.generateJPEG(for: race)
            fileExtension = "jpg"
        }
        
        guard let data else { return }
        
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(fileName).\(fileExtension)")
        
        do {
            try data.write(to: url, options: .atomic)
            shareItem = ExportShareItem(url: url)
        } catch {
            // Skip share sheet if the file could not be written.
        }
    }
}

/// Display-only clock. Uses TimelineView so scrolling the runner list
/// (UITrackingRunLoopMode) cannot pause a Timer scheduled in .default mode.
private struct RaceElapsedTimeView: View {
    let startTime: Date
    let isComplete: Bool
    
    @State private var frozenElapsed: TimeInterval?
    
    var body: some View {
        VStack(spacing: 4) {
            if let frozenElapsed {
                timeLabel(elapsed: frozenElapsed, complete: true)
            } else {
                TimelineView(.periodic(from: startTime, by: 0.01)) { context in
                    timeLabel(
                        elapsed: context.date.timeIntervalSince(startTime),
                        complete: false
                    )
                }
            }
            
            if isComplete {
                Text("All runners finished!")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .onChange(of: isComplete) { _, complete in
            if complete {
                frozenElapsed = Date().timeIntervalSince(startTime)
            }
        }
        .onAppear {
            if isComplete {
                frozenElapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func timeLabel(elapsed: TimeInterval, complete: Bool) -> some View {
        Text(formatTimeInterval(elapsed))
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(complete ? .green : .blue)
            .monospacedDigit()
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
}

struct RunnerRowView: View {
    let place: Int
    let finishTime: Date?
    let raceStartTime: Date?
    @Binding var runnerNumber: String
    let isRaceFinished: Bool
    
    private var displayTime: String {
        guard let finishTime = finishTime, let startTime = raceStartTime else {
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
            Text("\(place)")
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
        }
        .padding(.vertical, 5)
    }
}
