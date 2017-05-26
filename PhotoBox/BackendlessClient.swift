//
//  BackendlessClient.swift
//  PhotoBox
//
//  Created by Haijian Huo on 4/4/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

import UIKit

/*
Sign up at https://backendless.com/ to get a free Backendless cloud server account.
Create an iOS app on your account.
Replace the APP_ID and SECRET_KEY in BackendlessClient.swift with the Application ID and the iOS Secret Key from your account.
Build and run the app with Xcode, the server side table schema will be created automatically once the first photo is uploaded.
*/

let APP_ID = ""
let SECRET_KEY = ""
let REST_KEY = ""
let VERSION_NUM = "v1"

let backendless = Backendless.sharedInstance()!

let kOneDaySeconds = 86400.0
let kLastSyncAt = "lastSyncAt"
let kThumbnailDemension: CGFloat = 200.0
let kCompressionQuality: CGFloat = 0.6

class BackendlessClient: NSObject {
    
    let queryDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss 'GMT'Z"
        return dateFormatter
    }()
    
    var lastSyncAt: Date? {
        get {
            if let date = UserDefaults.standard.object(forKey: kLastSyncAt) as! Date? {
                return date
            }
            else {
                return nil
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kLastSyncAt)
        }
    }

    override init() {
        super.init()
        backendless.initApp(APP_ID, secret: SECRET_KEY, version: VERSION_NUM)
        backendless.initAppFault()
     }

    func createPhotoItem(thumbnailUrl: String, imageUrl: String, successBlock: @escaping () -> Void, errorBlock: @escaping (Fault?) -> Void) {
        
        let item = BEPhotoItem()
        item.thumbnailUrl = thumbnailUrl
        item.imageUrl = imageUrl
        item.deleted = false
        backendless.persistenceService.save(item, response: { (response: Any?) in
            successBlock()
        }, error: { (fault: Fault?) in
            print("createPhotoItem: \(fault?.description ?? "nil error message")")
            errorBlock(fault)
        })
    }
    
    func deletePhotoItem(item: PhotoItem, successBlock: @escaping (Any?) -> Void, errorBlock: @escaping (Fault?) -> Void) {
        
        let object = BEPhotoItem()
        object.objectId = item.objectId
        object.deleted = true
        backendless.persistenceService.save(object, response: { (response: Any?) in
            successBlock(response)
        }, error: { (fault: Fault?) in
            print("deletePhotoItem: \(fault?.message ?? "nil error message")")
            errorBlock(fault)
        })
    }
    
    
    func getPhotoItems(successBlock: @escaping ([Any]?) -> Void, errorBlock: @escaping (Fault?) -> Void) {
        
        var whereClause = "deleted = false"
        if let maxDate = self.lastSyncAt {
            let maxDateString = self.queryDateFormatter.string(from: maxDate)
            whereClause = "created > '\(maxDateString)' or updated > '\(maxDateString)'"
        }
        //print("whereClause: \(whereClause)")
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        dataQuery.queryOptions.sortBy = ["created DESC"]
        dataQuery.queryOptions.pageSize = NSNumber(value: 100)
        backendless.persistenceService.find(BEPhotoItem.ofClass(), dataQuery: dataQuery, response: { (backendlessCollection: BackendlessCollection?) in
            successBlock(backendlessCollection?.data)
            
        }) { (fault: Fault?) in
            print("getPhotoItems: \(fault?.message ?? "nil error message")")
            errorBlock(fault)
        }
    }
    
    func uploadImages(image: UIImage?, successBlock: @escaping (String?) -> Void, errorBlock: @escaping (Fault?) -> Void) {
        
        guard let image = image else {
            errorBlock(nil)
            return
        }
        
        let timeId = Helpers.timeId()
        let fileNameSmallSize = String(format: "files/%@.jpeg", timeId)
        let fileNameLargeSize = String(format: "files/%@l.jpeg", timeId)
        
        var thumbnail: UIImage
        let size = image.size
        let width = min(size.width, size.height)
        
        if width > kThumbnailDemension {
            let ratio = kThumbnailDemension/width
            thumbnail = Helpers.resizeImage(image, ratio: ratio)
        }
        else {
            thumbnail = image
        }
        
        backendless.fileService.upload(fileNameSmallSize, content: UIImageJPEGRepresentation(thumbnail, kCompressionQuality), response: { [weak self] (backendlessFile: BackendlessFile?) in
            let thumbnailUrl = backendlessFile?.fileURL
            backendless.fileService.upload(fileNameLargeSize, content: UIImageJPEGRepresentation(image, kCompressionQuality), response: { (backendlessFile: BackendlessFile?) in
                guard let strongSelf = self else {
                    errorBlock(nil)
                    return
                }
                
                let imageUrl = backendlessFile?.fileURL
                
                strongSelf.createPhotoItem(thumbnailUrl: thumbnailUrl!, imageUrl: imageUrl!, successBlock: {
                    successBlock(imageUrl)
                }, errorBlock: { (fault: Fault?) in
                    errorBlock(fault)
                })
                
                
            }, error: { (fault: Fault?) in
                print("upload thumbnail: \(fault?.message ?? "nil error message")")
                errorBlock(fault)
            })
            }, error: { (fault: Fault?) in
                print("upload thumbnail: \(fault?.message ?? "nil error message")")
                errorBlock(fault)
        })
    }
    
    
    // RESTful APIs
    
    func bulkDeleteTable(table: String, whereClause: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)  {
        
        let whereClauseEncoded = whereClause.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlHostAllowed)
        
        let urlString = String(format:"https://api.backendless.com/%@/data/bulk/%@?where=%@",VERSION_NUM, table, whereClauseEncoded!)
        
        let url = URL(string: urlString)!
        
        let request: NSMutableURLRequest = NSMutableURLRequest(url: url)
        request.httpMethod = "DELETE"
        request.httpShouldHandleCookies = false
        request.addValue(APP_ID, forHTTPHeaderField: "application-id")
        request.addValue(REST_KEY, forHTTPHeaderField: "secret-key")
        request.addValue("REST", forHTTPHeaderField: "application-type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            completionHandler(data, response, error)
        })
        task.resume()
    }

}
