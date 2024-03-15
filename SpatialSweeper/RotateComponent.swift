//
//  RotateComponent.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/4/24.
//

import Foundation
import RealityKit

struct RotateComponent: Component {
    var isCollecting: Bool = false
    var animationProgress: Float  = 0.0
    
    var startPositionY: Float?
    var endPositionY: Float?
}
