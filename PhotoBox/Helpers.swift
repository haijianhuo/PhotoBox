//
//  Helper.swift
//  PhotoBox
//
//  Created by Haijian Huo on 3/31/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

import UIKit

class Helpers: NSObject {

    class func documentDirectoryURL() -> URL {
        do {
            let searchPathDirectory = FileManager.SearchPathDirectory.documentDirectory
            
            return try FileManager.default.url(for: searchPathDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
        }
        catch {
            fatalError("*** Error finding default directory: \(error)")
        }
    }
    
    class func timeId() -> String {
        return String(format: "%0.0f", Date().timeIntervalSince1970)
    }

    class func resizeImage(_ image: UIImage,  ratio: CGFloat) -> UIImage {
        let newWidth = image.size.width * ratio
        let newHeight = image.size.height * ratio
        let newSize = CGSize(width: newWidth, height: newHeight)
        UIGraphicsBeginImageContext(newSize)
        image.draw(in: CGRect(origin: CGPoint(x: 0, y :0), size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

}
