//
//  GameViewController.swift
//  Mars mission
//
//  Created by 张熙景 on 4/30/22.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    var scene: GameScene!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Configure the main view
        let skView = view as! SKView
        skView.showsFPS = true
        
        // 2. Create and configure our game scene.
        // Create an instance of the SKScene named GameScene
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        
        // 3. Show the scene.
        skView.presentScene(scene)
    }
    
}
