/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit
import GameplayKit
import ARKit

class GameScene: SKScene {
  
  //MARK: - Convenience property
  var sceneView: ARSKView {
    return view as! ARSKView
  }
  
  var sight: SKSpriteNode!
  
  // determines real-world area you are playing in
  // 2 x 2 meter space with you in the middle
  let gameSize = CGSize(width: 2, height: 2)
  
  var isWorldSetup = false
  
  private func setUpWorld() {
    guard let currentFrame = sceneView.session.currentFrame else { return }
    
    isWorldSetup = true
    
    // set up a 4 dimensional matrix
    var translation = matrix_identity_float4x4
    translation.columns.3.z = -0.3
    let transform = currentFrame.camera.transform * translation
    
    let anchor = ARAnchor(transform: transform)
    sceneView.session.add(anchor: anchor)
  }
  
  //MARK: - Frame Lifecycle
  override func update(_ currentTime: TimeInterval) {
    if !isWorldSetup {
      setUpWorld()
    }
    
    guard let currentFrame = sceneView.session.currentFrame, let lightEstimate = currentFrame.lightEstimate else {
      return
    }
    
    // Blending it into the background
    let neutralIntensity: CGFloat = 1000
    let ambientIntensity = min(lightEstimate.ambientIntensity, neutralIntensity)
    let blendFactor = 1 - ambientIntensity / neutralIntensity
    
    for node in children {
      if let bug = node as? SKSpriteNode {
        bug.color = .red
        bug.colorBlendFactor = blendFactor
      }
    }
  }
  
  override func didMove(to view: SKView) {
    sight = SKSpriteNode(imageNamed: "sight")
    addChild(sight)
  }
  
  override func  touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    let location = sight.position
    // retrieve an array of all the nodes tha tinersect the same xy location as the sight
    let hitNodes = nodes(at: location)
    
    var hitBug: SKNode?
    for node in hitNodes {
      if node.name == "bug" {
        hitBug = node
        break
      }
    }
    
    run(Sounds.fire)
    
    if let hitBug = hitBug, let anchor = sceneView.anchor(for: hitBug) {
      let action = SKAction.run {
        self.sceneView.session.remove(anchor: anchor)
      }
      let group = SKAction.group([Sounds.hit, action])
      let sequence = [SKAction.wait(forDuration: 0.3), group]
      hitBug.run(SKAction.sequence(sequence))
    }
  }
}

