//
//  GameMode.swift
//  TicTacToeGame
//
//  Created by Vedat Dokuzkardeş on 12.01.2024.
//

import SwiftUI

enum GameMode: CaseIterable, Identifiable {
    
    var id: Self { return self }
    
    case vsHuman, vsCPU
    
    var name: String {
        switch self {
        case .vsHuman:
            return AppStrings.vsHuman
        case .vsCPU:
            return AppStrings.vsCpu
        }
    }
    
    var color: Color {
        switch self {
        case .vsHuman:
            return Color.cyan
        case .vsCPU:
            return Color.blue
        }
    }
}
