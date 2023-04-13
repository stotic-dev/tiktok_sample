//
//  AVplayerExtention.swift
//  Swift6TikTok
//
//  Created by 佐藤汰一 on 2021/10/16.
//

import Foundation
import AVFoundation

extension AVPlayer{
    var isPlaying:Bool{
        return self.rate != 0 && self.error == nil
    }
}
