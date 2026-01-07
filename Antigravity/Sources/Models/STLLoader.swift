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
             // posAttr.map.bytes is the raw pointer
             // We need to copy this into a standard array [SIMD3<Float>]
             // Accessing the buffer via map
             let vertexCount = mdlObject.vertexCount
             var positions = [SIMD3<Float>](repeating: .zero, count: vertexCount)
             
             positions.withUnsafeMutableBytes { ptr in
                 // Copy from ModelIO buffer
                 // Note: This assumes tightly packed float3. ModelIO layouts can vary.
                 // A safer way is iterating, but slow. 
                 // Allow stride check if possible, but for STL standard import usually it's packed.
                 // Let's rely on standard layout for now or iterate.
                 
                 let bytesToCopy = vertexCount * MemoryLayout<SIMD3<Float>>.stride
                 if posAttr.map.bytes.count >= bytesToCopy {
                     ptr.copyMemory(from: UnsafeRawBufferPointer(start: posAttr.map.bytes, count: bytesToCopy))
                 }
             }
             descriptor.positions = MeshBuffers.Positions(positions)
        }
        
        // 2. Extract Normals
        if let normAttr = mdlObject.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal, as: .float3) {
             let vertexCount = mdlObject.vertexCount
             var normals = [SIMD3<Float>](repeating: .zero, count: vertexCount)
             
             normals.withUnsafeMutableBytes { ptr in
                 let bytesToCopy = vertexCount * MemoryLayout<SIMD3<Float>>.stride
                 if normAttr.map.bytes.count >= bytesToCopy {
                     ptr.copyMemory(from: UnsafeRawBufferPointer(start: normAttr.map.bytes, count: bytesToCopy))
                 }
             }
             descriptor.normals = MeshBuffers.Normals(normals)
        }
        
        // 3. Extract Indices (Primitives)
        // flatten submeshes
        var allIndices: [UInt32] = []
        if let submeshes = mdlObject.submeshes as? [MDLSubmesh] {
            for submesh in submeshes {
                let indexCount = submesh.indexCount
                let indexBuffer = submesh.indexBuffer
                let map = indexBuffer.map
                
                // ModelIO supports different index types (UInt8, UInt16, UInt32)
                // We need to normalize to UInt32
                let ptr = map.bytes
                let type = submesh.indexType
                
                if type == .uInt32 {
                     let indices = ptr.bindMemory(to: UInt32.self, capacity: indexCount)
                     for i in 0..<indexCount { allIndices.append(indices[i]) }
                } else if type == .uInt16 {
                     let indices = ptr.bindMemory(to: UInt16.self, capacity: indexCount)
                     for i in 0..<indexCount { allIndices.append(UInt32(indices[i])) }
                } else if type == .uInt8 {
                     let indices = ptr.bindMemory(to: UInt8.self, capacity: indexCount)
                     for i in 0..<indexCount { allIndices.append(UInt32(indices[i])) }
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
