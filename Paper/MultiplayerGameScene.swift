//
//  MultiplayerGameScene.swift
//  Paper
//
//  Multiplayer Game Scene with real-time player synchronization
//

import SpriteKit
import GameplayKit

class MultiplayerGameScene: SKScene, SKPhysicsContactDelegate, WebSocketManagerDelegate {
    
    // MARK: - Game Objects
    private var localPlayerAirplane: SKSpriteNode! // Local player's airplane
    private var remotePlayerAirplanes: [String: SKSpriteNode] = [:] // Remote players' airplanes
    private var cameraNode: SKCameraNode!
    private var worldNode: SKNode!
    
    // MARK: - Multiplayer State
    private let webSocketManager = WebSocketManager.shared
    private let gameId: String
    private let playerId: String
    private let playerName: String
    private var gameStarted = false
    private var playerColor: UIColor = .white
    private var playerStates: [String: PlayerState] = [:]
    
    // MARK: - Game State
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    private var gameOver = false
    private var leaderboardLabel: SKLabelNode!
    
    // MARK: - Physics Categories
    let airplaneCategory: UInt32 = 0x1 << 0
    let obstacleCategory: UInt32 = 0x1 << 1
    let collectibleCategory: UInt32 = 0x1 << 2
    let groundCategory: UInt32 = 0x1 << 3
    
    // MARK: - Controls & Physics
    private var touchLocation: CGPoint?
    private var airplaneVelocity = CGVector.zero
    private let maxVelocity: CGFloat = 400
    private let acceleration: CGFloat = 800
    private let drag: CGFloat = 0.98
    
    // MARK: - Wind Effects
    private var windForce = CGVector.zero
    private var windTimer: TimeInterval = 0
    
    // MARK: - Network Timing
    private var lastPositionUpdate: TimeInterval = 0
    private let positionUpdateInterval: TimeInterval = 1.0/30.0 // 30 updates per second
    
    // MARK: - Parallax Layers
    private var backgroundLayer: SKNode!
    private var midgroundLayer: SKNode!
    private var foregroundLayer: SKNode!
    private var backgroundTiles: [SKSpriteNode] = []
    private var midgroundTiles: [SKSpriteNode] = []
    private var foregroundTiles: [SKSpriteNode] = []
    private let tileGridSize = 3
    
    // MARK: - Initialization
    
    init(size: CGSize, gameId: String, playerId: String, playerName: String) {
        self.gameId = gameId
        self.playerId = playerId
        self.playerName = playerName
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        setupPhysics()
        setupWorld()
        setupLocalPlayer()
        setupCamera()
        setupUI()
        setupBackground()
        setupWebSocket()
        
        // Assign player color based on index
        assignPlayerColor()
    }
    
    // MARK: - Setup Methods
    
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }
    
    private func setupWorld() {
        worldNode = SKNode()
        addChild(worldNode)
        
        backgroundLayer = SKNode()
        midgroundLayer = SKNode()
        foregroundLayer = SKNode()
        
        worldNode.addChild(backgroundLayer)
        worldNode.addChild(midgroundLayer)
        worldNode.addChild(foregroundLayer)
    }
    
    private func setupLocalPlayer() {
        localPlayerAirplane = createPaperAirplane(color: playerColor, playerId: playerId)
        localPlayerAirplane.position = CGPoint(x: 0, y: 0)
        worldNode.addChild(localPlayerAirplane)
    }
    
    private func createPaperAirplane(color: UIColor, playerId: String) -> SKSpriteNode {
        let airplane = SKSpriteNode(color: color, size: CGSize(width: 60, height: 40))
        airplane.name = "airplane_\(playerId)"
        airplane.zPosition = 10
        
        // Create airplane shape
        let airplaneShape = SKShapeNode()
        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: -30, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 15))
        path.addLine(to: CGPoint(x: 20, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -15))
        path.addLine(to: CGPoint(x: -30, y: 0))
        
        airplaneShape.path = path
        airplaneShape.fillColor = color
        airplaneShape.strokeColor = color.withAlphaComponent(0.7)
        airplaneShape.lineWidth = 2
        airplane.addChild(airplaneShape)
        
        // Add player name label
        let nameLabel = SKLabelNode(fontNamed: "Arial")
        nameLabel.text = playerId == self.playerId ? playerName : "Player"
        nameLabel.fontSize = 12
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: 25)
        nameLabel.zPosition = 1
        airplane.addChild(nameLabel)
        
        // Add physics body only for local player
        if playerId == self.playerId {
            let airplaneBody = SKPhysicsBody(rectangleOf: airplane.size)
            airplaneBody.categoryBitMask = airplaneCategory
            airplaneBody.contactTestBitMask = obstacleCategory | collectibleCategory
            airplaneBody.collisionBitMask = groundCategory
            airplaneBody.affectedByGravity = false
            airplaneBody.allowsRotation = true
            airplaneBody.linearDamping = 0.5
            airplaneBody.angularDamping = 0.8
            airplane.physicsBody = airplaneBody
        }
        
        return airplane
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = localPlayerAirplane.position
    }
    
    private func setupUI() {
        // Score label
        scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -frame.width/2 + 100, y: frame.height/2 - 50)
        scoreLabel.zPosition = 100
        cameraNode.addChild(scoreLabel)
        
        // Leaderboard
        leaderboardLabel = SKLabelNode(fontNamed: "Arial")
        leaderboardLabel.text = "Players:"
        leaderboardLabel.fontSize = 16
        leaderboardLabel.fontColor = .white
        leaderboardLabel.position = CGPoint(x: frame.width/2 - 100, y: frame.height/2 - 50)
        leaderboardLabel.zPosition = 100
        leaderboardLabel.horizontalAlignmentMode = .right
        cameraNode.addChild(leaderboardLabel)
        
        // Connection status
        let connectionLabel = SKLabelNode(fontNamed: "Arial")
        connectionLabel.text = "Multiplayer Mode"
        connectionLabel.fontSize = 14
        connectionLabel.fontColor = .green
        connectionLabel.position = CGPoint(x: 0, y: frame.height/2 - 30)
        connectionLabel.zPosition = 100
        cameraNode.addChild(connectionLabel)
    }
    
    private func setupBackground() {
        // Reuse background setup from original game
        backgroundLayer.removeAllChildren()
        backgroundTiles.removeAll()
        midgroundLayer.removeAllChildren()
        midgroundTiles.removeAll()
        foregroundLayer.removeAllChildren()
        foregroundTiles.removeAll()
        
        let tileWidth = frame.width
        let tileHeight = frame.height
        let colors: [UIColor] = [
            UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        ]
        
        // Background tiles
        for i in 0..<tileGridSize {
            for j in 0..<tileGridSize {
                let skyNode = SKSpriteNode(color: .clear, size: CGSize(width: tileWidth, height: tileHeight))
                skyNode.anchorPoint = CGPoint(x: 0, y: 0)
                skyNode.position = CGPoint(x: CGFloat(i) * tileWidth - tileWidth, y: CGFloat(j) * tileHeight - tileHeight)
                skyNode.zPosition = -100
                
                for (index, color) in colors.enumerated() {
                    let skySection = SKSpriteNode(color: color, size: CGSize(width: tileWidth, height: tileHeight / CGFloat(colors.count)))
                    skySection.position = CGPoint(x: tileWidth/2, y: CGFloat(index) * tileHeight / CGFloat(colors.count) + tileHeight/(2*CGFloat(colors.count)))
                    skySection.zPosition = -100 + CGFloat(index)
                    skyNode.addChild(skySection)
                }
                
                backgroundLayer.addChild(skyNode)
                backgroundTiles.append(skyNode)
            }
        }
    }
    
    private func setupWebSocket() {
        webSocketManager.delegate = self
    }
    
    private func assignPlayerColor() {
        let colorIndex = abs(playerId.hashValue) % MultiplayerGameConfig.playerColors.count
        let hexColor = MultiplayerGameConfig.playerColors[colorIndex]
        playerColor = UIColor(hex: hexColor) ?? .white
        
        // Update local player color
        if let shape = localPlayerAirplane.children.first(where: { $0 is SKShapeNode }) as? SKShapeNode {
            shape.fillColor = playerColor
            shape.strokeColor = playerColor.withAlphaComponent(0.7)
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver {
            returnToLobby()
            return
        }
        
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = nil
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        if gameOver { return }
        
        updateWind(currentTime)
        updateLocalPlayerMovement()
        updateCamera()
        moveWorld()
        updateScore()
        updateLeaderboard()
        
        // Send position updates to other players
        if currentTime - lastPositionUpdate > positionUpdateInterval {
            sendPlayerPosition()
            lastPositionUpdate = currentTime
        }
    }
    
    private func updateWind(_ currentTime: TimeInterval) {
        windTimer += 1.0/60.0
        
        if windTimer > 3.0 {
            windTimer = 0
            windForce = CGVector(
                dx: CGFloat.random(in: -50...50),
                dy: CGFloat.random(in: -30...30)
            )
        }
        
        airplaneVelocity.dx += windForce.dx * 0.01
        airplaneVelocity.dy += windForce.dy * 0.01
    }
    
    private func updateLocalPlayerMovement() {
        guard let touchLocation = touchLocation else { return }
        
        let worldTouchLocation = convert(touchLocation, to: worldNode)
        let direction = CGVector(dx: worldTouchLocation.x - localPlayerAirplane.position.x,
                                dy: worldTouchLocation.y - localPlayerAirplane.position.y)
        
        let length = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        if length > 0 {
            let normalizedDirection = CGVector(dx: direction.dx / length, dy: direction.dy / length)
            
            airplaneVelocity.dx += normalizedDirection.dx * acceleration * CGFloat(1.0/60.0)
            airplaneVelocity.dy += normalizedDirection.dy * acceleration * CGFloat(1.0/60.0)
        }
        
        airplaneVelocity.dx *= drag
        airplaneVelocity.dy *= drag
        
        let currentSpeed = sqrt(airplaneVelocity.dx * airplaneVelocity.dx + airplaneVelocity.dy * airplaneVelocity.dy)
        if currentSpeed > maxVelocity {
            let scale = maxVelocity / currentSpeed
            airplaneVelocity.dx *= scale
            airplaneVelocity.dy *= scale
        }
        
        localPlayerAirplane.position.y += airplaneVelocity.dy * CGFloat(1.0/60.0)
        
        let angle = atan2(airplaneVelocity.dy, airplaneVelocity.dx)
        localPlayerAirplane.zRotation = angle
    }
    
    private func updateCamera() {
        cameraNode.position = localPlayerAirplane.position
    }
    
    private func moveWorld() {
        let scrollSpeed = airplaneVelocity.dx * CGFloat(1.0/60.0)
        
        worldNode.enumerateChildNodes(withName: "obstacle") { node, _ in
            node.position.x -= scrollSpeed
        }
        worldNode.enumerateChildNodes(withName: "collectible") { node, _ in
            node.position.x -= scrollSpeed
        }
    }
    
    private func updateScore() {
        score += 1
        scoreLabel.text = "Score: \(score)"
    }
    
    private func updateLeaderboard() {
        var leaderboardText = "Players:\n"
        let sortedPlayers = playerStates.values.sorted { $0.score > $1.score }
        
        for (index, player) in sortedPlayers.enumerated() {
            let isLocal = player.id == playerId
            let prefix = isLocal ? "★ " : "  "
            let statusIcon = player.isAlive ? "✈️" : "💥"
            leaderboardText += "\(prefix)\(player.name): \(player.score) \(statusIcon)\n"
        }
        
        leaderboardLabel.text = leaderboardText
    }
    
    private func sendPlayerPosition() {
        webSocketManager.sendPlayerPosition(
            gameId: gameId,
            playerId: playerId,
            position: localPlayerAirplane.position,
            velocity: airplaneVelocity,
            rotation: localPlayerAirplane.zRotation
        )
    }
    
    private func updateRemotePlayer(_ playerState: PlayerState) {
        let playerId = playerState.id
        
        // Create remote player if it doesn't exist
        if remotePlayerAirplanes[playerId] == nil {
            let color = UIColor(hex: playerState.color) ?? .white
            let remoteAirplane = createPaperAirplane(color: color, playerId: playerId)
            remotePlayerAirplanes[playerId] = remoteAirplane
            worldNode.addChild(remoteAirplane)
            
            // Update name label
            if let nameLabel = remoteAirplane.children.first(where: { $0 is SKLabelNode }) as? SKLabelNode {
                nameLabel.text = playerState.name
            }
        }
        
        // Update position and rotation
        if let remoteAirplane = remotePlayerAirplanes[playerId] {
            // Smooth interpolation for remote players
            let targetPosition = playerState.position.cgPoint
            let currentPosition = remoteAirplane.position
            let interpolationFactor: CGFloat = 0.1
            
            remoteAirplane.position = CGPoint(
                x: currentPosition.x + (targetPosition.x - currentPosition.x) * interpolationFactor,
                y: currentPosition.y + (targetPosition.y - currentPosition.y) * interpolationFactor
            )
            remoteAirplane.zRotation = playerState.rotation
            
            // Update visibility based on alive status
            remoteAirplane.alpha = playerState.isAlive ? 1.0 : 0.5
        }
        
        // Update player state
        playerStates[playerId] = playerState
    }
    
    private func removeRemotePlayer(_ playerId: String) {
        remotePlayerAirplanes[playerId]?.removeFromParent()
        remotePlayerAirplanes.removeValue(forKey: playerId)
        playerStates.removeValue(forKey: playerId)
    }
    
    private func returnToLobby() {
        let lobbyScene = MultiplayerLobbyScene(size: self.size, playerName: playerName)
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(lobbyScene, transition: transition)
    }
    
    // MARK: - Physics Contact Delegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == airplaneCategory | obstacleCategory {
            handlePlayerCrash()
        } else if collision == airplaneCategory | collectibleCategory {
            if let collectible = contact.bodyA.categoryBitMask == collectibleCategory ? contact.bodyA.node : contact.bodyB.node {
                handleCollectibleGathered(collectible)
            }
        }
    }
    
    private func handlePlayerCrash() {
        gameOver = true
        
        // Send crash event to other players
        let crashEvent = GameEventData(eventType: .playerCrashed, position: localPlayerAirplane.position)
        webSocketManager.sendGameEvent(gameId: gameId, playerId: playerId, event: crashEvent)
        
        // Show game over UI
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-Bold")
        gameOverLabel.text = "Game Over!"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 0)
        gameOverLabel.zPosition = 200
        cameraNode.addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.text = "Tap to return to lobby"
        restartLabel.fontSize = 20
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -50)
        restartLabel.zPosition = 200
        cameraNode.addChild(restartLabel)
    }
    
    private func handleCollectibleGathered(_ collectible: SKNode) {
        collectible.removeFromParent()
        score += 50
        
        let collectEvent = GameEventData(eventType: .collectibleGathered, position: collectible.position, value: 50)
        webSocketManager.sendGameEvent(gameId: gameId, playerId: playerId, event: collectEvent)
    }
    
    // MARK: - WebSocketManagerDelegate
    
    func webSocketDidConnect() {
        print("Connected to multiplayer server")
    }
    
    func webSocketDidDisconnect() {
        print("Disconnected from multiplayer server")
        returnToLobby()
    }
    
    func webSocketDidReceiveMessage(_ message: MultiplayerMessage) {
        switch message.type {
        case .playerMove:
            if case .playerMovement(let movementData) = message.data,
               message.playerId != playerId {
                let playerState = PlayerState(
                    id: message.playerId,
                    name: message.playerName ?? "Player",
                    position: movementData.position,
                    velocity: movementData.velocity,
                    rotation: movementData.rotation,
                    score: playerStates[message.playerId]?.score ?? 0,
                    isAlive: true,
                    color: playerStates[message.playerId]?.color ?? "#FFFFFF"
                )
                updateRemotePlayer(playerState)
            }
            
        case .gameEvent:
            if case .gameEvent(let eventData) = message.data {
                handleRemoteGameEvent(eventData, from: message.playerId)
            }
            
        case .playerLeft:
            removeRemotePlayer(message.playerId)
            
        case .gameState:
            if case .gameState(let gameStateData) = message.data {
                // Update all player states
                for playerState in gameStateData.players {
                    if playerState.id != playerId {
                        updateRemotePlayer(playerState)
                    }
                }
            }
            
        default:
            break
        }
    }
    
    private func handleRemoteGameEvent(_ event: GameEventData, from playerId: String) {
        switch event.eventType {
        case .playerCrashed:
            if var playerState = playerStates[playerId] {
                playerState.isAlive = false
                updateRemotePlayer(playerState)
            }
            
        case .collectibleGathered:
            if var playerState = playerStates[playerId] {
                playerState.score += event.value ?? 0
                updateRemotePlayer(playerState)
            }
            
        default:
            break
        }
    }
    
    func webSocketDidReceiveError(_ error: Error) {
        print("WebSocket error: \(error)")
    }
}

// MARK: - UIColor Extension

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    a = 1.0
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}