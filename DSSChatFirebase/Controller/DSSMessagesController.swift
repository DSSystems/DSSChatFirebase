//
//  ViewController.swift
//  DSSChatFirebase
//
//  Created by David on 13/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

class DSSMessagesController: UITableViewController, DSSLoginControllerDelegate, DSSNewMessageControllerDelegate {
    let cellId = "cellId"
    
    var messages = [DSSMessage]()
    var messagesDictionary = [String: DSSMessage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(handleNewMessage))
        
        tableView.register(DSSUserCell.self, forCellReuseIdentifier: cellId)
        
        checkIfUserIsLoggedIn()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (didAllow, error) in
            if error != nil {
                DSSAlert.showBasic(title: "Error", message: "Failed to activate notifications.", viewController: self)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        guard let uid = Auth.auth().currentUser?.uid, let chatPartnerId = message.chatParnterId() else { return }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(chatPartnerId)

        let deletedUserMessagesRef = Database.database().reference().child("deleted-messages").child(uid).child(chatPartnerId)
        let deletedChatPartnerMessagesRef = Database.database().reference().child("deleted-messages").child(chatPartnerId).child(uid)
        
        DSSAlert.showActionConfirmation(title: "Delete confirmation", message: "Are you sure you want to delete this conversation?", viewController: self) {
            userMessagesRef.observeSingleEvent(of: .childAdded) { (snapshot) in
                deletedUserMessagesRef.updateChildValues([snapshot.key: 1])
                deletedChatPartnerMessagesRef.updateChildValues([snapshot.key: 1])
            }
            
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                if error != nil {
                    DSSAlert.showBasic(title: "Error", message: "Failed to delete message. \(error!)", viewController: self)
                    return
                }
                
                Database.database().reference().child("user-messages").child(chatPartnerId).child(uid).removeValue(completionBlock: { (error, ref) in
                    if error != nil {
                        DSSAlert.showBasic(title: "Error", message: "Failed to delete message. \(error!)", viewController: self)
                        return
                    }
                    self.messagesDictionary.removeValue(forKey: chatPartnerId)
                    self.attemptReloadOfTable()

                })
            })
        }
    }
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        ref.observe(.childAdded) { (snapshot) in
            let partnerId = snapshot.key
            
            let partnerMessagesRef = Database.database().reference().child("user-messages").child(uid).child(partnerId)
            
            partnerMessagesRef.observe(.childAdded, with: { (snapshot) in
                let messageId = snapshot.key
                
                let messagesRef = Database.database().reference().child("messages").child(messageId)
                messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    if let dictionary = snapshot.value as? [String: Any] {
                        let message = DSSMessage(dictionary: dictionary)
                        
                        if let chatPartnerId = message.chatParnterId() {
                            self.messagesDictionary[chatPartnerId] = message
                        }
                        
                        self.pushNewMessageNotificationWith(id: messageId, message: message)
                        
                        self.attemptReloadOfTable()
                    }
                })
            })
            
        }
        
        ref.observe(.childRemoved) { (snapshot) in
            print(self.messagesDictionary)
            print("Something happen?", snapshot.key)
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            print(self.messagesDictionary)
            self.attemptReloadOfTable()
        }
        
    }
    
    var timer: Timer?
    
    fileprivate func attemptReloadOfTable() {
        self.timer?.invalidate()
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    @objc func handleReloadTable() {
        messages = Array(self.messagesDictionary.values)
        messages.sort(by: { (message1, message2) -> Bool in
            if let timestamp1 = message1.timestamp?.intValue, let timestamp2 = message2.timestamp?.intValue {
                return timestamp1 > timestamp2
            }
            return false
        })
        
//        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatParnterId() else {
            return
        }
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        
        ref.observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String: Any] else {
                return
            }
            
            let user = DSSUser()
            user.setValuesFrom(dictionary)
            user.id = chatPartnerId
            
            self.showChatLogControllerForUser(user)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! DSSUserCell
        
        let message = messages[indexPath.row]
        
        cell.message = message
        
        return cell
    }
    
    @objc func handleNewMessage() {
        let newMessageController = DSSNewMessageController()
        newMessageController.delegade = self
        let navigationController = UINavigationController(rootViewController: newMessageController)
        present(navigationController, animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        }
        else {
            fetchUserAndSetNavBarTitle()
        }
    }
    
    func fetchUserAndSetNavBarTitle() {

        guard let uid = Auth.auth().currentUser?.uid else {return}
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let user = DSSUser()
                user.setValuesFrom(dictionary)
                
                self.setupNavBarWith(user: user)
            }
        }, withCancel: nil)
    }
    
    func setupNavBarWith(user: DSSUser) {
        
        observeUserMessages()
        
        let titleView = UIView()

        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        titleView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        let containerView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
        
        let profileImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            if let profileImageUrl = user.profileImageUrl {
                imageView.loadImageUsingCache(withURLString: profileImageUrl)
            }
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.layer.cornerRadius = 20
            imageView.layer.masksToBounds = true
            return imageView
        }()
        
        let nameLabel: UILabel = {
            let label = UILabel()
            label.text = user.name
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        titleView.addSubview(containerView)
        navigationItem.titleView = titleView
        
        containerView.addSubview(profileImageView)
        containerView.addSubview(nameLabel)
        
        [profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        profileImageView.heightAnchor.constraint(equalToConstant: 40),
        profileImageView.widthAnchor.constraint(equalToConstant: 40)].forEach { (constraints) in
            constraints.isActive = true
        }
        
        [nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
         nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
         nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
         nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor)
            ].forEach { (constraints) in
                constraints.isActive = true
        }
        
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        
    }
    
    func cleanMessages() {
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
    }
    
    @objc func showChatLogControllerForUser(_ user: DSSUser) {
        let chatLogController = DSSChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    @objc func handleLogout() {
        cleanMessages()
        navigationItem.title = ""
        let loginController = DSSLoginController()
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        loginController.delegate = self
        
        present(loginController, animated: true)
    }
    
    private func pushNewMessageNotificationWith(id: String, message: DSSMessage) {
        let content = UNMutableNotificationContent()
        guard let chatPartnerId = message.chatParnterId(), let message = message.text else {
            print("Error while getting chatPartnerId")
            return
        }
        
        let chatPartnerRef = Database.database().reference().child("users").child(chatPartnerId)
        chatPartnerRef.observeSingleEvent(of: .value) { (snapshot) in
            if let dictionary = snapshot.value as? [String: Any] {
                guard let chatPartnerName = dictionary["name"] as? String else { return }
                content.subtitle = chatPartnerName
            }
        }
        
        content.title = "DSSChatFirebase:"
        content.body = message
        content.badge = 1
        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0, repeats: false)
        print("Notification with ID: \(id)\n\n")
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil {
                DSSAlert.showBasic(title: "Error", message: "Failed to push notification.", viewController: self)
            }
            // Notification successfully pushed
            
        }
    }
}

