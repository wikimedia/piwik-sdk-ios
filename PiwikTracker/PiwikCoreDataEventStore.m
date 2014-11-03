//
//  PiwikCoreDataEventStore.m
//  PiwikTracker
//
//  Created by Mattias Levin on 01/11/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import "PiwikCoreDataEventStore.h"
#import <CoreData/CoreData.h>
#import "PTEventEntity.h"


@interface PiwikCoreDataEventStore ()

@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end


static NSUInteger const DefaultMaxNumberOfStoredEvents = 500;


@implementation PiwikCoreDataEventStore


@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;



- (instancetype)init {
  self = [super init];
  if (self) {
    _maxNumberOfQueuedEvents = DefaultMaxNumberOfStoredEvents;
  }
  return self;
}


- (void)saveEventWithParameters:(NSDictionary*)parameters completionBlock:(void (^)(void))completionBlock {
  
  [self.managedObjectContext performBlock:^{
    
    NSError *error;
    
    // Check if we reached the limit of the number of queued events
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PTEventEntity"];
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    if (count < self.maxNumberOfQueuedEvents) {
      
      // Create new event entity
      PTEventEntity *eventEntity = [NSEntityDescription insertNewObjectForEntityForName:@"PTEventEntity" inManagedObjectContext:self.managedObjectContext];
      eventEntity.requestParameters = [NSKeyedArchiver archivedDataWithRootObject:parameters];
      
      [self.managedObjectContext save:&error];
      
    } else {
      NSLog(@"Piwik tracker reach maximum number of queued events");
    }
    
    completionBlock();
    
  }];
  
}


- (void)readEvents:(NSUInteger)numberOfEvents completionBlock:(void (^)(NSSet *eventIDs, NSArray *events, BOOL hasMore))completionBlock {
  
  [self.managedObjectContext performBlock:^{
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PTEventEntity"];
    
    // Oldest first
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    
    fetchRequest.fetchLimit = numberOfEvents + 1;
    
    NSError *error;
    NSArray *eventEntities = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    NSUInteger returnCount = eventEntities.count == fetchRequest.fetchLimit ? numberOfEvents : eventEntities.count;
    
    NSMutableArray *events = [NSMutableArray arrayWithCapacity:returnCount];
    NSMutableSet *eventIDs = [NSMutableSet setWithCapacity:returnCount];
    
    if (eventEntities && eventEntities.count > 0) {
      
      [eventEntities enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, returnCount)] options:0
                                    usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                      
                                      PTEventEntity *eventEntity = (PTEventEntity*)obj;
                                      NSDictionary *parameters = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:eventEntity.requestParameters];
                                      
                                      [events addObject:parameters];
                                      [eventIDs addObject:eventEntity.objectID];
                                      
                                    }];
      
      completionBlock(eventIDs, events, eventEntities.count == fetchRequest.fetchLimit ? YES : NO);
      
    } else {
      // No more pending events
      completionBlock(nil, nil, NO);
    }
    
  }];
  
}


- (void)deleteEventsWithIDs:(NSSet*)eventIDs completionBlock:(void (^)(void))completionBlock {
  
  [self.managedObjectContext performBlock:^{
    
    NSError *error;
    
    for (NSManagedObjectID *entityID in eventIDs) {
      
      PTEventEntity *event = (PTEventEntity*)[self.managedObjectContext existingObjectWithID:entityID error:&error];
      if (event) {
        [self.managedObjectContext deleteObject:event];
      }
      
    }
    
    [self.managedObjectContext save:&error];
    
  }];

}


- (void)deleteAllEvents {
  
  [self.managedObjectContext performBlock:^{
    
    NSError *error;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PTEventEntity"];
    
    NSArray *events = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *event in events) {
      [self.managedObjectContext deleteObject:event];
    }
    
    [self.managedObjectContext save:&error];
    
  }];
  
}



#pragma mark - Core Data stack

- (NSManagedObjectContext*)managedObjectContext {
  
  if (_managedObjectContext) {
    return _managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator) {
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
  }
  
  return _managedObjectContext;
}


- (NSManagedObjectModel*)managedObjectModel {
  
  if (_managedObjectModel) {
    return _managedObjectModel;
  }
  
  NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"piwiktracker" withExtension:@"momd"];
  _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  
  return _managedObjectModel;
}


- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
  
  if (_persistentStoreCoordinator) {
    return _persistentStoreCoordinator;
  }
  
  NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"piwiktracker"];
  
  NSError *error = nil;
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
  if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
    
    BOOL isMigrationError = [error code] == NSPersistentStoreIncompatibleVersionHashError || [error code] == NSMigrationMissingSourceModelError;
    
    if ([[error domain] isEqualToString:NSCocoaErrorDomain] && isMigrationError) {
      
      // Could not open the database, remote it ans try again
      [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
      
      NSLog(@"Removed incompatible model version: %@", [storeURL lastPathComponent]);
      
      // Try one more time to create the store
      [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                configuration:nil
                                                          URL:storeURL
                                                      options:nil
                                                        error:&error];
      
      if (_persistentStoreCoordinator) {
        // If we successfully added a store, remove the error that was initially created
        error = nil;
      } else {
        // Not possible to recover of workaround
        NSLog(@"Unresolved error when setting up code data stack %@, %@", error, [error userInfo]);
        abort();
      }
      
    }
    
  }
  
  return _persistentStoreCoordinator;
}


- (NSURL*)applicationDocumentsDirectory {
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}



@end
