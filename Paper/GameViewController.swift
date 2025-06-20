//
//  GameViewController.swift
//  Paper
//
//  Created by T on 6/20/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create the scene programmatically
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .aspectFill
        
        // Present the scene
        if let view = self.view as! SKView? {
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
            
            // Fix SKView focus issues
            view.isMultipleTouchEnabled = false
            view.allowsTransparency = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure proper view setup
        if let skView = view as? SKView {
            skView.paused = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the game when view disappears
        if let skView = view as? SKView {
            skView.paused = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update scene size if needed
        if let skView = view as? SKView, let scene = skView.scene {
            scene.size = view.bounds.size
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
}
