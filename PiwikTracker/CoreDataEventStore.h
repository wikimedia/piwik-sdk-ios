//
//  CoreDataEventStore.h
//  PiwikTracker
//
//  Created by Mattias Levin on 01/11/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PiwikEventStore.h"

@interface CoreDataEventStore : NSObject <PiwikEventStore>

@property (nonatomic) NSUInteger maxNumberOfQueuedEvents;

@end
