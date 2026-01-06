import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    var modelURL: URL?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Load Model
        if let url = modelURL {
            loadModel(url: url, into: arView)
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    private func loadModel(url: URL, into arView: ARView) {
        // Asynchronously load STL
        DispatchQueue.global(qos: .userInitiated).async {
            if let mesh = STLLoader.loadSTL(url: url) {
                let material = SimpleMaterial(color: .white, isMetallic: false)
                let modelEntity = ModelEntity(mesh: mesh, materials: [material])
                
                // Add bounding box
                let bounds = modelEntity.visualBounds(relativeTo: nil)
                let boxEntity = GeometryUtils.createBoundingBoxEntity(bounds: bounds)
                modelEntity.addChild(boxEntity)
                
                let anchor = AnchorEntity(plane: .horizontal)
                anchor.addChild(modelEntity)
                
                DispatchQueue.main.async {
                    arView.scene.anchors.append(anchor)
                }
            }
        }
    }
}
