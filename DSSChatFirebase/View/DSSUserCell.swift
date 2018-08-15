//
//  DSSUserCell.swift
//  DSSChatFirebase
//
//  Created by David on 20/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit
import Firebase

class DSSUserCell: UITableViewCell {
    
    var message: DSSMessage? {
        didSet {
            setNameAndProfileImage()
            
            detailTextLabel?.text = message?.text
            
            if let seconds = message?.timestamp?.doubleValue {
                let timestampDate = Date(timeIntervalSince1970: seconds)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm:ss a"
                timeLabel.text = dateFormatter.string(from: timestampDate)
            }
        }
    }
    
    func setNameAndProfileImage() {
    
        if let id = message?.chatParnterId() {
            let ref = Database.database().reference().child("users").child(id)
            
            ref.observeSingleEvent(of: .value) { (snapshot) in
                if let dictionary = snapshot.value as? [String: Any] {
                    self.textLabel?.text = dictionary["name"] as? String
                    if let profileImageUrl = dictionary["profileImageUrl"] as? String {
                        self.profileImageView.loadImageUsingCache(withURLString: profileImageUrl)
                    }
                }
            }
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 64, y: textLabel!.frame.origin.y, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 64, y: detailTextLabel!.frame.origin.y, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
//        label.text = "HH:MM:SS"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .darkGray
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        setupProfileImageView()
        
        setupTimeLabel()
    }
    
    private func setupTimeLabel() {
        timeLabel.setConstraints([
            timeLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: topAnchor, constant: 18),
            timeLabel.widthAnchor.constraint(equalToConstant: 100),
            timeLabel.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!)
            ])
    }
    
    private func setupProfileImageView()
    {
        [profileImageView.leftAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leftAnchor, constant: 8),
         profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
         profileImageView.widthAnchor.constraint(equalToConstant: 48),
         profileImageView.heightAnchor.constraint(equalToConstant: 48)].forEach { (constraint) in
            constraint.isActive = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
