//
//  VacuumTypeSelection.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/7/24.
//

import SwiftUI

struct VacuumTypeSelection: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Vacuum Type")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Picker("Vacuum Type", selection: $viewModel.vacuumType) {
                    ForEach(VacuumType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.palette)
                .padding(.top, 12)
            }
            .padding(.horizontal, geometry.size.width * 0.20)
        }
    }
}
