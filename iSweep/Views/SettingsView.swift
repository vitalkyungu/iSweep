//
//  SettingsView.swift
//  iSweep
//
//  Created by Vital Kyungu on 4/8/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("autoCleanEnabled") var autoClean = true
    @AppStorage("cleanThreshold") var threshold = 0.8
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Automation") {
                    Toggle("Auto Clean", isOn: $autoClean)
                }
                
                Section(header: Text("Cleanup Threshold")) {
                    Slider(value: $threshold, in: 0.5...0.95, step: 0.05) {
                        Text("Threshold")
                    }
                    Text("Clean when storage reaches \(Int(threshold * 100))%")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
