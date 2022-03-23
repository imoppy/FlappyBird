//
//  GameScene.swift
//  FlappyBird
//
//  Created by 若原 旬 on 2022/03/18.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var bird: SKSpriteNode!
    var itemNode: SKNode!
    var currentItem: SKSpriteNode!

    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 0...00001
    let groundCategory: UInt32 = 1 << 1     // 0...00010
    let wallCategory: UInt32 = 1 << 2       // 0...00100
    let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemCategory: UInt32 = 1 << 4       // 0...10000
    let itemScoreCategory: UInt32 = 1 << 5  // 0..100000

    // スコア用
    var score = 0
    var scoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    var itemScore = 0
    var itemScoreLabelNode: SKLabelNode!
    var bestItemScoreLabelNode: SKLabelNode!
    let userDefaults: UserDefaults = UserDefaults.standard

    override func didMove(to view: SKView) {
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self

        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // ゲームオーバーになったらスクロールを一括で止められるように 親ノードを作成する
        scrollNode = SKNode()
        addChild(scrollNode)

        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // アイテム用のノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)

        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        
        // スコア表示ラベルの設定
        setupScoreLabel()
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)

        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )

            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)

            // スプライトに物理体を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())

            // 衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory

            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false

            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }

    func setupCloud() {
        // 雲の画像
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest // 当たり判定を行うスプライトに貼り付けるテクスチャは画質優先にしたほうが一般的に良い

        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

        // スプライトを配置、アクションを設定
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            sprite.run(repeatScrollCloud)
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear

        // 移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width

        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)

        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()

        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])

        // 鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()

        // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
        let slit_length = birdSize.height * 4

        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60

        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2

        // 空の中央位置を基準にして下側の壁の中央位置を取得
        let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2

        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            // 壁をまとめるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 // 雲より手前、地面より奥

            // 下側の壁の中央位置にランダム値を足して、下側の壁の表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let under_wall_y = under_wall_center_y + random_y

            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)

            // 下側の壁に物理体を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false

            // 壁をまとめるノードに下側の壁を追加
            wall.addChild(under)

            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)

            // 上側の壁に物理体を設定する
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false

            // 壁をまとめるノードに上側の壁を追加
            wall.addChild(upper)

            // スコアカウント用の透明な壁を作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            // 透明な壁に物理体を設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            // 壁をまとめるノードに透明な壁を追加
            wall.addChild(scoreNode)

            // 壁をまとめるノードにアニメーションを設定
            wall.run(wallAnimation)

            // 壁を表示するノードに今回作成した壁を追加
            self.wallNode.addChild(wall)
        })
        // 次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)

        // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

        // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
        wallNode.run(repeatForeverAnimation)
    }

    func setupBird() {
        // 鳥の画像を2種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear

        // 2種類のテクスチャを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)

        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)

        // 物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)

        // カテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory | itemScoreCategory

        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false

        // アニメーションを設定
        bird.run(flap)

        // スプライトを追加する
        addChild(bird)
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero

            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    func setupItem() {
        // アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "kamaboko")
        itemTexture.filteringMode = .linear

        // 移動する距離を計算
        let movingDistance = self.frame.size.width + itemTexture.size().width

        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)

        // 自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()

        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])

        // 隙間位置の上下の振れ幅を60ptとする
        let random_y_range: CGFloat = 60

        // 空の中央位置(y座標)を取得
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2

        // 空の中央位置を基準にしてアイテムの中央位置を取得
        let item_center_y = sky_center_y / 2 + 200

        // アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run({
            // アイテムをまとめるノードを作成
            let items = SKNode()
            items.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0)
            items.zPosition = -70 // 雲より手前、地面より奥、壁より奥

            // アイテムの中央位置にランダム値を足して、アイテムの表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let item_y = item_center_y + random_y

            // アイテムを作成
            let itemSpriteNode = SKSpriteNode(texture: itemTexture)
            itemSpriteNode.position = CGPoint(x: 0, y: item_y)

            // アイテムに物理体を設定する
            itemSpriteNode.physicsBody = SKPhysicsBody(rectangleOf: itemTexture.size())
            itemSpriteNode.physicsBody?.categoryBitMask = self.itemCategory
            itemSpriteNode.physicsBody?.isDynamic = false

            // アイテムをまとめるノードに追加
            items.addChild(itemSpriteNode)
            self.currentItem = itemSpriteNode

            // スコアカウント用の透明なアイテムを作成
            let itemScoreNode = SKNode()
            itemScoreNode.position = CGPoint(x: 0, y: item_y)
            // 透明なアイテムに物理体を設定する
            itemScoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSpriteNode.size.width, height: itemSpriteNode.size.height))
            itemScoreNode.physicsBody?.categoryBitMask = self.itemScoreCategory
            itemScoreNode.physicsBody?.isDynamic = false
            // アイテムをまとめるノードに透明なアイテムを追加
            items.addChild(itemScoreNode)

            // アイテムをまとめるノードにアニメーションを設定
            items.run(itemAnimation)

            // アイテムを表示するノードに今回作成したアイテムを追加
            self.itemNode.addChild(items)
        })
        // 次のアイテム作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 3)

        // アイテムを作成->時間待ち->アイテムを作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))

        // アイテムを表示するノードにアイテムの作成を無限に繰り返すアクションを設定
        itemNode.run(repeatForeverAnimation)
    }

    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }

        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコアカウント用の透明な壁と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"

            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
        } else if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
            // アイテムスコアカウント用の透明な壁と衝突した
            print("ItemScoreUp")
            itemScore += 1
            itemScoreLabelNode.text = "ItemScore:\(itemScore)"

            // ベストスコア更新か確認する
            var bestItemScore = userDefaults.integer(forKey: "BEST_ITEM")
            if itemScore > bestItemScore {
                bestItemScore = itemScore
                bestItemScoreLabelNode.text = "Best Item Score:\(bestItemScore)"
                userDefaults.set(bestItemScore, forKey: "BEST_ITEM")
                userDefaults.synchronize()
            }
            
            // アイテムを削除
            let remove = SKAction.removeFromParent()
            currentItem.run(remove)
        } else {
            // 壁か地面と衝突した
            print("GameOver")

            // スクロールを停止させる
            scrollNode.speed = 0

            // 衝突後は地面と反発するのみとする(リスタートするまで壁と反発させない)
            bird.physicsBody?.collisionBitMask = groundCategory

            // 衝突後1秒間、鳥をくるくる回転させる
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }

    func restart() {
        // スコアを0にする
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemScore = 0
        itemScoreLabelNode.text = "Item Score:\(itemScore)"

        // 鳥を初期位置に戻し、壁と地面の両方に反発するように戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0

        // 全ての壁を取り除く
        wallNode.removeAllChildren()

        // 鳥の羽ばたきを戻す
        bird.speed = 1

        // スクロールを再開させる
        scrollNode.speed = 1
    }
    
    func setupScoreLabel() {
        // スコア表示を作成
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.text = "Score:\(score)"
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)

        // ベストスコア表示を作成
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)

        // アイテムスコア表示を作成
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.text = "Score:\(itemScore)"
        itemScoreLabelNode.fontColor = UIColor.darkGray
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
        
        // アイテムのベストスコア表示を作成
        let bestItemScore = userDefaults.integer(forKey: "BEST_ITEM")
        bestItemScoreLabelNode = SKLabelNode()
        bestItemScoreLabelNode.fontColor = UIColor.darkGray
        bestItemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 150)
        bestItemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestItemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestItemScoreLabelNode.text = "Best Item Score:\(bestItemScore)"
        self.addChild(bestItemScoreLabelNode)

    }
}
