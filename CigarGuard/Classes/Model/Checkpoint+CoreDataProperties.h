//
//  Checkpoint+CoreDataProperties.h
//  CigarGuard
//
//  Created by admin on 4/29/16.
//  Copyright © 2016 GP. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Checkpoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface Checkpoint (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *average;
@property (nullable, nonatomic, retain) NSNumber *current_setting;
@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSNumber *humidity;
@property (nullable, nonatomic, retain) NSNumber *max_val;
@property (nullable, nonatomic, retain) NSNumber *min_val;
@property (nullable, nonatomic, retain) NSNumber *state;
@property (nullable, nonatomic, retain) NSNumber *temperature;
@property (nullable, nonatomic, retain) History *history;

@end

NS_ASSUME_NONNULL_END
