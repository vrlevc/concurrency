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

/// Iterator must be at least forward iterators (std::accumulate can work with single-pass input iterators)
/// T must be default constructible to create the results vector
template<typename Iterator, typename T>
T parallel_accumulate(Iterator first, Iterator last, T init)
{
	using u_long = unsigned long;
	using u_long_c = u_long const;
	
	u_long_c length = std::distance(first, last);
	
	/// 1: return init for empty range
	if (!length)
		return init;
	
	/// 2: optimize threads number by using block size for thread
	u_long_c min_per_thread = 25;
	u_long_c max_per_thread = (length+min_per_thread-1)/min_per_thread;
	
	u_long_c hardware_threads = std::thread::hardware_concurrency();
	
	/// 3: do not run more threads then hardware can supprt (oversubscription)
	///    and optimize thread number according to block size
	u_long_c num_threads = std::min(hardware_threads!=0?hardware_threads:2, max_per_thread);
	
	/// 4: the number of entries for each thread to process
	u_long_c block_size = length/num_threads;
	
	/// 5: intermediate results and threads
	std::vector<T> results(num_threads);
	std::vector<std::thread> threads(num_threads-1); // need to launch one fewer thread than num_threads, because we already have one
	
	Iterator block_start = first;
	for (u_long i=0; i<(num_threads-1); ++i)
	{
		Iterator block_end = block_start;
		std::advance(block_end, block_size);	/// 6: end of current block
		threads[i] = std::thread(				/// 7: launch thread to accumulate results
			accumulate_block<Iterator, T>(),
			block_start, block_end, std::ref(results[i]));
		block_start = block_end;	/// 8: The start of the next block is the end of this one
	}
	/// 9: process the final block
	accumulate_block<Iterator, T>()(block_start, last, results[num_threads-1]);
	
	/// 10: wait for all the spawned threads
	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
	
	/// 11: add up the results
	return std::accumulate(results.begin(), results.end(), init);
}

// MARK: -

@interface chapter02_4ThreadsNumberTests : XCTestCase

@end

@implementation chapter02_4ThreadsNumberTests

// MARK: -

- (void)testParallelAccumulate
{
	static const constexpr int N = 1'000'000;
	
	// Prepare data for test:
	std::vector<int> data(N);
	for (int i=0;i<N;++i)
		data[i]=1;
	
	// use parallel accumulator
	XCTAssertEqual(N, parallel_accumulate(data.begin(), data.end(), 0));
}


@end
