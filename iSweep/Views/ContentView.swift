//
//  ContentView.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/8/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StorageViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. Logo
                Image(systemName: "trash")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color("tealPrimary"))
                
                // 2. Storage Meter
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.storagePercentage)
                        .stroke(Color("tealPrimary"), lineWidth: 10)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.7), value: viewModel.storagePercentage)
                    
                    Text("\(Int(viewModel.storagePercentage * 100))%")
                        .font(.system(size: 24, weight: .bold))
                        .contentTransition(.numericText())
                }
                .frame(width: 150, height: 150)
                
                // 3. Category Pills
                HStack(spacing: 15) {
                    NavigationLink {
                        PhotosView(viewModel: viewModel)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.stack")
                                .font(.title3)
                            Text("Photos")
                                .font(.subheadline)
                            Text("\(viewModel.duplicates.count) dupes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 100, height: 100)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    NavigationLink {
                        VideosView(viewModel: viewModel)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "video")
                                .font(.title3)
                            Text("Videos")
                                .font(.subheadline)
                            Text("\(viewModel.largeVideos.count) large")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 100, height: 100)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                }
                
                // 4. Action Buttons
                VStack(spacing: 10) {
                    Button {
                        viewModel.performCleanup()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sweep Now")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("tealPrimary"))
                    .disabled(viewModel.isLoading)
                    
                    Button("Settings") {
                        showingSettings = true
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationTitle("iSweep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("iSweep")
                        .font(.headline.weight(.semibold))
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert(viewModel.alertMessage,
                   isPresented: $viewModel.showCriticalAlert) {
                Button("Clean Now", role: .destructive) {
                    viewModel.performCleanup()
                }
                Button("Later", role: .cancel) {}
            }
            .task {
                await viewModel.scanPhotos()
                viewModel.checkStorage()
            }
        }
    }
}

#Preview {
    ContentView()
}
