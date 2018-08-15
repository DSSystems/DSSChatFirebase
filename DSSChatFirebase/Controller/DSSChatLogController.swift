//
//  DSSChatLogController.swift
//  DSSChatFirebase
//
//  Created by David on 18/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class DSSChatLogController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, DSSChatMessageCellDelegate, DSSChatInputContainerViewDelegate, UITextFieldDelegate {
    
    let cellId = "cellId"
    
    var user: DSSUser? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
    }
    
    var messages = [DSSMessage]()
    
    func observeMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        guard let partnerId = user?.id else {return}
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(partnerId)
        
        userMessagesRef.observe(.childAdded) { (snapshot) in
            let messageId = snapshot.key
            
            let messagesRef = Database.database().reference().child("messages").child(messageId)
            
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: Any] else {
                    return
                }
                
                let message = DSSMessage(dictionary: dictionary)
                
                if message.chatParnterId() == self.user?.id {
                    self.messages.append(message)
                    DispatchQueue.main.async {
                        self.collectionView?.reloadData()
                        
                    }
                }
            })
        }
        
        // Scroll to the last index
        if self.messages.count > 0 {
            let indexPath = IndexPath(item: self.messages.count - 1, section: 0)
            
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = .white
        collectionView?.register(DSSChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive

        setupKeyBoardObservers()
    }
    
    lazy var chatInputContainerView: DSSChatInputContainerView = {
        let containerView = DSSChatInputContainerView(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        containerView.delegate = self
//        containerView.anchor(top: nil, leading: collectionView?.safeAreaLayoutGuide.leadingAnchor, bottom: collectionView?.safeAreaLayoutGuide.bottomAnchor, trailing: collectionView?.safeAreaLayoutGuide.trailingAnchor, padding: .zero, size: CGSize(width: 0, height: 50))
        return containerView
    }()
    
    func didPressedUploadImageButton() {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            // we selected a media
            do
            {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: videoUrl.path)
                
                let fileSize = fileAttributes[FileAttributeKey.size]
                
                handleVideoSelectedFor(url: videoUrl, fileSize: fileSize as! Int64)
                
            } catch {
                print(error.localizedDescription)
            }
            
        } else {
            // We selected an image
            handleImageSelectedFor(info: info)
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedFor(url: URL, fileSize: Int64) {
        
        let fileName = NSUUID().uuidString
        let size = Int(fileSize / 1024)
        let storageRef = Storage.storage().reference().child("messages_movies").child(fileName)
        
        let uploadTask = storageRef.putFile(from: url, metadata: nil) { (metadata, error) in
            if error != nil {
                print("An error has accurred while uploading the file", error!)
                return
            }

            storageRef.downloadURL(completion: { (videoUrl, error) in
                if error != nil {
                    print("An error has accurred while getting the url of uploaded file")
                    return
                }

                if let urlString = videoUrl?.absoluteString {
                    if let thumbnailImage = self.thumbnailImageForVideoFrom(fileUrl: url) {
                        
                        self.uploadToFirebaseStorageFrom(image: thumbnailImage, completion: { (imageUrl) in
                            let properties: [String: Any] = ["videoUrl": urlString, "imageUrl": imageUrl, "imageWidth": thumbnailImage.size.width, "imageHeight": thumbnailImage.size.height]
                            
                            self.sendMessageWidthProperties(properties)
                        })
                        
                    }
                
                } else {
                    print("Error while sending message with video")
                }
            })
        }

        uploadTask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(Int(completedUnitCount / 1024) / size * 100)
            }
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
    }
    
    private func thumbnailImageForVideoFrom(fileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil)
            
            return UIImage(cgImage: thumbnailCGImage)
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    private func handleImageSelectedFor(info: [String: Any]) {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            uploadToFirebaseStorageFrom(image: selectedImage) { (imageUrl) in
                self.sendMessageWith(imageUrl: imageUrl, image: selectedImage)
            }
        }
    }
    
    private func uploadToFirebaseStorageFrom(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploadData, metadata: nil) { (metadata, error) in
                if error != nil {
                    print(error!)
                    return
                }
                
                ref.downloadURL(completion: { (url, error) in
                    guard let url = url else {
                        print("error obtaining the URL of uploaded image: ", error!)
                        return
                    }
                    
                    completion(url.absoluteString)
                })
            }
        }
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return chatInputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    func setupKeyBoardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handelKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    @objc func handelKeyboardDidShow(notification: NSNotification) {
        if messages.count > 0 {
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
        
            collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! CGRect
        let keyboardDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
//        print(keyboardFrame)
        
        containerViewBottomAnchor?.constant = -(keyboardFrame.height)
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification) {
        let keyboardDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        //        print(keyboardFrame)
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! DSSChatMessageCell
        
        let message = messages[indexPath.row]
        
        setupCell(cell: cell, message: message)
        
        return cell
    }
    
    private func setupCell(cell: DSSChatMessageCell, message: DSSMessage) {
        cell.message = message
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCache(withURLString: profileImageUrl)
        }
        
        if message.fromId == Auth.auth().currentUser?.uid {
            //Outgoung blue
            cell.bubbleView.backgroundColor = UIColor.customBlueBubbleColor
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
            cell.bubbleViewLeadingAnchor?.isActive = false
            cell.bubbleViewTrailingAnchor?.isActive = true
        } else {
            //incoming gray
            cell.bubbleView.backgroundColor = UIColor.customLightGray
            cell.textView.textColor = .black
            cell.profileImageView.isHidden = false
            cell.bubbleViewTrailingAnchor?.isActive = false
            cell.bubbleViewLeadingAnchor?.isActive = true
        }
        
        if let textMessage = message.text {
            cell.textView.text = textMessage
            
            cell.bubbleWidthAnchor?.constant = estimateFrameFromText(textMessage).width + 32
        } else if message.imageUrl != nil {
            cell.bubbleWidthAnchor?.constant = 200
        }
        
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCache(withURLString: messageImageUrl)
            cell.delegate = self
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = .clear
            cell.textView.isHidden = true
        } else {
            cell.delegate = nil
            cell.messageImageView.isHidden = true
            cell.textView.isHidden = false
        }

        cell.playButton.isHidden = message.videoUrl == nil
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = UIScreen.main.bounds.width
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        
        if let text = message.text {
            height = estimateFrameFromText(text).height + 20
        } else if message.imageUrl != nil {
            guard let imageWidth = message.imageWidth, let imageHeight = message.imageHeight else {
                return CGSize(width: width, height: 200)
            }
            height = CGFloat(200.0 * imageHeight.floatValue / imageWidth.floatValue)
        }
        
        return CGSize(width: width, height: height)
    }
    
    private func estimateFrameFromText(_ text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)

        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    var containerViewBottomAnchor: NSLayoutConstraint?
    
    func didPressedSendButton() {
        guard let message = chatInputContainerView.inputTextField.text else {return}
        let properties = ["text": message]
        
        sendMessageWidthProperties(properties)
    }
    
    private func sendMessageWith(imageUrl: String, image: UIImage) {
        
        let properties: [String: Any] = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height]
        
        sendMessageWidthProperties(properties)
    }
    
    private func sendMessageWidthProperties(_ properties: [String: Any]) {
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        guard let fromId = Auth.auth().currentUser?.uid,
            let toId = user?.id else {return}
        
        let timestamp: NSNumber = NSNumber(value: Int(NSDate().timeIntervalSince1970))
        
        var values: [String : Any] = ["fromId": fromId, "toId": toId, "timestamp": timestamp]
        
        // Append properties dictionary onto values somehow
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print("Message was not sent")
                return
            }
            
            self.chatInputContainerView.inputTextField.text = nil
            self.chatInputContainerView.inputTextField.resignFirstResponder()
            
            let userMessagesRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            
            let messageId = childRef.key
            
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        }
    }
    
    private var startingFrame: CGRect?
    private var blackBackgroundView: UIView?
    private var startingImageView: UIView?
    
    func performZoomingForStarting(imageView: UIImageView) {
        startingFrame = imageView.superview?.convert(imageView.frame, to: nil)
        startingImageView = imageView
        
        if let startingFrame = self.startingFrame {
            let zoomingImageView = UIImageView(frame: startingFrame)
            zoomingImageView.image = imageView.image
            zoomingImageView.layer.cornerRadius = 16
            zoomingImageView.layer.masksToBounds = true
            zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
            zoomingImageView.isUserInteractionEnabled = true
            
            if let keyWindow = UIApplication.shared.keyWindow {
                blackBackgroundView = UIView(frame: keyWindow.frame)
                
                guard let backgroundView = self.blackBackgroundView else {return}
                backgroundView.alpha = 0
                backgroundView.backgroundColor = .black
                keyWindow.addSubview(backgroundView)
                backgroundView.fillSuperview()
                
                keyWindow.addSubview(zoomingImageView)
                
                let width: CGFloat = keyWindow.frame.width
                if let imageHeight: CGFloat = imageView.image?.size.height, let imageWidth = imageView.image?.size.width {
                    let height: CGFloat = width * imageHeight / imageWidth
                    
                    self.startingImageView?.isHidden = true
                    UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                        zoomingImageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
                        zoomingImageView.center = keyWindow.center
                        zoomingImageView.layer.cornerRadius = 0
                        backgroundView.alpha = 1
                        self.chatInputContainerView.alpha = 0
                    }, completion: nil)
                }
            } else {
                print("Error obtaining reference to keyWindow")
            }
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                if let startingFrame = self.startingFrame, let backgroundView = self.blackBackgroundView {
                    zoomOutImageView.frame = startingFrame
                    zoomOutImageView.layer.cornerRadius = 16
                    
                    backgroundView.alpha = 0
                    
                    self.chatInputContainerView.alpha = 1
                }
            }, completion: { (completed: Bool) in
                self.startingImageView?.isHidden = false
                zoomOutImageView.removeFromSuperview()
                self.blackBackgroundView?.removeFromSuperview()
            })
        }
    }
}
