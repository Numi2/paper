//
//  GameScene.swift
//  Paper
//
//  Created by T on 6/20/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game objects
    private var paperAirplane: SKSpriteNode!
    private var cameraNode: SKCameraNode!
    private var worldNode: SKNode!
    
    // Game state
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    private var gameOver = false
    
    // Physics categories
    let airplaneCategory: UInt32 = 0x1 << 0
    let obstacleCategory: UInt32 = 0x1 << 1
    let collectibleCategory: UInt32 = 0x1 << 2
    let groundCategory: UInt32 = 0x1 << 3
    
    // Controls
    private var touchLocation: CGPoint?
    private var airplaneVelocity = CGVector.zero
    private let maxVelocity: CGFloat = 350  // Slightly reduced for better control
    private let acceleration: CGFloat = 1000  // Increased for better responsiveness
    private let drag: CGFloat = 0.95  // Increased drag for more realistic feel
    
    // Wind effects
    private var windForce = CGVector.zero
    private var windTimer: TimeInterval = 0
    
    // Parallax layers
    private var backgroundLayer: SKNode!
    private var midgroundLayer: SKNode!
    private var foregroundLayer: SKNode!
    
    override func didMove(to view: SKView) {
        setupPhysics()
        setupWorld()
        setupPaperAirplane()
        setupCamera()
        setupUI()
        setupBackground()
        startGame()
    }
    
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
    }
    
    private func setupWorld() {
        worldNode = SKNode()
        addChild(worldNode)
        
        // Create parallax layers
        backgroundLayer = SKNode()
        midgroundLayer = SKNode()
        foregroundLayer = SKNode()
        
        worldNode.addChild(backgroundLayer)
        worldNode.addChild(midgroundLayer)
        worldNode.addChild(foregroundLayer)
    }
    
    private func setupPaperAirplane() {
        // Create paper airplane using shapes
        paperAirplane = SKSpriteNode(color: .white, size: CGSize(width: 60, height: 40))
        paperAirplane.position = CGPoint(x: -frame.width/3, y: 0)
        paperAirplane.zPosition = 10
        
        // Add paper airplane details
        let airplaneShape = SKShapeNode()
        let path = CGMutablePath()
        
        // Create a paper airplane shape
        path.move(to: CGPoint(x: -30, y: 0))  // Nose
        path.addLine(to: CGPoint(x: 0, y: 15))   // Top wing
        path.addLine(to: CGPoint(x: 20, y: 0))   // Top wing tip
        path.addLine(to: CGPoint(x: 0, y: -15))  // Bottom wing
        path.addLine(to: CGPoint(x: -30, y: 0))  // Back to nose
        
        airplaneShape.path = path
        airplaneShape.fillColor = .white
        airplaneShape.strokeColor = .lightGray
        airplaneShape.lineWidth = 2
        paperAirplane.addChild(airplaneShape)
        
        // Add a small tail
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
        
        // Setup physics body
        let airplaneBody = SKPhysicsBody(rectangleOf: paperAirplane.size)
        airplaneBody.categoryBitMask = airplaneCategory
        airplaneBody.contactTestBitMask = obstacleCategory | collectibleCategory
        airplaneBody.collisionBitMask = groundCategory
        airplaneBody.affectedByGravity = false
        airplaneBody.allowsRotation = true
        airplaneBody.linearDamping = 0.5
        airplaneBody.angularDamping = 0.8
        paperAirplane.physicsBody = airplaneBody
        
        worldNode.addChild(paperAirplane)
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        
        // Position camera behind and slightly above the airplane
        let cameraOffset = CGPoint(x: -100, y: 50)
        cameraNode.position = CGPoint(x: paperAirplane.position.x + cameraOffset.x,
                                    y: paperAirplane.position.y + cameraOffset.y)
    }
    
    private func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -frame.width/2 + 100, y: frame.height/2 - 50)
        scoreLabel.zPosition = 100
        cameraNode.addChild(scoreLabel)
        
        // Add speed indicator
        let speedLabel = SKLabelNode(fontNamed: "Arial")
        speedLabel.text = "Speed: 0"
        speedLabel.fontSize = 18
        speedLabel.fontColor = .white
        speedLabel.position = CGPoint(x: -frame.width/2 + 100, y: frame.height/2 - 80)
        speedLabel.zPosition = 100
        speedLabel.name = "speedLabel"
        cameraNode.addChild(speedLabel)
        
        // Add instructions
        let instructionsLabel = SKLabelNode(fontNamed: "Arial")
        instructionsLabel.text = "Tap and drag to control the paper airplane"
        instructionsLabel.fontSize = 18
        instructionsLabel.fontColor = .white
        instructionsLabel.position = CGPoint(x: 0, y: -frame.height/2 + 100)
        instructionsLabel.zPosition = 100
        cameraNode.addChild(instructionsLabel)
    }
    
    private func setupBackground() {
        // Create infinite sky gradient in background layer
        let skyWidth = frame.width * 2
        let skyHeight = frame.height * 2
        
        // Create multiple sky sections for seamless scrolling
        for i in 0...2 {
            let skyNode = SKSpriteNode(color: .clear, size: CGSize(width: skyWidth, height: skyHeight))
            skyNode.position = CGPoint(x: CGFloat(i) * skyWidth, y: 0)
            skyNode.zPosition = -100
            
            // Create gradient effect with multiple colored rectangles
            let colors: [UIColor] = [
                UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0), // Light blue
                UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0), // Sky blue
                UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)  // Very light blue
            ]
            
            for (index, color) in colors.enumerated() {
                let skySection = SKSpriteNode(color: color, size: CGSize(width: skyWidth, height: skyHeight / CGFloat(colors.count)))
                skySection.position = CGPoint(x: 0, y: CGFloat(index) * skyHeight / CGFloat(colors.count) - skyHeight/2)
                skySection.zPosition = -100 + CGFloat(index)
                skyNode.addChild(skySection)
            }
            
            backgroundLayer.addChild(skyNode)
        }
        
        // Add clouds to midground layer
        addClouds()
    }
    
    private func addClouds() {
        // Create more clouds for better coverage
        for _ in 0..<25 {
            let cloud = createCloud()
            let randomX = CGFloat.random(in: -frame.width * 2...frame.width * 4)
            let randomY = CGFloat.random(in: -frame.height/2...frame.height)
            cloud.position = CGPoint(x: randomX, y: randomY)
            cloud.zPosition = -50
            midgroundLayer.addChild(cloud)
        }
    }
    
    private func createCloud() -> SKSpriteNode {
        let cloud = SKSpriteNode(color: .white, size: CGSize(width: CGFloat.random(in: 80...150), height: CGFloat.random(in: 40...80)))
        cloud.alpha = 0.8
        cloud.name = "cloud"
        
        // Add some cloud-like shape variations
        let cloudShape = SKShapeNode(ellipseOf: cloud.size)
        cloudShape.fillColor = .white
        cloudShape.strokeColor = .clear
        cloud.addChild(cloudShape)
        
        return cloud
    }
    
    private func startGame() {
        // Start spawning obstacles and collectibles with better timing
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnObstacle()
                },
                SKAction.wait(forDuration: 2.5)  // Slightly longer intervals
            ])
        ))
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    self?.spawnCollectible()
                },
                SKAction.wait(forDuration: 2.0)  // Better timing
            ])
        ))
    }
    
    private func spawnObstacle() {
        let obstacle = createObstacle()
        // Spawn obstacles at a consistent distance ahead of the airplane
        let spawnDistance: CGFloat = frame.width + 200
        obstacle.position = CGPoint(x: paperAirplane.position.x + spawnDistance,
                                  y: CGFloat.random(in: -frame.height/2 + 100...frame.height/2 - 100))
        obstacle.zPosition = 5
        
        // Add physics body
        let obstacleBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacleBody.categoryBitMask = obstacleCategory
        obstacleBody.contactTestBitMask = airplaneCategory
        obstacleBody.collisionBitMask = 0
        obstacleBody.affectedByGravity = false
        obstacleBody.isDynamic = false
        obstacle.physicsBody = obstacleBody
        
        foregroundLayer.addChild(obstacle)
        
        // Move obstacle towards airplane with consistent speed
        let moveAction = SKAction.moveBy(x: -spawnDistance - frame.width, y: 0, duration: 4.0)
        let removeAction = SKAction.removeFromParent()
        obstacle.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    private func createObstacle() -> SKSpriteNode {
        let obstacleTypes = ["cloud", "bird", "building"]
        let randomType = obstacleTypes.randomElement() ?? "cloud"
        
        switch randomType {
        case "cloud":
            return createCloudObstacle()
        case "bird":
            return createBirdObstacle()
        case "building":
            return createBuildingObstacle()
        default:
            return createCloudObstacle()
        }
    }
    
    private func createCloudObstacle() -> SKSpriteNode {
        let cloud = SKSpriteNode(color: .darkGray, size: CGSize(width: 80, height: 60))
        cloud.name = "obstacle"
        
        // Add cloud-like shape
        let cloudShape = SKShapeNode(ellipseOf: cloud.size)
        cloudShape.fillColor = .darkGray
        cloudShape.strokeColor = .gray
        cloudShape.lineWidth = 2
        cloud.addChild(cloudShape)
        
        // Add some smaller cloud parts
        for _ in 0..<3 {
            let smallCloud = SKShapeNode(ellipseOf: CGSize(width: 30, height: 20))
            smallCloud.fillColor = .darkGray
            smallCloud.strokeColor = .clear
            smallCloud.position = CGPoint(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -10...10))
            cloud.addChild(smallCloud)
        }
        
        return cloud
    }
    
    private func createBirdObstacle() -> SKSpriteNode {
        let bird = SKSpriteNode(color: .black, size: CGSize(width: 40, height: 30))
        bird.name = "obstacle"
        
        // Create bird shape
        let birdShape = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -20, y: 0))  // Head
        path.addLine(to: CGPoint(x: -10, y: 10))  // Wing up
        path.addLine(to: CGPoint(x: 10, y: 5))   // Wing tip
        path.addLine(to: CGPoint(x: 15, y: 0))   // Tail
        path.addLine(to: CGPoint(x: 10, y: -5))  // Wing tip down
        path.addLine(to: CGPoint(x: -10, y: -10)) // Wing down
        path.closeSubpath()
        
        birdShape.path = path
        birdShape.fillColor = .black
        birdShape.strokeColor = .darkGray
        birdShape.lineWidth = 1
        bird.addChild(birdShape)
        
        // Add wing flapping animation
        let flapAction = SKAction.sequence([
            SKAction.scaleY(to: 0.8, duration: 0.2),
            SKAction.scaleY(to: 1.2, duration: 0.2)
        ])
        bird.run(SKAction.repeatForever(flapAction))
        
        return bird
    }
    
    private func createBuildingObstacle() -> SKSpriteNode {
        let building = SKSpriteNode(color: .brown, size: CGSize(width: 60, height: 100))
        building.name = "obstacle"
        
        // Add building details
        let buildingShape = SKShapeNode(rectOf: building.size)
        buildingShape.fillColor = .brown
        buildingShape.strokeColor = .darkGray
        buildingShape.lineWidth = 2
        building.addChild(buildingShape)
        
        // Add windows
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
    
    private func spawnCollectible() {
        let collectible = createStarCollectible()
        // Spawn collectibles at a consistent distance ahead of the airplane
        let spawnDistance: CGFloat = frame.width + 150
        collectible.position = CGPoint(x: paperAirplane.position.x + spawnDistance,
                                     y: CGFloat.random(in: -frame.height/2 + 100...frame.height/2 - 100))
        collectible.zPosition = 5
        
        // Add physics body
        let collectibleBody = SKPhysicsBody(circleOfRadius: 15)
        collectibleBody.categoryBitMask = collectibleCategory
        collectibleBody.contactTestBitMask = airplaneCategory
        collectibleBody.collisionBitMask = 0
        collectibleBody.affectedByGravity = false
        collectibleBody.isDynamic = false
        collectible.physicsBody = collectibleBody
        
        foregroundLayer.addChild(collectible)
        
        // Move collectible towards airplane with consistent speed
        let moveAction = SKAction.moveBy(x: -spawnDistance - frame.width, y: 0, duration: 4.0)
        let removeAction = SKAction.removeFromParent()
        collectible.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    private func createStarCollectible() -> SKSpriteNode {
        let star = SKSpriteNode(color: .clear, size: CGSize(width: 30, height: 30))
        star.name = "collectible"
        
        // Create star shape
        let starShape = SKShapeNode()
        let path = CGMutablePath()
        
        let outerRadius: CGFloat = 15
        let innerRadius: CGFloat = 7
        let points = 5
        
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
        
        // Add rotation and scaling animation
        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
        let scaleAction = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        
        star.run(SKAction.repeatForever(rotateAction))
        star.run(SKAction.repeatForever(scaleAction))
        
        return star
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver {
            // Restart game
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = self.scaleMode
            view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.5))
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
    
    override func update(_ currentTime: TimeInterval) {
        if gameOver { return }
        
        updateWind(currentTime)
        updateAirplaneMovement()
        updateCamera()
        updateParallaxLayers()
        updateScore()
        cleanupOffscreenObjects()
    }
    
    private func updateWind(_ currentTime: TimeInterval) {
        windTimer += 1.0/60.0
        
        // Change wind direction every 5 seconds (less frequent for more stable flight)
        if windTimer > 5.0 {
            windTimer = 0
            windForce = CGVector(
                dx: CGFloat.random(in: -30...30),  // Reduced wind strength
                dy: CGFloat.random(in: -20...20)
            )
        }
        
        // Apply wind more subtly to airplane
        airplaneVelocity.dx += windForce.dx * 0.005  // Reduced wind effect
        airplaneVelocity.dy += windForce.dy * 0.005
    }
    
    private func updateParallaxLayers() {
        // Calculate movement based on airplane velocity
        let movementX = airplaneVelocity.dx * 0.1
        
        // Parallax scrolling with better syncing
        let backgroundSpeed: CGFloat = 0.2
        let midgroundSpeed: CGFloat = 0.5
        let foregroundSpeed: CGFloat = 0.8
        
        // Move background layers
        backgroundLayer.position.x -= movementX * backgroundSpeed
        midgroundLayer.position.x -= movementX * midgroundSpeed
        foregroundLayer.position.x -= movementX * foregroundSpeed
        
        // Infinite scrolling for background
        let skyWidth = frame.width * 2
        for child in backgroundLayer.children {
            if child.position.x < -skyWidth {
                child.position.x += skyWidth * 3
            } else if child.position.x > skyWidth * 2 {
                child.position.x -= skyWidth * 3
            }
        }
        
        // Infinite scrolling for midground (clouds)
        for child in midgroundLayer.children {
            if child.position.x < paperAirplane.position.x - frame.width * 2 {
                child.position.x += frame.width * 4
                child.position.y = CGFloat.random(in: -frame.height/2...frame.height)
            }
        }
        
        // Infinite scrolling for foreground
        for child in foregroundLayer.children {
            if child.position.x < paperAirplane.position.x - frame.width * 2 {
                child.removeFromParent()
            }
        }
    }
    
    private func updateAirplaneMovement() {
        guard let touchLocation = touchLocation else { 
            // Apply drag when not touching
            airplaneVelocity.dx *= drag
            airplaneVelocity.dy *= drag
            return 
        }
        
        // Convert touch location to world coordinates
        let worldTouchLocation = convert(touchLocation, to: worldNode)
        
        // Calculate direction from airplane to touch
        let direction = CGVector(dx: worldTouchLocation.x - paperAirplane.position.x,
                               dy: worldTouchLocation.y - paperAirplane.position.y)
        
        // Normalize direction
        let length = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        if length > 0 {
            let normalizedDirection = CGVector(dx: direction.dx / length, dy: direction.dy / length)
            
            // Apply acceleration with better responsiveness
            let frameTime: CGFloat = 1.0/60.0
            airplaneVelocity.dx += normalizedDirection.dx * acceleration * frameTime
            airplaneVelocity.dy += normalizedDirection.dy * acceleration * frameTime
        }
        
        // Apply drag
        airplaneVelocity.dx *= drag
        airplaneVelocity.dy *= drag
        
        // Limit maximum velocity
        let currentSpeed = sqrt(airplaneVelocity.dx * airplaneVelocity.dx + airplaneVelocity.dy * airplaneVelocity.dy)
        if currentSpeed > maxVelocity {
            let scale = maxVelocity / currentSpeed
            airplaneVelocity.dx *= scale
            airplaneVelocity.dy *= scale
        }
        
        // Apply velocity to position
        let frameTime: CGFloat = 1.0/60.0
        paperAirplane.position.x += airplaneVelocity.dx * frameTime
        paperAirplane.position.y += airplaneVelocity.dy * frameTime
        
        // Rotate airplane based on velocity with smoother rotation
        if currentSpeed > 5 {  // Lower threshold for rotation
            let targetAngle = atan2(airplaneVelocity.dy, airplaneVelocity.dx)
            let currentAngle = paperAirplane.zRotation
            
            // Smooth rotation interpolation with better handling of angle wrapping
            var angleDifference = targetAngle - currentAngle
            
            // Handle angle wrapping for smoother rotation
            if angleDifference > .pi {
                angleDifference -= 2 * .pi
            } else if angleDifference < -.pi {
                angleDifference += 2 * .pi
            }
            
            let rotationSpeed: CGFloat = 0.15  // Slightly faster rotation
            paperAirplane.zRotation += angleDifference * rotationSpeed
        }
        
        // Keep airplane within bounds with softer boundary handling
        let margin: CGFloat = 30  // Reduced margin for more freedom
        if paperAirplane.position.x < -frame.width/2 + margin {
            paperAirplane.position.x = -frame.width/2 + margin
            airplaneVelocity.dx = max(airplaneVelocity.dx, 0)  // Bounce off walls
        } else if paperAirplane.position.x > frame.width/2 - margin {
            paperAirplane.position.x = frame.width/2 - margin
            airplaneVelocity.dx = min(airplaneVelocity.dx, 0)
        }
        
        if paperAirplane.position.y < -frame.height/2 + margin {
            paperAirplane.position.y = -frame.height/2 + margin
            airplaneVelocity.dy = max(airplaneVelocity.dy, 0)
        } else if paperAirplane.position.y > frame.height/2 - margin {
            paperAirplane.position.y = frame.height/2 - margin
            airplaneVelocity.dy = min(airplaneVelocity.dy, 0)
        }
    }
    
    private func updateCamera() {
        // Calculate target camera position based on airplane position and velocity
        let currentSpeed = sqrt(airplaneVelocity.dx * airplaneVelocity.dx + airplaneVelocity.dy * airplaneVelocity.dy)
        let speedFactor = min(currentSpeed / maxVelocity, 1.0)
        
        // Dynamic camera offset based on speed
        let baseOffsetX: CGFloat = -100
        let baseOffsetY: CGFloat = 50
        let speedOffsetX = -speedFactor * 30  // Reduced camera movement at high speed
        let speedOffsetY = speedFactor * 20   // Reduced vertical movement
        
        let targetX = paperAirplane.position.x + baseOffsetX + speedOffsetX
        let targetY = paperAirplane.position.y + baseOffsetY + speedOffsetY
        
        // Smooth camera follow with speed-dependent responsiveness
        let cameraSpeed: CGFloat = 0.08 + speedFactor * 0.05  // More stable camera
        cameraNode.position.x += (targetX - cameraNode.position.x) * cameraSpeed
        cameraNode.position.y += (targetY - cameraNode.position.y) * cameraSpeed
        
        // Add very subtle camera shake at high speeds
        if currentSpeed > 300 {
            let shakeAmount: CGFloat = 1.0  // Reduced shake
            cameraNode.position.x += CGFloat.random(in: -shakeAmount...shakeAmount)
            cameraNode.position.y += CGFloat.random(in: -shakeAmount...shakeAmount)
        }
    }
    
    private func updateScore() {
        score += 1
        scoreLabel.text = "Score: \(score)"
        
        // Update speed indicator
        let currentSpeed = sqrt(airplaneVelocity.dx * airplaneVelocity.dx + airplaneVelocity.dy * airplaneVelocity.dy)
        if let speedLabel = cameraNode.childNode(withName: "speedLabel") as? SKLabelNode {
            speedLabel.text = "Speed: \(Int(currentSpeed))"
            
            // Change color based on speed
            if currentSpeed > 300 {
                speedLabel.fontColor = .red
            } else if currentSpeed > 200 {
                speedLabel.fontColor = .orange
            } else {
                speedLabel.fontColor = .white
            }
        }
    }
    
    private func cleanupOffscreenObjects() {
        // Clean up obstacles in foreground layer
        foregroundLayer.enumerateChildNodes(withName: "obstacle") { node, _ in
            if node.position.x < self.paperAirplane.position.x - self.frame.width {
                node.removeFromParent()
            }
        }
        
        // Clean up collectibles in foreground layer
        foregroundLayer.enumerateChildNodes(withName: "collectible") { node, _ in
            if node.position.x < self.paperAirplane.position.x - self.frame.width {
                node.removeFromParent()
            }
        }
        
        // Clean up any stray particles
        worldNode.enumerateChildNodes(withName: "") { node, _ in
            if node is SKEmitterNode && node.position.x < self.paperAirplane.position.x - self.frame.width * 2 {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if collision == airplaneCategory | obstacleCategory {
            // Collision with obstacle
            gameOver = true
            handleGameOver()
        } else if collision == airplaneCategory | collectibleCategory {
            // Collectible collected
            if let collectible = contact.bodyA.categoryBitMask == collectibleCategory ? contact.bodyA.node : contact.bodyB.node {
                collectible.removeFromParent()
                score += 50
                scoreLabel.text = "Score: \(score)"
                
                // Add collection effect
                let sparkle = SKEmitterNode()
                sparkle.particleColor = .yellow
                sparkle.particleBirthRate = 50  // Reduced particle count
                sparkle.numParticlesToEmit = 10  // Fewer particles
                sparkle.particleLifetime = 0.3  // Shorter lifetime
                sparkle.particleSpeed = 80  // Reduced speed
                sparkle.particleSpeedRange = 30
                sparkle.particleAlpha = 0.8  // Slightly transparent
                sparkle.particleAlphaRange = 0.3
                sparkle.particleScale = 0.08  // Smaller particles
                sparkle.particleScaleRange = 0.04
                sparkle.position = collectible.position
                worldNode.addChild(sparkle)
                
                // Remove sparkle after animation
                sparkle.run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.3),  // Shorter duration
                    SKAction.removeFromParent()
                ]))
            }
        }
    }
    
    private func handleGameOver() {
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-Bold")
        gameOverLabel.text = "Game Over!"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 0)
        gameOverLabel.zPosition = 200
        cameraNode.addChild(gameOverLabel)
        
        let finalScoreLabel = SKLabelNode(fontNamed: "Arial")
        finalScoreLabel.text = "Final Score: \(score)"
        finalScoreLabel.fontSize = 24
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: 0, y: -50)
        finalScoreLabel.zPosition = 200
        cameraNode.addChild(finalScoreLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.text = "Tap to restart"
        restartLabel.fontSize = 20
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -100)
        restartLabel.zPosition = 200
        cameraNode.addChild(restartLabel)
    }
}
