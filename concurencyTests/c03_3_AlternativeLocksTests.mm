//
//  c03_3_AlternativeLocksTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 12/14/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <memory>
#include <thread>
#include <vector>

struct some_resource_t
{
	void do_something() {}
};

// MARK: -

@interface c03_3_AlternativeLocksTests : XCTestCase
@end

@implementation c03_3_AlternativeLocksTests

// MARK: -


/// Listing 3.11 Thread-safe lazy initialization using a mutex
// Note: This solution causes unnecessary serialization of threads using the resource.
- (void)testLazyInitialization
{
	std::shared_ptr<some_resource_t> resource_ptr;
	std::mutex resource_mutex;
	auto foo = [&]()
	{
		/// All threads are serialized here:
		std::unique_lock<std::mutex> lk(resource_mutex);
		if (!resource_ptr)
		{
			/// Only the initialization need protection:
			resource_ptr.reset(new some_resource_t);
		}
		lk.unlock();
		resource_ptr->do_something();
	};
	
	std::vector<std::thread> threads;
	for (int i=0;i<10;++i)
		threads.emplace_back(foo);
	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
}


@end
