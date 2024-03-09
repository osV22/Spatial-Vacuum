//
//  SpatialSweeperApp.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/4/24.
//

import SwiftUI

@main
struct SpatialSweeperApp: App {
    @StateObject private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(viewModel: viewModel)
        }
    }
}
