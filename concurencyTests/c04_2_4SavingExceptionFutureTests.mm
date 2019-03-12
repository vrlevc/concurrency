//
//  c04_2_4SavingExceptionFutureTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 3/12/19.
//  Copyright © 2019 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <future>

static double square_root(double x)
{
	if (x<0)
	{
		// thrown exception will be packet into futere and availabe from get() function
		throw std::out_of_range("x<0");
	}
	return sqrt(x);
};

// MARK: -

@interface c04_2_4SavingExceptionFutureTests : XCTestCase

@end

@implementation c04_2_4SavingExceptionFutureTests

// MARK: -

- (void)test_exception_async
{
	bool thrown_and_catched = false;
	const double x = -1;
	XCTAssertTrue(x < 0.0);
	
	std::future<double> f = std::async(square_root, x);
	
	// catch exception thrown in other thread if any (YES in our case):
	std::exception_ptr exp; // is going to be NOT nullptr
	try
	{
		double y = f.get(); // rethrows exception from other thread
		std::printf("   >>> No exception , result is %f\n", y);
	}
	catch(...)
	{
		exp = std::current_exception();
	}
	// notify about exception if any
	if (exp)
	{
		try
		{
			std::rethrow_exception(exp);
		}
		catch(const std::exception& e)
		{
			thrown_and_catched = true;
			std::printf("   >>> Exception from other thread is : %s\n", e.what());
		}
	}
	
	XCTAssertTrue(thrown_and_catched);
}

-(void)test_exception_task
{
	bool thrown_and_catched = false;
	const double x = -1;
	XCTAssertTrue(x < 0.0);
	
	std::packaged_task<double(double)> sqrt_task(square_root);
	std::future<double> sqrt_res = sqrt_task.get_future();
	std::thread task_processor(std::move(sqrt_task), x);  // throws exception and packs it into future
	task_processor.join();
	
	std::exception_ptr exp;
	try
	{
		double y = sqrt_res.get(); // rethrows exception from other thread
		std::printf("   >>> No exception , result is %f\n", y);
	}
	catch(const std::exception& e)
	{
		thrown_and_catched = true;
		std::printf("   >>> Exception from other thread is : %s\n", e.what());
	}
	
	XCTAssertTrue(thrown_and_catched);
}

-(void)test_exeption_promise
{
	bool thrown_and_catched = false;
	const double x = -1;
	XCTAssertTrue(x < 0.0);
	
	std::promise<double> sqrt_promice;
	std::future<double> sqrt_res = sqrt_promice.get_future();
	
	auto fn_set_promice_explicit = [&sqrt_promice](double x)
	{
		try
		{
			sqrt_promice.set_value( square_root(x) ); // throws for -1
		}
		catch(...)
		{
			sqrt_promice.set_exception( std::current_exception() );
		}
	};
	std::thread processor( fn_set_promice_explicit, x );
	processor.join();
	
	std::exception_ptr exp;
	try
	{
		double y = sqrt_res.get(); // rethrows exception from other thread
		std::printf("   >>> No exception , result is %f\n", y);
	}
	catch(const std::exception& e)
	{
		thrown_and_catched = true;
		std::printf("   >>> Exception from other thread is : %s\n", e.what());
	}
	
	XCTAssertTrue(thrown_and_catched);
}

// MARK: -

@end
