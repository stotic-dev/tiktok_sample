//
//  PreviewViewController.swift
//  Swift6TikTok
//
//  Created by 佐藤汰一 on 2021/09/28.
//

import UIKit
import AVKit

class PreviewViewController: UIViewController {
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    var movieURL:URL?
    var musicURL:URL?
    var playerController:AVPlayerViewController?
    var player:AVPlayer?
    var captionString:String?
    var sendUrl:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        musicButton.addTarget(self, action: #selector(tappedMusicButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(tappedNextButton), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(tappedEditButton), for: .touchUpInside)
        
        guard let url = self.movieURL else { return }
        setUpVideoPlayer(url: url)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //selectViewController
        if segue.identifier == "SelectSegue"{
            let selectViewController = segue.destination as! SelectViewController
            
            selectViewController.passedURL = self.movieURL
            
            DispatchQueue.global().async {
                
                selectViewController.resultHandler = {url,text1,text2,musicUrl in
                    self.sendUrl = url
                    self.setUpVideoPlayer(url: URL(string: url)!)
                    self.captionString = text1 + "\n" + text2
                    self.musicURL = URL(string: musicUrl)
                }
            }
        }
        
        //shareViewController
        if segue.identifier == "ShareSegue"{
            let shareViewController = segue.destination as! ShareViewController
            shareViewController.captionString = captionString
            shareViewController.passedUrl = sendUrl
        }
        
        //editViewController
        if segue.identifier == "EditSegue"{
            let editViewController = segue.destination as! EditViewController
            editViewController.delegate = self
            editViewController.videoURL = movieURL
            
            if(musicURL != nil){
                editViewController.musicURL = musicURL
            }
            
        }
    }
    
    private func setUpVideoPlayer(url:URL){
        
        playerController?.removeFromParent()
        player = nil
        player = AVPlayer(url: url)
        player?.volume = 1.0
        view.backgroundColor = .black
        
        playerController = AVPlayerViewController()
        playerController?.videoGravity = .resizeAspectFill
        playerController?.view.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height - 100)
        playerController?.showsPlaybackControls = false
        playerController?.player = player
        self.addChild(playerController!)
        self.view.addSubview((playerController?.view)!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        
        let cancelButton = UIButton(frame: CGRect(x: 10.0, y: 10.0, width: 30, height: 30))
        cancelButton.setImage(UIImage(named: "cancel"), for: UIControl.State())
        cancelButton.addTarget(self, action: #selector(tappedCancelButton), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        player?.play()
    }
    
    @objc private func tappedCancelButton(){
        player?.pause()
        player = nil
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func tappedMusicButton(){
        player?.pause()
        performSegue(withIdentifier: "SelectSegue", sender: nil)
    }
    
    @objc private func tappedNextButton(){
        if self.captionString != nil{
            player?.pause()
            performSegue(withIdentifier: "ShareSegue", sender: nil)
            
        }else{
            print("楽曲を選択してください")
            let alertViewController = UIAlertController(title: "アラート", message: "楽曲を選択してください", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertViewController.addAction(action)
            present(alertViewController, animated: true, completion: nil)
        }
        
        
    }
    
    @objc private func tappedEditButton(){
        player?.pause()
        performSegue(withIdentifier: "EditSegue", sender: nil)
    }
    
    @objc private func playerItemDidReachEnd(_ notification:Notification){
        if player != nil{
            self.player?.seek(to: CMTime.zero)
            self.player?.volume = 1
            self.player?.play()
        }
    }
}

extension PreviewViewController:EditViewControllerDelegate{
    func trimEnd(url: URL) {
        DispatchQueue.main.async {
            self.setUpVideoPlayer(url: url)
        }
    }
}
