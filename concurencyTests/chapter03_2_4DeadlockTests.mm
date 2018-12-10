//
//  chapter03_2_4DeadlockTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 12/5/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <mutex>
#include <thread>
#include <vector>

/// Listing 3.6 Using std::lock() and std::lock_guard in a swap operation

using some_big_object = int;
void swap(some_big_object& lhs, some_big_object& rhs) { std::swap(lhs, rhs); }

class X
{
private:
	some_big_object	some_detail;
	std::mutex m;
public:
	X(const some_big_object& sd) : some_detail(sd) {};
	some_big_object v() { return some_detail; }	// NON Thread safe - for testing only!!!
	
	friend void swap_lock_guard(X& lhs, X& rhs)
	{
		if (&lhs==&rhs)
			return;
		
		/// Lock two mutexes together:
		std::lock(lhs.m, rhs.m);
		std::lock_guard<std::mutex> lock_a(lhs.m, std::adopt_lock); // Just get ownership
		std::lock_guard<std::mutex> lock_b(rhs.m, std::adopt_lock); // Just get ownership
		swap(lhs.some_detail, rhs.some_detail);
	}
	
	friend void swap_unique_lock(X& lhs, X& rhs)
	{
		if (&lhs==&rhs)
			return;
		
		/// If the instance does own the mutex, the destructor must call unlock(),
		/// and if the instance does not own the mutex, it must not call unlock().
		/// This flag can be queried by calling the owns_lock() member function.
		
		/// std::defer_lock leaves mutexes unlocked
		std::unique_lock<std::mutex> lock_a(lhs.m, std::defer_lock);
		std::unique_lock<std::mutex> lock_b(rhs.m, std::defer_lock);
		std::lock(lock_a, lock_b);	// Lock two mutexes together
		swap(lhs.some_detail, rhs.some_detail);
	}
};

// MARK: -

@interface chapter03_2_4DeadlockTests : XCTestCase
@end

@implementation chapter03_2_4DeadlockTests

// MARK: -

- (void)testDeadlock_lock_guard
{
	constexpr int N = 1000;
	
	X a(10);
	X b(20);
	
	std::vector<std::thread> swapers;
	for (int i=0;i<N;++i)
	{
		swapers.emplace_back([lhs=std::ref(a), rhs=std::ref(b)](){
			for (int n=0;n<N;++n)
				swap_lock_guard(lhs.get(), rhs.get());
		});
	}
	
	std::for_each(swapers.begin(), swapers.end(), std::mem_fn(&std::thread::join));
	
	XCTAssertTrue( a.v() + b.v() == 10 + 20 );
}

- (void)testDeadlock_unique_lock
{
	constexpr int N = 1000;
	
	X a(10);
	X b(20);
	
	std::vector<std::thread> swapers;
	for (int i=0;i<N;++i)
	{
		swapers.emplace_back([lhs=std::ref(a), rhs=std::ref(b)](){
			for (int n=0;n<N;++n)
				swap_unique_lock(lhs.get(), rhs.get());
		});
	}
	
	std::for_each(swapers.begin(), swapers.end(), std::mem_fn(&std::thread::join));
	
	XCTAssertTrue( a.v() + b.v() == 10 + 20 );
}

- (void)testTransferingLockOwnership
{
	std::mutex some_mutex;
	
	auto get_lock = [&]()
	{
		std::unique_lock<std::mutex> lk(some_mutex);
		// ... doing thomething for getting data ...
		return lk;
	};
	
	auto process_data = [&]()
	{
		std::unique_lock<std::mutex> lk( get_lock() );
		// ... doing thomething ...
	};
	
	// test:
	process_data();
}

- (void)testGranularityLocking
{
	std::mutex some_mutex;
	
	// Lock mutex and work with protected data
	std::unique_lock<std::mutex> lock(some_mutex);
	// e.g. get next data chunk for porcesing ...
	
	// Unlock mutex for processing data
	lock.unlock();
	// e.g. process current obtained data chunk ...
	
	// Lock mutex back to writing data
	lock.lock();
	// e.g. write processed data chunk back to protected data ...
	
	// RAII - std::unique_lock will unlock mutex on exit ...
}

@end
