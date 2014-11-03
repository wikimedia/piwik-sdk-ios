//
//  PiwikInMemoryEventStore.h
//  PiwikTracker
//
//  Created by Mattias Levin on 29/10/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PiwikEventStore.h"


@interface PiwikInMemoryEventStore : NSObject <PiwikEventStore>

// TODO Property unused
@property (nonatomic) NSUInteger maxNumberOfQueuedEvents;

@end
