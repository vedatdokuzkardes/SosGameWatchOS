//
//  GameViewModel.swift
//  TicTacToeGame
//
//  Created by Vedat Dokuzkardeş on 13.01.2024.
//

import SwiftUI
import Combine

final class GameViewModel: ObservableObject {
    
    private let localPlayerId: String = "123" // Replace with your actual logic to get the local player ID
        private var game: Game? // Re
    
    let columns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())]
    
    private let winPatterns: Set<Set<Int>> = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4,6]
    ]
    
    @Published private(set) var moves: [GameMove?] = Array(repeating: nil, count: 9)
    @Published private(set) var player1Score = 0
    @Published private(set) var player2Score = 0
    @Published private(set) var player1Name = ""
    @Published private(set) var player2Name = ""
    @Published private(set) var gameNotification = ""
    @Published private(set) var activePlayer: Player = .player1
    @Published private(set) var alertItem: AlertItem?
    @Published private(set) var isGameBoardDisabled = false
    @Published private(set) var showLoading = false
    
    @Published private var gameMode: GameMode
    @Published private var players: [Player]
    
    @Published var showAlert = false
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(with gameMode: GameMode) {
        self.gameMode = gameMode
        
        switch gameMode {
            
        case .vsHuman:
            self.players = [.player1, .player2]
        case .vsCPU:
            self.players = [.player1, .cpu]
        }
        
        gameNotification = "It's \(activePlayer.name)'s move"
        observeData()
    }
    
    private func observeData() {
        $players
            .map { $0.first?.name ?? "" }
            .assign(to: &$player1Name)
        
        $players
            .map { $0.last?.name ?? "" }
            .assign(to: &$player2Name)
        
    }
    

    
    private func setActivePlayerAndNotification(from game: Game) {
        if localPlayerId == game.player1Id {
            if localPlayerId == game.activePlayerId{
                self.activePlayer = .player1
                gameNotification = AppStrings.yourMove
            }else {
                gameNotification = "It's \(activePlayer.name)'s move"
            }
        }else {
            if localPlayerId == game.activePlayerId {
                self.activePlayer = .player2
                gameNotification = AppStrings.yourMove
            }else {
                gameNotification = "It's \(activePlayer.name)'s move"
            }
        }
    }
    
    func processMove(for position: Int) {
        if isSquareOccupied(in: moves, for: position) {return}
        
        moves[position] = GameMove(player: activePlayer, boardIndex: position)
    
        
        if checkForWinCondition(in: moves){
            showAlert(for: .finished)
            increaseScore()
            return
        }
        
        if checkForDraw(in: moves) {
            showAlert(for: .draw)
            return
        }
        
        activePlayer = players.first(where: { $0 != activePlayer })!
        
        if gameMode == .vsCPU && activePlayer == .cpu {
            isGameBoardDisabled = true
            computerMove()
        }
        
        gameNotification = "It's \(activePlayer.name)'s move"
    }
    
    private func computerMove() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [self] in
            processMove(for: getAIMovePosition(in: moves))
            isGameBoardDisabled = false
        }
    }
    
    private func getAIMovePosition(in moves: [GameMove?]) -> Int {
        
        let centerSquare = 4
        
        //if we can win, then take it
        let computerMoves = moves.compactMap { $0 }.filter { $0.player == .cpu }
        let computerPositions = Set(computerMoves.map { $0.boardIndex })
        
        
        if let position = getTheWinningSpot(for: computerPositions) {
            return position
        }
        
        //block the player
        let humanMoves = moves.compactMap { $0 }.filter { $0.player == .player1 }
        let humanPositions = Set(humanMoves.map { $0.boardIndex })
        
        if let position = getTheWinningSpot(for: humanPositions) {
            return position
        }
        
        //take the middle
        if !isSquareOccupied(in: moves, for: centerSquare) { return centerSquare }
        
        //take random spot
        var movePosition = Int.random(in: 0..<9)
        
        while isSquareOccupied(in: moves, for: movePosition) {
            movePosition = Int.random(in: 0..<9)
        }
        
        return movePosition
    }
    
    private func getTheWinningSpot(for positions: Set<Int>) -> Int? {
        for pattern in winPatterns {
            let winPositions = pattern.subtracting(positions)
            
            if winPositions.count == 1 && !isSquareOccupied(in: moves, for: winPositions.first!) {
                return winPositions.first!
            }
        }
        
        return nil
    }
    
    private func isSquareOccupied(in moves: [GameMove?], for index: Int) -> Bool{
        
        moves.contains(where: { $0?.boardIndex == index })
    }
    
    private func checkForDraw(in moves: [GameMove?]) -> Bool {
        moves.compactMap { $0 }.count == 9
    }
    
    private func checkForWinCondition(in moves: [GameMove?]) -> Bool {
        let playerMoves = moves.compactMap { $0 }.filter{ $0.player == activePlayer }
        let playerPositions = Set(playerMoves.map { $0.boardIndex })
        
        
        for pattern in  winPatterns where pattern.isSubset(of: playerPositions) { return true }
        return false
    }
    
    private func increaseScore() {
        if activePlayer == .player1 {
            player1Score += 1
        } else {
            player2Score += 1
        }
    }
    
    private func showAlert(for state: GameState) {
        gameNotification = state.name
        
        switch state {
            
        case .finished, .draw, .waitingForPlayer:
            let title = (state == .finished) ? "\(activePlayer.name) has won!" : state.name
            alertItem = AlertItem(title: title, message: AppStrings.tryRematch)
        case .quit:
            let title = state.name
            alertItem = AlertItem(title: title, message: "", buttonTitle: "OK")
            isGameBoardDisabled = true
        }
        
        showAlert = true
    }
    
    func resetGame() {
        activePlayer = .player1
        moves = Array(repeating: nil, count: 9)
        
    }

}
