//
//  VacuumTypeSelection.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/7/24.
//

import SwiftUI

struct VacuumTypeSelection: View {
    @Binding var selectedVacuumType: VacuumType
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack {
            Text("Vacuum Type")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 50)
            
            Picker("Vacuum Type", selection: $selectedVacuumType) {
                ForEach(VacuumType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.palette)
            .padding(.top, 12)
        }
        .padding(.horizontal, 280)
        .onChange(of: selectedVacuumType) {
            viewModel.vacuumType = selectedVacuumType
        }
    }
}
