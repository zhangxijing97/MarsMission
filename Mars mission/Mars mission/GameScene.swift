//
//  GameScene.swift
//  Mars mission
//
//  Created by 张熙景 on 4/30/22.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene {
    
    // Instance to the CMMotionManager object that will be used to monitor horizontal movemen
    // Access to the accelerometer, magnetometer, rotation rate
    let coreMotionManager = CMMotionManager()
    
    let backgroundNode = SKSpriteNode(imageNamed: "Background")
    let backgroundPlanetNode = SKSpriteNode(imageNamed: "PlanetStart")
    let playerNode = SKSpriteNode(imageNamed: "Spacecraft")
    let marsNode = SKSpriteNode(imageNamed: "Mars")
    let moonNode = SKSpriteNode(imageNamed: "Moon")
    let foregroundNode = SKSpriteNode()
    
    // Variable about EngineExhaust
    var engineExhaust: SKEmitterNode?
    var remainExhaust = 0
    
    // Variable about Text
    var score = 0
    let scoreTextNode = SKLabelNode(fontNamed: "Copperplate")
    let impulseTextNode = SKLabelNode(fontNamed: "Copperplate")
    let startGameTextNode = SKLabelNode(fontNamed: "Copperplate")
    
    var impulseCount = 20
    let CollisionCategoryPlayer  : UInt32 = 0x1 << 1
    let CollisionCategoryPowerUpOrbs : UInt32 = 0x1 << 2
    let CollisionCategorySatellites : UInt32 = 0x1 << 3
    let CollisionCategorySpaceStation : UInt32 = 0x1 << 4
    
    // Music
    let orbPopAudio = SKAction.playSoundFileNamed("energy.wav", waitForCompletion: false)
    let rocketAudio = SKAction.playSoundFileNamed("rocket.wav", waitForCompletion: false)
    let explosionAudio = SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false)
    let gameOverAudio = SKAction.playSoundFileNamed("mixkit-arcade-retro-game-over-213.wav", waitForCompletion: false)
    let gameWinAudio = SKAction.playSoundFileNamed("mixkit-video-game-win-2016.wav", waitForCompletion: false)
    
    let audioNode = SKAudioNode(fileNamed: "BoxCat-Games-Battle-Boss.mp3")
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        
        super.init(size: size)
        
        physicsWorld.contactDelegate = self
        
        // Set physicsWorld gravity
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        
        backgroundColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)

        isUserInteractionEnabled = true
        
        // Add backgroundAudio
        audioNode.isPositional = false
        addChild(audioNode)
        
        // Add background
        backgroundNode.size.width = frame.size.width
        backgroundNode.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundNode.position = CGPoint(x: size.width / 2.0, y: 0.0)
        addChild(backgroundNode)
        
        // Add PlanetNode
        backgroundPlanetNode.size.width = frame.size.width
        backgroundPlanetNode.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundPlanetNode.position = CGPoint(x: size.width / 2.0, y: 0.0)
        addChild(backgroundPlanetNode)
        
        // Add marsNode
        marsNode.size.width = frame.size.width
        marsNode.anchorPoint = CGPoint(x: 1, y: 0.0)
        marsNode.position = CGPoint(x: size.width / 2.0, y: 2200)
        backgroundNode.addChild(marsNode)
        
        // Add moonNode
//        moonNode.size.width = frame.size.width
        moonNode.anchorPoint = CGPoint(x: 1, y: 0.0)
        moonNode.position = CGPoint(x: size.width / 2.0, y: 500)
        backgroundNode.addChild(moonNode)
        
        // Add foregroundNode
        addChild(foregroundNode)
        
        // Add player
        playerNode.physicsBody =  SKPhysicsBody(circleOfRadius: playerNode.size.width / 2)
        playerNode.physicsBody?.isDynamic = false
        playerNode.position = CGPoint(x: size.width / 2.0, y: 220.0)
        playerNode.physicsBody?.linearDamping = 1.0
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryPlayer
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryPowerUpOrbs | CollisionCategorySatellites | CollisionCategorySpaceStation
        playerNode.physicsBody?.collisionBitMask = 0
        foregroundNode.addChild(playerNode)
        
        // Add engine Exhaust Path
        let engineExhaustPath = Bundle.main.path(forResource: "EngineExhaust", ofType: "sks")
        engineExhaust = NSKeyedUnarchiver.unarchiveObject(withFile: engineExhaustPath!) as? SKEmitterNode
        engineExhaust?.position = CGPoint(x: 0.0, y: -(playerNode.size.height / 2))
        playerNode.addChild(engineExhaust!)
        engineExhaust?.isHidden = true
        
        // Add score text
        scoreTextNode.text = "SCORE : \(score)"
        scoreTextNode.fontSize = 20
        scoreTextNode.fontColor = SKColor.white
        scoreTextNode.position = CGPoint(x: size.width / 2, y: size.height - 70)
        scoreTextNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        addChild(scoreTextNode)
        
        // Add impulse counter text
        impulseTextNode.text = "IMPULSES : \(impulseCount)"
        impulseTextNode.fontSize = 20
        impulseTextNode.fontColor = SKColor.white
        impulseTextNode.position = CGPoint(x: size.width / 2, y: size.height - 50)
        impulseTextNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        addChild(impulseTextNode)
        
        // Add startGame text
        startGameTextNode.text = "TAP ANYWHERE TO START!"
        startGameTextNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.center
        startGameTextNode.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        startGameTextNode.fontSize = 20
        startGameTextNode.fontColor = SKColor.white
        startGameTextNode.position = CGPoint(x: scene!.size.width / 2, y: scene!.size.height / 2)
        addChild(startGameTextNode)
        
        // Call Function to add to foreground
        addOrbsToForeground()
        addSatelliteToForeground()
        addSpaceStationToForeground()
    }
    
    // Add orbs to Foreground function
    func addOrbsToForeground() {
        var orbNodePosition = CGPoint(x: playerNode.position.x, y: playerNode.position.y + 100)
        var orbXShift : CGFloat = -1.0
        for _ in 1...50 {
            let orbNode = SKSpriteNode(imageNamed: "PowerUpBlue")
            if orbNodePosition.x - (orbNode.size.width * 2) <= 0 {
                orbXShift = 1.0
            }
            if orbNodePosition.x + orbNode.size.width >= size.width {
                orbXShift = -1.0
            }
            orbNodePosition.x += 40.0 * orbXShift
            orbNodePosition.y += 240
            orbNode.position = orbNodePosition
            orbNode.physicsBody = SKPhysicsBody(circleOfRadius: orbNode.size.width / 2)
            orbNode.physicsBody?.isDynamic = false
            orbNode.physicsBody?.categoryBitMask = CollisionCategoryPowerUpOrbs
            orbNode.physicsBody?.collisionBitMask = 0
            orbNode.name = "PowerUpBlue"
            
            // SKAction
            let moveLeftAction = SKAction.moveTo(x: 0.0, duration: 10.0)
            let moveRightAction = SKAction.moveTo(x: size.width, duration: 10.0)
            
            let groupMoveLeft = SKAction.group([moveLeftAction])
            let groupMoveRight = SKAction.group([moveRightAction])
            
            let actionSequence = SKAction.sequence([groupMoveLeft, groupMoveRight])
            let moveAction = SKAction.repeatForever(actionSequence)
            
            orbNode.run(moveAction)
            
            foregroundNode.addChild(orbNode)
        }
    }
    
    // Add Satellite function
    func addSatelliteToForeground() {
        
        for i in 1...10 {
            
            let satelliteNode = SKSpriteNode(imageNamed: "Satellite")
            satelliteNode.physicsBody?.categoryBitMask = CollisionCategorySatellites
            satelliteNode.physicsBody?.collisionBitMask = 0
            
            satelliteNode.position = CGPoint(x: size.width, y: 600.0 * CGFloat(i))
            satelliteNode.physicsBody = SKPhysicsBody(circleOfRadius: satelliteNode.size.width / 2)
            satelliteNode.physicsBody?.isDynamic = false
            satelliteNode.physicsBody?.categoryBitMask = CollisionCategorySatellites
            satelliteNode.physicsBody?.collisionBitMask = 0
            satelliteNode.name = "SATELLITE"
            
            // SKAction
            let moveLeftAction = SKAction.moveTo(x: 0.0, duration: 2.0)
            let moveRightAction = SKAction.moveTo(x: size.width, duration: 2.0)
            
            let moveTopAction = SKAction.moveTo(y: satelliteNode.position.y + 100 + 100, duration: 2.0)
            let moveDownAction = SKAction.moveTo(y: satelliteNode.position.y + 100 - 100, duration: 2.0)
            
            let scaleBig = SKAction.scale(to: 2, duration: 2.0)
            let scaleSmall = SKAction.scale(to: 1, duration: 2.0)
            
            let fadeIn = SKAction.fadeIn(withDuration: 2.0)
            let fadeOut = SKAction.fadeOut(withDuration: 2.0)
            
            let groupMoveLeft = SKAction.group([moveLeftAction, scaleBig, fadeIn, moveTopAction])
            let groupMoveRight = SKAction.group([moveRightAction, scaleSmall, fadeOut, moveDownAction])
            
            let actionSequence = SKAction.sequence([groupMoveLeft, groupMoveRight])
            let moveAction = SKAction.repeatForever(actionSequence)
            
            satelliteNode.run(moveAction)
            
            foregroundNode.addChild(satelliteNode)
        }
    }
    
    // Add SpaceStation function
    func addSpaceStationToForeground() {
        
        for i in 11...20 {
            
            let spaceStationNode = SKSpriteNode(imageNamed: "SpaceStation")
            spaceStationNode.physicsBody?.categoryBitMask = CollisionCategorySpaceStation
            spaceStationNode.physicsBody?.collisionBitMask = 0
            
            spaceStationNode.position = CGPoint(x: size.width, y: 600.0 * CGFloat(i))
            spaceStationNode.physicsBody = SKPhysicsBody(circleOfRadius: spaceStationNode.size.width / 2)
            spaceStationNode.physicsBody?.isDynamic = false
            spaceStationNode.physicsBody?.categoryBitMask = CollisionCategorySpaceStation
            spaceStationNode.physicsBody?.collisionBitMask = 0
            spaceStationNode.name = "SPACESTATION"
            
            // SKAction
            let moveLeftAction = SKAction.moveTo(x: 0.0, duration: 2.0)
            let moveRightAction = SKAction.moveTo(x: size.width, duration: 2.0)
            
            let moveTopAction = SKAction.moveTo(y: spaceStationNode.position.y + 100 + 100, duration: 2.0)
            let moveDownAction = SKAction.moveTo(y: spaceStationNode.position.y + 100 - 100, duration: 2.0)
            
            let scaleBig = SKAction.scale(to: 2, duration: 2.0)
            let scaleSmall = SKAction.scale(to: 1, duration: 2.0)
            
            let fadeIn = SKAction.fadeIn(withDuration: 2.0)
            let fadeOut = SKAction.fadeOut(withDuration: 2.0)
            
            let groupMoveLeft = SKAction.group([moveLeftAction, scaleBig, fadeIn, moveDownAction])
            let groupMoveRight = SKAction.group([moveRightAction, scaleSmall, fadeOut, moveTopAction])
            
            let actionSequence = SKAction.sequence([groupMoveLeft, groupMoveRight])
            let moveAction = SKAction.repeatForever(actionSequence)
            
            spaceStationNode.run(moveAction)
            
            foregroundNode.addChild(spaceStationNode)
        }
    }
    
    // When touches began, move player 40.0
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        startGameTextNode.removeFromParent()
        
        if !playerNode.physicsBody!.isDynamic {
            playerNode.physicsBody?.isDynamic = true
            // accelerometer will use to update 3/10ths of a second
            coreMotionManager.accelerometerUpdateInterval = 0.3
            // starts the accelerometer updates
            coreMotionManager.startAccelerometerUpdates()
        }
        if impulseCount > 0 {
            
            run(rocketAudio)
            
            playerNode.physicsBody!.applyImpulse(CGVector(dx: 0.0, dy: 60.0))
            impulseCount -= 1
            impulseTextNode.text = "IMPULSES : \(impulseCount)"
            
            engineExhaust?.isHidden = false
            remainExhaust = remainExhaust + 1
            
            Timer.scheduledTimer(timeInterval: 0.5,
                                 target: self,
                                 selector: #selector(GameScene.hideEngineExaust(_:)),
                                 userInfo: nil,
                                 repeats: false)
        }
    }
    
    // Invoked when the contact first begins
    func didBegin(_ contact: SKPhysicsContact) {
        
        print("There has been contact.")
        let nodeB = contact.bodyB.node
        if nodeB?.name == "PowerUpBlue" {
            run(orbPopAudio)
            
            impulseCount += 1
            impulseTextNode.text = "IMPULSES : \(impulseCount)"
            
            score += 1
            scoreTextNode.text = "SCORE : \(score)"
            
            nodeB?.removeFromParent()
        } else if nodeB?.name == "SATELLITE" {
            
            run(explosionAudio)
            
            audioNode.run(SKAction.stop())

            playerNode.physicsBody?.contactTestBitMask = 0
            impulseCount = 0
            let colorizeAction = SKAction.colorize(with: UIColor.red, colorBlendFactor: 1.0, duration: 1)
            playerNode.run(colorizeAction)
            
            Timer.scheduledTimer(timeInterval: 0.5,
                                 target: self,
                                 selector: #selector(GameScene.gameOverWithResult(_:)),
                                 userInfo: nil,
                                 repeats: false)
        } else if nodeB?.name == "SPACESTATION" {
            
            run(explosionAudio)
            
            audioNode.run(SKAction.stop())
            
            playerNode.physicsBody?.contactTestBitMask = 0
            impulseCount = 0
            let colorizeAction = SKAction.colorize(with: UIColor.red, colorBlendFactor: 1.0, duration: 1)
            playerNode.run(colorizeAction)
            
            Timer.scheduledTimer(timeInterval: 0.5,
                                 target: self,
                                 selector: #selector(GameScene.gameOverWithResult(_:)),
                                 userInfo: nil,
                                 repeats: false)
        }
    }
    
    // Every time the player goes higher in the scene, the background will be moved down in the scene
    override func update(_ currentTime: TimeInterval) {
        if playerNode.position.y >= 180.0 && playerNode.position.y < 13400.0 {
            backgroundNode.position = CGPoint(x: backgroundNode.position.x, y: -((playerNode.position.y - 180.0)/8));
            backgroundPlanetNode.position = CGPoint(x: backgroundPlanetNode.position.x, y:-((playerNode.position.y - 180.0)/8));
            foregroundNode.position = CGPoint(x: foregroundNode.position.x, y: -(playerNode.position.y - 180.0));
        } else if playerNode.position.y > 14000.0 {
            gameOverWithResult(true)
        } else if playerNode.position.y < 0.0 {
            gameOverWithResult(false)
            run(gameOverAudio)
        }
    }
    
    // gameOverWithResult function
    @objc func gameOverWithResult(_ gameResult: Bool) {
        
        playerNode.removeFromParent()
        
        let transition = SKTransition.crossFade(withDuration: 2.0)
        let menuScene = MenuScene(size: size, gameResult: gameResult, score: score)
        view?.presentScene(menuScene, transition: transition)
        
        if gameResult {
            print("YOU WON!")
            run(gameWinAudio)
        } else {
            print("YOU LOSE!")
            run(gameOverAudio)
        }
    }
    
    // Use magnetometer to control player
    override func didSimulatePhysics() {
        // Use x-acceleration * 380.0 and y-axis to conntrol Player
        if let accelerometerData = coreMotionManager.accelerometerData {
            playerNode.physicsBody!.velocity =
                    CGVector(dx: CGFloat(accelerometerData.acceleration.x * 380.0),
                                     dy: playerNode.physicsBody!.velocity.dy)
        }
        // If the player is flying off the scene, back to the scene
        if playerNode.position.x < -(playerNode.size.width / 2) {
                playerNode.position =
                    CGPoint(x: size.width - playerNode.size.width / 2,
                            y: playerNode.position.y)
        } else if playerNode.position.x > self.size.width {
                playerNode.position = CGPoint(x: playerNode.size.width / 2,
                                              y: playerNode.position.y);
        }
    }
    
    // Turning off accelerometer updates when the GameScene is no longer used
    deinit {
        coreMotionManager.stopAccelerometerUpdates()
    }
    
    // Hide enginne exaust
    @objc func hideEngineExaust(_ timer:Timer!) {
        remainExhaust = remainExhaust - 1
        if engineExhaust!.isHidden == false {
            if remainExhaust == 0 {
                engineExhaust?.isHidden = true
            }
        }
    }
    
}
// outside

extension GameScene: SKPhysicsContactDelegate {

}
