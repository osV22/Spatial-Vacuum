//
//  AppViewModel.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/6/24.
//

import Foundation

// In an ideal world, we should separate VMs, possible todo...
class AppViewModel: ObservableObject {
    @Published var vacuumType: VacuumType = .virtual
}
