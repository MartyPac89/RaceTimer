//
//  RegistrationListView.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import SwiftUI

struct RegistrationListView: View {
    @EnvironmentObject var registrationManager: RegistrationManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRunner: RunnerRegistration?
    @State private var showingEditRunner = false
    
    private var sortedRegistrations: [RunnerRegistration] {
        registrationManager.registrations.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Registration List")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(registrationManager.registrations.count) runners registered")
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
                
                // Registrations List
                if registrationManager.registrations.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No registrations yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Go to 'New Registration' to add runners")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(sortedRegistrations) { registration in
                                RegistrationListRowView(registration: registration) {
                                    selectedRunner = registration
                                    showingEditRunner = true
                                } onDelete: {
                                    registrationManager.deleteRegistration(registration)
                                }
                            }
                        }
                    }
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
        .sheet(item: $selectedRunner) { runner in
            EditRunnerView(runner: runner) { updatedRunner in
                registrationManager.updateRegistration(updatedRunner)
            }
        }
    }
}

struct RegistrationListRowView: View {
    let registration: RunnerRegistration
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(registration.name.isEmpty ? "No name" : registration.name)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(registration.dateRegistered, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text("\(registration.age)")
                .font(.body)
                .frame(width: 60, alignment: .center)
            
            Text(registration.gender.isEmpty ? "—" : registration.gender)
                .font(.body)
                .frame(width: 80, alignment: .center)
            
            Text(registration.startingNumber.isEmpty ? "—" : registration.startingNumber)
                .font(.body)
                .frame(width: 80, alignment: .center)
            
            HStack {
                Button("Edit") {
                    onEdit()
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
        .padding()
        .background(Color(.systemBackground))
    }
}

struct EditRunnerView: View {
    let runner: RunnerRegistration
    let onSave: (RunnerRegistration) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var age: String
    @State private var gender: String
    @State private var startingNumber: String
    
    init(runner: RunnerRegistration, onSave: @escaping (RunnerRegistration) -> Void) {
        self.runner = runner
        self.onSave = onSave
        _name = State(initialValue: runner.name)
        _age = State(initialValue: runner.age == 0 ? "" : String(runner.age))
        _gender = State(initialValue: runner.gender)
        _startingNumber = State(initialValue: runner.startingNumber)
    }
    
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
            .navigationTitle("Edit Runner")
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
        var updatedRunner = runner
        updatedRunner.name = name
        updatedRunner.age = Int(age) ?? 0
        updatedRunner.gender = gender
        updatedRunner.startingNumber = startingNumber
        
        onSave(updatedRunner)
        dismiss()
    }
}

#Preview {
    RegistrationListView()
        .environmentObject(RegistrationManager())
}
