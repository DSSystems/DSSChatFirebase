//
//  DSSMessageViewController.swift
//  DSSChatFirebase
//
//  Created by David on 15/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit
import Firebase

protocol DSSNewMessageControllerDelegate {
    func showChatLogControllerForUser(_ user: DSSUser)

}

class DSSNewMessageController: UITableViewController {

    let cellId = "cellId"
    var users = [DSSUser]()
    
    var delegade: DSSNewMessageControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        
        tableView.register(DSSUserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
    }
    
    func fetchUser() {
        Database.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: Any] {
                let user = DSSUser()
//                print(dictionary)
//                user.setValuesForKeys(dictionary) FOR SOME REASON IT IS NOT WORKING
                user.id = snapshot.key
                
                user.setValuesFrom(dictionary)
                
                self.users.append(user)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }, withCancel: nil)
    }

    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as? DSSUserCell else {
//            print("Unable to dequeue table cell")
//            return UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
//        }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! DSSUserCell
        
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
//        cell.imageView?.image = UIImage(named: "blankProfileImageView")
//        cell.imageView?.contentMode = .scaleAspectFill
        
        if let profileImageUrl = user.profileImageUrl {
            
            cell.profileImageView.loadImageUsingCache(withURLString: profileImageUrl)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.delegade?.showChatLogControllerForUser(user)
        }
    }
}


