//
//  UIImageViewExtension.swift
//  DSSChatFirebase
//
//  Created by David on 18/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit

let imageCache = NSCache<NSString, UIImage>()

extension UIImageView {
    func loadImageUsingCache (withURLString urlString: String) {
        let url = URL(string: urlString)
        self.image = nil
        // check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            self.image = cachedImage
            return
        }

        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                // Error downloading the profileImeage
                print(error as Any)
                return
            }
            
            DispatchQueue.main.async {
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    self.image = downloadedImage
                }
            }
            }.resume()
    }
}
