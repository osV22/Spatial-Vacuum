//
//  ContentView.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/4/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        HomeView(viewModel: viewModel)
    }
}
