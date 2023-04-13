//
//  MusicModel.swift
//  Swift6TikTok
//
//  Created by 佐藤汰一 on 2021/09/28.
//

import Foundation
import SwiftyJSON
import Alamofire

protocol MusicDelegate {
    func catchData(count:Int)
}

class MusicModel {
    
    var artistName:String?
    var truckName:String?
    var musicUrlString:String?
    var artworkUrl100String:String?
    
    var artistNameArray = [String]()
    var truckNameArray = [String]()
    var musicUrlStringArray = [String]()
    var artworkUrlStringArray = [String]()
    
    var delegate:MusicDelegate?
    
    func setData(resultCount:Int,encodeUrlString:String){
        
        print(encodeUrlString)
        //通信
        AF.request(encodeUrlString, method: .get, parameters: nil, encoding: JSONEncoding.default).responseJSON { res in
            
            self.artistNameArray.removeAll()
            self.truckNameArray.removeAll()
            self.musicUrlStringArray.removeAll()
            self.artworkUrlStringArray.removeAll()
            
            switch res.result{
            case .success:
                do {
                    guard let data = res.data else { return }
                    let json:JSON = try JSON(data: data)
                    for i in 0...resultCount-1{
                        let path = json["results"][i]
                        
                        if path["artistName"].string == nil{
                            print("ヒットしませんでした")
                            return
                        }
                        
                        self.artistNameArray.append(path["artistName"].string!)
                        self.truckNameArray.append(path["trackName"].string!)
                        self.musicUrlStringArray.append(path["previewUrl"].string!)
                        self.artworkUrlStringArray.append(path["artworkUrl100"].string!)
                    }
                    self.delegate?.catchData(count: 1)
                    
                } catch let error {
                    print("Json解析に失敗しました\(error)")
                    return
                }
                break
            case .failure:
                break
            }
            
        }
        
    }
    
    //    private func showAlert(){
    //        let alertView = UIAlertController(title: "エラー", message: "楽曲の取得に失敗しました", preferredStyle: .alert)
    //        let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    //        alertView.addAction(ok)
    //    }
    
}
