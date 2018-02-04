//
//  DNOrganizationObject.h
//  Delve
//
//  Created by Letsgomo Labs on 17/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DNOrganizationObject : NSObject

@property (strong, nonatomic)  NSString *heading;
@property (strong, nonatomic)  NSMutableArray *personsCommented;

@property (strong, nonatomic)  NSString *employeeImageURL;
@property (nonatomic, strong) NSData *employeeImageData;
@property (strong, nonatomic)  NSString *employeeDesig;
@property (strong, nonatomic)  NSString *employeeName;

@end
