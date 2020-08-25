//
//  StorageManager.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 20/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result <String , Error>) -> Void
    
    public func uploadProfilePicture(with data : Data ,fileName : String ,completion : @escaping UploadPictureCompletion){
        
        
        storage.child("images/\(fileName)").putData(data, metadata: nil,completion: { metadata , error in
            
            guard error == nil else{
                
                print("Failed to upload data to firebase for picture")
                
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
         self.storage.child("images/\(fileName)").downloadURL(completion: {url , error in
                
                guard let url = url else {
                    print("failedToGetDownloadUrl")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                
                print("download url returned \(urlString)")
                completion(.success(urlString))
            })
            
        } )
    }
    
    
    public func downloadURL(for path : String ,completion : @escaping(Result<URL,Error>) -> Void){
        
        let reference = storage.child(path)
        
        reference.downloadURL { url , error in
            
            guard let url = url , error == nil else {
                
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
           
        }
    }
    
    
    public func uploadMessagePhoto(with data : Data ,fileName : String ,completion : @escaping UploadPictureCompletion){
        
        
        storage.child("message_images/\(fileName)").putData(data, metadata: nil,completion: { metadata , error in
            
            guard error == nil else{
                
                print("Failed to upload data to firebase for picture")
                
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
         self.storage.child("message_images/\(fileName)").downloadURL(completion: {url , error in
                
                guard let url = url else {
                    print("failedToGetDownloadUrl")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                
                print("download url returned \(urlString)")
                completion(.success(urlString))
            })
            
        } )
    }
    public enum StorageErrors : Error {
        case failedToUpload
         case failedToGetDownloadUrl
        
    }
}
