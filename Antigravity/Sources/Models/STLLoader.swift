import RealityKit
import Foundation
import ModelIO

class STLLoader {
    
    /// Loads an STL file from a URL using ModelIO and returns a RealityKit MeshResource.
    static func loadSTL(url: URL) -> MeshResource? {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Use ModelIO for robust parsing
        let asset = MDLAsset(url: url)
        
        guard let mdlObject = asset.object(at: 0) as? MDLMesh else {
            print("Failed to load MDLMesh from asset.")
            return nil
        }
        
        // Add normals if missing (smooth shading)
        mdlObject.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.5)
        
        do {
            // Generate RealityKit MeshResource directly from ModelIO mesh
            let resource = try MeshResource.generate(from: mdlObject)
            return resource
        } catch {
            print("Error converting MDLMesh to MeshResource: \(error)")
            return nil
        }
    }
}
