//
//  CenteredTitle.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/7/24.
//

import SwiftUI

struct CenteredTitle: View {
    let title: String
    
    init(_ title: String) {
           self.title = title
    }
    
    var body: some View {
        Text(title)
            .font(.largeTitle)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    CenteredTitle("Some Title")
}
