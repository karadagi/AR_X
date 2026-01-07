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
                            
                            Text("Tap on floor to place model")
                                .font(.headline)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.bottom, 50)
                        }
                    )
                    .transition(.opacity)
            } else if let url = selectedFileURL {
                ModelPreviewView(fileURL: url, selectedFileURL: $selectedFileURL, showAR: $showAR)
                    .transition(.move(edge: .bottom))
            } else {
                HomeView(selectedFileURL: $selectedFileURL, showAR: .constant(false)) // Update binding logic
            }
        }
    }
}
