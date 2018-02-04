//
//  DNCommentModal.h
//  Delve
//
//  Created by Rakesh Jogi on 20/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNCommentModal : NSObject

@property (nonatomic, strong) NSString *userImageUrl;                                    // Image of commented user
@property (nonatomic, strong) NSString *commentTimeString;                           // String to show time
@property (nonatomic, strong) NSString *commentTitleString;
@property (nonatomic, strong) NSString *commentString;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *idOfUser;

@property (nonatomic) NSTimeInterval secondsCommentedBefore;

@end
