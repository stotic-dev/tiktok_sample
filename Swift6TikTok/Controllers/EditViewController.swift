//
//  EditViewController.swift
//  Swift6TikTok
//
//  Created by 佐藤汰一 on 2021/10/13.
//

import UIKit
import PryntTrimmerView
import AVFoundation
import MobileCoreServices
import SwiftVideoGenerator
import SwiftMessages

protocol EditViewControllerDelegate {
    func trimEnd(url:URL)
}

class EditViewController: UIViewController {
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trimmerView: TrimmerView!
    
    var videoURL:URL?
    var musicURL:URL?
    var newVideoURL:URL?
    var asset:AVAsset?
    var player:AVPlayer?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?
    var delegate : EditViewControllerDelegate?
    
    var duration:CMTimeRange?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        trimmerView.mainColor = .white
        trimmerView.handleColor = .darkGray
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        guard let videoURL = self.videoURL else { return }
        setupAsset(videoURL: videoURL)
    }
    
    private func setupAsset(videoURL:URL){
        asset = AVURLAsset(url: videoURL)
        self.duration = CMTimeRange(start: .zero, duration: asset!.duration)
        
        trimmerView.asset = self.asset
        trimmerView.delegate = self
        print("startTime:\(trimmerView.startTime),endTime:\(trimmerView.endTime)")
        addVideoPlayer(with: self.asset!, playerView: playerView)
    }
    
    private func addVideoPlayer(with asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
    }
    
    private func startPlaybackTimeChecker(){
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer(timeInterval: 0.1, target: self, selector: #selector(onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }
    
    private func stopPlaybackTimeChecker(){
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    private func trim(asset:AVAsset) throws{
        var videoTrack:AVAssetTrack
        let videoTracks = asset.tracks(withMediaType: .video)
        videoTrack = videoTracks[0]
        
        let mixComposition = AVMutableComposition()
        
        let compositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try compositionVideoTrack?.insertTimeRange(duration!, of: videoTrack, at: CMTime.zero)
        
        exportAsset(asset: mixComposition)
    }
    
    private func exportAsset(asset:AVAsset){
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else { return }
        let documentUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("trimmerVideoFile.mp4")
        session.outputURL = URL(fileURLWithPath: documentUrl.path)
        session.outputFileType = .mp4
        
        if FileManager.default.fileExists(atPath: session.outputURL!.path){
            do {
                try FileManager.default.removeItem(atPath: session.outputURL!.path)
            } catch let error as Error {
                print(error.asAFError.debugDescription)
            }
        }
        
        session.exportAsynchronously {
            
            switch session.status{
            case .completed:
                print("動画の保存を完了")
                print(session.outputURL?.absoluteString)
                self.newVideoURL = session.outputURL
                
                if self.musicURL != nil{
                    self.generateVideoAndAudio(videoUrl: session.outputURL!)
                }
                
                guard let url = self.newVideoURL else { return }
                self.delegate?.trimEnd(url: url)
                
                DispatchQueue.main.async {
                    self.player?.pause()
                    self.player = nil
                    self.stopPlaybackTimeChecker()
                    self.dismiss(animated: true, completion: nil)
                }
                break
                
            case .failed:
                print("動画の保存に失敗")
                self.showAlert()
                break
                
            case .cancelled:
                print("動画の保存をキャンセル")
                break
                
            default: break
            }
        }
    }
    
    private func generateVideoAndAudio(videoUrl:URL){
        VideoGenerator.fileName = "newAudioMovie"
        VideoGenerator.current.mergeVideoWithAudio(videoUrl: videoUrl, audioUrl: musicURL!) { result in
            switch result{
            case .success(let url):
                self.newVideoURL = url
                break
            case .failure:
                self.showAlert()
                break
            }
        }
    }
    
    private func showAlert(){
        let view = MessageView.viewFromNib(layout: .messageView)
        view.configureTheme(.error)
        view.configureContent(title: "エラー", body: "動画の保存に失敗しました")
        
        view.button?.setTitle("OK", for: .normal)

        view.layer.cornerRadius = 10
        
        SwiftMessages.show(view: view)
    }
    
    @objc private func onPlaybackTimeChecker(){
        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else { return }
        
        let playbackTime = player.currentTime()
        trimmerView.seek(to: playbackTime)
        
        if playbackTime >= endTime{
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
    
    
    
    @objc private func itemDidFinishPlaying(_ notification:Notification){
        if let startTime = trimmerView.startTime{
            player?.seek(to: startTime)
            if player?.isPlaying != true {
                player?.play()
            }
        }
        
    }

    
    @IBAction func playAction(_ sender: Any) {
        if player?.isPlaying == true {
            player?.pause()
            stopPlaybackTimeChecker()
        }else{
            player?.play()
            startPlaybackTimeChecker()
        }
    }
    
    @IBAction func editAction(_ sender: Any) {
        do {
            guard let asset = self.asset else { return }
            try trim(asset: asset)
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
}

extension EditViewController:TrimmerViewDelegate{
    func didChangePositionBar(_ playerTime: CMTime) {
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        startPlaybackTimeChecker()
        duration = CMTimeRange(start: trimmerView.startTime!, end: trimmerView.endTime!)
    }
    
    
}
