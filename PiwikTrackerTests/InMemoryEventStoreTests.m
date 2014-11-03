//
//  InMemoryEventStoreTests.m
//  PiwikTracker
//
//  Created by Mattias Levin on 29/10/14.
//  Copyright (c) 2014 Mattias Levin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "PiwikInMemoryEventStore.h"


@interface InMemoryEventStoreTests : XCTestCase

@property (nonatomic, strong) PiwikInMemoryEventStore *eventStore;
@property (nonatomic, strong) NSDictionary *parameters;

@end


@implementation InMemoryEventStoreTests


- (void)setUp {
  [super setUp];
  
  self.eventStore = [[PiwikInMemoryEventStore alloc] init];
  
  self.parameters = @{@"key" : @"value"};
  
}


- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}


- (void)testSingleEvent {
  
  __weak typeof(self)weakSelf = self;
  [self.eventStore saveEventWithParameters:self.parameters completionBlock:^{
    
    [weakSelf.eventStore readEvents:10 completionBlock:^(NSSet *eventIDs, NSArray *events, BOOL hasMore) {
      
      XCTAssertTrue(eventIDs.count == 1);
      XCTAssertTrue(events.count == 1);
      XCTAssertFalse(hasMore);
      XCTAssertTrue([events[0][@"key"] isEqualToString:@"value"]);
      
    }];
    
  }];

}


- (void)testBulkEvents {
  
  for (int i = 0; i < 22; i++) {
    [self.eventStore saveEventWithParameters:self.parameters completionBlock:^{
      // Do nothing
    }];
  }
  
  __weak typeof(self)weakSelf = self;
  [self.eventStore saveEventWithParameters:self.parameters completionBlock:^{
    
    [weakSelf.eventStore readEvents:10 completionBlock:^(NSSet *eventIDs, NSArray *events, BOOL hasMore) {
      
      XCTAssertTrue(eventIDs.count == 10);
      XCTAssertTrue(events.count == 10);
      XCTAssertTrue(hasMore);
      
    }];
    
  }];
  
}


- (void)testDeleteSingleEvent {
  
  __weak typeof(self)weakSelf = self;
  [self.eventStore saveEventWithParameters:self.parameters completionBlock:^{
    
    [weakSelf.eventStore readEvents:10 completionBlock:^(NSSet *eventIDs, NSArray *events, BOOL hasMore) {
      
      XCTAssertTrue(events.count == 1);
      XCTAssertTrue(eventIDs.count == 1);
      
      NSString *eventID = [NSString stringWithString:eventIDs.anyObject];
      [weakSelf.eventStore deleteEventsWithIDs:[NSSet setWithObject:eventID] completionBlock:^{
        
        [weakSelf.eventStore readEvents:10 completionBlock:^(NSSet *eventIDs, NSArray *events, BOOL hasMore) {
          
          XCTAssertTrue(eventIDs.count == 0);
          XCTAssertTrue(events.count == 0);
          XCTAssertFalse(hasMore);
          
        }];
        
      }];
      
    }];
    
  }];
  
}


- (void)testDeleteMultipleEvents {
  
  
  for (int i = 0; i < 9; i++) {
    [self.eventStore saveEventWithParameters:self.parameters completionBlock:^{
      // Do nothing
    }];
  }
  
  __weak typeof(self)weakSelf = self;
  [self.eventStore saveEventWithParameters:self.parameters completionBlock:^{
    
    [weakSelf.eventStore readEvents:5 completionBlock:^(NSSet *eventIDs, NSArray *events, BOOL hasMore) {
      
      XCTAssertTrue(events.count == 5);
      

      [weakSelf.eventStore deleteEventsWithIDs:eventIDs completionBlock:^{
        
        [weakSelf.eventStore readEvents:10 completionBlock:^(NSSet *eventIDs, NSArray *events, BOOL hasMore) {
          
          XCTAssertTrue(eventIDs.count == 5);
          XCTAssertTrue(events.count == 5);
          XCTAssertFalse(hasMore);
          
        }];
        
      }];
      
    }];
    
  }];

}


- (void)deleteAllTest {
  
  for (int i = 0; i < 10; i++) {
    [self.eventStore saveEventWithParameters:self.parameters completionBlock:^{
      // Do nothing
    }];
  }
  
  [self.eventStore deleteAllEvents];
  
  __weak typeof(self)weakSelf = self;
  [self.eventStore saveEventWithParameters:self.parameters completionBlock:^{
    
    [weakSelf.eventStore readEvents:20 completionBlock:^(NSSet *eventIDs, NSArray *events, BOOL hasMore) {
      
      XCTAssertTrue(events.count == 1);
      XCTAssertFalse(hasMore);
      
    }];
    
  }];

}



@end
