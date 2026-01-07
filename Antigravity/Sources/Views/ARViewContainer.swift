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
        config.environmentTexturing = .automatic
        arView.session.run(config)
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        // Prepare Coordinator to handle taps
        context.coordinator.arView = arView
        
        // Add Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Preload Model
        if let url = modelURL {
            context.coordinator.loadModel(url: url)
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        weak var arView: ARView?
        var loadedModelEntity: ModelEntity?
        
        func loadModel(url: URL) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let mesh = STLLoader.loadSTL(url: url) {
                    let material = SimpleMaterial(color: .white, isMetallic: false)
                    let modelEntity = ModelEntity(mesh: mesh, materials: [material])
                    
                    // Add bounding box visual
                    let bounds = modelEntity.visualBounds(relativeTo: nil)
                    let boxEntity = GeometryUtils.createBoundingBoxEntity(bounds: bounds)
                    modelEntity.addChild(boxEntity)
                    
                    // Generate collision shape for raycasting/manipulation
                    modelEntity.generateCollisionShapes(recursive: true)
                    
                    self.loadedModelEntity = modelEntity
                }
            }
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView, let model = loadedModelEntity else { return }
            
            let tapLocation = sender.location(in: arView)
            
            // Raycast for horizontal planes
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                // Determine position
                let position = simd_make_float3(firstResult.worldTransform.columns.3)
                
                placeAnchor(at: position, model: model, in: arView)
            }
        }
        
        func placeAnchor(at position: SIMD3<Float>, model: ModelEntity, in arView: ARView) {
            // Clone the model so valid one can be placed multiple times if desired
            let modelClone = model.clone(recursive: true)
            
            // Create anchor
            let anchor = AnchorEntity(world: position)
            anchor.addChild(modelClone)
            
            arView.scene.anchors.append(anchor)
        }
    }
}
