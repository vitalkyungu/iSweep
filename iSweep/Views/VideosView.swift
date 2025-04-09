//
//  VideosView.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/8/25.
//

import SwiftUI
import Photos

struct VideosView: View {
    @ObservedObject var viewModel: StorageViewModel
    @State private var showPermissionAlert = false
    @State private var showDeleteAlert = false
    @State private var deleteResults: (successCount: Int, failedCount: Int)? = nil
    @State private var isDeleting = false
    
    var body: some View {
        List {
            Section(header: Text("Large Videos"),
                    footer: videosFooter) {
                if viewModel.largeVideos.isEmpty {
                    if PHPhotoLibrary.authorizationStatus() != .authorized {
                        Button("Grant Video Access") {
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
                    
                    if !viewModel.largeVideos.isEmpty {
                        deleteButton
                    }
                }
            }
        }
        .navigationTitle("Videos")
        .toolbar {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("Video Access Required",
               isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable photo library access in Settings to scan your videos")
        }
        .alert("Delete \(viewModel.largeVideos.count) videos?",
               isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteVideos()
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
                Text("Successfully deleted \(results.successCount) videos\nFailed to delete \(results.failedCount)")
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
        // Calculate based on actual video sizes if available in MediaItem
        // For now using approximate average of 100MB per video
        let totalSizeMB = Double(viewModel.largeVideos.count) * 100
        if totalSizeMB > 1000 {
            return String(format: "%.1f GB", totalSizeMB / 1000)
        } else {
            return String(format: "%.0f MB", totalSizeMB)
        }
    }
    
    private var videosFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewModel.largeVideos.isEmpty {
                Text("\(viewModel.largeVideos.count) large videos found")
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
                    Label("Delete All Large Videos", systemImage: "trash")
                }
                Spacer()
            }
        }
        .disabled(isDeleting)
    }
    
    private func deleteVideos() async {
            isDeleting = true
            defer { isDeleting = false }
            
            let results = await StorageScanner.deleteMediaItems(viewModel.largeVideos)
            await MainActor.run {
                deleteResults = results
                if results.successCount > 0 {
                    viewModel.largeVideos.removeAll()
            }
        }
    }
}
