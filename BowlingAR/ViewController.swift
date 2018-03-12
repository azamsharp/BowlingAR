//
//  ViewController.swift
//  BowlingAR
//
//  Created by Mohammad Azam on 2/27/18.
//  Copyright © 2018 Mohammad Azam. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum BodyType : Int {
    case pin = 1
    case ball = 2
    case lane = 4
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var bowlingScene :SCNScene!
    
    private var pinsAdded :Bool = false
    private var pinCount :Int = 1
    private var hud :MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hud = MBProgressHUD.showAdded(to: self.sceneView, animated: true)
        self.hud.label.text = "Detecting Plane..."
       
        self.sceneView.autoenablesDefaultLighting = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        registerGestureRecognizers()
    }
    
    private func registerGestureRecognizers() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        
        // swipe up gesture
        let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeUp))
        swipeUpGestureRecognizer.direction = .up
        self.sceneView.addGestureRecognizer(swipeUpGestureRecognizer)
    }
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if anchor is ARPlaneAnchor {
            
            // add a plane so the pin and the ball can rest on it
            let plane = SCNPlane(width: 5, height: 5)
            let material = SCNMaterial()
            material.isDoubleSided = true
            material.diffuse.contents = UIColor.clear
            
            plane.materials = [material]
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            planeNode.physicsBody?.categoryBitMask = BodyType.lane.rawValue
            planeNode.physicsBody?.collisionBitMask = BodyType.ball.rawValue | BodyType.pin.rawValue
            
            
            planeNode.position = SCNVector3(anchor.transform.columns.3.x,anchor.transform.columns.3.y,anchor.transform.columns.3.z)
            planeNode.eulerAngles = SCNVector3(Double.pi/2,0,0)
            
            self.sceneView.scene.rootNode.addChildNode(planeNode)
            
            DispatchQueue.main.async {
                
                self.hud.label.text = "Plane Found"
                self.hud.hide(animated: true, afterDelay: 1.0)
                
            }
            
        }
        
    }
    
    @objc func swipeUp(recognizer :UISwipeGestureRecognizer) {
        
        let sceneView = recognizer.view as! ARSCNView
        let touch = recognizer.location(in: sceneView)
        
        let hitTestResults = sceneView.hitTest(touch, options: nil)
        
        if let hitTest = hitTestResults.first {
            
            let node = hitTest.node
            
            if node.name == "ball" {
                
                let vectorForce = SCNVector3(0, 0, -5.0)
                node.physicsBody?.applyForce(vectorForce, asImpulse: true)
                
            }
            
        }
        
    }
    
    @objc func tapped(recognizer :UITapGestureRecognizer) {
        
        let sceneView = recognizer.view as! ARSCNView
        let touch = recognizer.location(in: sceneView)
        
        let hitTestResults = sceneView.hitTest(touch, types: .existingPlane)
        
        if let hitTest = hitTestResults.first {
            
            self.bowlingScene = SCNScene(named: "bowling.dae")
            
            if self.pinCount <= 5 {
                
                guard let pin = self.bowlingScene.rootNode.childNode(withName: "pin", recursively: true) else {
                    return
                }
                
                pin.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                pin.physicsBody?.categoryBitMask = BodyType.pin.rawValue
                
                pin.position = SCNVector3(hitTest.worldTransform.columns.3.x,hitTest.worldTransform.columns.3.y + 0.2,hitTest.worldTransform.columns.3.z)
                
                self.sceneView.scene.rootNode.addChildNode(pin)
                self.pinCount += 1
                self.pinsAdded = true
                
            } else {
                
                guard let ball = self.bowlingScene.rootNode.childNode(withName: "ball", recursively: true) else {
                    return
                }
                
                ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                ball.physicsBody?.categoryBitMask = BodyType.ball.rawValue
                
                ball.position = SCNVector3(hitTest.worldTransform.columns.3.x,hitTest.worldTransform.columns.3.y + 0.4,hitTest.worldTransform.columns.3.z)
                
                self.sceneView.scene.rootNode.addChildNode(ball)
                
            }
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}
