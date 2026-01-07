import RealityKit
import UIKit

class GeometryUtils {
    static func createBoundingBoxEntity(bounds: BoundingBox) -> ModelEntity {
        // Create a wireframe-like box using small cylinders for edges or a transparent box
        // For simplicity: A transparent box with edges is complex in RealityKit without custom shaders
        // We will create a semi-transparent ghost box.
        
        let width = bounds.max.x - bounds.min.x
        let height = bounds.max.y - bounds.min.y
        let depth = bounds.max.z - bounds.min.z
        
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(width, height, depth))
        let material = SimpleMaterial(color: .blue.withAlphaComponent(0.3), isMetallic: false)
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
}
