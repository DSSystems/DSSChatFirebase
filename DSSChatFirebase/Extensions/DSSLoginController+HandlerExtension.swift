//
//  DSSLoginController+HandlerExtension.swift
//  DSSChatFirebase
//
//  Created by David on 17/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit
import Firebase

extension DSSLoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func handleRegister() throws {
        
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Unable to get all necessary fields to register user.")
            return
        }
        
        if name.isEmpty || email.isEmpty || password.isEmpty {
            throw LoginError.incompleteForm
        }
        
        if !email.isValidEmail {
            throw LoginError.invalidEmail
        }
        
        if password.count < 6 {
            throw LoginError.incorrectPasswordLength
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (response, error) in
            if (error != nil) {
                if error?.localizedDescription == "The email address is already in use by another account." {
                    guard let errorDescription = error?.localizedDescription else {
                        return
                    }
                    
                    DSSAlert.showBasic(title: "Register error", message: errorDescription, viewController: self)
                    
                    self.emailTextField.text = ""
                    self.emailTextField.becomeFirstResponder()
                    self.passwordTextField.text = ""
                    self.loginRegisterButton.isEnabled = true
                    
                } else {
                    print(error as Any)
                    return
                }
            }
            
            guard let uid = response?.user.uid else {
                //Error writing user data into the database
                return
            }
            
            // successfully authenticated user
            
            let profileImageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child(uid).child("\(profileImageName).jpg")
            
            if let profileImage = self.profileImageView.image, let uploadData = UIImageJPEGRepresentation(profileImage.scaled(to: CGSize(width: 200, height: 200)), 0.65) {
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                    
                    if error != nil {
                        print(error!)
                        return
                    }
                    
                    storageRef.downloadURL(completion: { (url, error) in
                        if error != nil {
                            //Problems obtaining the url
                            print(error!)
                            return
                        }
                        guard let url = url else {
                            //Error geting the downloadUrl of uploaded file
                            return
                        }
                        
                        let values = ["name": name, "email": email, "profileImageUrl": url.absoluteString]
                        
                        self.registerUserIntoDatabase(uid: uid, values: values)
                        
                    })
                })
            }
            
        }
    }
    
    func handleLogin() throws {
        
        passwordTextField.resignFirstResponder()
        
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            print("Unable to get email and password.")
            return
        }
        
        if email.isEmpty || password.isEmpty {
            throw LoginError.incompleteForm
        }
        
        if !email.isValidEmail {
            throw LoginError.invalidEmail
        }
        
        if password.count < 6 {
            throw LoginError.incorrectPasswordLength
        }

        Auth.auth().signIn(withEmail: email, password: password) { (response, error) in
            if error != nil {
                guard let errorDescription = error?.localizedDescription else { return }
                
                DSSAlert.showBasic(title: "Unable to login", message: errorDescription, viewController: self)
                
                self.passwordTextField.text = ""
                self.passwordTextField.becomeFirstResponder()
                return
            }
            
            self.delegate?.fetchUserAndSetNavBarTitle()
            
            self.dismiss(animated: true, completion: nil)
            
        }
    }
    
    private func registerUserIntoDatabase(uid: String, values: [String: Any]) {
        let ref = Database.database().reference()
        
        let usersReference = ref.child("users").child(uid)
        
        usersReference.updateChildValues(values, withCompletionBlock: { (error, ref) in
            if error != nil {
                print(error!)
                return
            }
            
//            self.delegate?.setNavBarTitle(values["name"] as! String)
            let user = DSSUser()
            user.setValuesFrom(values)
            self.delegate?.setupNavBarWith(user: user)
            
            self.dismiss(animated: true, completion: nil)
        })
    }
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        }
        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}
