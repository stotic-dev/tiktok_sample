//
//  SetupViewController.swift
//  Swift6TikTok
//
//  Created by 佐藤汰一 on 2021/09/28.
//

import UIKit
import SwiftyCam
import AVFoundation
import MobileCoreServices

class SetupViewController: SwiftyCamViewController {
    @IBOutlet weak var albumButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var recordButton: SwiftyRecordButton!
    
    var videoURL:URL?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        albumButton.addTarget(self, action: #selector(tappedAlbumButton), for: .touchUpInside)
        flipButton.addTarget(self, action: #selector(tappedFlipButton), for: .touchUpInside)
        
        //swiftyCumの設定
        shouldPrompToAppSettings = true
        cameraDelegate = self
        maximumVideoDuration = 20.0
        shouldUseDeviceOrientation = true
        allowAutoRotate = false
        audioEnabled = false
        recordButton.buttonEnabled = false
        recordButton.delegate = self
        swipeToZoomInverted = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        recordButton.delegate = self
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    private func hideButton(){
        UIView.animate(withDuration: 0.25) {
            self.flipButton.alpha = 0.0
        }
    }
    
    private func showButton(){
        UIView.animate(withDuration: 0.25) {
            self.flipButton.alpha = 1.0
        }
    }
    
    private func forcusAnimationAt(_ point:CGPoint){
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        } completion: { success in
            UIView.animate(withDuration: 0.25, delay: 0.5, options: .curveEaseInOut) {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            } completion: { success in
                self.view.removeFromSuperview()
            }

        }

    }
    
    @objc private func tappedAlbumButton(){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.mediaTypes = ["public.movie"]
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc private func tappedFlipButton(){
        switchCamera()
    }


}

extension SetupViewController:SwiftyCamViewControllerDelegate{
    
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("swiftyCamSessionDidStartRunning")
        recordButton.buttonEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("swiftyCamSessionDidStopRunning")
        recordButton.buttonEnabled = false
    }

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("didBeginRecordingVideo")
        recordButton.growButton()
        showButton()
    }

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
         print("didFinishRecordingVideo")
        recordButton.shrinkButton()
        hideButton()
    }

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
         print("didFinishProcessVideoAt")
        
        print(url.debugDescription)
        let previewViewController = storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as! PreviewViewController
        previewViewController.movieURL = url
        self.navigationController?.pushViewController(previewViewController, animated: true)
    }

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
         forcusAnimationAt(point)
    }

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
          print("ZoomLevel zoom: \(zoom)")
    }

    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
         // Called when user switches between cameras
         // Returns current camera selection
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print("error: \(error)")
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture medea", comment: "Alert message when something goes wrong during capture session configure")
        let alertView = UIAlertController(title: "AVcam", message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
        alertView.addAction(ok)
        self.present(alertView, animated: true, completion: nil)
    }
    
    
    
}

extension SetupViewController:UINavigationControllerDelegate,UIImagePickerControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let movieURL = info[.mediaURL] as? URL else { return }
        videoURL = movieURL
        
        picker.dismiss(animated: true, completion: nil)
        
        let previewViewController = storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as! PreviewViewController
        previewViewController.movieURL = videoURL
        navigationController?.pushViewController(previewViewController, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

