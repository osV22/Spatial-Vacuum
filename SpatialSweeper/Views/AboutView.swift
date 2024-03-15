//
//  AboutView.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/7/24.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            CenteredTitle("About")
                .padding(.bottom, 20)
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text("""
                👋 Howdy!
                
                Hope you're enjoying this tiny thing and finally cleaned your room, buckaroo!

                If you liked this and have an opening for a mobile dev, I would love to join your team!
                3 YoE, 2 yrs as a mobile dev (Flutter/Dart). Based in Portland 🌲
                Got something exciting to work on or want to yell at me? ed@noble9.io or [(portfolio)](https://ahmedg.pages.dev) - Ahmed 😀
                """)
                .accentColor(.cyan)
                
                Spacer()
                Spacer()
                
                Text("Small Note...")
                    .font(.title3)
                Text("""
                Some real vacuum handles may cause erratic behavior with the hand tracking if a portion of your hand is obscured by the handle.
                    - As a result, the scoreboard is attached to your head when opting to use a 'Real' vacuum.
                """)
                
//                Spacer()
//                Spacer()
//                
//                Text("Contributions")
//                    .font(.title3)
//                Text("""
//                If you want to help add some features or contribute in any way, you're welcome to send a PR!
//                Here's the repo: [Spatial Vacuum on GitHub](https://github.com/osV22/SpatialSweeper)
//                Could especially use help with improving hand tracking issues for the real vacuum method, as vacuum handles covering a portion of your hand can cause erratic tracking behavior.
//                """)
//                .accentColor(.cyan)
//                
                Spacer()
                Spacer()
                
                Text("Credits")
                    .font(.title3)
                Text("""
                - [the_gonchar (twitter)](https://twitter.com/the_gonchar)
                    - For his awesome tutorial this entire thing is based on.
                    - There's a repository available if you prefer to fork it directly. However, I followed the tutorial to learn more about RealityKit, and I cannot recommend it enough!
                - [Coin Model by AB (sketchfab)](https://sketchfab.com/3d-models/mario-coin-fdfa74ede6c34d90afca650a51bda6de)
                - [Virtual Vacuum Model by annzep (sketchfab)](https://sketchfab.com/3d-models/vacuum-cleaner-c7fe3bb62ddc42d0afec14551a821242)
                    - Used the middle model and stripped away as much unnecessary content as possible.
                - [Coin Collect Sound by Pixabay (Pixabay)](https://pixabay.com/sound-effects/collectcoin-6075/)
                """)
                .accentColor(.cyan)
                
                Spacer()
                Spacer()
                
                Text("Privacy Policy")
                    .font(.title3)
                Text("""
                - N/A
                    - App does not collect any information. Have Fun!
                """)

            }
            .padding(.bottom, 80)
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    AboutView()
}
