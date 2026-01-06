import SwiftUI
import SceneKit
import SceneKit.ModelIO

struct ModelPreviewView: View {
    let fileURL: URL
    @Binding var showAR: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var scene: SCNScene?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let scene = scene {
                SceneView(scene: scene, pointOfView: nil, options: [.allowsCameraControl, .autoenablesDefaultLighting])
                    .edgesIgnoringSafeArea(.all)
            }
            
            if isLoading {
                ProgressView("Loading 3D Model...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
            }
            
            VStack {
                HStack {
                    Button(action: {
                        // Close preview, go back to home
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
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
                        .foregroundColor(.black)
                        .padding()
                        .frame(width: 200)
                        .background(Color.white)
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
            // Secure access is handled by the parent or we need to start it here again 
            // if it was stopped. It's safer to start it.
            let accessing = fileURL.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }
            
            let asset = MDLAsset(url: fileURL)
            let scnScene = SCNScene(mdlAsset: asset)
            
            // Auto-scale to fit view if needed, but SceneKit allows zooming.
            // Let's ensure it has a camera or rely on default light/camera.
            
            DispatchQueue.main.async {
                self.scene = scnScene
                self.isLoading = false
            }
        }
    }
}
