//
//  ViewController.swift
//  FaceDetectChesnikov

//  Created by Максим Чесников on 30.11.2019.
//  Copyright © 2019 Максим Чесников. All rights reserved.
//

import UIKit
import AVKit
import Vision
import ARKit
import CoreML
import SceneKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ARSessionDelegate {
    
    let sceneView = ARSCNView(frame: UIScreen.main.bounds)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.showsStatistics = true
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    var k = 0
    var sum = 0

}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        guard let device = sceneView.device else {
            return nil
        }
        
        let faceGeometry = ARSCNFaceGeometry(device: device)
        
        let node = SCNNode(geometry: faceGeometry)
        
        node.geometry?.firstMaterial?.fillMode = .lines
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else {
                return
        }
        
        faceGeometry.update(from: faceAnchor.geometry)
        
        let text = SCNText(string: "", extrusionDepth: 2)
        let font = UIFont(name: "Avenir-Heavy", size: 18)
        text.font = font
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        text.materials = [material]
        text.firstMaterial?.isDoubleSided = true
        
        let textNode = SCNNode(geometry: faceGeometry)
        textNode.position = SCNVector3(-0.1, -0.01, -0.5)
        print(textNode.position)
        textNode.scale = SCNVector3(0.002, 0.002, 0.002)
        
        textNode.geometry = text
        //self.sceneView.scene.rootNode.addChildNode(textNode)
        guard let model = try? VNCoreMLModel(for: face2().model) else {
            fatalError("Unable to load model")
        }
        
        
        let coreMlRequest = VNCoreMLRequest(model: model) {[weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first
                else {
                    fatalError("Unexpected results")
            }

            DispatchQueue.main.async {[weak self] in
                print(topResult.identifier)
                self!.sum += 1
                print(self!.sum)
                print(self!.k)
                if topResult.identifier != "UNKNOWN" {
                    
                    text.string = topResult.identifier
                    self!.sceneView.scene.rootNode.addChildNode(textNode)
                    self!.sceneView.autoenablesDefaultLighting = true
                    print(self!.sum)
                    print(self!.k)
                }
                else{
                    self!.k += 1
                   
                }
            }
        }
        
        guard let pixelBuffer = self.sceneView.session.currentFrame?.capturedImage else { return }
        
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        DispatchQueue.global().async {
            do {
                try handler.perform([coreMlRequest])
            } catch {
                print(error)
            }
        }
    }
    
}
