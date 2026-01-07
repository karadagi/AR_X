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
        
        // Add normals if missing
        mdlObject.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.5)
        
        // Convert to MeshDescriptor manually since RealityKit doesn't natively consume MDLMesh directly
        // We need to extract positions and normals.
        
        var descriptor = MeshDescriptor(name: "STLImport")
        
        // 1. Extract Positions
        if let posAttr = mdlObject.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition, as: .float3) {
            let vertexCount = mdlObject.vertexCount
            let map = posAttr.map
            let bytes = map.bytes.bindMemory(to: SIMD3<Float>.self, capacity: vertexCount)
            
            var positions = [SIMD3<Float>]()
            positions.reserveCapacity(vertexCount)
            
            for i in 0..<vertexCount {
                positions.append(bytes[i])
            }
            descriptor.positions = MeshBuffer(positions)
        }
        
        // 2. Extract Normals
        if let normAttr = mdlObject.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal, as: .float3) {
            let vertexCount = mdlObject.vertexCount
            let map = normAttr.map
            let bytes = map.bytes.bindMemory(to: SIMD3<Float>.self, capacity: vertexCount)
            
            var normals = [SIMD3<Float>]()
            normals.reserveCapacity(vertexCount)
            
            for i in 0..<vertexCount {
                normals.append(bytes[i])
            }
            descriptor.normals = MeshBuffer(normals)
        }
        
        // 3. Extract Indices (Primitives)
        var allIndices = [UInt32]()
        if let submeshes = mdlObject.submeshes as? [MDLSubmesh] {
            for submesh in submeshes {
                let indexBuffer = submesh.indexBuffer
                let indexCount = submesh.indexCount
                let map = indexBuffer.map
                let ptr = map.bytes
                
                switch submesh.indexType {
                case .uInt32:
                    let indices = ptr.bindMemory(to: UInt32.self, capacity: indexCount)
                    for i in 0..<indexCount { allIndices.append(indices[i]) }
                case .uInt16:
                    let indices = ptr.bindMemory(to: UInt16.self, capacity: indexCount)
                    for i in 0..<indexCount { allIndices.append(UInt32(indices[i])) }
                case .uInt8:
                    let indices = ptr.bindMemory(to: UInt8.self, capacity: indexCount)
                    for i in 0..<indexCount { allIndices.append(UInt32(indices[i])) }
                default:
                    break
                }
            }
        }
        descriptor.primitives = .triangles(allIndices)
        
        do {
            let resource = try MeshResource.generate(from: [descriptor])
            return resource
        } catch {
            print("Error generating MeshResource: \(error)")
            return nil
        }
    }
}
