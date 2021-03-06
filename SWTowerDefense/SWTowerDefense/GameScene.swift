//
//  GameScene.swift
//  SWTowerDefense
//
//  Created by Gabriel Borges on 4/6/16.
//  Copyright (c) 2016 Gabe Borges. All rights reserved.
//

import SpriteKit
import AVFoundation

@available(iOS 9.0, *)
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let critterCategory = UInt32(0x1)
    let bulletCategory = UInt32(0x1 << 1)
    let sceneCategory = UInt32(0x1 << 2)

    var critters = [Critter]()
    var towers = [Tower]()
    var bullets = [Bullet]()
    
    var shootTimer = NSTimer()
    var lives = 10
    var cash = 1000
    let livesLabel = SKLabelNode(fontNamed: "Arial")
    let cashLabel = SKLabelNode(fontNamed: "Arial")
    var endPoint = CGPointMake(667.0,232.625)
    
    var exitButton: SKSpriteNode!
    var backgroundMusic: AVAudioPlayer!
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
        endPoint.x = self.size.width * 1
        endPoint.y = self.size.height * (0.703)
        
        let backgroundMap = SKSpriteNode(imageNamed: "background")
        backgroundMap.position = CGPointMake(self.size.width/2, self.size.height/2)
        backgroundMap.size = self.size
        backgroundMap.zPosition = 0
        self.addChild(backgroundMap)
        
        livesLabel.fontSize = 25
        livesLabel.position = CGPointMake(self.size.width - 140, self.size.height - 50)
        livesLabel.fontColor = UIColor.whiteColor()
        livesLabel.zPosition = 1
        
        cashLabel.fontSize = 25
        cashLabel.position = CGPointMake(self.size.width - 300, self.size.height - 50)
        cashLabel.fontColor = UIColor.whiteColor()
        cashLabel.zPosition = 1
        
        updateLabels(cashChange: 0, livesChange: 0)
        
        let endPointNode = SKSpriteNode()
        endPointNode.position = endPoint
        endPointNode.size = CGSize(width: 1, height: 1)
        
        exitButton = SKSpriteNode(imageNamed: "button_exit")
        exitButton.position = CGPointMake(self.size.width - 40, self.size.height - 40)
        exitButton.size = CGSize(width: 60, height: 60)
        exitButton.zPosition = 2
        self.addChild(exitButton)
        
        
        self.addChild(livesLabel)
        self.addChild(cashLabel)
        
        let path = NSBundle.mainBundle().pathForResource("DuelOfTheFates.mp3", ofType:nil)!
        let url = NSURL(fileURLWithPath: path)
        
        do {
            let sound = try AVAudioPlayer(contentsOfURL: url)
            backgroundMusic = sound
            sound.play()
        } catch {
            // couldn't load file :(
        }
        
        loadCritters()
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches) {
            let location = touch.locationInNode(self)
            
            let tower = Tower()
            
            if (exitButton.containsPoint(location)) {
                let scene =  MenuScene(size: self.size)
                let skView = self.view! as SKView
                skView.ignoresSiblingOrder = true
                scene.scaleMode = .ResizeFill
                scene.size = skView.bounds.size
                let transition = SKTransition.fadeWithDuration(1)
                skView.presentScene(scene, transition: transition)
            }
            
            if (canAffordTower(tower.towerCost) && !exitButton.containsPoint(location)) {
                
                tower.xScale = 0.5
                tower.yScale = 0.5
                tower.position = location
                tower.zPosition = 2
                addChild(tower)
                towers.append(tower)
                updateLabels(cashChange: -tower.towerCost, livesChange: 0)
                updateTowersTarget()
            }
        }
    }
   
    override func update(currentTime: NSTimeInterval) {
        /* Called before each frame is rendered */
        
        for tower in towers {
            let calcDiff = currentTime - tower.lastUpdateTime
            tower.lastUpdateTime = currentTime
            
            tower.lastFireTime += calcDiff
        }
        
        updateBulletPositions()
        critterIsAtEndCheck()
        updateTowersTarget()
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let firstBody = contact.bodyA.node as? SKSpriteNode
        let secondBody = contact.bodyB.node as? SKSpriteNode
        
        if (firstBody != nil && secondBody != nil) {
            if (contact.bodyA.categoryBitMask == critterCategory) && (contact.bodyB.categoryBitMask == bulletCategory ) {
                
                let firstBody = firstBody as! Critter
                let secondBody = secondBody as! Bullet
                
                // Calculates Damage & if health <= 0, deletes the Critter
                
                firstBody.health -= secondBody.damageDone
                if (firstBody.health <= 0) {
                    firstBody.removeFromParent()
                    let critterIndex = critters.indexOf(firstBody)
                    if (critterIndex != nil) {
                        critters.removeAtIndex(critterIndex!)
                    }
                    
                    updateLabels(cashChange: 50, livesChange: 0)
                    secondBody.originTower.currentEnemy = nil
                }
                
                // Remove the bullet
                
                secondBody.removeFromParent()
                let bulletIndex = bullets.indexOf(secondBody)
                bullets.removeAtIndex(bulletIndex!)
            }
        }
    }
    
    func loadCritters() {
        // Create content to handle waves && Adjust enemy difficulty based on wave number
        let spawnInterval = 1.0; let critterAmount = 10
        
        let delay = SKAction.waitForDuration(spawnInterval)
        
        let addCritter = SKAction.runBlock({
            [unowned self] in
            let critter = Critter()
            let initPoint = CGPoint(x: 0.0 , y: self.size.height * (0.71527))
            critter.xScale = 0.5
            critter.yScale = 0.5
            critter.position = initPoint
            critter.physicsBody = SKPhysicsBody(rectangleOfSize: critter.size)
            critter.physicsBody!.dynamic = false
            critter.physicsBody!.categoryBitMask = self.critterCategory
            critter.zPosition = 1
            
            let pointTwo = CGPointMake(self.size.width * (0.457), self.size.height * (0.71527))
            let pointThree = CGPointMake(self.size.width * (0.457), self.size.height * (0.208))
            let pointFour = CGPointMake(self.size.width * 0.239, self.size.height * 0.208)
            let pointFive = CGPointMake(self.size.width * 0.239, self.size.height * 0.527)
            let pointSix = CGPointMake(self.size.width * 0.1132,self.size.height * 0.527)
            let pointSeven = CGPointMake(self.size.width * 0.1132,self.size.width * 0.0521)
            let pointEight = CGPointMake(self.size.width * 0.862, self.size.width * 0.0521)
            let pointNine = CGPointMake(self.size.width * 0.862,self.size.height * 0.703)
            
            let moveInitToTwo = SKAction.moveTo(pointTwo, duration: critter.walkSpeed * 0.964)
            let moveToThree = SKAction.moveTo(pointThree, duration: critter.walkSpeed * 0.62)
            let moveToFour = SKAction.moveTo(pointFour, duration: critter.walkSpeed * 0.512)
            let moveToFive = SKAction.moveTo(pointFive, duration: critter.walkSpeed * 0.432)
            let moveToSix = SKAction.moveTo(pointSix, duration: critter.walkSpeed * 0.32)
            let moveToSeven = SKAction.moveTo(pointSeven, duration: critter.walkSpeed * 0.62)
            let moveToEight = SKAction.moveTo(pointEight, duration: critter.walkSpeed * 1.6)
            let moveToNine = SKAction.moveTo(pointNine, duration: critter.walkSpeed * 0.8)
            let moveToEnd = SKAction.moveTo(self.endPoint, duration: critter.walkSpeed * 0.32)
            
            let moveSequence = SKAction.sequence([moveInitToTwo, moveToThree, moveToFour, moveToFive, moveToSix, moveToSeven, moveToEight, moveToNine, moveToEnd])
            critter.runAction(moveSequence)
            self.addChild(critter)
            self.critters.append(critter)
        })
        
        let loadAction = SKAction.sequence([delay, addCritter])
        
        //runAction(SKAction.repeatAction(loadAction, count: critterAmount))
        runAction(SKAction.repeatActionForever(loadAction))
    }
    
    func canAffordTower(cost: Int) -> Bool {
        if ((cash - cost) >= 0){
            return true
        }
        else{
            return false
        }
    }
    
    func updateLabels(cashChange cashChange: Int, livesChange: Int) {
        cash = cash + cashChange
        lives = lives + livesChange
        cashLabel.text = "Cash: " + String(cash)
        livesLabel.text = "Lives: " + String(lives)
        
        if lives <= 0 {
            let scene =  GameOverScene(size: self.size)
            let skView = self.view! as SKView
            skView.ignoresSiblingOrder = true
            scene.scaleMode = .ResizeFill
            scene.size = skView.bounds.size
            let transition = SKTransition.fadeWithDuration(1)
            skView.presentScene(scene, transition: transition)
        }
    }
    
    func critterIsAtEndCheck() {
        for critter in critters {
            if (critter.hasActions() == false) {
                print("If statment run")
                critter.removeFromParent()
                updateLabels(cashChange: 0, livesChange: -1)
                let i = critters.indexOf(critter)
                critters.removeAtIndex(i!)
            }
        }
    }
    
    
    // I'm almost 100% sure the below code is VERY innefficient...
    
    func updateTowersTarget() {
        // Run Loop for each tower
        for tower in towers {
            updateBulletPositions()
            // Check if Tower doesn't have target
            //let currentEnemy = tower.currentEnemy
            
            
            if (tower.currentEnemy != nil) {
                let critterExists = critters.indexOf(tower.currentEnemy)
                
                if (critterExists == nil) {
                    findCritterForTower(tower)
                }
                
                rotateTower(tower)
                let distance = calcDistance(firstPoint: tower.position, secondPoint: tower.currentEnemy.position)
                if (distance < tower.attackRange) {
                    if (tower.lastFireTime > tower.fireRate) {
                        tower.lastFireTime = 0
                        fireTower(tower)
                    }
                }
                else {
                    tower.canFire = false
                    findCritterForTower(tower)
                }
            }
            // Tower doesn't have an enemy :(
            else {
                findCritterForTower(tower)
                if (tower.currentEnemy == nil) {
                    tower.canFire = false
                }
            }
        }
    }
    
    func findCritterForTower(tower: Tower) {
        var currentClosestCritter = Critter()
        var currentClosestCritterDistance = CGFloat(-1)
        
        // Sub-Loop in Critters - always targets closest critter
        for critter in critters {
            let critterDistance = calcDistance(firstPoint: critter.position, secondPoint: tower.position)
            if (critterDistance < tower.attackRange && critterDistance > currentClosestCritterDistance) {
                currentClosestCritter = critter
                currentClosestCritterDistance = critterDistance
            }
        }
        
        if (currentClosestCritterDistance == CGFloat(-1)) {
            return
        }
        else {
            tower.currentEnemy = currentClosestCritter
            tower.canFire = true
            
        }
    }
    
    func updateBulletPositions() {
        for bullet in bullets {
            let bulletsCritter = bullet.critterTarget
            let critterExists = critters.indexOf(bulletsCritter)
            
            if (critterExists == nil) {
                bullet.removeFromParent()
                let i = bullets.indexOf(bullet)
                bullets.removeAtIndex(i!)
            }
            else {
                let location = bullet.critterTarget.position
                
                let dx = location.x - bullet.position.x
                let dy = location.y - bullet.position.y
                let angle = atan2(dy, dx)
                
                bullet.rotationAngle = angle
                
                let vx = cos(angle) * bullet.travelSpeed
                let vy = sin(angle) * bullet.travelSpeed
                
                bullet.position.x += vx
                bullet.position.y += vy
            }
        }
    }
    
    func rotateTower(tower: Tower) {
        let location = tower.currentEnemy.position
        
        let dx = location.x - tower.position.x
        let dy = location.y - tower.position.y
        let angle = atan2(dy, dx) - CGFloat(M_PI / 2)
        
        tower.zRotation = angle
    }
    
    func fireTower(tower: Tower) {
        if(tower.canFire) {
            
            let bullet = Bullet()
            let initPoint = tower.position
            bullet.xScale = 0.005
            bullet.yScale = 0.005
            bullet.position = initPoint
            bullet.zPosition = 1
            bullet.originTower = tower
            bullet.critterTarget = tower.currentEnemy
            bullet.destinationPoint = bullet.critterTarget.position
            bullet.damageDone = tower.damage
            bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width/2)
            bullet.physicsBody!.categoryBitMask = self.bulletCategory
            bullet.physicsBody!.usesPreciseCollisionDetection = true
            bullet.physicsBody!.collisionBitMask = bulletCategory | critterCategory
            bullet.physicsBody!.contactTestBitMask = bulletCategory | critterCategory
                
            self.addChild(bullet)
            self.bullets.append(bullet)
        }
        else {
            updateBulletPositions()
        }
    }
    
    func calcDistance(firstPoint firstPoint: CGPoint, secondPoint: CGPoint) -> CGFloat {
        let xDist = (secondPoint.x - firstPoint.x)
        let yDist = (secondPoint.y - firstPoint.y)
        return sqrt(xDist * xDist + yDist * yDist)
    }
    
    	
    func upgradetower(tower: Tower){
    	if (cash < tower.upgradeCost){
    		tower.upgradeCost = tower.upgradeCost * 2
    		tower.level += 1
        }
    }
}
