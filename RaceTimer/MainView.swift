//
//  MainView.swift
//  RaceTimer
//
//  Created by MartyPac on 05.09.2025.
//

import SwiftUI

struct MainView: View {
    @StateObject private var raceManager = RaceManager()
    @State private var showingNewRace = false
    @State private var showingFinishedRaces = false
    
    var body: some View {
        ZStack {
            // Professional Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.2, blue: 0.3),
                    Color(red: 0.15, green: 0.25, blue: 0.35)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Sport Silhouettes Background
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "figure.run")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.1))
                        .rotationEffect(.degrees(-15))
                        .offset(x: 20, y: -50)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "figure.outdoor.cycle")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.08))
                        .rotationEffect(.degrees(10))
                        .offset(x: -30, y: 20)
                    
                    Spacer()
                    
                    Image(systemName: "figure.pool.swim")
                        .font(.system(size: 45))
                        .foregroundColor(.white.opacity(0.06))
                        .rotationEffect(.degrees(-5))
                        .offset(x: 40, y: -30)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Image(systemName: "figure.run")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.05))
                        .rotationEffect(.degrees(20))
                        .offset(x: 10, y: 40)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 10) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text("RaceTimer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Text("Professional Race Timing")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button(action: {
                        showingNewRace = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("NEW RACE")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: {
                        showingFinishedRaces = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("FINISHED RACES")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
        }
        .environmentObject(raceManager)
        .fullScreenCover(isPresented: $showingNewRace) {
            NewRaceSetupView()
                .environmentObject(raceManager)
        }
        .fullScreenCover(isPresented: $showingFinishedRaces) {
            FinishedRacesView()
                .environmentObject(raceManager)
        }
    }
}

#Preview {
    MainView()
}
