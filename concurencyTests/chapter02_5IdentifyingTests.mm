//
//  Created by Viktor Levchenko on 11/27/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <vector>
#include <thread>
#include <iostream>

static void printThreadId()
{
    std::printf("  >>> thread self id : %#x\n", std::this_thread::get_id());
}

// MARK: -

@interface chapter02_5IdentifyingTests : XCTestCase
@end
@implementation chapter02_5IdentifyingTests

// MARK: -

- (void)testThreadId
{
    std::vector<std::thread> pull;
    for (int i=0;i<10;++i)
        pull.emplace_back( printThreadId );
    
    // print thread id
    std::for_each(pull.begin(), pull.end(), [](std::thread& t){
        std::printf("  >>> thread id : %#x\n", t.get_id());
    });
    
    // print hash for thread id
    std::for_each(pull.begin(), pull.end(), [](std::thread& t){
        std::size_t hash = std::hash<std::thread::id>{}(t.get_id());
        std::printf("  >>> thread hash(id) : %lu\n", hash);
    });
    
    std::for_each(pull.begin(), pull.end(), std::mem_fn(&std::thread::join));
}

@end
