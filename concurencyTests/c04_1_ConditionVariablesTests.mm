//
//  c04_1_ConditionVariablesTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 12/20/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>
#include <string>
#include <queue>
#include <mutex>
#include <condition_variable>

// MARK: -

@interface c04_1_ConditionVariablesTests : XCTestCase
@end

@implementation c04_1_ConditionVariablesTests

// MARK: -

/// Listing 4.1 Waiting for data to process with a std::condition_variable
- (void)testConditionalVariableWaiting
{
	using data_chunk = std::string;
	auto more_data_to_prepare = []() { return true; };
	auto prepare_data = []() { return data_chunk("data_chunk"); };
	
	std::mutex mut;
	std::queue<data_chunk> data_queue;	// 1: pass data between threads
	std::condition_variable data_cond;
	
	auto data_preparation_thread = [&]()
	{
		while ( more_data_to_prepare() )
		{
			data_chunk const data = prepare_data();
			std::lock_guard<std::mutex> lk(mut); // 2.1: protect queue
			data_queue.push(data);	// 2.2: push data into queue
			data_cond.notify_one(); //   3: notify waiting threads
		}
	};
	
	auto data_processing_thread = [&]()
	{
		while ( true )
		{
			std::unique_lock<std::mutex> lk(mut);
			data_cond.wait(lk, [&]{ return !data_queue.empty(); });
			data_chunk data = data_queue.front();
			data_queue.pop();
			lk.unlock();
			process(data);
			if (is_last_chunk(data))
				break;
		}
	};
	
}

@end
