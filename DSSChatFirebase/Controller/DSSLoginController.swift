//
//  DSSLoginController.swift
//  DSSChatFirebase
//
//  Created by David on 13/07/18.
//  Copyright © 2018 DS_Systems. All rights reserved.
//

import UIKit
import Firebase

protocol DSSLoginControllerDelegate {
    func fetchUserAndSetNavBarTitle()
    func setupNavBarWith(user: DSSUser)
}

class DSSLoginController: UIViewController, UITextFieldDelegate {
    var delegate: DSSLoginControllerDelegate?
    
    let inputsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var loginRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.customDarkBlue
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(handleLoginRegister), for: .touchUpInside)
        return button
    }()
    
    let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Name"
        return textField
    }()
    
    let nameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.customLightGray
        return view
    }()
    
    let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email address"
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        return textField
    }()
    
    let emailSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.customLightGray
        return view
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        return textField
    }()
    
    lazy var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Targaryen")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        imageView.isUserInteractionEnabled = true
        imageView.tintColor = .white
        return imageView
    }()
    
    lazy var loginRegisterSegmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["Login", "Register"])
        segmentedControl.tintColor = .white
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(handleLoginRegisterChanged), for: .valueChanged)
        return segmentedControl
    }()
    
    var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    var passwordTextFieldHeightAnchor: NSLayoutConstraint?

    @objc func handleLoginRegisterChanged() {
        let title = loginRegisterSegmentedControl.titleForSegment(at: loginRegisterSegmentedControl.selectedSegmentIndex)
        
        loginRegisterButton.setTitle(title, for: .normal)
        
        inputsContainerViewHeightAnchor?.constant = loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 100 : 150
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.customBlue
        
        view.addSubview(inputsContainerView)
        view.addSubview(loginRegisterButton)
        view.addSubview(profileImageView)
        view.addSubview(loginRegisterSegmentedControl)
        
        setupInputsContainerView()
        setupLoginRegisterButton()
        setunProfileImageView()
        setupLoginRegisterSegmentedControl()
        
    }
    
    func setupLoginRegisterSegmentedControl() {
        loginRegisterSegmentedControl.anchor(centerX: view.centerXAnchor, centerY: nil, width: inputsContainerView.widthAnchor, height: nil)
        loginRegisterSegmentedControl.bottomAnchor.constraint(equalTo: inputsContainerView.topAnchor, constant: -12).isActive = true
        loginRegisterSegmentedControl.heightAnchor.constraint(equalToConstant: 36).isActive = true
    }
    
    func setunProfileImageView() {
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: loginRegisterSegmentedControl.topAnchor, constant: -12).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        profileImageView.layer.cornerRadius = 75
        profileImageView.layer.masksToBounds = true
    }
    
    func setupInputsContainerView() {
        inputsContainerView.anchor(centerX: view.centerXAnchor,
                                   centerY: view.centerYAnchor,
                                   width: view.widthAnchor,
                                   height: nil,
                                   padding: .init(top: 0, left: 12, bottom: 0, right: 12),
                                   size: .zero)
        inputsContainerViewHeightAnchor = inputsContainerView.heightAnchor.constraint(equalToConstant: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 100 : 150)
        inputsContainerViewHeightAnchor?.isActive = true
        
        inputsContainerView.addSubview(nameTextField)
        inputsContainerView.addSubview(nameSeparatorView)
        inputsContainerView.addSubview(emailTextField)
        inputsContainerView.addSubview(emailSeparatorView)
        inputsContainerView.addSubview(passwordTextField)

        nameTextField.anchor(top: inputsContainerView.topAnchor,
                             leading: inputsContainerView.leadingAnchor,
                             bottom: nil,
                             trailing: inputsContainerView.trailingAnchor,
                             padding: .init(top: 0, left: 12, bottom: 0, right: 12),
                             size: .zero)
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        nameTextField.delegate = self
        
        nameSeparatorView.anchor(top: nameTextField.bottomAnchor,
                                 leading: inputsContainerView.leadingAnchor,
                                 bottom: nil,
                                 trailing: inputsContainerView.trailingAnchor,
                                 padding: .zero,
                                 size: .init(width: 0, height: 1))

        emailTextField.anchor(top: nameTextField.bottomAnchor,
                             leading: inputsContainerView.leadingAnchor,
                             bottom: nil,
                             trailing: inputsContainerView.trailingAnchor,
                             padding: .init(top: 0, left: 12, bottom: 0, right: 12),
                             size: .zero)
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        emailTextField.delegate = self

        emailSeparatorView.anchor(top: emailTextField.bottomAnchor,
                                 leading: inputsContainerView.leadingAnchor,
                                 bottom: nil,
                                 trailing: inputsContainerView.trailingAnchor,
                                 padding: .zero,
                                 size: .init(width: 0, height: 1))

        passwordTextField.anchor(top: emailTextField.bottomAnchor,
                              leading: inputsContainerView.leadingAnchor,
                              bottom: nil,
                              trailing: inputsContainerView.trailingAnchor,
                              padding: .init(top: 0, left: 12, bottom: 0, right: 12),
                              size: .zero)
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputsContainerView.heightAnchor, multiplier: loginRegisterSegmentedControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        passwordTextField.delegate = self
    }
    
    func setupLoginRegisterButton() {
        [loginRegisterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
         loginRegisterButton.topAnchor.constraint(equalTo: inputsContainerView.bottomAnchor, constant: 12),
         loginRegisterButton.widthAnchor.constraint(equalTo: inputsContainerView.widthAnchor),
         loginRegisterButton.heightAnchor.constraint(equalToConstant: 50)].forEach { (constraint) in
            constraint.isActive = true
        }
    }
    
    @objc func handleLoginRegister() {
        
        if loginRegisterSegmentedControl.selectedSegmentIndex == 0 {
            do {
                try handleLogin()
            } catch LoginError.incompleteForm {
                DSSAlert.showBasic(title: "Incomplete form", message: "Please fill out all the required fields.", viewController: self)
                passwordTextField.text = ""
                emailTextField.becomeFirstResponder()
            } catch LoginError.invalidEmail {
                DSSAlert.showBasic(title: "Invalid email address", message: "Please fill a valid email account.", viewController: self)
                passwordTextField.text = ""
                emailTextField.becomeFirstResponder()
            } catch LoginError.incorrectPasswordLength {
                DSSAlert.showBasic(title: "Invalid assword", message: "The password must be at least 6 characters.", viewController: self)
                passwordTextField.text = ""
                passwordTextField.becomeFirstResponder()
            } catch {
                DSSAlert.showBasic(title: "Unable to login", message: "There was an error when attempting to login.", viewController: self)
            }
        }
        else
        {
            do {
                try handleRegister()
            } catch LoginError.incompleteForm {
                DSSAlert.showBasic(title: "Incomplete form", message: "Please fill out all the required fields.", viewController: self)
                passwordTextField.text = ""
                nameTextField.becomeFirstResponder()
            } catch LoginError.invalidEmail {
                DSSAlert.showBasic(title: "Invalid email address", message: "Please fill a valid email account.", viewController: self)
                passwordTextField.text = ""
                emailTextField.becomeFirstResponder()
            } catch LoginError.incorrectPasswordLength {
                DSSAlert.showBasic(title: "Invalid assword", message: "The password must be at least 6 characters.", viewController: self)
                passwordTextField.text = ""
                passwordTextField.becomeFirstResponder()
            } catch {
                DSSAlert.showBasic(title: "Unable to register", message: "There was an error when attempting to register user.", viewController: self)
            }
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        view.endEditing(true)
//    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
            case nameTextField:
                textField.resignFirstResponder()
                emailTextField.becomeFirstResponder()
            case emailTextField:
                textField.resignFirstResponder()
                passwordTextField.becomeFirstResponder()
            case passwordTextField:
                textField.resignFirstResponder()
            default:
                break
        }
        
        return true
    }
}
