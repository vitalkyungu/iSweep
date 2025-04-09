//
//  MediaRow.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/8/25.
//

import SwiftUI
import PhotosUI

struct MediaRow: View {
    let item: MediaItem
    
    var body: some View {
        HStack {
            // Icon based on media type
            Image(systemName: item.size.contains("MB") ? "film" : "photo")
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                Text(item.size)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Preview thumbnail (would be real PHAsset image in full implementation)
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}
