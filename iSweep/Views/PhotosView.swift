//
//  PhotosView.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/8/25.
//

import SwiftUI
import Photos

struct PhotosView: View {
    @ObservedObject var viewModel: StorageViewModel
    @State private var showPermissionAlert = false
    @State private var showDeleteAlert = false
    @State private var deleteResults: (successCount: Int, failedCount: Int)? = nil
    @State private var isDeleting = false
    
    var body: some View {
        List {
            Section("Large Videos") {
                if viewModel.largeVideos.isEmpty {
                    if PHPhotoLibrary.authorizationStatus() != .authorized {
                        Button("Grant Photo Access") {
                            Task {
                                await viewModel.requestPhotoAccess()
                                await MainActor.run {
                                    if PHPhotoLibrary.authorizationStatus() != .authorized {
                                        showPermissionAlert = true
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    } else {
                        Text("No large videos found")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(viewModel.largeVideos) { item in
                        MediaRow(item: item)
                    }
                }
            }
            
            Section(header: Text("Duplicate Photos"),
                    footer: duplicateFooter) {
                if viewModel.duplicates.isEmpty {
                    Text(viewModel.isLoading ? "Scanning..." : "No duplicates found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.duplicates) { item in
                        MediaRow(item: item)
                    }
                    
                    if !viewModel.duplicates.isEmpty {
                        deleteButton
                    }
                }
            }
        }
        .navigationTitle("Photos")
        .toolbar {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Photo Access Required",
               isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable photo access in Settings to scan your library")
        }
        .alert("Delete \(viewModel.duplicates.count) duplicates?",
               isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteDuplicates()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Deletion Complete",
               isPresented: Binding(get: { deleteResults != nil },
                                   set: { _ in deleteResults = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            if let results = deleteResults {
                Text("Successfully deleted \(results.successCount) duplicates\nFailed to delete \(results.failedCount)")
            }
        }
        .task {
            await viewModel.requestPhotoAccess()
        }
        .refreshable {
            await viewModel.scanPhotos()
        }
    }
    
    private func calculateTotalSize() -> String {
        let averagePhotoSizeMB = 2.5 // Average size in MB
        let totalSizeMB = Double(viewModel.duplicates.count) * averagePhotoSizeMB
        if totalSizeMB > 1000 {
            return String(format: "%.1f GB", totalSizeMB / 1000)
        } else {
            return String(format: "%.1f MB", totalSizeMB)
        }
    }
    
    private var duplicateFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.duplicates.isEmpty {
                Text("\(viewModel.duplicates.count) duplicates found")
                    .font(.caption)
                Text("Total wasted space: \(calculateTotalSize())")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            HStack {
                Spacer()
                if isDeleting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Label("Delete All Duplicates", systemImage: "trash")
                }
                Spacer()
            }
        }
        .disabled(isDeleting)
    }
    
    private func deleteDuplicates() async {
           isDeleting = true
           defer { isDeleting = false }
           
           let results = await StorageScanner.deleteMediaItems(viewModel.duplicates)
           await MainActor.run {
               deleteResults = results
               if results.successCount > 0 {
                   viewModel.duplicates.removeAll()
            }
        }
    }
}
