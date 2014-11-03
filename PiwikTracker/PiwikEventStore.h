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


/**
 Save a single event to the event store,
 
 @param parameters Event parameters.
 @param completionBlock Called after the event has been successfully saved.
 */
- (void)saveEventWithParameters:(NSDictionary*)parameters completionBlock:(void (^)(void))completionBlock;


/**
 Read a specified number of events from the event store.
 
 @param numberOfEvents Number of events to read.
 @param completionBlock return the events and associated ids. hasMore indicates if there are additional events in the event store.
 */
- (void)readEvents:(NSUInteger)numberOfEvents completionBlock:(void (^)(NSSet *eventIDs, NSArray *events, BOOL hasMore))completionBlock;


/**
 Delete events from the event store.
 
 @param eventIDs Ids of the events to delete.
 @param completionBlock Called after the events has been successfully deleted.
 */
- (void)deleteEventsWithIDs:(NSSet*)eventIDs completionBlock:(void (^)(void))completionBlock;


/**
 Delete all events in the event store.
 */
- (void)deleteAllEvents;


@end