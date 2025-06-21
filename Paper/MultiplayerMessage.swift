//
//  MultiplayerMessage.swift
//  Paper
//
//  Multiplayer Message Protocol Definitions
//

import Foundation
import SpriteKit

// MARK: - Message Types

enum MessageType: String, Codable {
    case createGame = "create_game"
    case joinGame = "join_game"
    case leaveGame = "leave_game"
    case gameCreated = "game_created"
    case gameJoined = "game_joined"
    case playerJoined = "player_joined"
    case playerLeft = "player_left"
    case gameStart = "game_start"
    case playerMove = "player_move"
    case gameEvent = "game_event"
    case gameState = "game_state"
    case gameOver = "game_over"
    case ping = "ping"
    case pong = "pong"
}

// MARK: - Main Message Structure

struct MultiplayerMessage: Codable {
    let type: MessageType
    let gameId: String?
    let playerId: String
    let playerName: String?
    let timestamp: TimeInterval
    let data: MessageDataWrapper?
    
    init(type: MessageType, gameId: String?, playerId: String, playerName: String?, data: MessageData?) {
        self.type = type
        self.gameId = gameId
        self.playerId = playerId
        self.playerName = playerName
        self.timestamp = Date().timeIntervalSince1970
        
        // Wrap the data based on its type
        if let playerMovement = data as? PlayerMovementData {
            self.data = .playerMovement(playerMovement)
        } else if let gameEvent = data as? GameEventData {
            self.data = .gameEvent(gameEvent)
        } else if let gameState = data as? GameStateData {
            self.data = .gameState(gameState)
        } else if let gameRoom = data as? GameRoomData {
            self.data = .gameRoom(gameRoom)
        } else {
            self.data = nil
        }
    }
}

// MARK: - Message Data Protocol

protocol MessageData: Codable {}

// MARK: - Message Data Wrapper

enum MessageDataWrapper: Codable {
    case playerMovement(PlayerMovementData)
    case gameEvent(GameEventData)
    case gameState(GameStateData)
    case gameRoom(GameRoomData)
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "playerMovement":
            let data = try container.decode(PlayerMovementData.self, forKey: .data)
            self = .playerMovement(data)
        case "gameEvent":
            let data = try container.decode(GameEventData.self, forKey: .data)
            self = .gameEvent(data)
        case "gameState":
            let data = try container.decode(GameStateData.self, forKey: .data)
            self = .gameState(data)
        case "gameRoom":
            let data = try container.decode(GameRoomData.self, forKey: .data)
            self = .gameRoom(data)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown data type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .playerMovement(let data):
            try container.encode("playerMovement", forKey: .type)
            try container.encode(data, forKey: .data)
        case .gameEvent(let data):
            try container.encode("gameEvent", forKey: .type)
            try container.encode(data, forKey: .data)
        case .gameState(let data):
            try container.encode("gameState", forKey: .type)
            try container.encode(data, forKey: .data)
        case .gameRoom(let data):
            try container.encode("gameRoom", forKey: .type)
            try container.encode(data, forKey: .data)
        }
    }
}

// MARK: - Player Movement Data

struct PlayerMovementData: MessageData {
    let position: CGPointCodable
    let velocity: CGVectorCodable
    let rotation: CGFloat
    let timestamp: TimeInterval
    
    init(position: CGPoint, velocity: CGVector, rotation: CGFloat, timestamp: TimeInterval) {
        self.position = CGPointCodable(point: position)
        self.velocity = CGVectorCodable(vector: velocity)
        self.rotation = rotation
        self.timestamp = timestamp
    }
}

// MARK: - Game Event Data

enum GameEventType: String, Codable {
    case obstacleHit = "obstacle_hit"
    case collectibleGathered = "collectible_gathered"
    case scoreUpdate = "score_update"
    case playerCrashed = "player_crashed"
    case obstacleSpawned = "obstacle_spawned"
    case collectibleSpawned = "collectible_spawned"
}

struct GameEventData: MessageData {
    let eventType: GameEventType
    let position: CGPointCodable?
    let value: Int?
    let objectId: String?
    let timestamp: TimeInterval
    
    init(eventType: GameEventType, position: CGPoint? = nil, value: Int? = nil, objectId: String? = nil) {
        self.eventType = eventType
        self.position = position != nil ? CGPointCodable(point: position!) : nil
        self.value = value
        self.objectId = objectId
        self.timestamp = Date().timeIntervalSince1970
    }
}

// MARK: - Game State Data

struct GameStateData: MessageData {
    let players: [PlayerState]
    let obstacles: [GameObjectState]
    let collectibles: [GameObjectState]
    let gameStarted: Bool
    let gameTime: TimeInterval
    let worldOffset: CGFloat
}

struct PlayerState: Codable {
    let id: String
    let name: String
    let position: CGPointCodable
    let velocity: CGVectorCodable
    let rotation: CGFloat
    let score: Int
    let isAlive: Bool
    let color: String // Hex color for player airplane
}

struct GameObjectState: Codable {
    let id: String
    let type: String
    let position: CGPointCodable
    let size: CGSizeCodable
    let rotation: CGFloat
}

// MARK: - Game Room Data

struct GameRoomData: MessageData {
    let gameId: String
    let maxPlayers: Int
    let currentPlayers: Int
    let players: [PlayerInfo]
    let gameStarted: Bool
}

struct PlayerInfo: Codable {
    let id: String
    let name: String
    let isReady: Bool
    let color: String
}

// MARK: - Codable Wrappers for Core Graphics Types

struct CGPointCodable: Codable {
    let x: CGFloat
    let y: CGFloat
    
    init(point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }
    
    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
}

struct CGVectorCodable: Codable {
    let dx: CGFloat
    let dy: CGFloat
    
    init(vector: CGVector) {
        self.dx = vector.dx
        self.dy = vector.dy
    }
    
    var cgVector: CGVector {
        return CGVector(dx: dx, dy: dy)
    }
}

struct CGSizeCodable: Codable {
    let width: CGFloat
    let height: CGFloat
    
    init(size: CGSize) {
        self.width = size.width
        self.height = size.height
    }
    
    var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}

// MARK: - Multiplayer Game Configuration

struct MultiplayerGameConfig {
    static let maxPlayers = 4
    static let gameStartDelay: TimeInterval = 3.0
    static let tickRate: TimeInterval = 1.0/60.0 // 60 FPS
    static let positionUpdateRate: TimeInterval = 1.0/30.0 // 30 updates per second
    static let connectionTimeout: TimeInterval = 30.0
    
    // Player colors for different players
    static let playerColors: [String] = [
        "#FFFFFF", // White
        "#FF6B6B", // Red
        "#4ECDC4", // Teal
        "#45B7D1", // Blue
        "#96CEB4", // Green
        "#FFEAA7", // Yellow
        "#DDA0DD", // Plum
        "#98D8C8"  // Mint
    ]
}

// MARK: - Error Handling

enum MultiplayerError: Error, LocalizedError {
    case connectionFailed
    case gameNotFound
    case gameIsFull
    case invalidMessage
    case networkError(String)
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to multiplayer server"
        case .gameNotFound:
            return "Game room not found"
        case .gameIsFull:
            return "Game room is full"
        case .invalidMessage:
            return "Invalid message received"
        case .networkError(let message):
            return "Network error: \(message)"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}