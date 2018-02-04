//
//  DNTableViewCellFeedCell.m
//  Delve
//
//  Created by Letsgomo Labs on 16/08/13.
//  Copyright (c) 2013 LetsGoMo Labs. All rights reserved.
//

#import "DNTableViewCellFeedCell.h"

@implementation DNTableViewCellFeedCell

@synthesize feedImage = _feedImage, feedTitle = _feedTitle, feedSource = _feedSource;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
