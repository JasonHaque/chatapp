//
//  DatabaseManager.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 18/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager{
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    
    
}


extension DatabaseManager{
    
    public func userExists(with email : String, completion : @escaping((Bool)->Void)){
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            
            guard snapshot.exists() else{
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
                        print("array exists")
                        
                        print(usersCollection)
                        let newElement = [
                            [
                                "name" : user.firstName + " " + user.lastName,
                                "email" : user.safeEmail
                            ]
                        ]
                        
                        usersCollection.append(contentsOf: newElement)
                        print(usersCollection)
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
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
        let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
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
            let recipient_newConversationData : [String : Any] = [
                
                "id" : conversationId,
                "other_user_email" : safeEmail,
                "name" : currentName,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read" : false
                ]
            ]
            
            //update recipient
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String : Any]]{
                    //append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else{
                    //create
                    
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            
            //update current user convo
            
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
        
        database.child("\(email)/conversations").observe(.value) { snapshot in
            
            guard let value = snapshot.value as? [[String : Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations : [Conversation] = value.compactMap({ dictionary in
                
                guard let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let latestMessage = dictionary["latest_message"] as? [String : Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else{
                        return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
                
                
            })
            
            completion(.success(conversations))
            
        }
        
    }
    
    ///gets all messages
    public func getAllMessagesForConversation(with id : String , completion : @escaping (Result<[Message],Error>) -> Void){
        
        
        database.child("\(id)/messages").observe(.value) { snapshot in
            
            guard let value = snapshot.value as? [[String : Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                print("failing to get messages from db")
                return
            }
            let messages : [Message] = value.compactMap({ dictionary in
                
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageId = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let type = dictionary["type"] as? String,
                    let dateString = dictionary["date"] as? String ,
                    let date = ChatViewController.dateFormatter.date(from: dateString) else{
                        return nil
                }
                var kind : MessageKind?
                
                if type == "photo"{
                    
                    guard let imageUrl = URL(string: content) ,
                    let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    
                    kind = .photo(media)
                    
                }
                else if type == "video"{
                    
                    guard let videoUrl = URL(string: content) ,
                    let placeholder = UIImage(named: "play_logo") else {
                        return nil
                    }
                    
                    let media = Media(url: videoUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    
                    kind = .video(media)
                    
                }
                else{
                    kind = .text(content)
                }
                
                guard let finalKind = kind else{
                    return nil
                }
                
                let sender = Sender(senderId: senderEmail, displayName: name, photoURL: "")
                
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalKind)
                
                
               
                
                
            })
            
            completion(.success(messages))
            
        }
        
    }
    
    ///sends a message to a convo
    public func sendMessage(to conversation : String ,otherUserEmail : String ,name : String, newMessage : Message , completion: @escaping (Bool) -> Void){
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
         database.child("\(conversation)/messages").observeSingleEvent(of :.value) { [weak self] snapshot in
            
            guard let strongSelf = self else{
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String : Any]] else{
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch newMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let mediaString = mediaItem.url?.absoluteString{
                    message = mediaString
                }
                
                break
            case .video(let mediaItem):
                
                if let mediaString = mediaItem.url?.absoluteString{
                    message = mediaString
                }
                
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
            let newMessageEntry : [String : Any] = [
                "id": newMessage.messageId,
                "type" : newMessage.kind.messageKindString,
                "content" : message,
                "date" : dateString,
                "sender_email" : currentUserEmail,
                "is_read": false,
                "name" : name
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages,withCompletionBlock: {error , _ in
                
                guard error == nil else{
                    completion(false)
                    return
                }
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    var databaseEntryConversations = [[String : Any]]()
                    
                    let updatedValue : [String : Any] = [
                        "date" : dateString,
                        "is_read" : false,
                        "message" : message
                    ]
                    if var currentUserConversations = snapshot.value as? [[String : Any]]{
                      
                        
                        var targetConversation : [String : Any]?
                        var position = 0
                        
                        
                        for conversationDictionary in currentUserConversations {
                            if let currentID = conversationDictionary["id"] as? String, currentID == conversation {
                                
                                targetConversation = conversationDictionary
                               
                                break
                                
                            }
                            position += 1
                        }
                        if var targetConversation = targetConversation {
                            
                            targetConversation["latest_message"] = updatedValue
                            
                           
                            
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                            
                        }
                        else{
                            let newConversationData : [String : Any] = [
                                
                                "id" : conversation,
                                "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name" : name,
                                "latest_message" : updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                    }
                    
                    else{
                        let newConversationData : [String : Any] = [
                            
                            "id" : conversation,
                            "other_user_email" : DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name" : name,
                            "latest_message" : updatedValue
                        ]
                        databaseEntryConversations = [
                            
                            newConversationData
                            
                        ]
                    }
                    
                    
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations) { error , _ in
                        
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        
                        //update latest msg for recipeint
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            
                            guard var otherUserConversations = snapshot.value as? [[String : Any]] else{
                                completion(false)
                                return
                            }
                            
                            let updatedValue : [String : Any] = [
                                "date" : dateString,
                                "is_read" : false,
                                "message" : message
                            ]
                            
                            var targetConversation : [String : Any]?
                            var position = 0
                            
                            
                            for conversationDictionary in otherUserConversations{
                                if let currentID = conversationDictionary["id"] as? String, currentID == conversation {
                                    
                                    targetConversation = conversationDictionary
                                   
                                    break
                                    
                                }
                                position += 1
                            }
                            targetConversation?["latest_message"] = updatedValue
                            
                            guard let finalConversation = targetConversation else{
                                completion(false)
                                return
                            }
                            
                            otherUserConversations[position] = finalConversation
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error , _ in
                                
                                guard error == nil else{
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                        
                        
                        
                    }
                }
                
                
            })
            
        }
        
    }
    
    public func deleteConversation(conversationId : String ,completion : @escaping (Bool) -> Void){
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        //Get all conversations and delete the conversation with given id
        
        let ref = database.child("\(safeEmail)/conversations")
        
        ref.observeSingleEvent(of: .value) { snapshot in
            
            if var conversations = snapshot.value as? [[String : Any]]{
                var positionToRemove = 0
                
                for conversation in conversations{
                    if let id = conversation["id"] as? String,
                        id == conversationId{
                        print("found conversation to delete")
                        break
                        
                    }
                    positionToRemove += 1
                }
                
                conversations.remove(at: positionToRemove)
                
                ref.setValue(conversations,withCompletionBlock: { error , _ in
                    
                    guard error == nil else{
                        completion(false)
                        print("could not delete convo")
                        return
                    }
                    print("Deleted convo  from the database")
                    completion(true)
                })
                
            }
        }
    }
}

extension DatabaseManager{
    
    public func getDataFor(path : String ,  completion : @escaping (Result<Any,Error>) -> Void){
        
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            
            guard let value = snapshot.value else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        }
        
    }
    
    public func conversationExists(with targetRecipientEmail : String , completion : @escaping (Result<String,Error>)-> Void){
        
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
            
            guard let collection = snapshot.value as? [[String : Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            if let conversation = collection.first(where: {
                
                guard let targetSenderEmail = $0["other_user_email"] as? String else{
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }){
                //get id
                
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                
                completion(.success(id))
                return
            }
            
            completion(.failure(DatabaseError.failedToFetch))
            return
            
        }
        
    }
}
