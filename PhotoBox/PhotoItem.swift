//
//  PhotoItem.swift
//  PhotoBox
//
//  Created by Haijian Huo on 3/30/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

import Foundation
import CoreData
import JSQCoreDataKit

public final class PhotoItem: NSManagedObject, CoreDataEntityProtocol {

    // MARK: CoreDataEntityProtocol

    public static let defaultSortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

    // MARK: Properties

    @NSManaged public var objectId: String
    @NSManaged public var thumbnailUrl: String
    @NSManaged public var imageUrl: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date?
    
    // MARK: Init

    public init(context: NSManagedObjectContext,
                objectId: String,
            thumbnailUrl: String,
                imageUrl: String,
                createdAt: Date,
                updatedAt: Date?
        ) {
        super.init(entity: PhotoItem.entity(context: context), insertInto: context)
        self.objectId = objectId
        self.thumbnailUrl = thumbnailUrl
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    @objc
    private override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
}
