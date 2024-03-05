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
        
        let headContainer = Entity()
        headContainer.name = "headContainer"
        controllerRoot.addChild(headContainer)
        
        setupSceneFirstTime()
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
        if let headContainer = controllerRoot.findEntity(named: "headContainer") {
            let box = Entity.createEntityBox(.green, size: 0.1)
            headContainer.addChild(box)
            box.position.z = -0.4
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
