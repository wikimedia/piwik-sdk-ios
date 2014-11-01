//
//  InMemoryEventStore.m
//  PiwikTracker
//
//  Created by Mattias Levin on 29/10/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import "InMemoryEventStore.h"


static NSString * const PiwikStorageQueue = @"com.piwik.storageQueu";



@interface Event : NSObject

@property (nonatomic, strong) NSString *identity;
@property (nonatomic, strong) NSDictionary *parameters;

+ (instancetype)eventWithParameters:(NSDictionary*)parameters;

@end



@interface InMemoryEventStore ()

@property (nonatomic, strong) NSMutableArray *eventStore;

@property (nonatomic, strong) dispatch_queue_t queue;

// TODO Max size?

@end


@implementation InMemoryEventStore


- (void)start {
  
  if (!self.eventStore) {
    self.eventStore = [NSMutableArray array];
  }
  
  self.queue = dispatch_queue_create([PiwikStorageQueue UTF8String], NULL);
  
}


- (void)saveEventWithParameters:(NSDictionary*)parameters completionBlock:(void (^)(void))completionBlock {
  
  __weak typeof(self)weakSelf = self;
  dispatch_async(self.queue, ^{
    [weakSelf.eventStore addObject:[Event eventWithParameters:parameters]];
    completionBlock();
  });
  
}


- (void)readEvents:(NSUInteger)numberOfEvents completionBlock:(void (^)(NSArray *eventIDs, NSArray *events, BOOL hasMore))completionBlock {
  
  __weak typeof(self)weakSelf = self;
  dispatch_async(self.queue, ^{
    
    __block BOOL moreEventsPending = NO;
    NSMutableArray *eventIdentities = [NSMutableArray array];
    NSMutableArray *eventParameters = [NSMutableArray array];
    [weakSelf.eventStore enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      if (idx > numberOfEvents - 1) {
        moreEventsPending = YES;
        *stop = YES;
      } else {
        Event *event = (Event*)obj;
        [eventIdentities addObject:event.identity];
        [eventParameters addObject:event.parameters];
      }
      
    }];
    
    completionBlock(eventIdentities, eventParameters, moreEventsPending);
    
  });
  
  
}


- (void)deleteEventsWithIDs:(NSArray*)eventIDs completionBlock:(void (^)(void))completionBlock {
  
  __weak typeof(self)weakSelf = self;
  dispatch_async(self.queue, ^{
    
    __block NSUInteger numberOfEventsToDelete = eventIDs.count;
    NSIndexSet *eventsToDelete = [weakSelf.eventStore indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
      
      Event *event = (Event*)obj;
      if (numberOfEventsToDelete < 1) {
        *stop = YES;
        return NO;
      } else if ([eventIDs containsObject:event.identity]) {
        numberOfEventsToDelete--;
        return YES;
      } else {
        return NO;
      }
      
    }];
    
    [weakSelf.eventStore removeObjectsAtIndexes:eventsToDelete];
    
    completionBlock();
    
  });
  
}


- (void)deleteAllEvents {
  
  __weak typeof(self)weakSelf = self;
  dispatch_async(self.queue, ^{
    weakSelf.eventStore = [NSMutableArray array];
  });
  
}


@end


@implementation Event

+ (instancetype)eventWithParameters:(NSDictionary*)parameters {
  return [[Event alloc] initWithParameters:parameters];
}


- (instancetype)initWithParameters:(NSDictionary*)parameters {
  self = [super init];
  if (self) {
    _identity = [self generateUniqueIdentity];
    _parameters = parameters;
  }
  return self;
}


- (NSString*)generateUniqueIdentity {
  return [NSUUID UUID].UUIDString;
}


@end
