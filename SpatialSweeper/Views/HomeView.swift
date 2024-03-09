//
//  HomeView.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/7/24.
//

import SwiftUI

struct HomeView: View {
    
    @ObservedObject var viewModel: AppViewModel
    
    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    
    @State private var selectedVacuumType: VacuumType = .virtual
    
    @State private var isShowingAboutView = false
    
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        NavigationStack {
            VStack {
                CenteredTitle("Vision Vacuum")
                Spacer()
                
                VacuumTypeSelection(selectedVacuumType: $selectedVacuumType, viewModel: viewModel)
                
                PlayButton(showImmersiveSpace: $showImmersiveSpace)
                
                AboutButton {
                    isShowingAboutView = true
                }
                
                Spacer()
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $isShowingAboutView) {
                AboutView()
            }
            .onChange(of: showImmersiveSpace) { _, newValue in
                Task {
                    if newValue {
                        switch await openImmersiveSpace(id: "ImmersiveSpace") {
                        case .opened:
                            immersiveSpaceIsShown = true
                        case .error, .userCancelled:
                            fallthrough
                        @unknown default:
                            immersiveSpaceIsShown = false
                            showImmersiveSpace = false
                        }
                    } else if immersiveSpaceIsShown {
                        await dismissImmersiveSpace()
                        immersiveSpaceIsShown = false
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView(viewModel: AppViewModel())
}
