//
//  ImmersiveView.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/4/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView<SceneController: SceneControllerProtocol>: View {
    @State var realityKitSceneController:SceneController?
    
    var body: some View {
        RealityView { content, attachments in
            self.realityKitSceneController = SceneController()
            await realityKitSceneController?.firstInit(&content, attachments: attachments)
        } update: { content, attachments in
            realityKitSceneController?.updateView(&content, attachments: attachments)
        } placeholder: {
            ProgressView()
        } attachments: {
            let _ = print("--attachments")
            Attachment(id: "emptyAttachment") {
            }
        }
        .gesture(SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded({ targetValue in
                realityKitSceneController?.onTapSpatial(targetValue)
            })
        )
        .onAppear {
            // appear happens before realitykit scene ccontroller init
        }
        .onDisappear {
            realityKitSceneController?.cleanup()
            realityKitSceneController = nil;
        }
    }
}
