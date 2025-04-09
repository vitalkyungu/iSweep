//
//  StorageScanner.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/7/25.
//

import Foundation
import Photos

final class StorageScanner {
    
    // MARK: - Storage Analysis
    static func getStorageOverview() -> (used: Double, free: Double, total: Double) {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSpace = systemAttributes[.systemSize] as? Double,
              let freeSpace = systemAttributes[.systemFreeSize] as? Double else {
            return (0, 0, 0)
        }
        return (totalSpace - freeSpace, freeSpace, totalSpace)
    }
    
    // MARK: - Media Analysis
    static func getLargeVideos() async -> [MediaItem] {
        await withCheckedContinuation { continuation in
            guard PHPhotoLibrary.authorizationStatus() == .authorized else {
                continuation.resume(returning: [])
                return
            }
            
            var videos: [MediaItem] = []
            let assets = PHAsset.fetchAssets(with: .video, options: nil)
            
            assets.enumerateObjects { asset, _, _ in
                autoreleasepool {
                    let sizeMB = Double(asset.pixelWidth * asset.pixelHeight) / 1_000_000
                    if sizeMB > 100 {
                        videos.append(MediaItem(
                            name: asset.creationDate?.formatted() ?? "Video",
                            size: "\(Int(sizeMB))MB",
                            assetId: asset.localIdentifier,
                            asset: asset
                        ))
                    }
                }
            }
            
            continuation.resume(returning: videos.sorted { $0.size > $1.size })
        }
    }
    
    static func findDuplicatePhotos() async -> [MediaItem] {
        await withCheckedContinuation { continuation in
            guard PHPhotoLibrary.authorizationStatus() == .authorized else {
                continuation.resume(returning: [])
                return
            }
            
            var duplicates: [MediaItem] = []
            var assetDict = [String: [PHAsset]]()
            let assets = PHAsset.fetchAssets(with: .image, options: nil)
            
            assets.enumerateObjects { asset, _, _ in
                autoreleasepool {
                    let key = "\(asset.pixelWidth)x\(asset.pixelHeight)-\(asset.creationDate?.timeIntervalSince1970 ?? 0)"
                    assetDict[key, default: []].append(asset)
                }
            }
            
            for (_, similarAssets) in assetDict where similarAssets.count > 1 {
                duplicates.append(contentsOf: similarAssets.prefix(2).map {
                    MediaItem(
                        name: "Duplicate \($0.creationDate?.formatted() ?? "")",
                        size: "\($0.pixelWidth)x$($0.pixelHeight)",
                        assetId: $0.localIdentifier,
                        asset: $0
                    )
                })
            }
            
            continuation.resume(returning: duplicates)
        }
    }
    
    // MARK: - Cache Cleaning
    static func clearAppCaches() -> (cleanedSize: String, errors: [String]) {
        #if targetEnvironment(simulator)
        return ("1.5GB", []) // Mock data for simulator
        #else
        var cleanedBytes: Int64 = 0
        var errors: [String] = []
        let fileManager = FileManager.default
        
        let targets = [
            fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
            fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?
                .appendingPathComponent("Caches"),
            fileManager.temporaryDirectory,
            fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?
                .appendingPathComponent("Safari/Cache.db")
        ].compactMap { $0 }
        
        for url in targets {
            do {
                guard fileManager.fileExists(atPath: url.path) else { continue }
                
                let sizeBefore = try directorySize(at: url)
                try fileManager.removeItem(at: url)
                let sizeAfter = try directorySize(at: url)
                cleanedBytes += (sizeBefore - sizeAfter)
                
            } catch {
                errors.append("❌ Failed to clean \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        return (ByteCountFormatter.string(fromByteCount: cleanedBytes, countStyle: .file), errors)
        #endif
    }
    
    // MARK: - Deletion
    static func deleteMediaItems(_ items: [MediaItem]) async -> (successCount: Int, failedCount: Int) {
        await withCheckedContinuation { continuation in
            guard PHPhotoLibrary.authorizationStatus() == .authorized else {
                continuation.resume(returning: (0, items.count))
                return
            }
            
            var success = 0
            var failed = 0
            let group = DispatchGroup()
            
            for item in items {
                guard let asset = item.asset else {
                    failed += 1
                    continue
                }
                
                group.enter()
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.deleteAssets([asset] as NSArray)
                }) { didSucceed, error in
                    didSucceed ? (success += 1) : (failed += 1)
                    if let error = error {
                        print("Deletion error: \(error.localizedDescription)")
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                continuation.resume(returning: (success, failed))
            }
        }
    }
    
    // MARK: - Helpers
    private static func directorySize(at url: URL) throws -> Int64 {
        let contents = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        return try contents.reduce(0) {
            let size = try $1.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            return $0 + Int64(size)
        }
    }
}
