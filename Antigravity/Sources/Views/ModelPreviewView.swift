import SwiftUI
import SceneKit
import SceneKit.ModelIO

struct ModelPreviewView: View {
    let fileURL: URL
    @Binding var selectedFileURL: URL? // Add binding to clear selection
    @Binding var showAR: Bool
    
    @State private var scene: SCNScene?
    @State private var isLoading = true
    @State private var lightIntensity: Float = 1000
    @State private var isShadowsEnabled: Bool = true
    @State private var showSettings: Bool = false
    @State private var lightNode: SCNNode?
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            if let scene = scene {
                SceneView(scene: scene, pointOfView: nil, options: [.allowsCameraControl])
                    .edgesIgnoringSafeArea(.all)
                    .background(Color.white)
            }
            
            if isLoading {
                ProgressView("Loading 3D Model...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .foregroundColor(.black)
            }
            
            // Settings Overlay
            if showSettings {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showSettings = false
                    }
                
                VStack(spacing: 20) {
                    Text("Settings")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Light Intensity")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Slider(value: Binding(
                            get: { lightIntensity },
                            set: { newValue in
                                lightIntensity = newValue
                                lightNode?.light?.intensity = CGFloat(newValue)
                            }
                        ), in: 0...4000)
                        .accentColor(.black)
                        
                        Divider()
                        
                        Toggle("Shadows", isOn: Binding(
                            get: { isShadowsEnabled },
                            set: { newValue in
                                isShadowsEnabled = newValue
                                lightNode?.light?.castsShadow = newValue
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .black))
                        .foregroundColor(.black)
                    }
                }
                .padding()
                .frame(width: 300)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .transition(.scale)
            }
            
            VStack {
                HStack {
                    Button(action: {
                        selectedFileURL = nil
                        showAR = false
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                            .padding()
                    }
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showSettings.toggle()
                        }
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.largeTitle)
                            .foregroundColor(.black)
                            .padding()
                    }
                }
                Spacer()
                
                // Button is always visible
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
            let scnScene = SCNScene(mdlAsset: asset)
            
            // Fix Up-Axis
            let wrapperNode = SCNNode()
            for child in scnScene.rootNode.childNodes {
                wrapperNode.addChildNode(child)
            }
            wrapperNode.eulerAngles.x = -Float.pi / 2
            scnScene.rootNode.addChildNode(wrapperNode)
            
            // Add Custom Light
            let light = SCNLight()
            light.type = .directional
            light.intensity = CGFloat(self.lightIntensity)
            light.castsShadow = true
            light.automaticallyAdjustsShadowProjection = true // Auto-fit shadow map
            light.shadowSampleCount = 4 // Softer edges
            
            let lightNode = SCNNode()
            lightNode.light = light
            lightNode.position = SCNVector3(10, 10, 10)
            lightNode.look(at: SCNVector3(0, 0, 0))
            scnScene.rootNode.addChildNode(lightNode)
            
            // Add Ambient Light
            let ambient = SCNLight()
            ambient.type = .ambient
            ambient.intensity = 300
            let ambientNode = SCNNode()
            ambientNode.light = ambient
            scnScene.rootNode.addChildNode(ambientNode)

            DispatchQueue.main.async {
                self.scene = scnScene
                self.lightNode = lightNode
                self.isLoading = false
            }
        }
    }
}
