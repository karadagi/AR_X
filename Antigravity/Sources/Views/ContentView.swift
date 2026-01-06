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
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                    )
            } else {
                HomeView(selectedFileURL: $selectedFileURL, showAR: $showAR)
            }
        }
    }
}
