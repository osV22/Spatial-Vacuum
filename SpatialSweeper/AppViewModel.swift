//
//  AppViewModel.swift
//  SpatialSweeper
//
//  Created by Ahmed G on 3/6/24.
//

import Foundation

enum VacuumType: String, CaseIterable, Identifiable {
    case virtual = "Virtual"
    case real = "Real"
    
    var id: String { self.rawValue }
}

// In an ideal world, we should separate VMs, possible todo...
class AppViewModel: ObservableObject {
    @Published var vacuumType: VacuumType = .virtual
}
