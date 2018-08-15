//
//  DSSChatInputContainerView.swift
//  DSSChatFirebase
//
//  Created by David on 24/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit

protocol DSSChatInputContainerViewDelegate {
    func didPressedUploadImageButton()
    func didPressedSendButton()
}

class DSSChatInputContainerView: UIView, UITextFieldDelegate {
    var delegate: DSSChatInputContainerViewDelegate?
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.delegate = self
        return textField
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "upload_image_icon")
        uploadImageView.contentMode = .scaleAspectFill
        //        uploadImageView.backgroundColor = .green
        uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        uploadImageView.isUserInteractionEnabled = true
        
        let sendButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Send", for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
            return button
        }()
        
        let separatorLineView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.customLightGray
            
            return view
        }()
        
        addSubview(sendButton)
        addSubview(uploadImageView)
        addSubview(inputTextField)
        addSubview(separatorLineView)
        
        uploadImageView.setConstraints([uploadImageView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                                        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                                        uploadImageView.heightAnchor.constraint(equalToConstant: 44),
                                        uploadImageView.widthAnchor.constraint(equalToConstant: 44)])
        
        sendButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        
        inputTextField.anchor(top: nil, leading: uploadImageView.trailingAnchor, bottom: nil, trailing: sendButton.leadingAnchor, padding: .init(top: 0, left: 8, bottom: 0, right: 0), size: .zero)
        inputTextField.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        separatorLineView.anchor(top: topAnchor, leading: safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: safeAreaLayoutGuide.trailingAnchor, padding: .zero, size: .init(width: 0, height: 1))
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.didPressedSendButton()
        
        return true
    }
    
    @objc func handleSend() {
        delegate?.didPressedSendButton()
    }
    
    @objc func handleUploadTap() {
        delegate?.didPressedUploadImageButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
