//
//  ViewController.swift
//  Floor is lava
//
//  Created by Ivan Ken Tiu on 25/09/2017.
//  Copyright © 2017 Ivan Ken Tiu. All rights reserved.
//

import UIKit
import ARKit
import CoreMotion

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    let motionManager = CMMotionManager()
    var vehicle = SCNPhysicsVehicle()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        // detect horizontal surfaces easy!
        self.configuration.planeDetection = .horizontal
        
        self.sceneView.session.run(configuration)
        
        // so that delegate function can get called!
        self.sceneView.delegate = self
        self.setUpAccelerometer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // pass in PlaneAnchor
    func createConcrete(planeAnchor: ARPlaneAnchor) -> SCNNode {
        // base it on the size of planeAnchor
        let concreteNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)))
        concreteNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "concrete")
        concreteNode.geometry?.firstMaterial?.isDoubleSided = true
        concreteNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        // align to detected surface by centering it relative to the horizontal
        concreteNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        
        // give floor a static body(unaffected by force or gravity) shortcut
        let staticBody = SCNPhysicsBody.static()
        concreteNode.physicsBody = staticBody
        
        return concreteNode
    }
    
    // when a new horizontal surface is detected (didAdd) , check ARAnchor added to sceneView
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // have to replace that surface with lava
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        // make sure lava node is position relative to the discovered node
        node.addChildNode(concreteNode)
        
        print("new flat surface detected, new ARPlaneAnchor added")
    }
    
    // Phone discover Floor is bigger keep updating ARPlaneAnchor
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        print("updating floor's anchor")
        // remove
        node.enumerateChildNodes { (childNode,_) in
            childNode.removeFromParentNode()
        }
        // then updated (plane anchor)
        let concreteNode = createConcrete(planeAnchor: planeAnchor)
        node.addChildNode(concreteNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // no need to use variable? add _
        guard let _ = anchor as? ARPlaneAnchor else { return }
        // if plane anchor removed need to make sure need to remove lavanode associated with this plane anchor
        node.enumerateChildNodes { (childNode,_) in
            childNode.removeFromParentNode()
        }
    }

    // add the car
    @IBAction func addCar(_ sender: Any) {
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        
        // add the scene then car node
        let scene = SCNScene(named: "Car-Scene.scn")
        let chassis = (scene?.rootNode.childNode(withName: "chassis", recursively: false))!
        let frontLeftWheel = (chassis.childNode(withName: "frontLeftParent", recursively: false))!
        let frontRightWheel = (chassis.childNode(withName: "frontRightParent", recursively: false))!
        let rearLeftWheel = (chassis.childNode(withName: "rearLeftParent", recursively: false))!
        let rearRightWheel = (chassis.childNode(withName: "rearRightParent", recursively: false))!
        
        let v_frontLeftWheel = SCNPhysicsVehicleWheel(node: frontLeftWheel)
        let v_frontRightWheel = SCNPhysicsVehicleWheel(node: frontRightWheel)
        let v_rearLeftWheel = SCNPhysicsVehicleWheel(node: rearLeftWheel)
        let v_rearRightWheel = SCNPhysicsVehicleWheel(node: rearRightWheel)
        
        chassis.position = currentPositionOfCamera
        // add physics here
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: chassis, options: [SCNPhysicsShape.Option.keepAsCompound: true]))
        
        // apply body to box node
        chassis.physicsBody = body
        self.vehicle = SCNPhysicsVehicle(chassisBody: chassis.physicsBody!, wheels: [v_rearRightWheel, v_rearLeftWheel, v_frontRightWheel, v_frontLeftWheel])
        // add behaviour to car
        self.sceneView.scene.physicsWorld.addBehavior(self.vehicle)
        self.sceneView.scene.rootNode.addChildNode(chassis)
    }
    
    func setUpAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1/60
            // this function will get trigger 60 times a sec or 1/60
            motionManager.startAccelerometerUpdates(to: .main, withHandler: { (accelerometerData, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                self.accelerometerDidChange(acceleration: accelerometerData!.acceleration)
            })
        } else {
            print("accelerometer not available")
        }
    }
    
    // call in block
    func accelerometerDidChange(acceleration: CMAcceleration) {
        print(acceleration.x)
        print(acceleration.y)
        print("")
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180 }
}

