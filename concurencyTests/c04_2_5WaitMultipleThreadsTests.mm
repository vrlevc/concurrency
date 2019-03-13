//
//  c04_2_5WaitMultipleThreadsTests.m
//  concurencyTests
//
//  Created by lva on 3/13/19.
//  Copyright © 2019 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <future>
#include <chrono>

// MARK: -

@interface c04_2_5WaitMultipleThreadsTests : XCTestCase
@end

@implementation c04_2_5WaitMultipleThreadsTests

// MARK: -

- (void)testLaunchMultipleThreads
{
    std::promise<bool> start;
    std::shared_future<bool> start_race( start.get_future() );
    
    std::promise<bool> log;
    auto log_name = log.get_future().share();
    
    auto runner = [start_race, log_name](const char * name) // took a copy of futures
    {
        // waiting for start notification:
        std::printf("   >>> Runner %s is ready.\n", name);
        
        // waiting for start notification ...
        if (start_race.get())
            std::printf("   >>> Runner %s - STARTED.\n", name);
        
        if (log_name.get())
            std::printf("   >>> Runner %s - logged its name.\n", name);
    };
    
    // prepare and launch blade-runners
    std::thread brElay(runner, "Elay");
    std::thread brGorr(runner, "Gorr");
    std::thread brNeos(runner, "Neos");
    std::thread brOdin(runner, "Odin");
    
    // Start race!
    start.set_value(true);
    
    using namespace std::chrono_literals;
    std::this_thread::sleep_for(5ms);
    
    // Ask to log names
    log.set_value(true);
    
    // wait for runnes done race
    brElay.join();
    brGorr.join();
    brNeos.join();
    brOdin.join();
}

@end

// MARK: -
