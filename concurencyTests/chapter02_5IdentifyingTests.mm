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
    std::cout << "  >>> thread id : " << std::this_thread::get_id() << std::endl;
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
        pull.push_back( std::thread( printThreadId ) );
    
    std::for_each(pull.begin(), pull.end(), [](std::thread& t){
       std::cout << "  >>> thread id : " << t.get_id() << std::endl;
    });
    std::for_each(pull.begin(), pull.end(), std::mem_fn(&std::thread::join));
}

@end
