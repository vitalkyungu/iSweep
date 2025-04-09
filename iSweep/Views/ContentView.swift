import SwiftUI

struct ContentView: View {
    @State private var storageUsed = StorageScanner.getUsedStoragePercentage()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. Logo (replace with your asset)
                Image(systemName: "trash")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color("tealPrimary"))
                
                // 2. Storage Meter (animated)
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: storageUsed)
                        .stroke(Color("tealPrimary"), lineWidth: 10)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1), value: storageUsed)
                }
                .frame(width: 150, height: 150)
                .padding(.vertical)
                
                // 3. Category Pills (tappable)
                HStack(spacing: 15) {
                    NavigationLink {
                       // PhotosView() // You'll create this next
                    } label: {
                        CategoryPill(title: "Photos", size: StorageScanner.getPhotosSize())
                    }
                    
                    NavigationLink {
                        Text("Apps View") // Placeholder for now
                    } label: {
                        CategoryPill(title: "Apps", size: "3.1GB")
                    }
                }
                
                // 4. Sweep Now Button
                Button(action: {
                    // Refresh storage data
                    storageUsed = StorageScanner.getUsedStoragePercentage()
                }) {
                    Text("Sweep Now")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("tealPrimary"))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationTitle("iSweep")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Reusable Category Pill Component
struct CategoryPill: View {
    var title: String
    var size: String
    
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

// Preview
#Preview {
    ContentView()
        .preferredColorScheme(.light) // Test dark mode
}
