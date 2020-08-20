//
//  LoginViewController.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 11/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView : UIImageView = {
       
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        
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
    
    private let logInButton : UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let faceBookloginButton : FBLoginButton = {
        
        let button = FBLoginButton()
        button.permissions = ["email","public_profile"]
        return button
    }()
    
    private let googleLoginButton = GIDSignInButton()

    private var loginObserver : NSObjectProtocol?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification,object: nil,queue: .main)
        { [weak self] _  in
            guard let strongSelf = self else {return}
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        }
        GIDSignIn.sharedInstance()?.presentingViewController = self
        title = "Log in"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        logInButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        faceBookloginButton.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(logInButton)
        
        
        
        scrollView.addSubview(faceBookloginButton)
        scrollView.addSubview(googleLoginButton)
    }
    
    deinit {
        if let observer = loginObserver{
            NotificationCenter.default.removeObserver(observer)
        }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        let size = view.width/3
        
        imageView.frame = CGRect(x: (view.width - size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+20,
                                  width: scrollView.width-60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        logInButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width-60,
                                   height: 52)
        faceBookloginButton.frame = CGRect(x: 30,
                                  y: logInButton.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        
        googleLoginButton.frame = CGRect(x: 30,
                                           y: faceBookloginButton.bottom+10,
                                           width: scrollView.width-60,
                                           height: 52)
        
        
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create User Account"
        navigationController?.pushViewController(vc, animated: false)
    }
    
    @objc private func loginTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text,let password = passwordField.text ,
            !email.isEmpty, !password.isEmpty , password.count >= 6 else {
                alertUserError()
                return
        }
        
        spinner.show(in: view)
        
        //FireBase Login
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult , error == nil else{
                print("Something went wrong \(error!)")
                return
            }
            
            let user = result.user
            print("logged in user \(user)")
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func alertUserError(){
        
        let alert = UIAlertController(title: "Woopsie", message: "Please fill out the info properly", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert,animated: true)
    }


}

extension LoginViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        if textField == passwordField {
            loginTapped()
        }
        
        return true
    }
}

extension LoginViewController : LoginButtonDelegate{
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard let token = result?.token?.tokenString else {
            print("User Failed to login with facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields" : "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        facebookRequest.start { (_, result, error) in
            
            guard let result = result as? [String : Any], error == nil else{
                print("Failed to make fb graph request")
                return
            }
            
            print(result)
            
            guard let firstName = result["first_name"] as? String ,
                let lastName = result["last_name"] as? String ,
                let email = result["email"] as? String,
                let picture = result["picture"] as? [String : Any] ,
                let data = picture["data"] as? [String : Any] ,
               let pictureUrl = data["url"] as? String else{
                    print("Failed to get email from fb")
                    return
            }
           
            
            
            DatabaseManager.shared.userExists(with: email) { exists in
                
                if !exists{
                    let chatUser = ChatAppUSer(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser , completion: { success in
                        
                        if success {
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url) { data , _ , _ in
                                
                                guard let data = data else {
                                    print("failed to get data from fb")
                                    return
                                }
                                
                                print("got data from fb")
                                
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
                            
                            
                            
                            
                        }
                        
                        
                        
                    })
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult,error in
                
                guard let strongSelf = self else {
                    return
                }
                guard authResult != nil , error == nil else{
                    
                    if let error = error {
                        print("Facebook credentials failed , MFA may be needed \(error)")
                    }
                    
                    return
                }
                
                print("Successfully logged user in")
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            }
        }
        
        
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //no operation
    }
    
    
}
