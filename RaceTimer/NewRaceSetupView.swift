//
//  NewRaceSetupView.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import SwiftUI

struct NewRaceSetupView: View {
    @EnvironmentObject var raceManager: RaceManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var raceName = ""
    @State private var distance = ""
    @State private var numberOfRunners = ""
    @State private var showingRaceTiming = false
    @State private var raceFinished = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("New Race Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top, 20)
                
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
                                let normalizedDistance = newValue.replacingOccurrences(of: ",", with: ".")
                                if normalizedDistance != newValue {
                                    distance = normalizedDistance
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Number of Runners")
                            .font(.headline)
                        TextField("Enter number of runners", text: $numberOfRunners)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: startRace) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("START RACE")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidInput() ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValidInput())
                .buttonStyle(BorderlessButtonStyle())
                .padding(.horizontal, 40)
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
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $showingRaceTiming) {
            RaceTimingView(raceFinished: $raceFinished)
                .environmentObject(raceManager)
        }
        .onChange(of: raceFinished) { _, finished in
            if finished {
                dismiss()
            }
        }
    }
    
    private func startRace() {
        guard isValidInput(),
              let distanceValue = Double(distance.replacingOccurrences(of: ",", with: ".")),
              let runnerCount = Int(numberOfRunners),
              runnerCount > 0 else { return }
        
        raceManager.createNewRace(name: raceName, distance: distanceValue, numberOfRunners: runnerCount)
        showingRaceTiming = true
    }
    
    private func isValidInput() -> Bool {
        let normalizedDistance = distance.replacingOccurrences(of: ",", with: ".")
        guard let runnerCount = Int(numberOfRunners), runnerCount > 0 else { return false }
        
        return !raceName.isEmpty &&
               !distance.isEmpty &&
               Double(normalizedDistance) != nil
    }
}

#Preview {
    NewRaceSetupView()
        .environmentObject(RaceManager())
}
