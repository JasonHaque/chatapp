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
        
        database.child(email).observeSingleEvent(of: .value) { snapshot in
            
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    
    public func insertUser(with user : ChatAppUSer){
        
        database.child(user.emailAddress).setValue([
            "first_name" : user.firstName,
            "last_name" : user.lastName
        ])
        
        
    }
}


struct ChatAppUSer{
    let firstName : String
    let lastName : String
    let emailAddress : String
    
    //let profilePictureUrl : String
}
