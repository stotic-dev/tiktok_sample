//
//  SelectViewController.swift
//  Swift6TikTok
//
//  Created by 佐藤汰一 on 2021/09/28.
//

import UIKit
import SDWebImage
import Alamofire
import AVFoundation
import SwiftVideoGenerator
import SwiftyJSON

class SelectViewController: UIViewController {
    @IBOutlet weak var tableVIew: UITableView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    let cellId = "musicCell"
    var resultHandler:((String,String,String,String)->Void)?
    
    var player:AVAudioPlayer?
    var videoPath:String?
    var passedURL:URL?
    var musicModel = MusicModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableVIew.delegate = self
        tableVIew.dataSource = self
        
        searchTextField.delegate = self
        
        searchButton.isEnabled = false
        searchButton.addTarget(self, action: #selector(tappedSearchButton), for: .touchUpInside)
        
        indicator.isHidden = true
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchTextField.resignFirstResponder()
    }
    
    private func reflesData(){
        indicator.isHidden = false
        indicator.startAnimating()
        guard let searchText = searchTextField.text else { return }
        let searchString = String(describing: searchText)
        let urlString = "https://itunes.apple.com/search?term=\(searchString)&entity=song&country=jp"
        
        guard let encodeURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        indicator.color = .blue
        self.musicModel.delegate = self
        self.musicModel.setData(resultCount: 50, encodeUrlString: encodeURLString)
        indicator.color = .red
        
        DispatchQueue.main.async {
            self.searchTextField.resignFirstResponder()
        }
    }
    
    private func downloadMusicURL(url:URL){
        let downloadTask:URLSessionDownloadTask = URLSession.shared.downloadTask(with: url) { url, res, error in
            if let error = error{
                print("楽曲のダウンロードに失敗しました\(error)")
                return
            }
            
            guard let url = url else { return }
            self.play(url: url)
            
        }
        downloadTask.resume()
        
    }
    
    private func play(url:URL){
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.volume = 1.0
            player?.play()
            
        } catch let error {
            print(error.asAFError.debugDescription)
            return
        }
    }
    
    @objc private func tappedSearchButton(){
        reflesData()
    }
    
}

extension SelectViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicModel.artistNameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        cell.selectionStyle = .none
        
        let artistImageView = cell.contentView.viewWithTag(1) as! UIImageView
        artistImageView.layer.cornerRadius = 10.0
        artistImageView.contentMode = .scaleAspectFill
        artistImageView.sd_setImage(with: URL(string: musicModel.artworkUrlStringArray[indexPath.row]), completed: nil)
        
        let musicNameLabel = cell.contentView.viewWithTag(2) as! UILabel
        musicNameLabel.text = musicModel.truckNameArray[indexPath.row]
        
        let artistNameLabel = cell.contentView.viewWithTag(3) as! UILabel
        artistNameLabel.text = musicModel.artistNameArray[indexPath.row]
        
        let favButton = UIButton(frame: CGRect(x: 301, y: 50.5, width: 40, height: 40))
        favButton.addTarget(self, action: #selector(tappedFavButton(_:)), for: .touchUpInside)
        favButton.setImage(UIImage(named: "fav"), for: .normal)
        favButton.tag = indexPath.row
        cell.contentView.addSubview(favButton)
        
        let playButton = UIButton(frame: CGRect(x: 20, y: 15, width: 100, height: 100))
        playButton.addTarget(self, action: #selector(tappedPlayButton(_:)), for: .touchUpInside)
        playButton.setImage(UIImage(named: "play"), for: .normal)
        playButton.tag = indexPath.row
        cell.contentView.addSubview(playButton)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let previewViewController = storyboard?.instantiateViewController(withIdentifier: "PreviewViewController") as! PreviewViewController
        previewViewController.movieURL = URL(string: musicModel.musicUrlStringArray[indexPath.row])
        navigationController?.popViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 135
    }
    
    @objc private func tappedFavButton(_ sender:UIButton){
        
        if player?.isPlaying == true{
            player?.stop()
        }
        
        //動画と音声をマージする（時間がかかる）
        
        //loadingIngicatorを出す
        LoadingView.lockView()
        
        VideoGenerator.fileName = "newAudioMovie"
        VideoGenerator.current.mergeVideoWithAudio(videoUrl: self.passedURL!, audioUrl: URL(string: self.musicModel.musicUrlStringArray[sender.tag])!) { result in
            
            LoadingView.unlockView()
            
            switch result{
            case .success(let url):
                //合成した動画を前の画面に渡して戻る
                
                self.videoPath = url.absoluteString
                if let handler = self.resultHandler{
                    
                    handler(self.videoPath!,self.musicModel.artistNameArray[sender.tag],self.musicModel.truckNameArray[sender.tag],self.musicModel.musicUrlStringArray[sender.tag])
                }
                
                self.player?.stop()
                self.player = nil
                
                self.dismiss(animated: true, completion: nil)
                
            case .failure(let error):
                print("動画と楽曲のマージに失敗しました\(error.localizedDescription)")
                break
            }
        }
        
        
        
    }
    
    @objc private func tappedPlayButton(_ sender:UIButton){
        
        //音楽を止める
        if player?.isPlaying == true{
            player?.stop()
        }
        
        guard let url = URL(string: musicModel.musicUrlStringArray[sender.tag]) else { return }
        downloadMusicURL(url: url)
    }
}

extension SelectViewController:UITextFieldDelegate{
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if searchTextField.text != nil{
            searchButton.isEnabled = true
        }else{
            searchButton.isEnabled = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        reflesData()
        return true
    }
}

extension SelectViewController:MusicDelegate{
    func catchData(count: Int) {
        if count == 1{
            tableVIew.reloadData()
            indicator.isHidden = true
            indicator.stopAnimating()
        }
    }
    
    
}
