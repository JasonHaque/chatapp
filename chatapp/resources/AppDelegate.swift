//
//  AppDelegate.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 11/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
          FirebaseApp.configure()
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        

        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        return GIDSignIn.sharedInstance().handle(url)

    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        guard error == nil else {
            print("Failed to sign in with google \(error!)")
            return
        }
        
        guard let user = user else{
            return
        }
        guard let email = user.profile.email ,
            let firstName = user.profile.givenName,
            let lastName = user.profile.familyName else{
            return
        }
        
        UserDefaults.standard.set(email, forKey: "email")
        
        DatabaseManager.shared.userExists(with: email) { exists in
            
            let chatUser = ChatAppUSer(firstName: firstName, lastName: lastName, emailAddress: email)
            if !exists{
                DatabaseManager.shared.insertUser(with: chatUser ,completion: { success in
                    
                    if success{
                        //upload image
                        
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else{
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url) { data, _, _ in
                                
                                guard let data = data else{
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
                            }.resume()
                            
                            
                        }
                        
                        
                    }
                    
                })
            }
        }
        guard let authentication = user.authentication else {
            
            print("missing auth object")
            return
            
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential) { result , error in
            
            guard result != nil , error == nil else{
                return
            }
            
            print("Sign in with google")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        }
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected")
    }
    
   
    

}


