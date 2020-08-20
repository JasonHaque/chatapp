//
//  RegisterViewController.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 11/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView : UIImageView = {
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let emailField : UITextField = {
        
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address Please"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let firstNameField : UITextField = {
           
           let field = UITextField()
           field.autocapitalizationType = .none
           field.autocorrectionType = .no
           field.returnKeyType = .continue
           field.layer.cornerRadius = 12
           field.layer.borderWidth = 1
           field.layer.borderColor = UIColor.lightGray.cgColor
           field.placeholder = "First Name"
           field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
           field.leftViewMode = .always
           field.backgroundColor = .white
           return field
       }()
    
    private let lastNameField : UITextField = {
           
           let field = UITextField()
           field.autocapitalizationType = .none
           field.autocorrectionType = .no
           field.returnKeyType = .continue
           field.layer.cornerRadius = 12
           field.layer.borderWidth = 1
           field.layer.borderColor = UIColor.lightGray.cgColor
           field.placeholder = "Last Name"
           field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
           field.leftViewMode = .always
           field.backgroundColor = .white
           return field
       }()
    
    private let passwordField : UITextField = {
        
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password Please"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let registerButton : UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log in"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(changeProfilePic))
        
        gesture.numberOfTouchesRequired = 1
        gesture.numberOfTapsRequired = 1
        
        imageView.addGestureRecognizer(gesture)
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        let size = view.width/3
        
        imageView.frame = CGRect(x: (view.width - size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        imageView.layer.cornerRadius = imageView.width/2.0
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+20,
                                  width: scrollView.width-60,
                                  height: 52)
        firstNameField.frame = CGRect(x: 30,
                                  y: emailField.bottom+20,
                                  width: scrollView.width-60,
                                  height: 52)
        lastNameField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom+20,
                                  width: scrollView.width-60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: lastNameField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        registerButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width-60,
                                   height: 52)
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create User Account"
        navigationController?.pushViewController(vc, animated: false)
    }
    
    @objc private func registerTapped(){
        
        emailField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text,
            let password = passwordField.text,
            let firstName = firstNameField.text,
            let lastName = lastNameField.text,
            !email.isEmpty,
            !firstName.isEmpty,
            !lastName.isEmpty,
            !password.isEmpty,
            password.count >= 6 else {
                alertUserError()
                return
        }
        spinner.show(in: view)
        
        //FireBase Login
        
        DatabaseManager.shared.userExists(with: email) {[weak self] exists in
            
            guard let strongSelf = self else{
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            guard !exists else{
                //user exists
                
               strongSelf.alertUserError(message: "a user account for this email already exists")
                
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                
                guard let strongSelf = self else{
                    return
                }
                guard authResult != nil , error == nil else{
                    print("something occured \(error!)")
                    return
                }
                
                let chatUser = ChatAppUSer(firstName: firstName, lastName: lastName, emailAddress: email)
                DatabaseManager.shared.insertUser(with: chatUser , completion: { success in
                    
                    if success{
                        guard let image = strongSelf.imageView.image, let data = image.pngData() else {
                            return
                        }
                        
                        let fileName = chatUser.profilePictureFileName
                        
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                            
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage manager error \(error)")
                            }
                        }
                    }
                    
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    @objc private func changeProfilePic(){
        
        presesntActionSheet()
        
    }
    
    func alertUserError(message : String = "Please fill out the info properly"){
        
        let alert = UIAlertController(title: "Woopsie", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert,animated: true)
    }
    
    
}

extension RegisterViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        if textField == passwordField {
            registerTapped()
        }
        
        return true
    }
}

extension RegisterViewController : UIImagePickerControllerDelegate,UINavigationControllerDelegate{
    
    func presesntActionSheet(){
        let actionsheet = UIAlertController(title: "Profile picture", message: "How would you like to add profile picture", preferredStyle: .actionSheet)
        
        actionsheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionsheet.addAction(UIAlertAction(title: "Take Photo", style: .default,
                                            handler: {[weak self] _ in
                                                self?.presentCamera()
        }))
        actionsheet.addAction(UIAlertAction(title: "Choose photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoLibrary()
            
        }))
        
        present(actionsheet,animated: true)
    }
    
    func presentCamera(){
        
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    
    func presentPhotoLibrary(){
        
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.imageView.image = selectedImage
        print(info)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
