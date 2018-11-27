//
//  chapter02_4ThreadsNumberTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 11/27/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <thread>
#include <vector>
#include <numeric>

/// Listing 2.8 A naive parallel version of std::accumulate

template<typename Iterator, typename T>
struct accumulate_block
{
	void operator()(Iterator first, Iterator last, T& result)
	{
		result = std::accumulate(first, last, result);
	}
};

template<typename Iterator, typename T>
T parallel_accumulate(Iterator first, Iterator last, T init)
{
	using u_long = unsigned long;
	using u_long_c = u_long const;
	
	u_long_c length = std::distance(first, last);
	
	if (!length)
		return init;
	
	u_long_c min_per_thread = 25;
	u_long_c max_per_thread = (length+min_per_thread-1)/min_per_thread;
	
	u_long_c hardware_threads = std::thread::hardware_concurrency();
	
	u_long_c num_threads = std::min(hardware_threads!=0?hardware_threads:2, max_per_thread);
	
	u_long_c block_size = length/num_threads;
	
	std::vector<T> results(num_threads);
	std::vector<std::thread> threads(num_threads-1);
	
	Iterator block_start = first;
	for (u_long i=0; i<(num_threads-1); ++i)
	{
		Iterator block_end = block_start;
		std::advance(block_end, block_size);
		threads[i] = std::thread(
			accumulate_block<Iterator, T>(),
			block_start, block_end, std::ref(results[i]));
		block_start = block_end;
	}
	accumulate_block<Iterator, T>()(block_start, last, results[num_threads-1]);
	
	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
	
	return std::accumulate(results.begin(), results.end(), init);
}

// MARK: -

@interface chapter02_4ThreadsNumberTests : XCTestCase

@end

@implementation chapter02_4ThreadsNumberTests

// MARK: -

- (void)testExample
{
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}


@end
