# SpatialSweeper
Vision OS Spatial Vacuum 

## Helpers
- To see visualize hand position and direction:
```swift
// on updateFrame

let handViz = getVisualizedBox(name: "hand", color: .red, size: 0.02)
handViz.transform = transform
            
let handDirection = getVisualizedBox(name: "handDirection", color: .yellow, size: 0.02, parent: handViz)
handDirection.position = .init(x: -1.0, y: 0.0, z: 0.0)
``` 