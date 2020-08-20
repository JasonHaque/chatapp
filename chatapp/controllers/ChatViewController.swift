//
//  ChatViewController.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 19/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message : MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    
    
}

struct Sender : SenderType {
    var senderId: String
    var displayName: String
    var photoURL : String
    
}
class ChatViewController: MessagesViewController{
    
    public var isNewConversation = false
    public let otherUserEmail : String

    private var messages = [Message]()
    private let selfSender = Sender(senderId: "Joe Smith", displayName: "1", photoURL: "")
    
    init(with email  : String){
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello world Message")))
        messages.append(Message(sender: selfSender,
                                messageId: "1",
                                sentDate: Date(),
                                kind: .text("Hello world Message")))
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    


}

extension ChatViewController : MessagesDataSource,MessagesLayoutDelegate,MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    
}

extension ChatViewController : InputBarAccessoryViewDelegate{
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        //send message
        
        if isNewConversation{
            
            //create Convo in db
        }
        
        else{
            //append to existing one
        }
    }
}
