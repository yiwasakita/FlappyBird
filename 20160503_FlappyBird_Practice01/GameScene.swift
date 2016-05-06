//
//  GameScene.swift
//  20160503_FlappyBird_Practice01
//
//  Created by tlsmooth89 on 5/3/16.
//  Copyright © 2016 yusuke.iwasaki. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!
    
    // Categories to judge contacts.
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    let itemCategory: UInt32 = 1 << 4
    
    // Score
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    var itemScore = 0
    var itemScoreLabelNode:SKLabelNode!
    
    // Sound for getting the item.
    var audioPlayer = AVAudioPlayer()
    var birdSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("bird", ofType: "wav")!)
    
    // Method to be called when the scene is displayed on the SKView.
    override func didMoveToView(view: SKView) {
        
        // The gravity.
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        physicsWorld.contactDelegate = self
        
        // The background color.
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // Parent node for scrolling sprites.
        scrollNode = SKNode()
        addChild(scrollNode)
        
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        itemNode = SKNode()
        scrollNode.addChild(itemNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        setupScoreLabel()        
    }
    
    func setupBird() {
        
        // Making birdTextures with the images.
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = SKTextureFilteringMode.Linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = SKTextureFilteringMode.Linear
        
        // Animation alternating the two birdTextures.
        let textureAnimation = SKAction.animateWithTextures([birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatActionForever(textureAnimation)
        
        // Making the sprite.
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: 30, y:self.frame.size.height * 0.7)
        
        // The physicsBody.
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        // Not to rotate when colliding.
        bird.physicsBody?.allowsRotation = false
        
        // The collision settings.
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        // Setting the animation.
        bird.runAction(flap)
        
        // Adding the sprite.
        addChild(bird)
    }
    
    func setupItem() {
        
        // Making itemTextures with the image.
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = SKTextureFilteringMode.Linear
        
        // Moving distance.
        let movingDistanceForItem = CGFloat(self.frame.size.width + itemTexture.size().width * 6)
        
        // moveWall to exit the frame (1)
        let moveItem = SKAction.moveByX(-movingDistanceForItem, y: 0, duration: 5.0)
        
        // removeWall (2)
        let removeItem = SKAction.removeFromParent()
        
        // itemAnimation combining (1) and (2)
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // createItem action.
        let createItemAnimation = SKAction.runBlock({
            
            // The node conveying the wall nodes.
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width * 6, y: 0.0)
            item.zPosition = -20.0 // Between the wall and the bird.
            
            // The center point of Y of the frame.
            let center_y = self.frame.size.height / 2
            // The maximum Y value to move the wall along with the y axis.
            let item_random_y_range = self.frame.size.height / 6
            // The possible lowest Y position of the under wall.
            let item_lowest_y = UInt32( center_y - item_random_y_range / 2 )
            // Generating a random number between 1 and the item_random_y_range.
            let item_random_y = arc4random_uniform( UInt32(item_random_y_range) )
            // Deciding the Y position for the under wall.
            let item_y = CGFloat(item_lowest_y + item_random_y)
            
            // Setting the items.
            let itemSprite = SKSpriteNode(texture: itemTexture)
            itemSprite.position = CGPoint(x: 0.0, y: item_y)
            item.addChild(itemSprite)
            
            // The physicsBody.
            itemSprite.physicsBody = SKPhysicsBody(circleOfRadius: itemSprite.size.height / 2)
            itemSprite.physicsBody?.categoryBitMask = self.itemCategory
            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory
            itemSprite.physicsBody?.dynamic = false
            
            item.runAction(itemAnimation)
            
            self.itemNode.addChild(item)
        })
        
        // The waiting time between the actions.
        let waitItemAnimation = SKAction.waitForDuration(4)
        
        // Repeat of the createWallAnimation and the waitAnimation.
        let repeatForeverItemAnimation = SKAction.repeatActionForever(SKAction.sequence([createItemAnimation, waitItemAnimation]))
        
        runAction(repeatForeverItemAnimation)
    }
    
    func setupGround() {
        
        // Making groundTexture with the image.
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        // Needed number of the groundTextures.
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        // The scroll action set.
        // The scroll action to the left, for one groundTexture distance (1)
        let moveGround = SKAction.moveByX(-groundTexture.size().width , y: 0, duration: 5.0)
        
        // The scroll action back to the original position (2)
        let resetGround = SKAction.moveByX(groundTexture.size().width, y: 0, duration: 0.0)
        
        // Repeat of (1) and (2).
        let repeatScrollGround = SKAction.repeatActionForever(SKAction.sequence([moveGround, resetGround]))
        
        // Setting the groundSprite.
        for var i:CGFloat = 0; i < needNumber; ++i {
            let sprite = SKSpriteNode(texture: groundTexture)
            
            // Setting position for the groundSprite.
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height / 2)
            
            // Setting the runAction to the sprite.
            sprite.runAction(repeatScrollGround)
            
            // The physicsBody.
            sprite.physicsBody = SKPhysicsBody(rectangleOfSize: groundTexture.size()) // Giving the physical entity.
            sprite.physicsBody?.categoryBitMask = groundCategory
            sprite.physicsBody?.dynamic = false // Otherwise it would fall like the bird.
            
            // Adding the groundSprite to the parent scrollNode.
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        
        // Making cloudTexture with the image.
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        // Needed number of the groundTextures.
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        // The scroll action set.
        // The scroll action to the left, for one cloudTexture distance (1)
        let moveCloud = SKAction.moveByX(-cloudTexture.size().width , y: 0, duration: 5.0)
        
        // The scroll action back to the original position (2)
        let resetCloud = SKAction.moveByX(cloudTexture.size().width, y: 0, duration: 0.0)
        
        // Repeat of (1) and (2).
        let repeatScrollCloud = SKAction.repeatActionForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // Setting the cloudSprite.
        for var i:CGFloat = 0; i < needCloudNumber; ++i {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // Setting it to the backest.
            
            // Setting position for the groundSprite.
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)
            
            // Setting the runAction to the sprite.
            sprite.runAction(repeatScrollCloud)
            
            // Adding the groundSprite to the parent scrollNode.
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        
        // Making wallTexture with the image.
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = SKTextureFilteringMode.Linear
        
        // Moving distance.
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width * 2)
        
        // moveWall to exit the frame (1)
        let moveWall = SKAction.moveByX(-movingDistance, y: 0, duration: 4.0)
        
        // removeWall (2)
        let removeWall = SKAction.removeFromParent()
        
        // wallAnimation combining (1) and (2)
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // createWall action.
        let createWallAnimation = SKAction.runBlock({
            
            // The node conveying the wall nodes.
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width * 2, y: 0.0)
            wall.zPosition = -50.0 // Between the ground and the cloud.
            
            // The center point of Y.
            let center_y = self.frame.size.height / 2
            // The maximum Y value to move the wall along with the y axis.
            let random_y_range = self.frame.size.height / 4
            // The possible lowest Y position of the under wall.
            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 - random_y_range / 2 )
            // Generating a random number between 1 and the random_y_range.
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            // Deciding the Y position for the under wall.
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // The Y axis distance for the bird to squeeze.
            let slit_length = self.frame.size.height / 5
            
            // Putting the under wall.
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            // The physicsBody.
            under.physicsBody = SKPhysicsBody(rectangleOfSize: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.dynamic = false
            
            // Putting the upper wall.
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            wall.addChild(upper)
            
            // The physicsBody.
            upper.physicsBody = SKPhysicsBody(rectangleOfSize: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.dynamic = false
            
            // Node for scoring.
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.dynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            wall.runAction(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        // The waiting time between the actions.
        let waitAnimation = SKAction.waitForDuration(2)
        
        // Repeat of the createWallAnimation and the waitAnimation.
        let repeatForeverAnimation = SKAction.repeatActionForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        runAction(repeatForeverAnimation)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if scrollNode.speed > 0 {
            // Setting the birds's speed zero.
            bird.physicsBody?.velocity = CGVector.zero
            
            // Giving the vertical power to the bird.
            bird.physicsBody?.applyImpulse((CGVector(dx: 0, dy: 15)))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    // SKPhysicsContactDelegate method. Called when colliding.
    func didBeginContact(contact: SKPhysicsContact) {
        // Do nothnig if gameover.
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // When the bird collides with the scoreCategory.
            print("ScoreUp")
            score += 1
            print(score)
            scoreLabelNode.text = "Score:\(score)"
            
            // Verifying if the current score is the best score.
            var bestScore = userDefaults.integerForKey("Best")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.setInteger(bestScore, forKey: "Best")
                userDefaults.synchronize()
            }
        } else if (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            // When the bird touches the item.
            print("GotItem")
            itemScore += 1
            print(itemScore)
            itemNode.removeAllChildren()
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            
            // Sound.
            do {
                audioPlayer = try AVAudioPlayer(contentsOfURL: birdSound)
            } catch {
                print("No sound found by URL:\(birdSound)")
            }
            audioPlayer.play()
        } else {
            // When the bird collides with the wall or the ground.
            print("GameOver")
            // Stop the scroll.
            scrollNode.speed = 0
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotateByAngle(CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.runAction(roll, completion: {
                self.bird.speed = 0
            })
        }
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        
        itemScore = 0
        itemScoreLabelNode.text = String("Item Score:\(itemScore)")
        
        bird.position = CGPoint(x:self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.blackColor()
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100 // The most forefront
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.blackColor()
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        
        let bestScore = userDefaults.integerForKey("Best")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.blackColor()
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
    }
}
