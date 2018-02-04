//
//  DNProfileCell.h
//  Delve
//
//  Created by Atul Khatri on 14/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNProfileCell : NSObject

@property (strong, nonatomic)  NSString *articleID;
@property (strong, nonatomic)  NSString *articleTitle;
@property (strong, nonatomic)  NSString *articleDate;
@property (strong, nonatomic)  NSString *articleLink;
@property (strong, nonatomic)  NSMutableArray *articleComments;
@end
