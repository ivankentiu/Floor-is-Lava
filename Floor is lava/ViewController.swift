//
//  ViewController.swift
//  Floor is lava
//
//  Created by Ivan Ken Tiu on 25/09/2017.
//  Copyright © 2017 Ivan Ken Tiu. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        // detect horizontal surfaces easy!
        self.configuration.planeDetection = .horizontal
        
        self.sceneView.session.run(configuration)
        
        // so that delegate function can get called!
        self.sceneView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // pass in PlaneAnchor
    func createLava(planeAnchor: ARPlaneAnchor) -> SCNNode {
        // base it on the size of planeAnchor
        let lavaNode = SCNNode(geometry: SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z)))
        lavaNode.geometry?.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "Lava")
        lavaNode.geometry?.firstMaterial?.isDoubleSided = true
        lavaNode.eulerAngles = SCNVector3(90.degreesToRadians, 0, 0)
        // align to detected surface by centering it relative to the horizontal
        lavaNode.position = SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        return lavaNode
    }
    
    // when a new horizontal surface is detected (didAdd) , check ARAnchor added to sceneView
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // have to replace that surface with lava
        let lavaNode = createLava(planeAnchor: planeAnchor)
        // make sure lava node is position relative to the discovered node
        node.addChildNode(lavaNode)
        
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
        let lavaNode = createLava(planeAnchor: planeAnchor)
        node.addChildNode(lavaNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // no need to use variable? add _
        guard let _ = anchor as? ARPlaneAnchor else { return }
        // if plane anchor removed need to make sure need to remove lavanode associated with this plane anchor
        node.enumerateChildNodes { (childNode,_) in
            childNode.removeFromParentNode()
        }
    }

}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180 }
}

