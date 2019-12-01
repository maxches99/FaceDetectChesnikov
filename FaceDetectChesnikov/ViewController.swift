//
//  ViewController.swift
//  FaceDetectChesnikov
//    MIT License
//
//    Copyright (c) 2019 Max Chesnikov
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

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
