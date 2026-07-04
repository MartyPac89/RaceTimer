//
//  RegistrationManager.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import Foundation

class RegistrationManager: ObservableObject {
    @Published var registrations: [RunnerRegistration] = []
    
    private let userDefaults = UserDefaults.standard
    private let registrationsKey = "savedRegistrations"
    
    init() {
        loadRegistrations()
    }
    
    func addRegistration(_ registration: RunnerRegistration) {
        registrations.append(registration)
        saveRegistrations()
    }
    
    func updateRegistration(_ registration: RunnerRegistration) {
        if let index = registrations.firstIndex(where: { $0.id == registration.id }) {
            registrations[index] = registration
            saveRegistrations()
        }
    }
    
    func deleteRegistration(_ registration: RunnerRegistration) {
        registrations.removeAll { $0.id == registration.id }
        saveRegistrations()
    }
    
    private func saveRegistrations() {
        if let encoded = try? JSONEncoder().encode(registrations) {
            userDefaults.set(encoded, forKey: registrationsKey)
        }
    }
    
    private func loadRegistrations() {
        if let data = userDefaults.data(forKey: registrationsKey),
           let decoded = try? JSONDecoder().decode([RunnerRegistration].self, from: data) {
            registrations = decoded
        }
    }
}
