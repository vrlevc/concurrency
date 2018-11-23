//
//  Created by Viktor Levchenko on 11/23/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <iostream>
#include <thread>

/// Global work done functor
class Work
{
	static bool done;
public:
	Work()  { done = false; }
	~Work() { done = true ; }
	static bool isDone() { return done; }
};
bool Work::done = false;

/// Thread via function
void do_some_work()
{
	Work work;
	std::cout<<"  >>> do some work from function \n";
}

/// Thread via callable object
class background_task
{
public:
	void operator()() const
	{
		Work work;
		std::cout<<"  >>> backgroud task";
		do_some_work();
	}
};

// MARK: -

@interface chapter02_LaunchingTests : XCTestCase

@end

@implementation chapter02_LaunchingTests

// MARK: -

- (void)testThreadFunction
{
	Work work;
	XCTAssertFalse(work.isDone());
	
	/// Use function to launch thread:
	std::thread function_thread(do_some_work);
	
	function_thread.join();
	
	XCTAssertTrue(work.isDone());
}

- (void)testThreadCallableObjec
{
	Work work;
	XCTAssertFalse(work.isDone());
	
	/// Regular way of using callable objects:
	background_task f;
	std::thread thread_task(f);
	
	/// Threads without named objects:
	std::thread thread_taskA( ( background_task() ) );
	std::thread thread_taskB{ background_task() };
	
	// waiting other threads
	thread_task.join();
	thread_taskA.join();
	thread_taskB.join();
	
	XCTAssertTrue(work.isDone());
}

@end
