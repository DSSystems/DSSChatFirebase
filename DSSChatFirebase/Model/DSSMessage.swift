//
//  DSSMessage.swift
//  DSSChatFirebase
//
//  Created by David on 19/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit
import Firebase

class DSSMessage: NSObject {
    
    var fromId: String?
    var text: String?
    var timestamp: NSNumber?
    var toId: String?
    
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    
    var videoUrl: String?
    
    init(dictionary: [String: Any]) {
        super.init()
        
        fromId = dictionary["fromId"] as? String
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
        toId = dictionary["toId"] as? String
        
        imageUrl = dictionary["imageUrl"] as? String
        imageWidth = dictionary["imageWidth"] as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
        
        videoUrl = dictionary["videoUrl"] as? String
    }
    
    func chatParnterId() -> String?
    {
        return fromId == Auth.auth().currentUser?.uid ? toId : fromId
    }
}
