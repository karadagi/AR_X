import RealityKit
import Foundation
import UIKit

class STLLoader {
    
    /// Loads an STL file from a URL and returns a RealityKit MeshResource.
    /// Handles Security Scoped Resources automatically.
    static func loadSTL(url: URL) -> MeshResource? {
        // 1. Secure Access
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            
            // Check for ASCII (starts with "solid") - naive check
            // For now, we prioritize Binary STL as it's standard for 3D printing/scanning.
            // A robust check would look at the first 80 bytes for "solid" AND file size checks.
            
            // Let's assume Binary for efficiency, or try to parse.
            return parseBinarySTL(data: data)
            
        } catch {
            print("Failed to read STL file: \(error)")
            return nil
        }
    }
    
    private static func parseBinarySTL(data: Data) -> MeshResource? {
        guard data.count > 84 else {
            print("Data too short to be binary STL")
            return nil
        }
        
        return data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> MeshResource? in
            let ptr = bytes.baseAddress!
            
            // Skip 80 byte header
            // Read count (4 bytes at offset 80)
            let countPtr = ptr.advanced(by: 80).bindMemory(to: UInt32.self, capacity: 1)
            let triangleCount = Int(countPtr.pointee)
            
            // Safety check for file size validity
            // Expected size = 84 + (50 * count)
            let expectedSize = 84 + (triangleCount * 50)
            if data.count < expectedSize {
                print("STL file size mismatch. Expected \(expectedSize), got \(data.count)")
                // Proceeding carefully or aborting? Let's abort to avoid crash.
                return nil
            }
            
            print("Parsing \(triangleCount) triangles...")
            
            // 50 bytes per triangle:
            // 12 bytes Normal (3 floats)
            // 12 bytes V1 (3 floats)
            // 12 bytes V2 (3 floats)
            // 12 bytes V3 (3 floats)
            // 2 bytes Attribute (uint16)
            
            var positions: [SIMD3<Float>] = []
            var normals: [SIMD3<Float>] = []
            var indices: [UInt32] = []
            
            // Reserve capacity to avoid reallocations
            positions.reserveCapacity(triangleCount * 3)
            normals.reserveCapacity(triangleCount * 3)
            indices.reserveCapacity(triangleCount * 3)
            
            var offset = 84
            
            for i in 0..<triangleCount {
                let trianglePtr = ptr.advanced(by: offset)
                
                // Read Normal
                // STL normals can be unreliable (sometimes 0,0,0). 
                // We will read them, but RealityKit can also recompute them if needed.
                let nX = trianglePtr.load(fromByteOffset: 0, as: Float.self)
                let nY = trianglePtr.load(fromByteOffset: 4, as: Float.self)
                let nZ = trianglePtr.load(fromByteOffset: 8, as: Float.self)
                let normal = SIMD3<Float>(nX, nY, nZ)
                
                // Read Vertices
                let v1 = SIMD3<Float>(
                    trianglePtr.load(fromByteOffset: 12, as: Float.self),
                    trianglePtr.load(fromByteOffset: 16, as: Float.self),
                    trianglePtr.load(fromByteOffset: 20, as: Float.self)
                )
                
                let v2 = SIMD3<Float>(
                    trianglePtr.load(fromByteOffset: 24, as: Float.self),
                    trianglePtr.load(fromByteOffset: 28, as: Float.self),
                    trianglePtr.load(fromByteOffset: 32, as: Float.self)
                )
                
                let v3 = SIMD3<Float>(
                    trianglePtr.load(fromByteOffset: 36, as: Float.self),
                    trianglePtr.load(fromByteOffset: 40, as: Float.self),
                    trianglePtr.load(fromByteOffset: 44, as: Float.self)
                )
                
                // STL assumes right-hand rule, usually. 
                // Coordinates in STL are arbitrary units. simple import.
                
                positions.append(v1)
                positions.append(v2)
                positions.append(v3)
                
                // Duplicate normal for each vertex (flat shading style)
                normals.append(normal)
                normals.append(normal)
                normals.append(normal)
                
                let baseIndex = UInt32(i * 3)
                indices.append(baseIndex)
                indices.append(baseIndex + 1)
                indices.append(baseIndex + 2)
                
                offset += 50
            }
            
            // Construct MeshDescriptor
            var descriptor = MeshDescriptor(name: "STLImport")
            descriptor.positions = MeshBuffers.Positions(positions)
            descriptor.normals = MeshBuffers.Normals(normals)
            descriptor.primitives = .triangles(indices)
            
            do {
                let resource = try MeshResource.generate(from: [descriptor])
                return resource
            } catch {
                print("Error generating MeshResource: \(error)")
                return nil
            }
        }
    }
}
