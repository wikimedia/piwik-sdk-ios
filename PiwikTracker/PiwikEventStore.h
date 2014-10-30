//
//  PiwikEventStore.h
//  PiwikTracker
//
//  Created by Mattias Levin on 29/10/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//


/**
 The event store is responsible for storing the event until the dispatcher send it to the Piwik server.

 Two implementations are provided by default, a CoreData based and in-memory based implementation.
 
 Developers can provide their own implementation to go with any existing frameworks used in their apps.
 */
@protocol PiwikEventStore <NSObject>


- (void)start;


- (void)saveEventWithParameters:(NSDictionary*)parameters completionBlock:(void (^)(void))completionBlock;


// TODO Change to NSSet?
- (void)readEvents:(NSUInteger)numberOfEvents completionBlock:(void (^)(NSArray *entityIDs, NSArray *events, BOOL hasMore))completionBlock;

// TODO Change to NSSet?
- (void)deleteEventsWithIDs:(NSArray*)entityIDs completionBlock:(void (^)(void))completionBlock;

// TODO completionblock?
- (void)deleteAllEvents;


@end