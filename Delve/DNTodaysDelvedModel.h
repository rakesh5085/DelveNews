//
//  DNTodaysDelvedModel.h
//  Delve
//
//  Created by Swati Jain on 21/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNTodaysDelvedModel : NSObject

@property (nonatomic, strong) NSString *titleOfArticle;
@property (nonatomic, strong) NSString *linkOfArticle;
@property (nonatomic, strong) NSString *idOfArticle;

@property (nonatomic, strong) NSMutableArray *clipsOfArticleArray;
@property (nonatomic, strong) NSMutableArray *commentsOfArticleArray;

@property (nonatomic, strong) NSString *delveAndCommentString;

@end
