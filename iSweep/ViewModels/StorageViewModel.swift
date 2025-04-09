//
//  StorageViewModel.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/8/25.
//

import SwiftUI
import Photos

@MainActor
final class StorageViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var alertMessage = ""
    @Published var showCriticalAlert = false
    @Published var storagePercentage: CGFloat = 0
    @Published var largeVideos: [MediaItem] = []
    @Published var duplicates: [MediaItem] = []
    @Published var isLoading = false
    @Published var showPhotoAccessAlert = false
    
    // MARK: - Storage Management
    func checkStorage(immediateAlert: Bool = false) {
        let (used, _, total) = StorageScanner.getStorageOverview()
        storagePercentage = total > 0 ? CGFloat(used / total) : 0
        
        if storagePercentage > 0.9 {
            alertMessage = "Critical: Less than 10% storage left!"
            showCriticalAlert = immediateAlert // Only show immediately if requested
        } else if storagePercentage > 0.75 {
            alertMessage = "Warning: Storage reaching capacity"
            if immediateAlert {
                showCriticalAlert = true
            }
        }
    }
    
    // MARK: - Photo Access
    func requestPhotoAccess() async {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .notDetermined:
            // First time - request permission
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await handleAuthorizationChange(newStatus)
            
        case .restricted, .denied:
            // Permission denied - show alert
            await MainActor.run {
                showPhotoAccessAlert = true
            }
            
        case .authorized, .limited:
            // Already authorized - scan photos
            await scanPhotos()
            
        @unknown default:
            break
        }
    }

    private func handleAuthorizationChange(_ status: PHAuthorizationStatus) async {
        await MainActor.run {
            showPhotoAccessAlert = (status != .authorized)
        }
        
        if status == .authorized {
            await scanPhotos()
        }
    }
    // MARK: - Cleanup
    func performCleanup() {
        isLoading = true
        Task {
            // 1. Perform cleaning
            let (cleaned, errors) = StorageScanner.clearAppCaches()
            
            // 2. FORCE storage recalculation
            let newStorage = StorageScanner.getStorageOverview()
            
            await MainActor.run {
                // 3. Update ALL values
                storagePercentage = newStorage.total > 0 ?
                    CGFloat(newStorage.used / newStorage.total) : 0
                
                // 4. Show results
                alertMessage = "Cleaned \(cleaned)"
                if !errors.isEmpty {
                    alertMessage += "\nErrors:\n\(errors.joined(separator: "\n"))"
                }
                
                // 5. Debug print
                print("""
                Cleaned: \(cleaned)
                New storage: \(storagePercentage * 100)%
                Errors: \(errors)
                """)
                
                isLoading = false
            }
        }
    }
    // MARK: - Photo Scanning
    func scanPhotos() async {
        isLoading = true
        defer { isLoading = false }
        
        #if targetEnvironment(simulator)
        // Mock data for simulator
        largeVideos = [
            MediaItem(name: "Beach Vacation.mp4", size: "1.2GB", assetId: "SIM1"),
            MediaItem(name: "Concert.mp4", size: "0.8GB", assetId: "SIM2")
        ]
        duplicates = [
            MediaItem(name: "Duplicate Photo", size: "12MP", assetId: "DUP1"),
            MediaItem(name: "Duplicate Photo", size: "12MP", assetId: "DUP2")
        ]
        #else
        guard PHPhotoLibrary.authorizationStatus() == .authorized else {
            await requestPhotoAccess()
            return
        }
        
        async let videos = StorageScanner.getLargeVideos()
        async let dupes = StorageScanner.findDuplicatePhotos()
        (largeVideos, duplicates) = await (videos, dupes)
        #endif
    }
}
