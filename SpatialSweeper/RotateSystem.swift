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
    
    func update(context: SceneUpdateContext) {
        let results = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        
        for result in results {
            result.orientation = result.orientation * simd_quatf(angle: 1.0 * Float(context.deltaTime), axis: .init(x: 0.0, y: 1.0, z: 0.0))
        }
    }
}
