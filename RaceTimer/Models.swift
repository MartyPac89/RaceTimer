//
//  Models.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import Foundation

struct Runner: Identifiable, Codable {
    var id = UUID()
    var runnerNumber: String
    var runnerName: String
    var finishTime: Date?
    var finishPlace: Int?
    
    init(runnerNumber: String = "", runnerName: String = "") {
        self.runnerNumber = runnerNumber
        self.runnerName = runnerName
        self.finishTime = nil
        self.finishPlace = nil
    }
}

struct Race: Identifiable, Codable {
    var id = UUID()
    var name: String
    var distance: Double // in kilometers
    var runners: [Runner]
    var dateCreated: Date
    var isCompleted: Bool
    var raceStartTime: Date? // Added to store race start time for elapsed time calculation
    
    init(name: String, distance: Double, numberOfRunners: Int) {
        self.name = name
        self.distance = distance
        self.dateCreated = Date()
        self.isCompleted = false
        self.raceStartTime = nil
        self.runners = (1...numberOfRunners).map { _ in Runner() }
    }
    
    var completedRunners: [Runner] {
        runners.filter { $0.finishTime != nil }
    }
    
    var sortedRunners: [Runner] {
        runners.sorted { runner1, runner2 in
            guard let time1 = runner1.finishTime, let time2 = runner2.finishTime else {
                return runner1.finishTime != nil
            }
            return time1 < time2
        }
    }
}

struct RunnerRegistration: Identifiable, Codable {
    var id = UUID()
    var name: String
    var age: Int
    var gender: String
    var startingNumber: String
    var dateRegistered: Date
    
    init(name: String = "", age: Int = 0, gender: String = "", startingNumber: String = "") {
        self.name = name
        self.age = age
        self.gender = gender
        self.startingNumber = startingNumber
        self.dateRegistered = Date()
    }
}
