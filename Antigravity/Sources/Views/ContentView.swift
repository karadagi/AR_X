import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var showAR = false
    @State private var selectedFileURL: URL?
    
    var body: some View {
        ZStack {
            if showAR {
                ARViewContainer(modelURL: selectedFileURL)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            HStack {
                                Button(action: {
                                    showAR = false
                                }) {
                                    Image(systemName: "arrow.left.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                    )
                    .transition(.opacity)
            } else if let url = selectedFileURL {
                ModelPreviewView(fileURL: url, showAR: $showAR)
                    .transition(.move(edge: .bottom))
            } else {
                HomeView(selectedFileURL: $selectedFileURL, showAR: .constant(false)) // Update binding logic
            }
        }
    }
}
