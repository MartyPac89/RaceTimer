//
//  NewRunnerRegistrationView.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import SwiftUI

struct NewRunnerRegistrationView: View {
    @EnvironmentObject var registrationManager: RegistrationManager
    @Environment(\.dismiss) private var dismiss
    @State private var runners: [RunnerRegistration] = []
    @State private var showingAddRunner = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Runner Registration")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Add runners to the registration list")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Table Header
                HStack {
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
                    Text("Actions")
                        .font(.headline)
                        .frame(width: 100, alignment: .center)
                }
                .padding()
                .background(Color(.systemGray5))
                
                // Runners List
                if runners.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No runners added yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Tap 'Add Runner' to get started")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(runners.enumerated()), id: \.element.id) { index, runner in
                                RunnerRegistrationRowView(
                                    runner: $runners[index],
                                    onDelete: {
                                        runners.remove(at: index)
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Add Runner Button
                Button(action: {
                    showingAddRunner = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("ADD RUNNER")
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save All") {
                        saveAllRunners()
                    }
                    .disabled(runners.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingAddRunner) {
            AddRunnerView { newRunner in
                runners.append(newRunner)
            }
        }
    }
    
    private func saveAllRunners() {
        for runner in runners {
            registrationManager.addRegistration(runner)
        }
        // Clear the current list after saving
        runners.removeAll()
    }
}

struct RunnerRegistrationRowView: View {
    @Binding var runner: RunnerRegistration
    let onDelete: () -> Void
    @State private var isEditing = false
    @State private var tempName = ""
    @State private var tempAge = ""
    @State private var tempGender = ""
    @State private var tempStartingNumber = ""
    
    var body: some View {
        HStack {
            if isEditing {
                // Edit Mode
                VStack(spacing: 8) {
                    TextField("Name", text: $tempName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    HStack {
                        TextField("Age", text: $tempAge)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                        
                        Picker("Gender", selection: $tempGender) {
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                            Text("Other").tag("Other")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 80)
                        
                        TextField("Start #", text: $tempStartingNumber)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Button("Cancel") {
                            isEditing = false
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Save") {
                            saveChanges()
                        }
                        .foregroundColor(.blue)
                    }
                }
            } else {
                // Display Mode
                VStack(alignment: .leading, spacing: 4) {
                    Text(runner.name.isEmpty ? "No name" : runner.name)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("\(runner.age)")
                            .font(.caption)
                            .frame(width: 60, alignment: .center)
                        
                        Text(runner.gender.isEmpty ? "—" : runner.gender)
                            .font(.caption)
                            .frame(width: 80, alignment: .center)
                        
                        Text(runner.startingNumber.isEmpty ? "—" : runner.startingNumber)
                            .font(.caption)
                            .frame(width: 80, alignment: .center)
                        
                        HStack {
                            Button("Edit") {
                                startEditing()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Button("Delete") {
                                onDelete()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .frame(width: 100, alignment: .center)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            loadCurrentValues()
        }
    }
    
    private func loadCurrentValues() {
        tempName = runner.name
        tempAge = runner.age == 0 ? "" : String(runner.age)
        tempGender = runner.gender
        tempStartingNumber = runner.startingNumber
    }
    
    private func startEditing() {
        loadCurrentValues()
        isEditing = true
    }
    
    private func saveChanges() {
        runner.name = tempName
        runner.age = Int(tempAge) ?? 0
        runner.gender = tempGender
        runner.startingNumber = tempStartingNumber
        isEditing = false
    }
}

struct AddRunnerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (RunnerRegistration) -> Void
    
    @State private var name = ""
    @State private var age = ""
    @State private var gender = "Male"
    @State private var startingNumber = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Runner Name")
                        .font(.headline)
                    TextField("Enter runner name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.headline)
                    TextField("Enter age", text: $age)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(.headline)
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Starting Number")
                        .font(.headline)
                    TextField("Enter starting number", text: $startingNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Runner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRunner()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveRunner() {
        let newRunner = RunnerRegistration(
            name: name,
            age: Int(age) ?? 0,
            gender: gender,
            startingNumber: startingNumber
        )
        onSave(newRunner)
        dismiss()
    }
}

#Preview {
    NewRunnerRegistrationView()
        .environmentObject(RegistrationManager())
}
