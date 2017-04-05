//
//  PersistencyManager.swift
//  PhotoBox
//
//  Created by Haijian Huo on 3/31/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

class PersistencyManager: NSObject {
    
    var stack: CoreDataStack!

    override init() {
        super.init()
        
        let model = CoreDataModel(name: "DataBox", bundle: Bundle.main)
        let factory = CoreDataStackFactory(model: model)
        
        factory.createStack(onQueue: nil) { (result: StackResult) in
            switch result {
            case .success(let s):
                self.stack = s
                //print("createStack: success!")
            case .failure(let err):
                assertionFailure("Error creating stack: \(err)")
            }
        }
    }
    
    func getPhotoItemFRC() -> NSFetchedResultsController<PhotoItem>! {
        let frc = NSFetchedResultsController(fetchRequest: PhotoItem.fetchRequest,
                                         managedObjectContext: self.stack.mainContext,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        
        return frc
    }

    func savePhotoItems(objects: [Any]) -> Date? {
        let backgroundChildContext = self.stack.childContext(concurrencyType: .privateQueueConcurrencyType)
        
        var lastUpdatedAt: Date?
        
        for object in objects {
            let item = object as! BEPhotoItem
            
            let fetchRequest = PhotoItem.fetchRequest
            fetchRequest.predicate = NSPredicate(format: "objectId == %@", item.objectId)
            
            do {
                let array = try backgroundChildContext.fetch(fetchRequest)
                if array.count > 0 {
                    let photoItem = array.first
                    if item.deleted {
                        backgroundChildContext.delete(photoItem!)
                    }
                }
                else {
                    if !item.deleted {
                        _ = PhotoItem(context: backgroundChildContext, objectId: item.objectId, thumbnailUrl: item.thumbnailUrl, imageUrl: item.imageUrl, createdAt: item.created, updatedAt: item.updated)
                        
                    }
                }
            } catch let error as NSError {
                print("fetchRequest: \(error.description)")
            }
            
            let updatedAt = (item.updated == nil ? item.created : item.updated)!
            
            if lastUpdatedAt ==  nil {
                lastUpdatedAt = updatedAt
            }
            else {
                if lastUpdatedAt?.compare(updatedAt) == .orderedAscending {
                    lastUpdatedAt = updatedAt
                }
            }
        }
        saveContext(backgroundChildContext)
        return lastUpdatedAt
    }

    func deletePhotoItem(_ item: PhotoItem) {
        let context = item.managedObjectContext!
        context.delete(item)
        saveContext(context)
    }
}
