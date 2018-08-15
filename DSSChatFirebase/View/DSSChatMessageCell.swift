//
//  DSSChatMessageCell.swift
//  DSSChatFirebase
//
//  Created by David on 21/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit
import AVFoundation

protocol DSSChatMessageCellDelegate {
    func performZoomingForStarting(imageView: UIImageView)
}

class DSSChatMessageCell: UICollectionViewCell {
    var delegate: DSSChatMessageCellDelegate?
    
    var message: DSSMessage?
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.hidesWhenStopped = true
        return aiv
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setTitle("Play video", for: .normal)
        let image = UIImage(named: "play_button")
        button.tintColor = .white
        button.imageView?.contentMode = .scaleAspectFill
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        return button
    }()
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    @objc func handlePlay() {
        if let videoUrl = message?.videoUrl, let url = URL(string: videoUrl) {
            player = AVPlayer(url: url)
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = bubbleView.bounds
            bubbleView.layer.addSublayer(playerLayer!)
            
            player?.play()
            activityIndicatorView.startAnimating()
            playButton.isHidden = true
        }
    }
    
    @objc func playerDidFinishPlaying() {
        activityIndicatorView.stopAnimating()
        playButton.isHidden = false
        playerLayer?.removeFromSuperlayer()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        playerLayer?.removeFromSuperlayer()
        player?.pause()
        activityIndicatorView.stopAnimating()
    }
    
    let textView: UITextView = {
        let tv = UITextView()
//        tv.text = "SAMPLE TEXT FOR NOW"
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.textColor = .white
        tv.backgroundColor = .clear
        tv.isEditable = false
        return tv
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        return view
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.customLightGray
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    lazy var messageImageView: UIImageView = {
        let imageView = UIImageView()
//        imageView.backgroundColor = UIColor.customLightGray
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))

        return imageView
    }()
    
    @objc func handleZoomTap(tapGesture: UITapGestureRecognizer) {
        if let imageView = tapGesture.view as? UIImageView {
            delegate?.performZoomingForStarting(imageView: imageView)
        } else {
            print("Error recognizing gesture")
        }
    }
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewTrailingAnchor: NSLayoutConstraint?
    var bubbleViewLeadingAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        
        bubbleView.addSubview(messageImageView)
        bubbleView.addSubview(playButton)
        bubbleView.addSubview(activityIndicatorView)
        
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleViewTrailingAnchor = bubbleView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        bubbleViewLeadingAnchor = bubbleView.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8)
        bubbleView.setConstraints([
            bubbleViewTrailingAnchor,
            bubbleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            bubbleWidthAnchor,
            bubbleView.heightAnchor.constraint(equalTo: heightAnchor)])
        
        textView.setConstraints([
            textView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 8),
            textView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor),
            textView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -8),
            textView.heightAnchor.constraint(equalTo: heightAnchor)])
        
        profileImageView.setConstraints([profileImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                                         profileImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
                                         profileImageView.widthAnchor.constraint(equalToConstant: 32),
                                         profileImageView.heightAnchor.constraint(equalToConstant: 32)])
        
        messageImageView.fillSuperview()
        
        playButton.anchor(centerX: bubbleView.centerXAnchor, centerY: bubbleView.centerYAnchor, width: nil, height: nil, padding: .zero, size: .init(width: 50, height: 50))
        
        activityIndicatorView.anchor(centerX: bubbleView.centerXAnchor, centerY: bubbleView.centerYAnchor, width: nil, height: nil, padding: .zero, size: .init(width: 50, height: 50))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
