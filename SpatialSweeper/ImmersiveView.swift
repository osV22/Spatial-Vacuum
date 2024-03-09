//
//  ImmersiveView.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/4/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @StateObject var realityKitSceneController: SweeperRealityController = SweeperRealityController()
    
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        RealityView { content, attachments in
            await realityKitSceneController.firstInit(&content, attachments: attachments, vacuumType: viewModel.vacuumType)
        } update: { content, attachments in
            realityKitSceneController.updateView(&content, attachments: attachments)
        } placeholder: {
            ProgressView()
        } attachments: {
            let _ = print("--attachments")
            Attachment(id: "score") {
                Text("\(realityKitSceneController.score)")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
        .gesture(SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded({ targetValue in
                realityKitSceneController.onTapSpatial(targetValue)
            })
        )
        .onAppear {
            // appear happens before realitykit scene ccontroller init
        }
        .onDisappear {
            realityKitSceneController.cleanup()
        }
    }
}
