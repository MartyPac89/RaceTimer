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
            SportBackgroundLayer()
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
            NewRaceSetupView(isPresented: $showingNewRace)
                .environmentObject(raceManager)
        }
        .fullScreenCover(isPresented: $showingFinishedRaces) {
            FinishedRacesView()
                .environmentObject(raceManager)
        }
    }
}

private struct SportBackgroundLayer: View {
    private struct IconSpec: Identifiable {
        let id: String
        let name: String
        let size: CGFloat
        let opacity: Double
        let rotation: Double
        let xRatio: CGFloat
        let yRatio: CGFloat
    }

    private let icons: [IconSpec] = [
        IconSpec(id: "run-top-right", name: "figure.run", size: 60, opacity: 0.10, rotation: -15, xRatio: 0.88, yRatio: 0.07),
        IconSpec(id: "flag-top-left", name: "flag.checkered", size: 44, opacity: 0.07, rotation: -8, xRatio: 0.10, yRatio: 0.10),
        IconSpec(id: "stopwatch-top", name: "stopwatch", size: 36, opacity: 0.05, rotation: 5, xRatio: 0.52, yRatio: 0.05),
        IconSpec(id: "walk-upper", name: "figure.walk", size: 38, opacity: 0.06, rotation: 12, xRatio: 0.22, yRatio: 0.18),
        IconSpec(id: "cycle-upper", name: "figure.outdoor.cycle", size: 50, opacity: 0.08, rotation: 10, xRatio: 0.78, yRatio: 0.16),
        IconSpec(id: "trophy-upper", name: "trophy", size: 34, opacity: 0.05, rotation: 14, xRatio: 0.58, yRatio: 0.22),
        IconSpec(id: "swim-mid-right", name: "figure.pool.swim", size: 45, opacity: 0.06, rotation: -5, xRatio: 0.92, yRatio: 0.32),
        IconSpec(id: "hike-mid-left", name: "figure.hiking", size: 42, opacity: 0.07, rotation: -18, xRatio: 0.08, yRatio: 0.36),
        IconSpec(id: "medal-mid", name: "medal", size: 32, opacity: 0.05, rotation: -6, xRatio: 0.38, yRatio: 0.40),
        IconSpec(id: "run-mid", name: "figure.run", size: 52, opacity: 0.04, rotation: -10, xRatio: 0.65, yRatio: 0.44),
        IconSpec(id: "soccer-lower-mid", name: "figure.soccer", size: 48, opacity: 0.07, rotation: -12, xRatio: 0.14, yRatio: 0.55),
        IconSpec(id: "basketball-lower-mid", name: "figure.basketball", size: 46, opacity: 0.06, rotation: 8, xRatio: 0.84, yRatio: 0.58),
        IconSpec(id: "cycle-lower", name: "figure.outdoor.cycle", size: 36, opacity: 0.04, rotation: -22, xRatio: 0.48, yRatio: 0.62),
        IconSpec(id: "run-lower", name: "figure.run", size: 40, opacity: 0.05, rotation: 20, xRatio: 0.72, yRatio: 0.70),
        IconSpec(id: "ski-bottom-right", name: "figure.skiing.downhill", size: 44, opacity: 0.06, rotation: 15, xRatio: 0.90, yRatio: 0.82),
        IconSpec(id: "swim-bottom-left", name: "figure.pool.swim", size: 38, opacity: 0.05, rotation: 6, xRatio: 0.12, yRatio: 0.86),
        IconSpec(id: "cycle-bottom", name: "figure.outdoor.cycle", size: 42, opacity: 0.05, rotation: -14, xRatio: 0.35, yRatio: 0.92),
        IconSpec(id: "run-bottom", name: "figure.run", size: 48, opacity: 0.04, rotation: 18, xRatio: 0.62, yRatio: 0.95),
        IconSpec(id: "flag-bottom-right", name: "flag.checkered", size: 36, opacity: 0.04, rotation: 10, xRatio: 0.78, yRatio: 0.90)
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(icons) { icon in
                    Image(systemName: icon.name)
                        .font(.system(size: icon.size))
                        .foregroundColor(.white.opacity(icon.opacity))
                        .rotationEffect(.degrees(icon.rotation))
                        .position(
                            x: geometry.size.width * icon.xRatio,
                            y: geometry.size.height * icon.yRatio
                        )
                }
            }
        }
    }
}

#Preview {
    MainView()
}
