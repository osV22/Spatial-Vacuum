//
//  RotateSystem.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/4/24.
//

import Foundation
import RealityKit

class RotateSystem: System {
    static let query = EntityQuery(where: .has(RotateComponent.self))

    required init(scene: Scene) {
    }
    
    var entitiesToRemove: [Entity] = []
    
    func update(context: SceneUpdateContext) {
        let results = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        
        for result in results {
            if var component = result.components[RotateComponent.self] {
                var speedMultiplier: Float = component.isCollecting ? 10.0 : 1.0
                
                result.orientation = result.orientation * simd_quatf(angle: speedMultiplier * Float(context.deltaTime), axis: .init(x: 0.0, y: 1.0, z: 0.0))
                
                if component.isCollecting {
                    let progress = component.animationProgress + (1.0 - component.animationProgress) * 0.1
                    component.animationProgress = progress
                    
                    result.components.set(OpacityComponent(opacity: 1.0 - progress))
                    
                    if component.startPositionY == nil {
                        // to avoid colliding with the same obj multiple times
                        result.components.remove(CollisionComponent.self)
                        component.startPositionY = result.position.y
                        component.endPositionY = result.position.y + 0.2
                    }
                    
                    if let startPositionY = component.startPositionY,
                       let endPositionY = component.endPositionY {
                        result.position.y = startPositionY + (endPositionY - startPositionY) * progress
                    }
                    
                    result.components.set(component)
                    
                    // close to being over
                    if progress > 0.999999999 {
                        
                    }
                }
            }
        }
        
        for entity in entitiesToRemove {
            entity.components.remove(RotateComponent.self)
            entity.removeFromParent()
        }
    }
}
