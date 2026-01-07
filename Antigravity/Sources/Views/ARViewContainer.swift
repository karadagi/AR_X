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
                    
                    // Smart Scaling Logic
                    // STLLoader returns unitless data.
                    // If bounding box largest dimension > 10.0, assume it's in Millimeters (mm).
                    // Convert mm to meters: multiply by 0.001.
                    
                    let originalBounds = modelEntity.visualBounds(relativeTo: nil)
                    let originalSize = max(originalBounds.extents.x, max(originalBounds.extents.y, originalBounds.extents.z))
                    
                    if originalSize > 10.0 {
                        // Likely mm, convert to meters
                        let mmScale: Float = 0.001
                        modelEntity.scale = SIMD3<Float>(repeating: mmScale)
                    } else if originalSize > 2.0 {
                        // Between 2m and 10m? That's huge for a tabletop AR app. Scale to fit 1m.
                        let scale = 1.0 / originalSize
                        modelEntity.scale = SIMD3<Float>(repeating: scale)
                    }
                    // Else: If it's < 2.0 (e.g. 0.5 or 0.1), assume it's already in meters. Keep as is.
                    
                    // Fix Layout (Up Axis)
                    modelEntity.orientation = simd_quatf(angle: -Float.pi/2, axis: SIMD3<Float>(1, 0, 0))
                    
                    // Add collision for interaction
                    modelEntity.generateCollisionShapes(recursive: true)
                    
                    self.loadedModelEntity = modelEntity
                }
            }
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = sender.location(in: arView)
            
            // Haptic Feedback
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            
            let results = arView.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                let position = simd_make_float3(firstResult.worldTransform.columns.3)
                
                if let model = loadedModelEntity {
                    placeAnchor(at: position, model: model, in: arView)
                } else {
                    // Fallback: Place a red debug box if model failed to load
                    // This confirms the "Tap" works even if the model is broken
                    let mesh = MeshResource.generateBox(size: 0.1)
                    let mat = SimpleMaterial(color: .red, isMetallic: false)
                    let debugEntity = ModelEntity(mesh: mesh, materials: [mat])
                    placeAnchor(at: position, model: debugEntity, in: arView)
                }
            }
        }
        
        func placeAnchor(at position: SIMD3<Float>, model: ModelEntity, in arView: ARView) {
            let modelClone = model.clone(recursive: true)
            // Reset position of the clone relative to anchor
            modelClone.position = .zero
            
            let anchor = AnchorEntity(world: position)
            anchor.addChild(modelClone)
            
            arView.scene.anchors.append(anchor)
            
            // Add bounding box entity as child *after* scaling so we see true bounds
            let bounds = modelClone.visualBounds(relativeTo: nil)
            let boxEntity = GeometryUtils.createBoundingBoxEntity(bounds: bounds)
            modelClone.addChild(boxEntity)
        }
    }
}
