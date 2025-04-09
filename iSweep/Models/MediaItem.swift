//
//  MediaItem.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/8/25.
//

import Photos

struct MediaItem: Identifiable {
    let id: String
    let name: String
    let size: String
    let asset: PHAsset?  // Add this property
    
    init(name: String, size: String, assetId: String, asset: PHAsset? = nil) {
        self.id = assetId
        self.name = name
        self.size = size
        self.asset = asset ?? PHAsset.fetchAssets(
            withLocalIdentifiers: [assetId],
            options: nil
        ).firstObject
    }
}
