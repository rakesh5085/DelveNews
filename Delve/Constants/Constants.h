//
//  Constants.h
//  Delve
//
//  Created by Letsgomo Labs on 30/07/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#ifndef Delve_Constants_h
#define Delve_Constants_h

// header view of a table
#define kHeaderHeight 94.0
#define kHeaderWidth 300.0

// Small image inside cell / Header of table
#define kImagePersonWidth 47.0
#define kImagePersonHeight 47.0

// lable inside any cell or header of tabel
#define kLableWidth 200.00
#define kLableHeight 18.0

// cell border parameters
#define kCellBorderWidth 1.0f
#define kCellBorderRadius 0.0f

// drop down table parameters
#define kDropDownTag 101
#define kDropDownTableHeight 132.0f
#define kRowHeight 44.0

// Notification for organization switch
#define kPOSTNOTIFICATION_SWITCH_ORG @"DNSwitchOrganizationNotification"

// notification for feeds refresh after 15 mins
#define kPOSTNOTIFICATION_REFRESH_FEEDS @"DNRefreshFeedsNotification"

// notification for Delve or Comment on an article
#define kPOSTNOTIFICATION_DELVE_OR_COMMENT @"DNDelveOrCommentNotification"

// notification for Delve or Comment on an article
#define kPOSTNOTIFICATION_USER_LOGGEDOUT @"DNUserLoggedOutNotification"

/*
 *  System Versioning Preprocessor Macros
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


//API Host Name
#define kAPI_Host_Name @"http://proto.delvenews.com"

#endif


