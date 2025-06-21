//
//  WebSocketManager.swift
//  Paper
//
//  Multiplayer WebSocket Manager
//

import Foundation
import Network

protocol WebSocketManagerDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect()
    func webSocketDidReceiveMessage(_ message: MultiplayerMessage)
    func webSocketDidReceiveError(_ error: Error)
}

class WebSocketManager: NSObject {
    static let shared = WebSocketManager()
    
    weak var delegate: WebSocketManagerDelegate?
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var isConnected = false
    
    // Server configuration
    private let serverURL = "ws://localhost:8080" // Change this to your server URL
    
    private override init() {
        super.init()
        setupURLSession()
    }
    
    private func setupURLSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard let url = URL(string: serverURL) else {
            print("Invalid WebSocket URL")
            return
        }
        
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start listening for messages
        listen()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        delegate?.webSocketDidDisconnect()
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                // Continue listening
                self?.listen()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.delegate?.webSocketDidReceiveError(error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            if let data = text.data(using: .utf8),
               let multiplayerMessage = try? JSONDecoder().decode(MultiplayerMessage.self, from: data) {
                DispatchQueue.main.async {
                    self.delegate?.webSocketDidReceiveMessage(multiplayerMessage)
                }
            }
        case .data(let data):
            if let multiplayerMessage = try? JSONDecoder().decode(MultiplayerMessage.self, from: data) {
                DispatchQueue.main.async {
                    self.delegate?.webSocketDidReceiveMessage(multiplayerMessage)
                }
            }
        @unknown default:
            print("Unknown message type received")
        }
    }
    
    // MARK: - Message Sending
    
    func send(_ message: MultiplayerMessage) {
        guard isConnected else {
            print("WebSocket not connected")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(message)
            let string = String(data: data, encoding: .utf8) ?? ""
            webSocketTask?.send(.string(string)) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }
    
    // MARK: - Convenience Methods
    
    func joinGame(gameId: String, playerId: String, playerName: String) {
        let message = MultiplayerMessage(
            type: .joinGame,
            gameId: gameId,
            playerId: playerId,
            playerName: playerName,
            data: nil
        )
        send(message)
    }
    
    func createGame(playerId: String, playerName: String) {
        let message = MultiplayerMessage(
            type: .createGame,
            gameId: nil,
            playerId: playerId,
            playerName: playerName,
            data: nil
        )
        send(message)
    }
    
    func sendPlayerPosition(gameId: String, playerId: String, position: CGPoint, velocity: CGVector, rotation: CGFloat) {
        let playerData = PlayerMovementData(
            position: position,
            velocity: velocity,
            rotation: rotation,
            timestamp: Date().timeIntervalSince1970
        )
        
        let message = MultiplayerMessage(
            type: .playerMove,
            gameId: gameId,
            playerId: playerId,
            playerName: nil,
            data: playerData
        )
        send(message)
    }
    
    func sendGameEvent(gameId: String, playerId: String, event: GameEventData) {
        let message = MultiplayerMessage(
            type: .gameEvent,
            gameId: gameId,
            playerId: playerId,
            playerName: nil,
            data: event
        )
        send(message)
    }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
        isConnected = true
        DispatchQueue.main.async {
            self.delegate?.webSocketDidConnect()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
        isConnected = false
        DispatchQueue.main.async {
            self.delegate?.webSocketDidDisconnect()
        }
    }
}