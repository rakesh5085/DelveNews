//
//  DNOrganizationModal.h
//  Delve
//
//  Created by Swati Jain on 21/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNOrganizationModal : NSObject

@property (nonatomic , strong) NSString *nameOfUser;
@property (nonatomic , strong) NSString *imageUrlString;
@property (nonatomic , strong) NSString *userId;
@property (nonatomic , strong) NSMutableArray *clips;
@property (nonatomic , strong) NSString *positionString;
@property (nonatomic , strong) NSString *emailString;

@property (nonatomic, strong) NSMutableData *userImageData;
@end
