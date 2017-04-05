//
//  BEPhotoItem.h
//  PhotoBox
//
//  Created by Haijian Huo on 4/4/17.
//  Copyright © 2017 Haijian Huo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BackendlessEntity.h"

@interface BEPhotoItem : BackendlessEntity

@property (nonatomic, strong) NSString *thumbnailUrl;
@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, assign) BOOL deleted;

@end
