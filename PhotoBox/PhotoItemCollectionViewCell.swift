//
//  PhotoItemCollectionViewCell.swift
//  PhotoBox
//
//  Created by Haijian Huo on 3/30/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

import UIKit

class PhotoItemCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var itemImageView: UIImageView!
    
    func setGalleryItem(_ item: PhotoItem) {
        let url = URL(string: item.thumbnailUrl)
        itemImageView.sd_setImage(with: url, placeholderImage: nil)

        self.layer.borderColor = UIColor.red.cgColor
    }
    
    override var isSelected: Bool {
        willSet {
            self.layer.borderWidth = newValue ? 2 : 0
        }
    }

}
