//
//  DNFeedCell.h
//  Delve
//
//  Created by Atul Khatri on 12/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNFeedCell : NSObject

@property (strong, nonatomic)  NSString *feedImage;
@property (strong, nonatomic)  NSString *feedTitle;
@property (strong, nonatomic)  NSString *feedSource;
@property (strong, nonatomic)  NSString *feedLink;
@property (strong, nonatomic)  NSMutableArray *feedDelves;
@property (strong, nonatomic)  NSMutableArray *feedComments;
@property (strong, nonatomic)  NSData* feedImageData;
@property (strong, nonatomic) NSString *feedId;

@end
