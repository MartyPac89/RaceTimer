//
//  RacerSelectionView.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import SwiftUI

struct RacerSelectionView: View {
    @EnvironmentObject var registrationManager: RegistrationManager
    @EnvironmentObject var raceManager: RaceManager
    @Environment(\.dismiss) private var dismiss
    
    let raceName: String
    let raceDistance: Double
    let onRaceCreated: (Race) -> Void
    
    @State private var selectedRacers: Set<UUID> = []
    
    private var sortedRegistrations: [RunnerRegistration] {
        registrationManager.registrations.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Assign Racers")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(raceName) • \(raceDistance, specifier: "%.1f") km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Select \(selectedRacers.count) racer\(selectedRacers.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Table Header
                HStack {
                    Text("Select")
                        .font(.headline)
                        .frame(width: 60, alignment: .center)
                    Text("Name")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Age")
                        .font(.headline)
                        .frame(width: 60, alignment: .center)
                    Text("Gender")
                        .font(.headline)
                        .frame(width: 80, alignment: .center)
                    Text("Start #")
                        .font(.headline)
                        .frame(width: 80, alignment: .center)
                }
                .padding()
                .background(Color(.systemGray5))
                
                // Racers List
                if registrationManager.registrations.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No registered racers")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Go to 'New Registration' to add racers first")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(sortedRegistrations) { racer in
                                RacerSelectionRowView(
                                    racer: racer,
                                    isSelected: selectedRacers.contains(racer.id)
                                ) {
                                    toggleRacerSelection(racer.id)
                                }
                            }
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if !selectedRacers.isEmpty {
                        Button(action: {
                            createRace()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("CREATE RACE WITH \(selectedRacers.count) RACER\(selectedRacers.count == 1 ? "" : "S")")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Button(action: {
                        selectedRacers.removeAll()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("CLEAR SELECTION")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(selectedRacers.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
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
    }
    
    private func toggleRacerSelection(_ racerId: UUID) {
        if selectedRacers.contains(racerId) {
            selectedRacers.remove(racerId)
        } else {
            selectedRacers.insert(racerId)
        }
    }
    
    private func createRace() {
        let selectedRacersList = sortedRegistrations.filter { selectedRacers.contains($0.id) }
        
        // Create runners from selected racers
        let runners = selectedRacersList.map { racer in
            Runner(
                runnerNumber: racer.startingNumber,
                runnerName: racer.name
            )
        }
        
        // Create the race
        var race = Race(name: raceName, distance: raceDistance, numberOfRunners: runners.count)
        race.runners = runners
        
        // Set the race in the race manager
        raceManager.currentRace = race
        
        // Call the callback
        onRaceCreated(race)
        
        // Dismiss this view - the parent will handle navigation to RaceTimingView
        dismiss()
    }
}

struct RacerSelectionRowView: View {
    let racer: RunnerRegistration
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            // Selection Button
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(width: 60, alignment: .center)
            
            // Racer Info
            VStack(alignment: .leading, spacing: 2) {
                Text(racer.name.isEmpty ? "No name" : racer.name)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(racer.dateRegistered, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text("\(racer.age)")
                .font(.body)
                .frame(width: 60, alignment: .center)
            
            Text(racer.gender.isEmpty ? "—" : racer.gender)
                .font(.body)
                .frame(width: 80, alignment: .center)
            
            Text(racer.startingNumber.isEmpty ? "—" : racer.startingNumber)
                .font(.body)
                .frame(width: 80, alignment: .center)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

#Preview {
    RacerSelectionView(
        raceName: "Test Race",
        raceDistance: 5.0,
        onRaceCreated: { _ in }
    )
    .environmentObject(RegistrationManager())
}
