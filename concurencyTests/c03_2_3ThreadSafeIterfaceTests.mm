//
//  chapter03_2_3ThreadSafeIterfaceTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 12/4/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "threadsafe_stack.hpp"

#include <vector>
#include <thread>
#include <chrono>
#include <iostream>

using namespace std::chrono_literals;

// MARK: -

@interface c03_2_3ThreadSafeIterfaceTests : XCTestCase
@end

@implementation c03_2_3ThreadSafeIterfaceTests

// MARK: -

- (void)testThreadSafeStack
{
	static constexpr int N = 100;
	
	using task_t = int;
	
	// Allocate test:
	threadsafe_stack<task_t> some_stack;

	// providers and consumers work together:
	std::vector<std::thread> providers;
	std::vector<std::thread> consumers;

	for (int i=0;i<N;++i)
	{
		providers.emplace_back([data=std::ref(some_stack), start=i*N, n=N]()
		{
			for (task_t task=start;task<start+n;++task) {
				data.get().push(task);
		//		printf("  >>> +++ %d\n", task);
			}
		});
		consumers.emplace_back([data=std::ref(some_stack)]()
		{
			do
			{
				try
				{
					task_t task = -1;
					data.get().pop(task);
			//		printf("  >>> --- %d\n", task);
				}
				catch (empty_stack e)
				{
				//	std::this_thread::sleep_for(1s);
				}
			}
			while (!data.get().empty());
		});
	}

	std::for_each(providers.begin(), providers.end(), std::mem_fn(&std::thread::join));
	std::for_each(consumers.begin(), consumers.end(), std::mem_fn(&std::thread::join));

	while (!some_stack.empty())
	{
		task_t task = -1;
		try { some_stack.pop(task); } catch (empty_stack e) {};
		std::printf("  >>> task left : %d\n", task);
	}
}

@end
