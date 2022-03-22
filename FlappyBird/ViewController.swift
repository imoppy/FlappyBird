//
//  ViewController.swift
//  FlappyBird
//
//  Created by 若原 旬 on 2022/03/18.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true

        let scene = GameScene(size: skView.frame.size)
        skView.presentScene(scene)
    }

    // ステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

}

