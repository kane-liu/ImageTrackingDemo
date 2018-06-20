//
//  ViewController.swift
//  ImageTrackingDemo
//
//  Created by 劉 柯 on 2018/06/15.
//  Copyright © 2018年 Ryu Ka. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: Video Player
    let videoPlayer: AVPlayer? = {
        guard let videoURL = Bundle.main.url(forResource: "video1", withExtension: "mp4", subdirectory: "art.scnassets") else {
            print("Video1 not exsiting")
            return nil
        }
        
        return AVPlayer(url: videoURL)
    }()
    
    @objc public func repeatVideo() {
        videoPlayer?.seek(to: .zero)
        videoPlayer?.play()
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSceneView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startImageTracking()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(repeatVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopImageTracking()
        
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    // MARK: SceneView
    private func setupSceneView() {
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
    }
    
    // MARK: Image Tracking by ARKit2.0
    private func startImageTracking() {
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("No Tracking images")
        }
        
        let configration = ARImageTrackingConfiguration()
        configration.trackingImages = trackingImages
        configration.maximumNumberOfTrackedImages = 2
        
        sceneView.session.run(configration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func stopImageTracking() {
        sceneView.session.pause()
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let anchor = anchor as? ARImageAnchor {
            let plane = SCNPlane(width: anchor.referenceImage.physicalSize.width, height: anchor.referenceImage.physicalSize.height)
            
            if anchor.referenceImage.name == "trackingImage1" {
                plane.firstMaterial?.diffuse.contents = videoPlayer
                videoPlayer?.play()
            }
            
            let planeNode = SCNNode(geometry: plane)
            /*
             `SCNPlane` is vertically oriented in its local coordinate space, but
             `ARImageAnchor` assumes the image is horizontal in its local space, so
             rotate the plane to match.
             */
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
        }
        
        return node
    }
}

extension ViewController: ARSessionDelegate {
 
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        print(error.localizedDescription)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        print("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        print("Session interruption ended")
        
        startImageTracking()
    }
}
