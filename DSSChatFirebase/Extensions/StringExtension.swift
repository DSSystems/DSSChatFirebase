//
//  StringExtension.swift
//  DSSChatFirebase
//
//  Created by David on 22/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit

extension String {
    var isValidEmail: Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }
}
