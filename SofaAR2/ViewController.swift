//
//  ViewController.swift
//  SofaAR2
//
//  Created by Paul Wallace on 12/26/17.
//  Copyright © 2017 Paul Wallace. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController {

    @IBOutlet var doublePressGestureRecognizer: UILongPressGestureRecognizer! {
        willSet {
            newValue.numberOfTouchesRequired = 2
            newValue.allowableMovement = 20
            newValue.minimumPressDuration = 0.1
            newValue.delegate = self
        }
    }
    @IBOutlet var rotationGestureRecognizer: UIRotationGestureRecognizer! {
        willSet {
            newValue.delegate = self
        }
    }
    
    @IBOutlet var sceneView: ARSCNView! {
        willSet {
            newValue.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
            newValue.automaticallyUpdatesLighting = true
        }
    }
    var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet var arStateLabel: UILabel! {
        willSet {
            newValue.text = ""
        }
    }
    
    var rotationReady : Bool = false
    var rotatingNode : SCNNode?
    var translatingNode : SCNNode?
    override func viewDidLoad() {
        super.viewDidLoad()
        //Load the scene from art.scnassets
        guard let scene = SCNScene(named: "art.scnassets/main.scn") else {return}
        sceneView.scene = scene
        //no lighting environment yet
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        session.delegate = self
        session.run(configuration, options: [])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let light = SCNLight()
        light.type = .ambient
        let ambientLightNode = SCNNode()
        ambientLightNode.position = SCNVector3(0,5,0)
        ambientLightNode.light = light
        sceneView.scene.rootNode.addChildNode(ambientLightNode)
    }
    
    @IBAction func screenDoublePressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.ended {
            print("Screen two finger long press ended")
            rotationReady = false
            rotatingNode = nil
        } else {
            //Get the rotating node if not already gotten
            if rotatingNode == nil {
                let location = sender.location(ofTouch: 0, in: sceneView)
                let results = sceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly: true])
                if let firstObj = results.first {
                    rotatingNode = firstObj.node
                }
                if !rotationReady {rotationReady = true}
            }
        }
    }

    @IBAction func screenRotated(_ sender: UIRotationGestureRecognizer) {
        print("Screen Rotated")
        //Only works if rotationReady is set to true
        if !rotationReady {return}
        if let node = rotatingNode {
            node.eulerAngles.y += Float(sender.rotation)
            sender.rotation = 0
        }
    }
    
    @IBAction func screenDragged(_ sender: UIPanGestureRecognizer) {
        print("Screen Dragged")
        
        if sender.state == UIGestureRecognizerState.ended {
            print("Screen Drag Ended")
            translatingNode = nil
            return
        }
        
        let location = sender.location(in: sceneView)
        let translation = sender.translation(in: sceneView)
        let finalPoint = CGPoint(x: translation.x + location.x, y: translation.y + location.y)
//        DispatchQueue.global(qos: .userInteractive).async {
        print("Running async dispatched code for drag recognizer")
        
        
        if self.translatingNode == nil {
            print("Finding a Translating Node")
            let objectResults = self.sceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly : true])
            if let object = objectResults.first {
                if object.node.name != "sofa" {return}
                self.translatingNode = object.node
                print("FOUND TRANSLATING NODE")
            } else {
                print("No object found!")
                return
            }
            print("FINISHING THE TRANSLATING NODE")
        }
        print("Translating Node Exists")
        //If we get here then we need to move the object now
        self.moveNodeToPlanePositionWhereFingerDragged(finalPoint: finalPoint, sender: sender)
    }
    
    func moveNodeToPlanePositionWhereFingerDragged(finalPoint: CGPoint, sender: UIPanGestureRecognizer) {
        if let node = translatingNode {
            let planeHitTestResults = self.sceneView.hitTest(finalPoint, types: ARHitTestResult.ResultType.existingPlane)
            if let firstPlane = planeHitTestResults.first {
                if let node = translatingNode {
                    let newPosition = SCNVector3.positionFrom(matrix: firstPlane.worldTransform)
                    node.position.x = newPosition.x - 0.5 //only when the origin is off on the object
                    node.position.z = newPosition.z
                    sender.setTranslation(CGPoint.zero, in: self.sceneView)
                }
            } else {
                print("No Plane Found")
            }
        } else {
            print("Translating Node Doesn't Exist")
        }

    }

    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        print("Screen tapped")
        //Add the sofa to the plane
        let location = sender.location(in: sceneView)
        
        DispatchQueue.global(qos: .background).async {
            let results = self.sceneView.hitTest(location, types: ARHitTestResult.ResultType.existingPlane)
            if let result = results.first {
                let x = result.worldTransform.columns.3.x
                let y = result.worldTransform.columns.3.y
                let z = result.worldTransform.columns.3.z
                guard let sofaScene = SCNScene(named: "art.scnassets/sofa-travis.scn") else {return}
                guard let sofaNode = sofaScene.rootNode.childNode(withName: "Sofa", recursively: true) else {return}
                sofaNode.position = SCNVector3(x, y + 0.55, z)
                //Rotate the sofaNode to face the camera
                let roll =  self.sceneView.pointOfView!.eulerAngles.z
                let pitch = self.sceneView.pointOfView!.eulerAngles.x
                let yaw = self.sceneView.pointOfView!.eulerAngles.y
                if( yaw > 0 ) { //Left side of the circle
                    if (roll == 0.0) {
                        // Actually on right side, edge case
                        sofaNode.eulerAngles.y = 0;
                    } else if (abs(roll) > abs(yaw) && abs(pitch) > abs(yaw) && ( abs(yaw) > 0.2 || (abs(roll) > 2.5 && abs(pitch) > 2.5))) {
                        // Back left
                        sofaNode.eulerAngles.y = (-1 * (Float.pi/2 + yaw))
                        print(((Float.pi * 2) + (sofaNode.eulerAngles.y)) * (180/Float.pi))
                    } else {
                        // Front left
                        sofaNode.eulerAngles.y = self.sceneView.pointOfView!.eulerAngles.y + Float.pi/2//1.56537
                    }
                } else { //Must be the right side
                    if (roll == 0.0) {
                        sofaNode.eulerAngles.y = Float.pi;
                    } else if (abs(roll) > abs(yaw) && abs(pitch) > abs(yaw) && ( abs(yaw) > 0.2 || (abs(roll) > 2.5 && abs(pitch) > 2.5))) {
                        sofaNode.eulerAngles.y = (-1 * (Float.pi/2 + yaw))
                        // Right lower side
                    } else {
                        sofaNode.eulerAngles.y = Float.pi/2 + self.sceneView.pointOfView!.eulerAngles.y
                    }
                }
                sofaNode.name = "sofa"
                self.sceneView.scene.rootNode.addChildNode(sofaNode)
            }
        }
    }
    
}

extension ViewController: ARSessionObserver {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
            case ARCamera.TrackingState.normal: self.arStateLabel.text = "Tracking is Normal"
            case ARCamera.TrackingState.notAvailable: self.arStateLabel.text = "Tracking is Not Avaliable"
            case ARCamera.TrackingState.limited(let reason):
                switch reason {
                case ARCamera.TrackingState.Reason.excessiveMotion: self.arStateLabel.text = "The Camera is Moving Too Much"
                case ARCamera.TrackingState.Reason.initializing: self.arStateLabel.text = "Initializing AR Functionality..."
                case ARCamera.TrackingState.Reason.insufficientFeatures: self.arStateLabel.text = "Try a Different Background"
                case .relocalizing: self.arStateLabel.text = "Relocalizing"
            }
        }
    }
}

extension ViewController: ARSessionDelegate{
    
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let image = UIImage(named: "art.scnassets/grid.png")
            planeGeometry.firstMaterial?.diffuse.contents = image
            node.simdPosition = simd_float3(planeAnchor.center.x, 0, planeAnchor.center.z) //Or can use the transform
            node.geometry = planeGeometry
            node.eulerAngles.x = -Float.pi/2
//            let fire = SCNParticleSystem(named: "art.scnassets/fire.scnp", inDirectory: nil)!
//            node.addParticleSystem(fire)
            
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let planeNode = node.geometry as! SCNPlane
            planeNode.width = CGFloat(planeAnchor.extent.x)
            planeNode.height = CGFloat(planeAnchor.extent.z)
            node.eulerAngles.x = -Float.pi/2
        }
    }
}

