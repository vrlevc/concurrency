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
	
	friend void swap(X& lhs, X& rhs)
	{
		if (&lhs==&rhs)
			return;
		std::lock(lhs.m, rhs.m);
		std::lock_guard<std::mutex> lock_a(lhs.m, std::adopt_lock);
		std::lock_guard<std::mutex> lock_b(rhs.m, std::adopt_lock);
		swap(lhs.some_detail, rhs.some_detail);
	}
};

// MARK: -

@interface chapter03_2_4DeadlockTests : XCTestCase
@end

@implementation chapter03_2_4DeadlockTests

// MARK: -

- (void)testDeadlock
{
	constexpr int N = 1000;
	
	X a(10);
	X b(20);
	
	std::vector<std::thread> swapers;
	for (int i=0;i<N;++i)
	{
		swapers.emplace_back([lhs=std::ref(a), rhs=std::ref(b)](){
			for (int n=0;n<N;++n)
				swap(lhs.get(), rhs.get());
		});
	}
	
	std::for_each(swapers.begin(), swapers.end(), std::mem_fn(&std::thread::join));
	
	XCTAssertTrue( a.v() + b.v() == 10 + 20 );
}

@end
