//
//  RaceManager.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import Foundation
import PDFKit

class RaceManager: ObservableObject {
    @Published var races: [Race] = []
    @Published var currentRace: Race?
    @Published var raceStartTime: Date?
    @Published var isRaceStarted = false
    
    private let userDefaults = UserDefaults.standard
    private let racesKey = "savedRaces"
    
    init() {
        loadRaces()
    }
    
    func startRace() {
        raceStartTime = Date()
        isRaceStarted = true
    }
    
    func createNewRace(name: String, distance: Double, numberOfRunners: Int) {
        let race = Race(name: name, distance: distance, numberOfRunners: numberOfRunners)
        currentRace = race
    }
    
    func recordTime(for runnerIndex: Int) {
        guard var race = currentRace, runnerIndex < race.runners.count, let startTime = raceStartTime else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        race.runners[runnerIndex].finishTime = startTime.addingTimeInterval(elapsedTime)
        currentRace = race
    }
    
    func updateRunnerNumber(for runnerIndex: Int, number: String) {
        guard var race = currentRace, runnerIndex < race.runners.count else { return }
        race.runners[runnerIndex].runnerNumber = number
        currentRace = race
    }
    
    func updateRunnerName(for runnerIndex: Int, name: String) {
        guard var race = currentRace, runnerIndex < race.runners.count else { return }
        race.runners[runnerIndex].runnerName = name
        currentRace = race
    }
    
    func finishRace() {
        guard var race = currentRace else { return }
        
        print("=== FINISH RACE DEBUG ===")
        print("Race runners before processing: \(race.runners.map { "\($0.runnerNumber): \($0.runnerName) - finishTime: \($0.finishTime != nil ? "EXISTS" : "NIL")" })")
        print("Race start time: \(raceStartTime)")
        
        race.isCompleted = true
        race.raceStartTime = raceStartTime
        
        print("Race start time set to: \(race.raceStartTime)")
        
        // Assign finish places based on finish times
        let sortedRunners = race.sortedRunners
        print("Sorted runners: \(sortedRunners.map { "\($0.runnerNumber): \($0.runnerName) - finishTime: \($0.finishTime != nil ? "EXISTS" : "NIL")" })")
        
        for (index, runner) in sortedRunners.enumerated() {
            if let runnerIndex = race.runners.firstIndex(where: { $0.id == runner.id }) {
                race.runners[runnerIndex].finishPlace = index + 1
                print("Assigned place \(index + 1) to runner \(race.runners[runnerIndex].runnerName)")
            }
        }
        
        print("Race runners after processing: \(race.runners.map { "\($0.runnerNumber): \($0.runnerName) - finishTime: \($0.finishTime != nil ? "EXISTS" : "NIL") - place: \($0.finishPlace)" })")
        
        races.append(race)
        print("Race added to races array. Total races: \(races.count)")
        
        currentRace = nil
        raceStartTime = nil
        isRaceStarted = false
        saveRaces()
        
        print("Race saved to UserDefaults")
    }
    
    func deleteRace(_ race: Race) {
        races.removeAll { $0.id == race.id }
        saveRaces()
    }
    
    func updateCompletedRaceRunnerNumber(for raceId: UUID, runnerId: UUID, number: String) {
        print("RaceManager: Updating runner number to '\(number)' for runner \(runnerId)")
        guard let raceIndex = races.firstIndex(where: { $0.id == raceId }),
              let runnerIndex = races[raceIndex].runners.firstIndex(where: { $0.id == runnerId }) else { 
            print("RaceManager: Failed to find race or runner")
            return 
        }
        
        print("RaceManager: Found race at index \(raceIndex), runner at index \(runnerIndex)")
        print("RaceManager: Before update - runner number: '\(races[raceIndex].runners[runnerIndex].runnerNumber)'")
        
        // Create a new race object to trigger @Published update
        var updatedRace = races[raceIndex]
        updatedRace.runners[runnerIndex].runnerNumber = number
        races[raceIndex] = updatedRace
        
        print("RaceManager: After update - runner number: '\(races[raceIndex].runners[runnerIndex].runnerNumber)'")
        saveRaces()
        print("RaceManager: Data saved")
    }
    
    func updateCompletedRaceRunnerName(for raceId: UUID, runnerId: UUID, name: String) {
        print("RaceManager: Updating runner name to '\(name)' for runner \(runnerId)")
        guard let raceIndex = races.firstIndex(where: { $0.id == raceId }),
              let runnerIndex = races[raceIndex].runners.firstIndex(where: { $0.id == runnerId }) else { 
            print("RaceManager: Failed to find race or runner")
            return 
        }
        
        print("RaceManager: Found race at index \(raceIndex), runner at index \(runnerIndex)")
        print("RaceManager: Before update - runner name: '\(races[raceIndex].runners[runnerIndex].runnerName)'")
        
        // Create a new race object to trigger @Published update
        var updatedRace = races[raceIndex]
        updatedRace.runners[runnerIndex].runnerName = name
        races[raceIndex] = updatedRace
        
        print("RaceManager: After update - runner name: '\(races[raceIndex].runners[runnerIndex].runnerName)'")
        saveRaces()
        print("RaceManager: Data saved")
    }
    
    func generatePDF(for race: Race) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "RaceTimer",
            kCGPDFContextAuthor: "RaceTimer App",
            kCGPDFContextTitle: race.name
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Logo at the top
            if let logoImage = UIImage(named: "logo") {
                let logoSize = CGSize(width: 120, height: 60) // Adjust size as needed
                let logoRect = CGRect(
                    x: (pageWidth - logoSize.width) / 2, // Center horizontally
                    y: 20, // Top margin
                    width: logoSize.width,
                    height: logoSize.height
                )
                logoImage.draw(in: logoRect)
            }
            
            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let title = NSAttributedString(string: race.name, attributes: titleAttributes)
            let titleRect = CGRect(x: 50, y: 100, width: pageWidth - 100, height: 30) // Moved down to accommodate logo
            title.draw(in: titleRect)
            
            // Race details
            let detailsFont = UIFont.systemFont(ofSize: 16)
            let detailsAttributes: [NSAttributedString.Key: Any] = [
                .font: detailsFont,
                .foregroundColor: UIColor.gray
            ]
            let distanceText = "Distance: \(String(format: "%.1f", race.distance)) km"
            let dateText = "Date: \(DateFormatter.localizedString(from: race.dateCreated, dateStyle: .medium, timeStyle: .short))"
            let details = "\(distanceText)\n\(dateText)"
            let detailsAttributed = NSAttributedString(string: details, attributes: detailsAttributes)
            let detailsRect = CGRect(x: 50, y: 140, width: pageWidth - 100, height: 40) // Moved down to accommodate logo
            detailsAttributed.draw(in: detailsRect)
            
            // Results table
            let tableY: CGFloat = 200 // Moved down to accommodate logo
            let rowHeight: CGFloat = 25
            let columnWidths: [CGFloat] = [60, 100, 120, 100, 120] // Place, Time, Pace, Runner #, Runner Name
            let tableX: CGFloat = 50
            
            // Table header
            let headerFont = UIFont.boldSystemFont(ofSize: 14)
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.white
            ]
            
            let headerBackground = CGRect(x: tableX, y: tableY, width: pageWidth - 100, height: rowHeight)
            UIColor.systemBlue.setFill()
            context.fill(headerBackground)
            
            var currentX = tableX + 10
            let headers = ["Place", "Time", "Pace/KM", "Runner #", "Runner Name"]
            for (index, header) in headers.enumerated() {
                let headerRect = CGRect(x: currentX, y: tableY + 5, width: columnWidths[index], height: rowHeight - 10)
                NSAttributedString(string: header, attributes: headerAttributes).draw(in: headerRect)
                currentX += columnWidths[index]
            }
            
            // Table rows
            let rowFont = UIFont.systemFont(ofSize: 12)
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: rowFont,
                .foregroundColor: UIColor.black
            ]
            
            let sortedRunners = race.sortedRunners
            for (index, runner) in sortedRunners.enumerated() {
                let rowY = tableY + rowHeight + CGFloat(index) * rowHeight
                
                currentX = tableX + 10
                
                // Place
                let placeRect = CGRect(x: currentX, y: rowY + 5, width: columnWidths[0], height: rowHeight - 10)
                NSAttributedString(string: "\(index + 1)", attributes: rowAttributes).draw(in: placeRect)
                currentX += columnWidths[0]
                
                // Time
                let timeText = formatTimeForPDF(runner.finishTime, raceStartTime: race.raceStartTime)
                let timeRect = CGRect(x: currentX, y: rowY + 5, width: columnWidths[1], height: rowHeight - 10)
                NSAttributedString(string: timeText, attributes: rowAttributes).draw(in: timeRect)
                currentX += columnWidths[1]
                
                // Pace
                let paceText = formatPaceForPDF(runner.finishTime, raceStartTime: race.raceStartTime, distance: race.distance)
                let paceRect = CGRect(x: currentX, y: rowY + 5, width: columnWidths[2], height: rowHeight - 10)
                NSAttributedString(string: paceText, attributes: rowAttributes).draw(in: paceRect)
                currentX += columnWidths[2]
                
                // Runner Number
                let runnerNumber = runner.runnerNumber.isEmpty ? "—" : runner.runnerNumber
                let runnerRect = CGRect(x: currentX, y: rowY + 5, width: columnWidths[3], height: rowHeight - 10)
                NSAttributedString(string: runnerNumber, attributes: rowAttributes).draw(in: runnerRect)
                currentX += columnWidths[3]
                
                // Runner Name
                let runnerName = runner.runnerName.isEmpty ? "—" : runner.runnerName
                let runnerNameRect = CGRect(x: currentX, y: rowY + 5, width: columnWidths[4], height: rowHeight - 10)
                NSAttributedString(string: runnerName, attributes: rowAttributes).draw(in: runnerNameRect)
            }
        }
        
        return data
    }
    
    private func formatTimeForPDF(_ finishTime: Date?, raceStartTime: Date?) -> String {
        guard let finishTime = finishTime, let startTime = raceStartTime else {
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        let milliseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func formatPaceForPDF(_ finishTime: Date?, raceStartTime: Date?, distance: Double) -> String {
        guard let finishTime = finishTime, let startTime = raceStartTime, distance > 0 else {
            return "—"
        }
        
        let elapsedTime = finishTime.timeIntervalSince(startTime)
        let pacePerKm = elapsedTime / distance
        
        let minutes = Int(pacePerKm) / 60
        let seconds = Int(pacePerKm) % 60
        let milliseconds = Int((pacePerKm.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func saveRaces() {
        if let encoded = try? JSONEncoder().encode(races) {
            userDefaults.set(encoded, forKey: racesKey)
        }
    }
    
    private func loadRaces() {
        if let data = userDefaults.data(forKey: racesKey),
           let decoded = try? JSONDecoder().decode([Race].self, from: data) {
            races = decoded
            print("=== LOAD RACES DEBUG ===")
            print("Loaded \(races.count) races from UserDefaults")
            for (index, race) in races.enumerated() {
                print("Race \(index): \(race.name) - \(race.runners.count) runners")
                for runner in race.runners {
                    print("  Runner: \(runner.runnerNumber): \(runner.runnerName) - finishTime: \(runner.finishTime != nil ? "EXISTS" : "NIL")")
                }
            }
        }
    }
}
