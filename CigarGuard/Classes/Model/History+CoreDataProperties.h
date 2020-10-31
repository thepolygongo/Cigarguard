//
//  History+CoreDataProperties.h
//  CigarGuard
//
//  Created by admin on 4/29/16.
//  Copyright © 2016 GP. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "History.h"

NS_ASSUME_NONNULL_BEGIN

@interface History (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSString *device_name;
@property (nullable, nonatomic, retain) NSString *device_uuid;
@property (nullable, nonatomic, retain) NSOrderedSet<Checkpoint *> *checkpoints;

@end

@interface History (CoreDataGeneratedAccessors)

- (void)insertObject:(Checkpoint *)value inCheckpointsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromCheckpointsAtIndex:(NSUInteger)idx;
- (void)insertCheckpoints:(NSArray<Checkpoint *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeCheckpointsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInCheckpointsAtIndex:(NSUInteger)idx withObject:(Checkpoint *)value;
- (void)replaceCheckpointsAtIndexes:(NSIndexSet *)indexes withCheckpoints:(NSArray<Checkpoint *> *)values;
- (void)addCheckpointsObject:(Checkpoint *)value;
- (void)removeCheckpointsObject:(Checkpoint *)value;
- (void)addCheckpoints:(NSOrderedSet<Checkpoint *> *)values;
- (void)removeCheckpoints:(NSOrderedSet<Checkpoint *> *)values;

@end

NS_ASSUME_NONNULL_END
