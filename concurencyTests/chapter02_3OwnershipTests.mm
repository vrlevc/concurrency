//
//  concurencyTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 11/22/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "scoped_thread.hpp"

#include <thread>
#include <vector>
#include <iostream>
#include <chrono>

using namespace std::chrono_literals;

/// Thread task as callable object
/// with external data refernece
struct func
{
    int& i;
    func(int& i_):i(i_){}
    void operator()()
    {
        for (unsigned j=0;j<10;++j)
			std::printf("  >>> func : do task #%d\n", i++);
    }
};

static void do_work(unsigned id)
{
    std::printf("  >>> thread #%d done work\n", id);
}

// MARK: -

@interface chapter02_3OwnershipTests : XCTestCase

@end

@implementation chapter02_3OwnershipTests

// MARK: -

- (void)testScopedThread
{
    int some_local_state_A = 10;
	scoped_thread t( std::thread{ func{ some_local_state_A } } );
	
	int some_local_state_B = 100;
	scoped_thread tt( func{ some_local_state_B } );
	
	// do thomethig in current thread ...
	std::this_thread::sleep_for(1s);
	
	XCTAssertTrue(some_local_state_A > 10);
	XCTAssertTrue(some_local_state_B > 100);
}

-(void)testVectorThread
{
    /// Listing 2.7 Spawn some threads and wait for them to finish
    
    std::vector<std::thread> threads;
    for (int i=0;i<10;++i)
        threads.emplace_back(do_work, i);
    
    std::for_each(threads.begin(), threads.end(),
                  std::mem_fn(&std::thread::join));
}

@end
