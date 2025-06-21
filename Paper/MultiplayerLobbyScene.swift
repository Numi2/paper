//
//  MultiplayerLobbyScene.swift
//  Paper
//
//  Multiplayer Lobby Scene for creating and joining games
//

import SpriteKit
import GameplayKit

class MultiplayerLobbyScene: SKScene, WebSocketManagerDelegate {
    
    // MARK: - UI Elements
    private var titleLabel: SKLabelNode!
    private var playerNameLabel: SKLabelNode!
    private var createGameButton: SKLabelNode!
    private var joinGameButton: SKLabelNode!
    private var gameIdTextField: SKLabelNode!
    private var connectionStatusLabel: SKLabelNode!
    private var playersListLabel: SKLabelNode!
    private var startGameButton: SKLabelNode!
    private var backButton: SKLabelNode!
    
    // MARK: - Game State
    private let webSocketManager = WebSocketManager.shared
    private var playerId: String
    private var playerName: String
    private var currentGameId: String?
    private var isInGame = false
    private var connectedPlayers: [PlayerInfo] = []
    
    // MARK: - Initialization
    
    init(size: CGSize, playerName: String) {
        self.playerId = UUID().uuidString
        self.playerName = playerName.isEmpty ? "Player_\(Int.random(in: 1000...9999))" : playerName
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.playerId = UUID().uuidString
        self.playerName = "Player_\(Int.random(in: 1000...9999))"
        super.init(coder: aDecoder)
    }
    
    override func didMove(to view: SKView) {
        setupUI()
        setupWebSocket()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        
        // Title
        titleLabel = SKLabelNode(fontNamed: "Arial-Bold")
        titleLabel.text = "Paper Airplane Multiplayer"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height - 100)
        addChild(titleLabel)
        
        // Player name display
        playerNameLabel = SKLabelNode(fontNamed: "Arial")
        playerNameLabel.text = "Player: \(playerName)"
        playerNameLabel.fontSize = 18
        playerNameLabel.fontColor = .lightGray
        playerNameLabel.position = CGPoint(x: size.width/2, y: size.height - 140)
        addChild(playerNameLabel)
        
        // Connection status
        connectionStatusLabel = SKLabelNode(fontNamed: "Arial")
        connectionStatusLabel.text = "Connecting..."
        connectionStatusLabel.fontSize = 16
        connectionStatusLabel.fontColor = .yellow
        connectionStatusLabel.position = CGPoint(x: size.width/2, y: size.height - 170)
        addChild(connectionStatusLabel)
        
        // Create Game Button
        createGameButton = createButton(text: "Create Game", 
                                      position: CGPoint(x: size.width/2, y: size.height/2 + 50))
        addChild(createGameButton)
        
        // Join Game Button
        joinGameButton = createButton(text: "Join Game", 
                                    position: CGPoint(x: size.width/2, y: size.height/2))
        addChild(joinGameButton)
        
        // Game ID input (placeholder)
        gameIdTextField = SKLabelNode(fontNamed: "Arial")
        gameIdTextField.text = "Game ID: (Tap to enter)"
        gameIdTextField.fontSize = 16
        gameIdTextField.fontColor = .lightGray
        gameIdTextField.position = CGPoint(x: size.width/2, y: size.height/2 - 50)
        addChild(gameIdTextField)
        
        // Players list
        playersListLabel = SKLabelNode(fontNamed: "Arial")
        playersListLabel.text = ""
        playersListLabel.fontSize = 14
        playersListLabel.fontColor = .white
        playersListLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 120)
        playersListLabel.numberOfLines = 0
        addChild(playersListLabel)
        
        // Start Game Button (initially hidden)
        startGameButton = createButton(text: "Start Game", 
                                     position: CGPoint(x: size.width/2, y: size.height/2 - 200))
        startGameButton.isHidden = true
        addChild(startGameButton)
        
        // Back Button
        backButton = createButton(text: "Back to Single Player", 
                                position: CGPoint(x: size.width/2, y: 100))
        addChild(backButton)
        
        updateUI()
    }
    
    private func createButton(text: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(fontNamed: "Arial-Bold")
        button.text = text
        button.fontSize = 20
        button.fontColor = .white
        button.position = position
        
        // Add background
        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 40), cornerRadius: 8)
        background.fillColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        background.strokeColor = .white
        background.lineWidth = 2
        background.position = CGPoint.zero
        background.zPosition = -1
        button.addChild(background)
        
        return button
    }
    
    private func updateUI() {
        // Show/hide elements based on connection and game state
        if isInGame {
            createGameButton.isHidden = true
            joinGameButton.isHidden = true
            gameIdTextField.isHidden = true
            startGameButton.isHidden = connectedPlayers.count < 2
            
            // Update players list
            var playersText = "Players in game:\n"
            for player in connectedPlayers {
                playersText += "• \(player.name)\n"
            }
            playersListLabel.text = playersText
        } else {
            createGameButton.isHidden = false
            joinGameButton.isHidden = false
            gameIdTextField.isHidden = false
            startGameButton.isHidden = true
            playersListLabel.text = ""
        }
    }
    
    // MARK: - WebSocket Setup
    
    private func setupWebSocket() {
        webSocketManager.delegate = self
        webSocketManager.connect()
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node == createGameButton {
                createGame()
            } else if node == joinGameButton {
                joinGame()
            } else if node == startGameButton && !startGameButton.isHidden {
                startMultiplayerGame()
            } else if node == backButton {
                backToSinglePlayer()
            } else if node == gameIdTextField {
                showGameIdInput()
            }
        }
    }
    
    // MARK: - Game Actions
    
    private func createGame() {
        guard webSocketManager.delegate != nil else {
            showAlert("Not connected to server")
            return
        }
        
        webSocketManager.createGame(playerId: playerId, playerName: playerName)
        connectionStatusLabel.text = "Creating game..."
    }
    
    private func joinGame() {
        // For now, we'll use a hardcoded game ID
        // In a real implementation, you'd want a proper text input field
        let gameId = "demo_game_123"
        webSocketManager.joinGame(gameId: gameId, playerId: playerId, playerName: playerName)
        connectionStatusLabel.text = "Joining game..."
    }
    
    private func showGameIdInput() {
        // This is a simplified implementation
        // In a real app, you'd want to show an actual text input dialog
        gameIdTextField.text = "Game ID: demo_game_123"
    }
    
    private func startMultiplayerGame() {
        guard let gameId = currentGameId else { return }
        
        // Transition to multiplayer game scene
        let multiplayerScene = MultiplayerGameScene(size: self.size, 
                                                   gameId: gameId, 
                                                   playerId: playerId, 
                                                   playerName: playerName)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(multiplayerScene, transition: transition)
    }
    
    private func backToSinglePlayer() {
        if isInGame {
            webSocketManager.send(MultiplayerMessage(type: .leaveGame, 
                                                   gameId: currentGameId, 
                                                   playerId: playerId, 
                                                   playerName: playerName, 
                                                   data: nil))
        }
        
        // Return to single player game
        let gameScene = GameScene(size: self.size)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }
    
    private func showAlert(_ message: String) {
        connectionStatusLabel.text = message
        connectionStatusLabel.fontColor = .red
        
        // Reset after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.connectionStatusLabel.fontColor = .yellow
        }
    }
    
    // MARK: - WebSocketManagerDelegate
    
    func webSocketDidConnect() {
        connectionStatusLabel.text = "Connected to server"
        connectionStatusLabel.fontColor = .green
    }
    
    func webSocketDidDisconnect() {
        connectionStatusLabel.text = "Disconnected from server"
        connectionStatusLabel.fontColor = .red
        isInGame = false
        currentGameId = nil
        connectedPlayers.removeAll()
        updateUI()
    }
    
    func webSocketDidReceiveMessage(_ message: MultiplayerMessage) {
        switch message.type {
        case .gameCreated:
            currentGameId = message.gameId
            isInGame = true
            connectionStatusLabel.text = "Game created! ID: \(message.gameId ?? "Unknown")"
            connectionStatusLabel.fontColor = .green
            updateUI()
            
        case .gameJoined:
            currentGameId = message.gameId
            isInGame = true
            connectionStatusLabel.text = "Joined game!"
            connectionStatusLabel.fontColor = .green
            updateUI()
            
        case .playerJoined:
            if case .gameRoom(let roomData) = message.data {
                connectedPlayers = roomData.players
                updateUI()
            }
            
        case .playerLeft:
            if case .gameRoom(let roomData) = message.data {
                connectedPlayers = roomData.players
                updateUI()
            }
            
        case .gameStart:
            startMultiplayerGame()
            
        default:
            break
        }
    }
    
    func webSocketDidReceiveError(_ error: Error) {
        showAlert("Connection error: \(error.localizedDescription)")
    }
}