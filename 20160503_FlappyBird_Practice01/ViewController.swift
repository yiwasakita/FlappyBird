//
//  ViewController.swift
//  20160503_FlappyBird_Practice01
//
//  Created by tlsmooth89 on 5/3/16.
//  Copyright © 2016 yusuke.iwasaki. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change the view type to SKView.
        let skView = self.view as! SKView
        
        // Displaying the FPS.
        skView.showsFPS = true
        
        // Displaying the number of nodes.
        skView.showsNodeCount = true
        
        // Making the scene with the size as the skView's.
        let scene = GameScene(size:skView.frame.size)
        
        // Displaying the scene on the skView.
        skView.presentScene(scene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Removing the status bar.
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

