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
import AVFoundation

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
    
    @Published var score: Int = 0
    var coinSound: AudioResource?
    
    struct CoinPlacement {
        var position: SIMD3<Float>
    }
    
    struct Triangle {
        // vert positions
        let positions: [SIMD3<Float>]
    }
    
    
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
    
    private var coinsGrid: [String: Bool] = [:]
    private var coins: [String: SIMD3<Float>] = [:]
    
    private var coinModel: Entity?
    private var handlePartModel: Entity?
    private var headPartModel: Entity?
    private var headConnector: Entity?
    private var scoreEntity: Entity?
    
    private var coinEntities: [String:Entity] = [:]
    
    private var coinCollisionGroup = CollisionGroup(rawValue: 1 << 0)
    private var vacuumCollisionGroup = CollisionGroup(rawValue: 1 << 1)
    
    init() {}
    
    public func firstInit(_ content: inout RealityViewContent, attachments: RealityViewAttachments) async {

        RotateSystem.registerSystem()
        RotateComponent.registerComponent()
        
        cancellable = NotificationCenter.default.publisher(for: Notification.Name("INJECTION_BUNDLE_NOTIFICATION"))
            .sink { _ in
                Task { @MainActor in
                    self.updateAfterInject()
                }
            }
        
        content.add(controllerRoot)
        
        if let scoreAttachment = attachments.entity(for: "score") {
            scoreEntity = scoreAttachment
            controllerRoot.addChild(scoreAttachment)
        }
        
        _ = content.subscribe(to: SceneEvents.Update.self, on: nil) { event in
            self.updateFrame(event)
        }
        
        _ = content.subscribe(to: CollisionEvents.Began.self, on: nil, self.onCollisionBegan)
        
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
                        entity.collision?.filter.group = .sceneUnderstanding
                        
                    if let classes = getClasses(meshAnchor: meshAnchor),
                            let meshResource = getMeshResourceFromAnchor(meshAnchor: meshAnchor) {
                            // Occlusion material will hide any content behind our scene mesh
                        let modelComponent = ModelComponent(mesh: meshResource, materials: [OcclusionMaterial()])
                            entity.components.set(modelComponent)
                        
                            updateCoinGrid(meshAnchor: meshAnchor, classes: classes)
                        }
                        meshEntities[meshAnchor.id] = entity
                        controllerRoot.addChild(entity)
                        
                    case .updated:
                        guard let entity = meshEntities[meshAnchor.id] else { continue }
                        
                        entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                        entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                        entity.collision?.filter.group = .sceneUnderstanding

                        
                    if let classes = getClasses(meshAnchor: meshAnchor),
                            let meshResource = getMeshResourceFromAnchor(meshAnchor: meshAnchor) {
                            let modelComponent = ModelComponent(mesh: meshResource, materials: [OcclusionMaterial()])
                            entity.components.set(modelComponent)
                        
                            updateCoinGrid(meshAnchor: meshAnchor, classes: classes)
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
        
        await setupSceneFirstTime()
    }
    

    private func playSound(for entity: Entity) {
        guard let audioFileURL = Bundle.main.url(forResource: "coin_collect", withExtension: "mp3") else {
            print("Audio file not found")
            return
        }
        
        do {
            // may add volume control later
            let audioResource = try AudioFileResource.load(contentsOf: audioFileURL, withName: "coinSound")
//            let audioPlaybackController = entity.playAudio(audioResource)
        } catch {
            print("Failed to load audio file: \(error)")
        }
    }
    
    private func onCollisionBegan(event: CollisionEvents.Began) {
        if event.entityA.name == "coin" {
            event.entityA.components[RotateComponent.self]?.isCollecting = true
            // play sound
            playSound(for: event.entityA)
            
            score += 1
        }
    }
    
    private func updateCoinGrid(meshAnchor: MeshAnchor, classes: [UInt8]) {
        // to ensure we have the right type of mesh
        guard meshAnchor.geometry.faces.primitive == .triangle,
              meshAnchor.geometry.vertices.format == .float3,
              let indexArray = getIndexArray(meshAnchor: meshAnchor) else {
            return
        }
        
        // TODO: This is not optimized b/c we're reading the position twice
        let positions = readFloat3FromMTL(source: meshAnchor.geometry.vertices)
        
        var triangles: [Triangle] = []
        
        for faceId in 0 ..< meshAnchor.geometry.faces.count {
            let classId = classes[faceId]
            if classId == 2 {
                let vert0: Int = Int(indexArray[faceId * 3])
                let vert1: Int = Int(indexArray[faceId * 3 + 1])
                let vert2: Int = Int(indexArray[faceId * 3 + 2])

                let points: [SIMD3<Float>] = [positions[vert0], positions[vert1], positions[vert2]]
                
                let transformed = points.map { input in
                    let result4: SIMD4<Float>  = meshAnchor.originFromAnchorTransform * simd_float4(input, 1.0)
                    return SIMD3<Float>(x: result4.x, y: result4.y, z: result4.z)
                }
                
                triangles.append(.init(positions: transformed))
            }
        }
        
        // Distance between the coins
        let cellSize: Float = 0.4
        
        // Go through every triangle and use the spatial DSA to mark spatial cubes from our user perspective
        for triangle in triangles {
            let bounds = triangleBoundingBox(of: triangle)
            
            let gridX = Int(bounds.minX / cellSize)
            let gridY = Int(bounds.minY / cellSize)
            let gridZ = Int(bounds.minZ / cellSize)
            
            let key = "\(gridX),\(gridY),\(gridZ)"
            
            if coinsGrid[key] == nil {
                coinsGrid[key] = true
                
                // Y should always be in the middle of the bounding box
                let trianglePosY = bounds.minY + (bounds.maxY - bounds.minY) / 2.0
                
                coins[key] = SIMD3<Float>(Float(gridX) * cellSize, trianglePosY, Float(gridZ) * cellSize)
            }
        }
    }
    
    private func triangleBoundingBox(of triangle: Triangle) -> (minX: Float, minY: Float, minZ: Float, maxX: Float, maxY: Float, maxZ: Float){
        var minX = Float.infinity
        var minY = Float.infinity
        var minZ = Float.infinity
        
        var maxX = -Float.infinity
        var maxY = -Float.infinity
        var maxZ = -Float.infinity
        
        for point in triangle.positions {
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            minZ = min(minZ, point.z)
            
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
            maxZ = max(maxZ, point.z)
        }
        
        return (minX, minY, minZ, maxX, maxY, maxZ)
    }
    
    private func getClasses(meshAnchor: MeshAnchor) -> [UInt8]? {
        guard let classifications = meshAnchor.geometry.classifications,
              classifications.format == .uchar else { return nil}
        
        let classbuffer = classifications.buffer.contents()
        let classTyped = classbuffer.bindMemory(to: UInt8.self, capacity: MemoryLayout<UInt8>.stride * classifications.count)
        
        let classBufferPointer = UnsafeBufferPointer(start: classTyped, count: classifications.count)
        
        return Array(classBufferPointer)
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
    
    private func getMeshResourceFromAnchor(meshAnchor: MeshAnchor, classes: [UInt8]? = nil) -> MeshResource? {
        guard meshAnchor.geometry.faces.primitive == .triangle,
              meshAnchor.geometry.vertices.format == .float3,
              let indexArray = getIndexArray(meshAnchor: meshAnchor) else {
                  return nil
              }
        
        var contents = MeshResource.Contents()
        var part = MeshResource.Part(id: "part", materialIndex: 0)
        
        let positions = readFloat3FromMTL(source: meshAnchor.geometry.vertices)
        
        // classes are used for classification/ floor detection
        var resultIndexArray = indexArray
        if let classes = classes {
            resultIndexArray = []
            for faceId in 0 ..< meshAnchor.geometry.faces.count {
                let classId = classes[faceId]
                // floor
                if classId == 2 {
                    let vert0: UInt32 = indexArray[faceId * 3]
                    let vert1: UInt32 = indexArray[faceId * 3 + 1]
                    let vert2: UInt32 = indexArray[faceId * 3 + 2]
                    
                    resultIndexArray.append(vert0)
                    resultIndexArray.append(vert1)
                    resultIndexArray.append(vert2)
                }
            }
        }
        
        part.triangleIndices = MeshBuffer(resultIndexArray)
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
    
    // triggered on EVERY FRAME
    public func updateFrame(_ event: SceneEvents.Update) {
        if worldTracking.state == .running {
            // AVP position
            if let headPosition = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()),
               let headContainer = controllerRoot.findEntity(named: "headContainer") {
                headContainer.transform = Transform(matrix: headPosition.originFromAnchorTransform)
            }
        }
        
        if handTracking.state == .running,
           let rightHand = handTracking.latestAnchors.rightHand,
           rightHand.isTracked,
           let scene = controllerRoot.scene,
           let headConnector = headConnector
        {
            let transform = Transform(matrix: rightHand.originFromAnchorTransform)
            
            let vacuumDirectionPoint: SIMD4<Float> = .init(x: -1.0, y: 0.0, z: 0.0, w: 1.0)
            
            let globalDirectionPoint = transform.matrix * vacuumDirectionPoint
            let globalDirectionPoint3: SIMD3<Float> = .init(x: globalDirectionPoint.x, y: globalDirectionPoint.y, z: globalDirectionPoint.z)
            
            handlePartModel?.position = transform.translation
            handlePartModel?.look(at: globalDirectionPoint3, from: transform.translation, relativeTo: controllerRoot)
            
            let globalPositionHeadConnector = headConnector.position(relativeTo: controllerRoot)
           
            headPartModel?.position = headConnector.position(relativeTo: controllerRoot)
            let direction = globalDirectionPoint3 - transform.translation
            headPartModel?.orientation = .init(angle: atan2(direction.x, direction.z), axis: .init(x: 0.0, y: 1.0, z: 0.0))
        
            // So the head does not clip through the floor
            let results = scene.raycast(from: transform.translation, to: globalPositionHeadConnector, mask: .sceneUnderstanding)
            if results.count > 0 {
                let offsetPosition = results[0].position - globalPositionHeadConnector
                headPartModel?.position += offsetPosition
                handlePartModel?.position += offsetPosition
            }
        }
        
        if let headPartModel = headPartModel,
           let headContainer = controllerRoot.findEntity(named: "headContainer") {
            scoreEntity?.look(at: headPartModel.position, from: headContainer.position, relativeTo: controllerRoot)
            scoreEntity?.position = headPartModel.position + .init(x: 0.0, y: 0.3, z: 0.0)
        }
        
        updateCoins()
    }
    
    private func getVisualizedBox(name: String, color: UIColor, size: Float, parent: Entity? = nil) -> Entity {
        if let targetEntity = controllerRoot.findEntity(named: name) {
            return targetEntity
        }
        
        let newEntity = Entity.createEntityBox(color, size: size)
        newEntity.name = name
        if let parent = parent {
            parent.addChild(newEntity)
        } else {
            controllerRoot.addChild(newEntity)
        }
        
        return newEntity
    }
    
    public func updateView(_ content: inout RealityViewContent, attachments: RealityViewAttachments) {
        print("ssc::updateview")
        scoreEntity = attachments.entity(for: "score")
    }
    
    func cleanup() {
        cancellable?.cancel()
        cancellable = nil
        mainScene = nil
    }
    
    public func onTapSpatial(_ targetValue: EntityTargetValue<SpatialTapGesture.Value>) {
    }
    
    private var frameCounter: Int = 0
    
    // avoid triggering this every frame for optimization purposes
    private func updateCoins() {
        frameCounter += 1
        if frameCounter < 20 { return }
        
        for (key, value) in coins {
            addCoin(key: key, position: value)
        }
    }
    
    private func addCoin(key: String, position: SIMD3<Float>) {
        guard coinEntities[key] == nil,
              let coin = coinModel?.clone(recursive: true) else {
            return
        }
        
        coin.orientation = .init(angle: .random(in: 0 ... 1), axis: .init(x: 0.0, y: 1.0, z: 0.0))
        coin.position = position
        controllerRoot.addChild(coin)
        coinEntities[key] = coin
        
    }
    
    func setupSceneFirstTime() async {
        
        if let scene = try? await Entity(named: "SweeperAssets", in: realityKitContentBundle) {
            
            if let coin = scene.findEntity(named: "coin") {
                coin.components.set(RotateComponent())
                // will collide with...
                coin.components[CollisionComponent.self]?.filter.mask = vacuumCollisionGroup
                // represent target group...
                coin.components[CollisionComponent.self]?.filter.group = coinCollisionGroup
                
                coinModel = coin
            }
            
            if let handlePart = scene.findEntity(named: "handlePart") {
                handlePart.components[CollisionComponent.self]?.filter.mask = coinCollisionGroup
                handlePart.components[CollisionComponent.self]?.filter.group = vacuumCollisionGroup
                
                handlePartModel = handlePart
                controllerRoot.addChild(handlePart)
                
                if let connector = handlePart.findEntity(named: "connector") {
                    headConnector = connector
                    
                }
            }
            
            if let headPart = scene.findEntity(named: "headPart") {
                headPart.components[CollisionComponent.self]?.filter.mask = coinCollisionGroup
                headPart.components[CollisionComponent.self]?.filter.group = vacuumCollisionGroup
                
                headPartModel = headPart
                controllerRoot.addChild(headPart)
            }
        }
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
