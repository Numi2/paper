//
//  GameScene.swift
//  Paper
//
//  Created by T on 6/20/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Game Objects
    private var paperAirplane: SKSpriteNode! // The main player's paper airplane
    private var cameraNode: SKCameraNode!    // Camera for following the airplane
    private var worldNode: SKNode!         // Node to contain all game elements for easy scrolling
    
    // MARK: - Game State
    private var score: Int = 0            // Player's current score
    private var scoreLabel: SKLabelNode!  // Displays the score on screen
    private var gameOver = false         // Flag to indicate if the game has ended
    
    // MARK: - Physics Categories
    // Bit masks for physics collision detection
    let airplaneCategory: UInt32 = 0x1 << 0
    let obstacleCategory: UInt32 = 0x1 << 1
    let collectibleCategory: UInt32 = 0x1 << 2
    let groundCategory: UInt32 = 0x1 << 3
    
    // MARK: - Controls
    private var touchLocation: CGPoint?   // Stores the current touch location for airplane control
    private var airplaneVelocity = CGVector.zero // Current velocity of the airplane
    private let maxVelocity: CGFloat = 400     // Maximum speed of the airplane
    private let acceleration: CGFloat = 800    // Acceleration applied towards touch
    private let drag: CGFloat = 0.98           // Drag coefficient to slow down the airplane
    
    // MARK: - Wind Effects
    private var windForce = CGVector.zero     // Current wind force affecting the airplane
    private var windTimer: TimeInterval = 0  // Timer to control wind direction changes
    
    // MARK: - Parallax Layers
    // Nodes for different parallax scrolling speeds to create depth
    private var backgroundLayer: SKNode!
    private var midgroundLayer: SKNode!
    private var foregroundLayer: SKNode!
    // Infinite background tiling
    private var backgroundTiles: [SKSpriteNode] = []
    // Infinite midground and foreground tiling
    private var midgroundTiles: [SKSpriteNode] = []
    private var foregroundTiles: [SKSpriteNode] = []
    // Grid size for infinite tiling
    private let tileGridSize = 3
    
    // Called when the scene is presented
    override func didMove(to view: SKView) {
        setupPhysics()
        setupWorld()
        setupPaperAirplane()
        setupCamera()
        setupUI()
        setupBackground()
        startGame()
    }
    
    // MARK: - Setup Methods
    
    // Configures the physics world
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8) // Sets a slight downward gravity
        physicsWorld.contactDelegate = self             // Sets the scene as the contact delegate for physics collisions
    }
    
    // Sets up the main world node and parallax layers
    private func setupWorld() {
        worldNode = SKNode()    // Initialize the world node
        addChild(worldNode)     // Add it to the scene
        
        // Initialize parallax layers and add them to the world node
        backgroundLayer = SKNode()
        midgroundLayer = SKNode()
        foregroundLayer = SKNode()
        
        worldNode.addChild(backgroundLayer)
        worldNode.addChild(midgroundLayer)
        worldNode.addChild(foregroundLayer)
    }
    
    // Creates and configures the paper airplane player
    private func setupPaperAirplane() {
        // Create paper airplane using shapes
        paperAirplane = SKSpriteNode(color: .white, size: CGSize(width: 60, height: 40))
        paperAirplane.position = CGPoint(x: 0, y: 0) // Center of the scene
        paperAirplane.zPosition = 10 // Drawing order
        
        // Add paper airplane details (visual shape)
        let airplaneShape = SKShapeNode()
        let path = CGMutablePath()
        
        // Define the shape of the paper airplane
        path.move(to: CGPoint(x: -30, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 15))
        path.addLine(to: CGPoint(x: 20, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -15))
        path.addLine(to: CGPoint(x: -30, y: 0))
        
        airplaneShape.path = path
        airplaneShape.fillColor = .white
        airplaneShape.strokeColor = .lightGray
        airplaneShape.lineWidth = 2
        paperAirplane.addChild(airplaneShape)
        
        // Add a small tail to the airplane
        let tail = SKShapeNode()
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -25, y: 0))
        tailPath.addLine(to: CGPoint(x: -20, y: 8))
        tailPath.addLine(to: CGPoint(x: -15, y: 0))
        tailPath.addLine(to: CGPoint(x: -20, y: -8))
        tailPath.closeSubpath()
        
        tail.path = tailPath
        tail.fillColor = .lightGray
        tail.strokeColor = .gray
        tail.lineWidth = 1
        paperAirplane.addChild(tail)
        
        // Setup physics body for collision detection and movement
        let airplaneBody = SKPhysicsBody(rectangleOf: paperAirplane.size)
        airplaneBody.categoryBitMask = airplaneCategory // Assign category for collision filtering
        airplaneBody.contactTestBitMask = obstacleCategory | collectibleCategory // Which categories it will test contact with
        airplaneBody.collisionBitMask = groundCategory // Which categories it will collide with
        airplaneBody.affectedByGravity = false // Disable gravity effect
        airplaneBody.allowsRotation = true    // Allow rotation
        airplaneBody.linearDamping = 0.5      // Reduces linear velocity over time
        airplaneBody.angularDamping = 0.8     // Reduces angular velocity over time
        paperAirplane.physicsBody = airplaneBody
        
        worldNode.addChild(paperAirplane) // Add airplane to the world
    }
    
    // Sets up the camera node to follow the airplane
    private func setupCamera() {
        cameraNode = SKCameraNode() // Initialize camera
        camera = cameraNode         // Assign as the scene's camera
        addChild(cameraNode)        // Add to the scene
        cameraNode.position = paperAirplane.position // Center camera on airplane
    }
    
    // Sets up the user interface elements like score and speed labels
    private func setupUI() {
        // Score label setup
        scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -frame.width/2 + 100, y: frame.height/2 - 50)
        scoreLabel.zPosition = 100 // Ensure it's on top
        cameraNode.addChild(scoreLabel) // Add to camera so it moves with the view
        
        // Speed indicator label setup
        let speedLabel = SKLabelNode(fontNamed: "Arial")
        speedLabel.text = "Speed: 0"
        speedLabel.fontSize = 18
        speedLabel.fontColor = .white
        speedLabel.position = CGPoint(x: -frame.width/2 + 100, y: frame.height/2 - 80)
        speedLabel.zPosition = 100
        speedLabel.name = "speedLabel" // Name for easy retrieval
        cameraNode.addChild(speedLabel)
        
        // Instructions label setup
        let instructionsLabel = SKLabelNode(fontNamed: "Arial")
        instructionsLabel.text = "Tap and drag to control the paper airplane"
        instructionsLabel.fontSize = 18
        instructionsLabel.fontColor = .white
        instructionsLabel.position = CGPoint(x: 0, y: -frame.height/2 + 100)
        instructionsLabel.zPosition = 100
        cameraNode.addChild(instructionsLabel)
    }
    
    // Sets up the background with a sky gradient and clouds
    private func setupBackground() {
        // Remove any existing tiles (for scene restart)
        backgroundLayer.removeAllChildren()
        backgroundTiles.removeAll()
        midgroundLayer.removeAllChildren()
        midgroundTiles.removeAll()
        foregroundLayer.removeAllChildren()
        foregroundTiles.removeAll()
        
        let tileWidth = frame.width
        let tileHeight = frame.height
        let colors: [UIColor] = [
            UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0), // Light blue
            UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0), // Sky blue
            UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)  // Very light blue
        ]
        // Background (sky) tiles 3x3 grid
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
        // Midground (cloud) tiles 3x3 grid
        for i in 0..<tileGridSize {
            for j in 0..<tileGridSize {
                let midNode = SKSpriteNode(color: .clear, size: CGSize(width: tileWidth, height: tileHeight))
                midNode.anchorPoint = CGPoint(x: 0, y: 0)
                midNode.position = CGPoint(x: CGFloat(i) * tileWidth - tileWidth, y: CGFloat(j) * tileHeight - tileHeight)
                midNode.zPosition = -50
                // Add clouds to this tile
                for _ in 0..<5 {
                    let cloud = createCloud()
                    let randomX = CGFloat.random(in: 0...tileWidth)
                    let randomY = CGFloat.random(in: 0...tileHeight)
                    cloud.position = CGPoint(x: randomX - tileWidth/2, y: randomY - tileHeight/2)
                    cloud.zPosition = -50
                    midNode.addChild(cloud)
                }
                midgroundLayer.addChild(midNode)
                midgroundTiles.append(midNode)
            }
        }
        // Foreground tiles 3x3 grid
        for i in 0..<tileGridSize {
            for j in 0..<tileGridSize {
                let fgNode = SKSpriteNode(color: .clear, size: CGSize(width: tileWidth, height: tileHeight))
                fgNode.anchorPoint = CGPoint(x: 0, y: 0)
                fgNode.position = CGPoint(x: CGFloat(i) * tileWidth - tileWidth, y: CGFloat(j) * tileHeight - tileHeight)
                fgNode.zPosition = 0
                foregroundLayer.addChild(fgNode)
                foregroundTiles.append(fgNode)
            }
        }
    }
    
    // Adds multiple cloud nodes to the midground layer
    private func addClouds() {
        for _ in 0..<15 { // Create 15 clouds
            let cloud = createCloud() // Generate a single cloud
            let randomX = CGFloat.random(in: -frame.width...frame.width * 2) // Random X position
            let randomY = CGFloat.random(in: -frame.height/2...frame.height) // Random Y position
            cloud.position = CGPoint(x: randomX, y: randomY)
            cloud.zPosition = -50 // Z-position for midground
            midgroundLayer.addChild(cloud) // Add to midground
        }
    }
    
    // Creates a single cloud sprite node
    private func createCloud() -> SKSpriteNode {
        let cloud = SKSpriteNode(color: .white, size: CGSize(width: CGFloat.random(in: 80...150), height: CGFloat.random(in: 40...80)))
        cloud.alpha = 0.8 // Semi-transparent
        cloud.name = "cloud" // Tag for identification
        
        // Add some cloud-like shape variations
        let cloudShape = SKShapeNode(ellipseOf: cloud.size)
        cloudShape.fillColor = .white
        cloudShape.strokeColor = .clear
        cloud.addChild(cloudShape)
        
        return cloud
    }
    
    // Starts spawning obstacles and collectibles
    private func startGame() {
        // Loop to repeatedly spawn obstacles
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnObstacle() // Call spawnObstacle method
                },
                SKAction.wait(forDuration: 2.0) // Wait 2 seconds before next spawn
            ])
        ))
        
        // Loop to repeatedly spawn collectibles
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnCollectible() // Call spawnCollectible method
                },
                SKAction.wait(forDuration: 1.5) // Wait 1.5 seconds before next spawn
            ])
        ))
    }
    
    // MARK: - Game Element Spawning
    
    // Spawns an obstacle at a random vertical position off-screen to the right
    private func spawnObstacle() {
        let obstacle = createObstacle() // Create a random obstacle type
        obstacle.position = CGPoint(x: paperAirplane.position.x + frame.width + 100, // Position off-screen
                                  y: CGFloat.random(in: -frame.height/2 + 100...frame.height/2 - 100)) // Random Y
        obstacle.zPosition = 5 // Drawing order
        
        // Add physics body for collision
        let obstacleBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacleBody.categoryBitMask = obstacleCategory
        obstacleBody.contactTestBitMask = airplaneCategory
        obstacleBody.collisionBitMask = 0       // No collision response
        obstacleBody.affectedByGravity = false  // Not affected by gravity
        obstacleBody.isDynamic = false          // Does not move by physics engine
        obstacle.physicsBody = obstacleBody
        
        worldNode.addChild(obstacle) // Add to the world
    }
    
    // Returns a randomly selected obstacle type (cloud, bird, or building)
    private func createObstacle() -> SKSpriteNode {
        let obstacleTypes = ["cloud", "bird", "building"] // Available obstacle types
        let randomType = obstacleTypes.randomElement() ?? "cloud" // Select a random one
        
        switch randomType {
        case "cloud":
            return createCloudObstacle()
        case "bird":
            return createBirdObstacle()
        case "building":
            return createBuildingObstacle()
        default:
            return createCloudObstacle() // Fallback
        }
    }
    
    // Creates a cloud-shaped obstacle
    private func createCloudObstacle() -> SKSpriteNode {
        let cloud = SKSpriteNode(color: .darkGray, size: CGSize(width: 80, height: 60))
        cloud.name = "obstacle" // Tag as obstacle
        
        // Add cloud-like shape
        let cloudShape = SKShapeNode(ellipseOf: cloud.size)
        cloudShape.fillColor = .darkGray
        cloudShape.strokeColor = .gray
        cloudShape.lineWidth = 2
        cloud.addChild(cloudShape)
        
        // Add some smaller cloud parts for detail
        for _ in 0..<3 {
            let smallCloud = SKShapeNode(ellipseOf: CGSize(width: 30, height: 20))
            smallCloud.fillColor = .darkGray
            smallCloud.strokeColor = .clear
            smallCloud.position = CGPoint(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -10...10))
            cloud.addChild(smallCloud)
        }
        
        return cloud
    }
    
    // Creates a bird-shaped obstacle with flapping animation
    private func createBirdObstacle() -> SKSpriteNode {
        let bird = SKSpriteNode(color: .black, size: CGSize(width: 40, height: 30))
        bird.name = "obstacle"
        
        // Create bird shape using a custom path
        let birdShape = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -20, y: 0))
        path.addLine(to: CGPoint(x: -10, y: 10))
        path.addLine(to: CGPoint(x: 10, y: 5))
        path.addLine(to: CGPoint(x: 15, y: 0))
        path.addLine(to: CGPoint(x: 10, y: -5))
        path.addLine(to: CGPoint(x: -10, y: -10))
        path.closeSubpath()
        
        birdShape.path = path
        birdShape.fillColor = .black
        birdShape.strokeColor = .darkGray
        birdShape.lineWidth = 1
        bird.addChild(birdShape)
        
        // Add wing flapping animation (scaling Y)
        let flapAction = SKAction.sequence([
            SKAction.scaleY(to: 0.8, duration: 0.2),
            SKAction.scaleY(to: 1.2, duration: 0.2)
        ])
        bird.run(SKAction.repeatForever(flapAction))
        
        return bird
    }
    
    // Creates a building-shaped obstacle with windows
    private func createBuildingObstacle() -> SKSpriteNode {
        let building = SKSpriteNode(color: .brown, size: CGSize(width: 60, height: 100))
        building.name = "obstacle"
        
        // Add building details (base shape)
        let buildingShape = SKShapeNode(rectOf: building.size)
        buildingShape.fillColor = .brown
        buildingShape.strokeColor = .darkGray
        buildingShape.lineWidth = 2
        building.addChild(buildingShape)
        
        // Add windows to the building
        for row in 0..<4 {
            for col in 0..<2 {
                let window = SKShapeNode(rectOf: CGSize(width: 8, height: 8))
                window.fillColor = .yellow
                window.strokeColor = .black
                window.lineWidth = 1
                window.position = CGPoint(x: CGFloat(col * 20 - 10), y: CGFloat(row * 20 - 30))
                building.addChild(window)
            }
        }
        
        return building
    }
    
    // Spawns a star collectible off-screen to the right
    private func spawnCollectible() {
        let collectible = createStarCollectible() // Create a star collectible
        collectible.position = CGPoint(x: paperAirplane.position.x + frame.width + 100, // Position off-screen
                                     y: CGFloat.random(in: -frame.height/2 + 100...frame.height/2 - 100)) // Random Y
        collectible.zPosition = 5 // Drawing order
        
        // Add physics body for collection detection
        let collectibleBody = SKPhysicsBody(circleOfRadius: 15)
        collectibleBody.categoryBitMask = collectibleCategory
        collectibleBody.contactTestBitMask = airplaneCategory
        collectibleBody.collisionBitMask = 0
        collectibleBody.affectedByGravity = false
        collectibleBody.isDynamic = false
        collectible.physicsBody = collectibleBody
        
        worldNode.addChild(collectible) // Add to the world
    }
    
    // Creates a star-shaped collectible with glow and animation
    private func createStarCollectible() -> SKSpriteNode {
        let star = SKSpriteNode(color: .clear, size: CGSize(width: 30, height: 30))
        star.name = "collectible" // Tag as collectible
        
        // Create star shape using a custom path
        let starShape = SKShapeNode()
        let path = CGMutablePath()
        
        let outerRadius: CGFloat = 15
        let innerRadius: CGFloat = 7
        let points = 5
        
        // Generate star points
        for i in 0..<points * 2 {
            let angle = CGFloat(i) * .pi / CGFloat(points)
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = cos(angle) * radius
            let y = sin(angle) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        starShape.path = path
        starShape.fillColor = .yellow
        starShape.strokeColor = .orange
        starShape.lineWidth = 2
        star.addChild(starShape)
        
        // Add glow effect
        let glow = SKShapeNode()
        glow.path = path
        glow.fillColor = .clear
        glow.strokeColor = .yellow
        glow.lineWidth = 4
        glow.alpha = 0.5
        star.addChild(glow)
        
        // Add rotation and scaling animation to the star
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
        let scaleAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        
        star.run(SKAction.repeatForever(rotateAction))
        star.run(SKAction.repeatForever(scaleAction))
        
        return star
    }
    
    // MARK: - Touch Handling
    
    // Called when a touch begins
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver {
            // Restart game if game is over
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = self.scaleMode
            view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.5))
            return
        }
        
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self) // Store touch location
    }
    
    // Called when a touch moves
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchLocation = touch.location(in: self) // Update touch location
    }
    
    // Called when a touch ends
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchLocation = nil // Clear touch location
    }
    
    // MARK: - Game Loop
    
    // Called once per frame to update game state
    override func update(_ currentTime: TimeInterval) {
        if gameOver { return } // Stop updates if game is over
        
        updateWind(currentTime)
        updateAirplaneMovement()
        moveWorld()
        updateCamera()
        updateParallaxLayers() // Note: This is now handled in moveWorld()
        updateScore()
        cleanupOffscreenObjects()
    }
    
    // Updates the wind force applied to the airplane
    private func updateWind(_ currentTime: TimeInterval) {
        windTimer += 1.0/60.0 // Increment timer
        
        // Change wind direction every 3 seconds
        if windTimer > 3.0 {
            windTimer = 0
            windForce = CGVector(
                dx: CGFloat.random(in: -50...50), // Random X wind
                dy: CGFloat.random(in: -30...30)  // Random Y wind
            )
        }
        
        // Apply wind to airplane velocity
        airplaneVelocity.dx += windForce.dx * 0.01
        airplaneVelocity.dy += windForce.dy * 0.01
    }
    
    // Moves the game world elements (obstacles, collectibles, parallax layers)
    private func moveWorld() {
        let scrollSpeed = airplaneVelocity.dx * CGFloat(1.0/60.0)
        // Move obstacles and collectibles left based on scroll speed
        worldNode.enumerateChildNodes(withName: "obstacle") { node, _ in
            node.position.x -= scrollSpeed
        }
        worldNode.enumerateChildNodes(withName: "collectible") { node, _ in
            node.position.x -= scrollSpeed
        }
        // Infinite tiling for all layers in both X and Y
        let tileWidth = frame.width
        let tileHeight = frame.height
        let camX = cameraNode.position.x
        let camY = cameraNode.position.y
        let parallaxSpeed: CGFloat = 0.1
        // Helper closure for repositioning tiles
        func repositionTiles(_ tiles: [SKSpriteNode], speed: CGFloat) {
            for tile in tiles {
                tile.position.x -= scrollSpeed * speed
            }
            for tile in tiles {
                // Wrap in X
                if tile.position.x + tileWidth < camX - tileWidth {
                    let rightmost = tiles.max(by: { $0.position.x < $1.position.x && abs($0.position.y - tile.position.y) < 1 })
                    tile.position.x = (rightmost?.position.x ?? 0) + tileWidth
                } else if tile.position.x > camX + tileWidth {
                    let leftmost = tiles.min(by: { $0.position.x < $1.position.x && abs($0.position.y - tile.position.y) < 1 })
                    tile.position.x = (leftmost?.position.x ?? 0) - tileWidth
                }
                // Wrap in Y
                if tile.position.y + tileHeight < camY - tileHeight {
                    let topmost = tiles.max(by: { $0.position.y < $1.position.y && abs($0.position.x - tile.position.x) < 1 })
                    tile.position.y = (topmost?.position.y ?? 0) + tileHeight
                } else if tile.position.y > camY + tileHeight {
                    let bottommost = tiles.min(by: { $0.position.y < $1.position.y && abs($0.position.x - tile.position.x) < 1 })
                    tile.position.y = (bottommost?.position.y ?? 0) - tileHeight
                }
            }
        }
        repositionTiles(backgroundTiles, speed: parallaxSpeed * 0.3)
        repositionTiles(midgroundTiles, speed: parallaxSpeed * 0.6)
        repositionTiles(foregroundTiles, speed: parallaxSpeed)
    }
    
    // This is handled in moveWorld() now, so it's empty.
    private func updateParallaxLayers() {
        // This is handled in moveWorld() now
    }
    
    // Updates the airplane's movement based on touch input and physics
    private func updateAirplaneMovement() {
        guard let touchLocation = touchLocation else { return } // Only move if touch exists
        
        // Convert touch location to world coordinates
        let worldTouchLocation = convert(touchLocation, to: worldNode)
        
        // Calculate direction vector from airplane to touch point
        let direction = CGVector(dx: worldTouchLocation.x - paperAirplane.position.x,
                               dy: worldTouchLocation.y - paperAirplane.position.y)
        
        // Normalize direction vector
        let length = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        if length > 0 {
            let normalizedDirection = CGVector(dx: direction.dx / length, dy: direction.dy / length)
            
            // Apply acceleration in the direction of touch
            airplaneVelocity.dx += normalizedDirection.dx * acceleration * CGFloat(1.0/60.0)
            airplaneVelocity.dy += normalizedDirection.dy * acceleration * CGFloat(1.0/60.0)
        }
        
        // Apply drag to reduce velocity over time
        airplaneVelocity.dx *= drag
        airplaneVelocity.dy *= drag
        
        // Limit maximum velocity to prevent excessive speed
        let currentSpeed = sqrt(airplaneVelocity.dx * airplaneVelocity.dx + airplaneVelocity.dy * airplaneVelocity.dy)
        if currentSpeed > maxVelocity {
            let scale = maxVelocity / currentSpeed
            airplaneVelocity.dx *= scale
            airplaneVelocity.dy *= scale
        }
        
        // Apply vertical velocity to airplane's position (horizontal is handled by world scrolling)
        paperAirplane.position.y += airplaneVelocity.dy * CGFloat(1.0/60.0)
        
        // Rotate airplane based on its current velocity for visual appeal
        let angle = atan2(airplaneVelocity.dy, airplaneVelocity.dx)
        paperAirplane.zRotation = angle
    }
    
    // Updates the camera's position to follow the airplane (centered, no smoothing)
    private func updateCamera() {
        cameraNode.position = paperAirplane.position
    }
    
    // Updates the score and speed display
    private func updateScore() {
        score += 1 // Increment score
        scoreLabel.text = "Score: \(score)" // Update score label
        
        // Update speed indicator label
        let currentSpeed = sqrt(airplaneVelocity.dx * airplaneVelocity.dx + airplaneVelocity.dy * airplaneVelocity.dy)
        if let speedLabel = cameraNode.childNode(withName: "speedLabel") as? SKLabelNode {
            speedLabel.text = "Speed: \(Int(currentSpeed))"
            
            // Change color based on speed for visual feedback
            if currentSpeed > 300 {
                speedLabel.fontColor = .red
            } else if currentSpeed > 200 {
                speedLabel.fontColor = .orange
            } else {
                speedLabel.fontColor = .white
            }
        }
    }
    
    // Removes off-screen obstacles and collectibles to optimize performance
    private func cleanupOffscreenObjects() {
        let cleanupThreshold = paperAirplane.position.x - self.frame.width // Define a threshold for removal
        
        // Remove obstacles that are far enough off-screen to the left
        worldNode.enumerateChildNodes(withName: "obstacle") { node, _ in
            if node.position.x < cleanupThreshold {
                node.removeFromParent()
            }
        }
        
        // Remove collectibles that are far enough off-screen to the left
        worldNode.enumerateChildNodes(withName: "collectible") { node, _ in
            if node.position.x < cleanupThreshold {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    
    // Called when two physics bodies come into contact
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == airplaneCategory | obstacleCategory {
            // Collision with obstacle: Game Over
            gameOver = true
            handleGameOver()
        } else if collision == airplaneCategory | collectibleCategory {
            // Collision with collectible: Increase score and add effect
            if let collectible = contact.bodyA.categoryBitMask == collectibleCategory ? contact.bodyA.node : contact.bodyB.node {
                collectible.removeFromParent() // Remove collectible
                score += 50 // Increase score
                scoreLabel.text = "Score: \(score)" // Update score display
                
                // Add collection sparkle effect
                let sparkle = SKEmitterNode()
                sparkle.particleColor = .yellow
                sparkle.particleBirthRate = 100
                sparkle.numParticlesToEmit = 20
                sparkle.particleLifetime = 0.5
                sparkle.particleSpeed = 100
                sparkle.particleSpeedRange = 50
                sparkle.particleAlpha = 1.0
                sparkle.particleAlphaRange = 0.5
                sparkle.particleScale = 0.1
                sparkle.particleScaleRange = 0.05
                sparkle.position = collectible.position
                worldNode.addChild(sparkle)
                
                // Remove sparkle after its animation
                sparkle.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.5),
                    SKAction.removeFromParent()
                ]))
            }
        }
    }
    
    // MARK: - Game Over
    
    // Handles the game over state: displays game over message and final score
    private func handleGameOver() {
        // Game Over label
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-Bold")
        gameOverLabel.text = "Game Over!"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 0)
        gameOverLabel.zPosition = 200
        cameraNode.addChild(gameOverLabel)
        
        // Final Score label
        let finalScoreLabel = SKLabelNode(fontNamed: "Arial")
        finalScoreLabel.text = "Final Score: \(score)"
        finalScoreLabel.fontSize = 24
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: 0, y: -50)
        finalScoreLabel.zPosition = 200
        cameraNode.addChild(finalScoreLabel)
        
        // Restart instruction label
        let restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.text = "Tap to restart"
        restartLabel.fontSize = 20
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -100)
        restartLabel.zPosition = 200
        cameraNode.addChild(restartLabel)
    }
}
