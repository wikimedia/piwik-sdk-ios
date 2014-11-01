//
//  CoreDataEventStore.m
//  PiwikTracker
//
//  Created by Mattias Levin on 01/11/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import "CoreDataEventStore.h"


@implementation CoreDataEventStore


- (void)start {
  
}


- (void)saveEventWithParameters:(NSDictionary*)parameters completionBlock:(void (^)(void))completionBlock {
  
}


- (void)readEvents:(NSUInteger)numberOfEvents completionBlock:(void (^)(NSSet *eventIDs, NSArray *events, BOOL hasMore))completionBlock {
  
}


- (void)deleteEventsWithIDs:(NSSet*)eventIDs completionBlock:(void (^)(void))completionBlock {
  
}


- (void)deleteAllEvents {
  
}


@end
