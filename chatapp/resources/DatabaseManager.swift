//
//  DatabaseManager.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 18/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager{
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    
    
}


extension DatabaseManager{
    
    public func userExists(with email : String, completion : @escaping((Bool)->Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    
    public func insertUser(with user : ChatAppUSer, completion : @escaping (Bool) -> Void){
        
        database.child(user.safeEmail).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
            ],withCompletionBlock: { error , _ in
                
                guard error == nil else {
                    print("failed to write to db")
                    completion(false)
                    return
                }
                
                completion(true)
                
        })
        
        
    }
    
    static func safeEmail(emailAddress : String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
    
}


struct ChatAppUSer{
    let firstName : String
    let lastName : String
    let emailAddress : String
    
    var safeEmail : String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
    var profilePictureFileName : String {
        
        return "\(safeEmail)_profile_picture.png"
    }
}
