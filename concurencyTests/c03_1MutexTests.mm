//
//  chapter03_1MutexTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 12/4/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <list>
#include <vector>
#include <mutex>
#include <thread>
#include <algorithm>
#include <iostream>

/// MUTEX - mutually exclusive

// global sapace
std::list<int> some_list;	// single global variable
std::mutex	some_mutex;		// varibale mutex

// thread safe functions:
void add_to_list(int newValue)
{
	std::lock_guard<std::mutex> guard(some_mutex);
	some_list.push_back(newValue);
	std::printf("  >>> added : %d\n", newValue);
}
bool list_contains(int value_to_find)
{
	std::lock_guard<std::mutex> guard(some_mutex);
	return std::find(some_list.begin(), some_list.end(), value_to_find) != some_list.end();
}

// MARK: -

@interface c03_1MutexTests : XCTestCase
@end

@implementation c03_1MutexTests

// MARK: -

/// Listing 3.1 Protecting list with mutex
- (void)testProtectedList
{
	static bool test_pass = true;
	
	static const constexpr int volume_number = 10;
	static const constexpr int fillers_number = 10;
	
	// working threads:
	std::vector<std::thread> threads;
	
	// fill list with data
	for(int i=0; i<fillers_number; ++i)
		threads.emplace_back( [index=i,volume=volume_number]() {
			for (int i=0;i<volume;++i)
				add_to_list(index*volume + i);
		} );
	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
	
	threads.clear();
	
	// check list for data
	for (int i=0; i<fillers_number; ++i)
		threads.emplace_back( [index=i,volume=volume_number]() {
			for (int i=0;i<volume;++i)
				if( !list_contains(index*volume + i) ) {
					printf("  >>> TEST FAILED : no %d such value in list", index*volume + i);
					test_pass = false;
				}
		} );
	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
	
	XCTAssertTrue(test_pass);
}

@end
