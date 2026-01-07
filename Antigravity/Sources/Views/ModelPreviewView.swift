import SwiftUI
import SceneKit
import SceneKit.ModelIO

struct ModelPreviewView: View {
    let fileURL: URL
    @Binding var selectedFileURL: URL? // Add binding to clear selection
    @Binding var showAR: Bool
    
    @State private var scene: SCNScene?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all) // Changed background to white for better contrast with black button, or handle black on light
            
            if let scene = scene {
                SceneView(scene: scene, pointOfView: nil, options: [.allowsCameraControl, .autoenablesDefaultLighting])
                    .edgesIgnoringSafeArea(.all)
                    .background(Color.white)
            }
            
            if isLoading {
                ProgressView("Loading 3D Model...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .foregroundColor(.black)
            }
            
            VStack {
                HStack {
                    Button(action: {
                        // Close preview by clearing selection
                        selectedFileURL = nil
                        showAR = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill") // Use arrow for "Back"
                            .font(.largeTitle)
                            .foregroundColor(.black) // Requested BLACK color
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
                
                Button(action: {
                    showAR = true
                }) {
                    Text("View in AR")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(Color.black)
                        .cornerRadius(30)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            loadModel()
        }
    }
    
    func loadModel() {
        DispatchQueue.global(qos: .userInitiated).async {
            let accessing = fileURL.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }
            
            let asset = MDLAsset(url: fileURL)
            // Fix Up-Axis: Z-up (standard STL) to Y-up (SceneKit)
            // Rotating the root object -90 degrees around X axis often solves this.
            
            let scnScene = SCNScene(mdlAsset: asset)
            
            // Apply rotation to root node
            let wrapperNode = SCNNode()
            for child in scnScene.rootNode.childNodes {
                wrapperNode.addChildNode(child)
            }
            wrapperNode.eulerAngles.x = -Float.pi / 2
            scnScene.rootNode.addChildNode(wrapperNode)

            DispatchQueue.main.async {
                self.scene = scnScene
                self.isLoading = false
            }
        }
    }
}
