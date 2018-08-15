//
//  DSSTools.swift
//  DSSChatFirebase
//
//  Created by David on 23/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit

enum LoginError: Error {
    case incompleteForm
    case invalidEmail
    case incorrectPasswordLength
}

class DSSAlert {
    class func showBasic(title: String, message: String, viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    class func showActionConfirmation(title: String, message: String, viewController: UIViewController, completion: @escaping () -> ()) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: { (_) in
            completion()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        
        viewController.present(alert, animated: true, completion: nil)
    }
}
