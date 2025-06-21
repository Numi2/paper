//
//  MenuScene.swift
//  Paper
//
//  Main Menu Scene for choosing game modes
//

import SpriteKit
import GameplayKit

class MenuScene: SKScene {
    
    // MARK: - UI Elements
    private var titleLabel: SKLabelNode!
    private var singlePlayerButton: SKLabelNode!
    private var multiplayerButton: SKLabelNode!
    private var instructionsLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Background gradient
        backgroundColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
        
        // Title
        titleLabel = SKLabelNode(fontNamed: "Arial-Bold")
        titleLabel.text = "Paper Airplane"
        titleLabel.fontSize = 48
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height - 150)
        addChild(titleLabel)
        
        // Subtitle
        let subtitleLabel = SKLabelNode(fontNamed: "Arial")
        subtitleLabel.text = "Soar Through the Skies"
        subtitleLabel.fontSize = 24
        subtitleLabel.fontColor = .lightGray
        subtitleLabel.position = CGPoint(x: size.width/2, y: size.height - 190)
        addChild(subtitleLabel)
        
        // Single Player Button
        singlePlayerButton = createButton(text: "Single Player", 
                                        position: CGPoint(x: size.width/2, y: size.height/2 + 50))
        addChild(singlePlayerButton)
        
        // Multiplayer Button
        multiplayerButton = createButton(text: "Multiplayer", 
                                       position: CGPoint(x: size.width/2, y: size.height/2 - 20))
        addChild(multiplayerButton)
        
        // Instructions
        instructionsLabel = SKLabelNode(fontNamed: "Arial")
        instructionsLabel.text = "Control your paper airplane by tapping and dragging\nAvoid obstacles and collect stars to increase your score!"
        instructionsLabel.fontSize = 16
        instructionsLabel.fontColor = .white
        instructionsLabel.numberOfLines = 0
        instructionsLabel.position = CGPoint(x: size.width/2, y: size.height/2 - 120)
        addChild(instructionsLabel)
        
        // Add floating paper airplane animation
        addFloatingAirplane()
    }
    
    private func createButton(text: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(fontNamed: "Arial-Bold")
        button.text = text
        button.fontSize = 28
        button.fontColor = .white
        button.position = position
        
        // Add background
        let background = SKShapeNode(rectOf: CGSize(width: 250, height: 50), cornerRadius: 12)
        background.fillColor = UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 0.8)
        background.strokeColor = .white
        background.lineWidth = 2
        background.position = CGPoint.zero
        background.zPosition = -1
        button.addChild(background)
        
        // Add hover effect animation
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        button.run(SKAction.repeatForever(SKAction.sequence([pulse, SKAction.wait(forDuration: 2.0)])))
        
        return button
    }
    
    private func addFloatingAirplane() {
        // Create a decorative paper airplane that floats across the screen
        let airplane = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 30))
        airplane.position = CGPoint(x: -50, y: size.height/2 + 200)
        airplane.zPosition = -2
        airplane.alpha = 0.7
        
        // Create airplane shape
        let airplaneShape = SKShapeNode()
        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: -20, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 10))
        path.addLine(to: CGPoint(x: 15, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -10))
        path.addLine(to: CGPoint(x: -20, y: 0))
        
        airplaneShape.path = path
        airplaneShape.fillColor = .white
        airplaneShape.strokeColor = .lightGray
        airplaneShape.lineWidth = 1
        airplane.addChild(airplaneShape)
        
        addChild(airplane)
        
        // Animate the airplane floating across the screen
        let moveAction = SKAction.moveTo(x: size.width + 50, duration: 8.0)
        let bobAction = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 1.0),
            SKAction.moveBy(x: 0, y: -10, duration: 1.0)
        ])
        let bobForever = SKAction.repeatForever(bobAction)
        
        airplane.run(SKAction.group([moveAction, bobForever])) {
            airplane.removeFromParent()
            // Add another airplane after this one finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.addFloatingAirplane()
            }
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let nodes = self.nodes(at: location)
        for node in nodes {
            if node == singlePlayerButton {
                startSinglePlayerGame()
            } else if node == multiplayerButton {
                startMultiplayerLobby()
            }
        }
    }
    
    // MARK: - Game Mode Selection
    
    private func startSinglePlayerGame() {
        // Add button press animation
        singlePlayerButton.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])) {
            // Transition to single player game
            let gameScene = GameScene(size: self.size)
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
    
    private func startMultiplayerLobby() {
        // Add button press animation
        multiplayerButton.run(SKAction.sequence([
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])) {
            // Transition to multiplayer lobby
            let lobbyScene = MultiplayerLobbyScene(size: self.size, playerName: "")
            let transition = SKTransition.fade(withDuration: 0.5)
            self.view?.presentScene(lobbyScene, transition: transition)
        }
    }
}