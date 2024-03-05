//
//  SweeperRealityController.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/4/24.
//

import Foundation
import SwiftUI
import RealityKit
import RealityKitContent
import Combine
import ARKit

@MainActor
protocol SceneControllerProtocol {
    func firstInit(_ content : inout RealityViewContent, attachments: RealityViewAttachments) async
    func updateView(_ content : inout RealityViewContent, attachments: RealityViewAttachments)
    func cleanup()
    func onTapSpatial(_ targetValue: EntityTargetValue<SpatialTapGesture.Value>)
    init()
}

@MainActor
final class SweeperRealityController: ObservableObject, SceneControllerProtocol {
    private var cancellable: AnyCancellable?;
    
    private lazy var controllerRoot: Entity = {
        var result = Entity()
        result.name = "controllerRoot"
        return result
    }()
    
    private var mainScene: Entity?
    
    private var worldTracking = WorldTrackingProvider()
    private var handTracking = HandTrackingProvider()
    private var sceneReconstruction = SceneReconstructionProvider(modes: [.classification])
    private var session = ARKitSession()
    
    private var meshEntities = [UUID: ModelEntity]()
    
    private var colors: [UIColor] = [.red, .blue, .green, .yellow, .purple, .black, .brown, .cyan]
    
    init() {}
    
    public func firstInit(_ content: inout RealityViewContent, attachments: RealityViewAttachments) async {
        cancellable = NotificationCenter.default.publisher(for: Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))
            .sink { _ in
                Task { @MainActor in
                    self.updateAfterInject()
                }
            }
        
        content.add(controllerRoot)
        
        _ = content.subscribe(to: SceneEvents.Update.self, on: nil) { event in
            self.updateFrame(event)
        }
        
        Task {
            do {
                try await session.run([worldTracking, handTracking, sceneReconstruction])
            } catch {
                print("Error Can't start ARKit \(error)")
            }
        }
        
        Task {
            for await update in sceneReconstruction.anchorUpdates {
                let meshAnchor = update.anchor
                
                // gen static mech from the anchor
                guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { continue }
                
                switch update.event {
                    case .added:
                        // same as normal entity but it has a model component
                        let entity = ModelEntity()
                        entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                        // isStatic helps with resource optimization
                        entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                        
                        if let meshResource = getMeshResourceFromAnchor(meshAnchor: meshAnchor) {
                            // Occlusion material will hide any content behind our scene mesh
                            let modelComponent = ModelComponent(mesh: meshResource, materials: [OcclusionMaterial()])
                            entity.components.set(modelComponent)
                        }
                        meshEntities[meshAnchor.id] = entity
                        controllerRoot.addChild(entity)
                        
                    case .updated:
                        guard let entity = meshEntities[meshAnchor.id] else { continue }
                        
                        entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                        entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                        
                        if let meshResource = getMeshResourceFromAnchor(meshAnchor: meshAnchor) {
                            let modelComponent = ModelComponent(mesh: meshResource, materials: [OcclusionMaterial()])
                            entity.components.set(modelComponent)
                        }
                        
                    case .removed:
                        // remove from parent in this case the root controller
                        meshEntities[meshAnchor.id]?.removeFromParent()
                        meshEntities.removeValue(forKey: meshAnchor.id)
                    
                }
            }
        }
        
        let headContainer = Entity()
        headContainer.name = "headContainer"
        controllerRoot.addChild(headContainer)
        
        setupSceneFirstTime()
    }
    
    private func getIndexArray(meshAnchor: MeshAnchor) -> [UInt32]? {
        let indexBufferRawPointer = meshAnchor.geometry.faces.buffer.contents()
        
        let numIndicies = meshAnchor.geometry.faces.count * 3 // triangle
        
        let typedPointer = indexBufferRawPointer.bindMemory(to: UInt32.self, capacity: meshAnchor.geometry.faces.bytesPerIndex * numIndicies)
        
        let indexBufferPointer = UnsafeBufferPointer(start: typedPointer, count: numIndicies)
        return Array(indexBufferPointer)
    }
    
    private func readFloat3FromMTL(source: GeometrySource) -> [SIMD3<Float>] {
        var result:[SIMD3<Float>] = []
        
        let pointer = source.buffer.contents()
        for i in 0 ..< source.count {
            let dataPointer = pointer + source.offset + i * source.stride
            
            let pointer = dataPointer.bindMemory(to: SIMD3<Float>.self, capacity: MemoryLayout<SIMD3<Float>>.stride)
            result.append(pointer.pointee)
        }
        
        return result
    }
    
    private func getMeshResourceFromAnchor(meshAnchor: MeshAnchor) -> MeshResource? {
        guard meshAnchor.geometry.faces.primitive == .triangle,
              meshAnchor.geometry.vertices.format == .float3,
              let indexArray = getIndexArray(meshAnchor: meshAnchor) else {
                  return nil
              }
        
        var contents = MeshResource.Contents()
        var part = MeshResource.Part(id: "part", materialIndex: 0)
        
        let positions = readFloat3FromMTL(source: meshAnchor.geometry.vertices)
        
        part.triangleIndices = MeshBuffer(indexArray)
        part.positions = MeshBuffer(positions)
        
        let model = MeshResource.Model(id: "main", parts: [part])
        contents.models = [model]
        
        contents.instances = [.init(id: "instance", model: "main")]
        // finally create resource
        if let meshResource = try? MeshResource.generate(from: contents) {
            return meshResource
        }
        
        return nil
    }
    
    // Triggers on EVERY FRAME
    public func updateFrame(_ event: SceneEvents.Update) {
        if worldTracking.state == .running {
            // AVP position
            if let headPosition = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()),
               let headContainer = controllerRoot.findEntity(named: "headContainer") {
                headContainer.transform = Transform(matrix: headPosition.originFromAnchorTransform)
            }
        }
    }
    
    public func updateView(_ content: inout RealityViewContent, attachments: RealityViewAttachments) {
        print("ssc::updateview")
    }
    
    func cleanup() {
        cancellable?.cancel()
        cancellable = nil
        mainScene = nil
    }
    
    public func onTapSpatial(_ targetValue: EntityTargetValue<SpatialTapGesture>) {
    }
    
    
    public func onTapSpatial(_ targetValue: EntityTargetValue<SpatialTapGesture.Value>) {
    }
    
    func setupSceneFirstTime() {
      
    }
    
    func updateAfterInject() {
    }
    
}


extension Entity {
    static func createEntityBox(_ color: UIColor, size: Float) -> Entity {
        let box = Entity()
        
        let modelComponent = ModelComponent(mesh: .generateBox(size: size), materials: [UnlitMaterial(color: color)])
        box.components.set(modelComponent)
        return box
        
    }
}
