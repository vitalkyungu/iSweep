//
//  CategoryPill.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/8/25.
//
import SwiftUI

struct CategoryPill: View {
    let title: String
    let size: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
            Text(size)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

