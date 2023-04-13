//
//  ShareViewController.swift
//  Swift6TikTok
//
//  Created by 佐藤汰一 on 2021/10/09.
//

import UIKit
import AVKit
import Photos

class ShareViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    var captionString:String?
    var passedUrl:String?
    var player:AVPlayer?
    var playerViewController:AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.isEditable = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        navigationController?.isNavigationBarHidden = true
        
        let notification = NotificationCenter.default
        notification.addObserver(self, selector: #selector(keyboadWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notification.addObserver(self, selector: #selector(keyboadWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        guard let url = URL(string: passedUrl!) else { return }
        setupPlayer(url: url)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
    }
    
    private func setupPlayer(url:URL){
        self.view.backgroundColor = .black
        playerViewController?.removeFromParent()
        player = AVPlayer(url: url)
        player?.volume = 1.0
        
        playerViewController = AVPlayerViewController()
        let center = CGPoint(x: view.frame.width/2, y: view.frame.height/2)
        let size = CGSize(width: view.frame.width, height: view.frame.height/1.7)
        playerViewController?.view.frame = CGRect(x: center.x - size.width/2, y: 0, width: size.width, height: size.height)
        playerViewController?.videoGravity = .resizeAspectFill
        playerViewController?.showsPlaybackControls = false
        playerViewController?.player = player
        self.addChild(playerViewController!)
        self.view.addSubview((playerViewController?.view)!)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(loopAvPlayer), name: .AVPlayerItemDidPlayToEndTime, object: playerViewController?.player?.currentItem!)
        
        player?.play()
     }
    
    private func showAlert(){
        let alertViewController = UIAlertController(title: "エラー", message: "動画の保存に失敗しました", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertViewController.addAction(action)
        present(alertViewController, animated: true, completion: nil)
    }
    
    
    @IBAction func saveAction(_ sender: Any) {
        PHPhotoLibrary.shared().performChanges {
            guard let url = URL(string: self.passedUrl!) else { return }
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        } completionHandler: { result, error in
            
            if let error = error{
                print(error.asAFError.debugDescription)
                self.showAlert()
                return
            }
            
            if result{
                print("動画を保存しました")
            }
        }

    }
    
    @IBAction func shareAction(_ sender: Any) {
        guard let urlString = passedUrl,let textViewString = textView.text,let captionString = captionString else { return }
        let activeString = "\(textViewString.debugDescription)\n\(captionString)\n#UdemyTikTokIOS14"
        let dic = [URL(string: urlString) as Any, activeString] as [Any]
        let activityViewController = UIActivityViewController(activityItems: dic, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.popoverPresentationController?.sourceRect = self.view.frame
        present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func returnAction(_ sender: Any) {
        player?.pause()
        player = nil
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func keyboadWillShow(_ notification:Notification){
        let rect = notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: duration) {
            self.view.transform = CGAffineTransform(translationX: 0, y: -(rect.size.height))
        }
    }
    
    @objc private func keyboadWillHide(_ notification:Notification){
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        UIView.animate(withDuration: duration) {
            self.view.transform = CGAffineTransform.identity
        }
    }
    
    @objc private func loopAvPlayer(){
        if player != nil{
            player?.seek(to: CMTime.zero)
            player?.volume = 1
            player?.play()
        }

    }
    
}
