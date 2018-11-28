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

/// Thread task as callable object
/// with external data refernece
struct func
{
    int& i;
    func(int& i_):i(i_){}
    void operator()()
    {
        for (unsigned j=0;j<10;++j)
            std::cout<<"  >>> func : do task #" << j << "\n";
    }
};

static void do_work(unsigned id)
{
    std::cout << "  >>> thread #" << id << " done work" << std::endl;
}

// MARK: -

@interface chapter02_3OwnershipTests : XCTestCase

@end

@implementation chapter02_3OwnershipTests

// MARK: -

- (void)testScopedThread
{
    int some_local_state = 0;
    scoped_thread t( std::thread{ func( some_local_state ) } );
    // do thomethig in current thread ...
}

-(void)testVectorThread
{
    /// Listing 2.7 Spawn some threads and wait for them to finish
    
    std::vector<std::thread> threads;
    for (int i=0;i<10;++i)
        threads.push_back(std::thread(do_work, i));
    
    std::for_each(threads.begin(), threads.end(),
                  std::mem_fn(&std::thread::join));
}

@end
