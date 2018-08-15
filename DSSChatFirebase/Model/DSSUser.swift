//
//  User.swift
//  DSSChatFirebase
//
//  Created by David on 15/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit

class DSSUser: NSObject {
    var id: String?
    var name: String?
    var email: String?
    var profileImageUrl: String?
    
    func setValuesFrom(_ dictionary: [String : Any]) {
        name = dictionary["name"] as? String
        email = dictionary["email"] as? String
        profileImageUrl = dictionary["profileImageUrl"] as? String
    }
}
