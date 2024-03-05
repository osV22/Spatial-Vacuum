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
        
        setupSceneFirstTime()
    }
    
    public func updateFrame(_ event: SceneEvents.Update) {
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


