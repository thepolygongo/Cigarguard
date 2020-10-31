//
//  History.h
//  CigarGuard
//
//  Created by admin on 4/29/16.
//  Copyright © 2016 GP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Checkpoint;

NS_ASSUME_NONNULL_BEGIN

@interface History : NSManagedObject

// Insert code here to declare functionality of your managed object subclass
- (NSString *)getDeviceName;

@end

NS_ASSUME_NONNULL_END

#import "History+CoreDataProperties.h"
