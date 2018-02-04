//
//  DNConversationCell.h
//  Delve
//
//  Created by Atul Khatri on 02/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DNConversationCell : NSObject

@property (strong, nonatomic)  NSString *imageURL;
@property (strong, nonatomic)  NSString *heading;
@property (strong, nonatomic)  NSString *publicationSourceName;
@property (strong, nonatomic)  NSString *publicationSourceIconURL;
@property (strong, nonatomic)  NSMutableArray *personsCommented;// comments
@property (strong, nonatomic)  NSMutableArray *personsCliped;// clips
@property (strong, nonatomic)  NSString *articleId;
@property (strong, nonatomic)  NSString *articleLink;
@property (nonatomic, strong)  NSData *mainImageData;
@property (nonatomic, strong)  NSData *iconImageData;


@end
