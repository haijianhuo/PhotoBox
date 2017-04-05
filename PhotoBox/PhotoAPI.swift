//
//  PhotoAPI.swift
//  PhotoBox
//
//  Created by Haijian Huo on 4/4/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

import UIKit

let photoAPI = PhotoAPI.sharedInstance

class PhotoAPI: NSObject {

    fileprivate let backendlessClient: BackendlessClient
    let persistencyManager: PersistencyManager
    
    class var sharedInstance: PhotoAPI {
        struct Singleton {
            static let instance = PhotoAPI()
        }
        return Singleton.instance
    }
    
    override init() {
        backendlessClient = BackendlessClient()
        persistencyManager = PersistencyManager()

        super.init()
    }
    
    deinit {
    }
    
    func getPhotoItemFRC() -> NSFetchedResultsController<PhotoItem>! {
        return self.persistencyManager.getPhotoItemFRC()
    }
    
    func createPhotoItem(thumbnailUrl: String, imageUrl: String, successBlock: @escaping () -> Void, errorBlock: @escaping (Fault?) -> Void) {
        
        self.backendlessClient.createPhotoItem(thumbnailUrl: thumbnailUrl, imageUrl: imageUrl, successBlock: {
            successBlock()
        }) { (fault: Fault?) in
            errorBlock(fault)
        }
    }
    
    func deletePhotoItem(item: PhotoItem, successBlock: @escaping (Any?) -> Void, errorBlock: @escaping (Fault?) -> Void) {
        
        if !Utils.isInternetReachableWithPopup() {
            errorBlock(nil)
        }

        self.backendlessClient.deletePhotoItem(item: item, successBlock: { (response: Any?) in
            
            self.persistencyManager.deletePhotoItem(item)
            successBlock(response)
        }, errorBlock: { (fault: Fault?) in
            if let fault = fault {
                print("\(fault.faultCode), \(fault.message)")
                if fault.faultCode == "1000" { //"Entity with the specified ID cannot be found
                    self.persistencyManager.deletePhotoItem(item)
                    successBlock(nil)
                    return
                }
            }
            errorBlock(fault)
        })
        
    }
    
    
    func getPhotoItems(successBlock: @escaping (Int) -> Void, errorBlock: @escaping (Fault?) -> Void) {
        
        if !Utils.isInternetReachableWithPopup() {
            errorBlock(nil)
        }

        self.backendlessClient.getPhotoItems(successBlock: { (objects: [Any]?) in
            var count = 0
            if let objects = objects {
                count = objects.count
                if count > 0 {
                    let lastUpdatedAt = self.persistencyManager.savePhotoItems(objects: objects)
                    
                    if lastUpdatedAt != nil {
                        self.backendlessClient.lastSyncAt = lastUpdatedAt
                    }
                }
            }
            successBlock(count)
        }) { (fault: Fault?) in
            errorBlock(fault)
        }
    }
    
    func uploadImages(image: UIImage?, successBlock: @escaping (String?) -> Void, errorBlock: @escaping (Fault?) -> Void) {
        
        if !Utils.isInternetReachableWithPopup() {
            errorBlock(nil)
        }

        self.backendlessClient.uploadImages(image: image, successBlock: { (imageUrl: String?) in
            successBlock(imageUrl)
        }) { (fault: Fault?) in
            errorBlock(fault)
        }
    }

}
