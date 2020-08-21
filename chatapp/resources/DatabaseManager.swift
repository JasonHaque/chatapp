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
                
                self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                    
                    if var usersCollection = snapshot.value as? [[String : String]]{
                        let newElement = [
                            [
                                "name" : user.firstName + " " + user.lastName,
                                "email" : user.safeEmail
                            ]
                        ]
                        
                        usersCollection.append(contentsOf: newElement)
                        self.database.child("users").setValue(usersCollection,withCompletionBlock: { error , _ in
                            
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            
                            completion(true)
                            
                        })
                        
                        
                    }
                    else{
                        let newCollection  : [[String : String]] = [
                            [
                                "name" : user.firstName + " " + user.lastName,
                                "email" : user.safeEmail
                            ]
                        ]
                        
                        self.database.child("users").setValue(newCollection,withCompletionBlock: { error , _ in
                            
                            guard error == nil else {
                                completion(false)
                                return
                            }
                            
                            completion(true)
                            
                        })
                        
                    }
                }
                
                
                
        })
        
        
    }
    
    static func safeEmail(emailAddress : String) -> String{
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
    
    public func getAllUsers (completion : @escaping (Result <[[String : String]], Error>) -> Void){
        
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            
            guard let value = snapshot.value as? [[String : String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
    }
    
    public enum DatabaseError : Error {
        case failedToFetch
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

//MARK:- sending messages

extension DatabaseManager {
    
    ///Create a new convo with target user email and first message
    public func createNewConversation(with otherUserEmail : String, name : String, firstMessage : Message , completion : @escaping (Bool) -> Void){
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            guard var userNode = snapshot.value as? [String : Any] else{
                completion(false)
                print("user not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData : [String : Any] = [
                
                "id" : conversationId,
                "other_user_email" : otherUserEmail,
                "name" : name,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read" : false
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String : Any]]{
                //already exists
                //append now
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                
                ref.setValue(userNode,withCompletionBlock: { [weak self] error , _ in
                    
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                    
                })
                
            }
            else{
                //let new
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode,withCompletionBlock: { [weak self] error , _ in
                    
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                    
                   
                    
                })
                
            }
        }
    }
    
    private func finishCreatingConversation(name :String ,conversationID : String , firstMessage : Message ,completion : @escaping (Bool) -> Void){
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        let collectionMessage : [String : Any] = [
            "id": firstMessage.messageId,
            "type" : firstMessage.kind.messageKindString,
            "content" : message,
            "date" : dateString,
            "sender_email" : currentUserEmail,
            "is_read": false,
            "name" : name
        ]
        let value : [String : Any] = [
            
            "messages" : [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value ,withCompletionBlock: { error , _ in
            
            guard error == nil else{
                completion(false)
                
                return
            }
            
            completion(true)
            
        })
    }
    
    /// fetches and returns all conversations for user with passed in email

    public func getAllConversations(for email : String , completion : @escaping (Result<[Conversation],Error>) -> Void){
        
    }
    
    ///gets all messages
    public func getAllMessagesForConversation(with id : String , completion : @escaping (Result<String,Error>) -> Void){
        
    }
    
    ///sends a message to a convo
    public func sendMessage(to conversation : String , message : Message , completion: @escaping (Bool) -> Void){
        
    }
}
