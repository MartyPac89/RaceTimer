//
//  NewRaceSetupView.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import SwiftUI

struct NewRaceSetupView: View {
    @EnvironmentObject var raceManager: RaceManager
    @EnvironmentObject var registrationManager: RegistrationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var raceName = ""
    @State private var distance = ""
    @State private var showingRacerSelection = false
    @State private var showingRaceTiming = false
    @State private var raceFinished = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("New Race Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Race Name")
                            .font(.headline)
                        TextField("Enter race name", text: $raceName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Distance (km)")
                            .font(.headline)
                        TextField("Enter distance", text: $distance)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .onChange(of: distance) { _, newValue in
                                // Normalize decimal separator - convert comma to dot for parsing
                                let normalizedDistance = newValue.replacingOccurrences(of: ",", with: ".")
                                if normalizedDistance != newValue {
                                    distance = normalizedDistance
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Registered Racers")
                            .font(.headline)
                        Text("\(registrationManager.registrations.count) racers available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Assign Racers Button
                Button(action: {
                    if isValidInput() {
                        showingRacerSelection = true
                    }
                }) {
                    HStack {
                        Image(systemName: "person.3")
                        Text("ASSIGN RACERS")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidInput() && registrationManager.registrations.count > 0 ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValidInput() || registrationManager.registrations.count == 0)
                .buttonStyle(BorderlessButtonStyle())
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $showingRacerSelection) {
            RacerSelectionView(
                raceName: raceName,
                raceDistance: Double(distance.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
                onRaceCreated: { race in
                    raceManager.currentRace = race
                    showingRacerSelection = false
                    // Navigate to RaceTimingView after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingRaceTiming = true
                    }
                }
            )
            .environmentObject(registrationManager)
            .environmentObject(raceManager)
        }
        .fullScreenCover(isPresented: $showingRaceTiming) {
            RaceTimingView(raceFinished: $raceFinished)
                .environmentObject(raceManager)
        }
    }
    
    private func isValidInput() -> Bool {
        // Normalize distance for validation - convert comma to dot
        let normalizedDistance = distance.replacingOccurrences(of: ",", with: ".")
        
        return !raceName.isEmpty &&
               !distance.isEmpty &&
               Double(normalizedDistance) != nil
    }
}

#Preview {
    NewRaceSetupView()
        .environmentObject(RaceManager())
}
