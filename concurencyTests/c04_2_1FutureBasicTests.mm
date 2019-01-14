//
//  c04_2_1FutureBasicTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 1/14/19.
//  Copyright © 2019 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>
#include <future>
#include <iostream>
#include <string>

struct X
{
	void foo(int, std::string const&);
	std::string bar(std::string const&);
};

static X baz(X&);

struct Y
{
	double operator()(double);
};

class move_only
{
public:
	move_only() {}
	move_only(move_only&&) {}
	move_only(move_only const&) = delete;
	move_only& operator=(move_only &&) { return *this; }
	move_only& operator=(move_only const&) = delete;
	
	void operator()() { std::printf( "  ~~~ move_only::operator() ... done\n" ); };
};

// MARK: -

@interface c04_2_1FutureBasicTests : XCTestCase
@end

@implementation c04_2_1FutureBasicTests

// MARK: -

- (void)testFutureFunction
{
	auto find_the_ansver_to_ltuae = [](){
		std::printf("  ~~~ find_the_ansver_to_ltuae ... -> 10\n");
		return 10;
	};
	auto do_other_staff = [](){
		// doing thomethig:
		std::printf("  >>> do_other_staff ... done\n");
	};
	
	std::future<int> the_ansver = std::async(find_the_ansver_to_ltuae);
	do_other_staff();
	std::printf("  >>> THE ANSWER IS : %d\n", the_ansver.get());
}

-(void)testFutureArguments
{
	X x;
	auto f1 = std::async(&X::foo, &x, 42, "hello"); // Calls p->foo(42,"hello") where p is &x
	auto f2 = std::async(&X::bar, x, "goodbye");    // Calls tmpx.bar("goodbye") where tmpx is a copy of x
	
	Y y;
	auto f3 = std::async(Y(), 3.1415); // Calls tmpy(3.1415) where tmpy is move-constrycted from Y()
	auto f4 = std::async(std::ref(y), 2.718); // Calls y(2.718)
	
	std::async(baz, std::ref(x)); // Calls baz(x)
	
	auto f5 = std::async(move_only()); // Calls tmp() where tmp is constructed from std::move(move_only())
	
	std::printf("  >>> F2 - FUTURE get : %s\n", f2.get().c_str());
	std::printf("  >>> F3 - FUTURE get : %f\n", f3.get());
	std::printf("  >>> F4 - FUTURE get : %f\n", f4.get());
	
	/// std::launch::deffered and std::launch::async
	
	auto f6 = std::async(std::launch::async, Y(), 1.2); // Run in new thread
	auto f7 = std::async(std::launch::deferred, baz, std::ref(x)); // Run in wait() or get()
	auto f8 = std::async(std::launch::deferred | std::launch::async, baz, std::ref(x)); // Implementation chooses
	auto f9 = std::async(baz, std::ref(x)); // Implementation chooses
	
	f6.get();
	f7.get();
	f8.get();
	f9.get();
}

@end

// MARK: -

void X::foo(int i, std::string const& s)
{
	std::printf("  ~~~ X::foo(int %d, std::string const& %s) ... done\n", i, s.c_str());
}
std::string X::bar(std::string const& val)
{
	std::printf("  ~~~ X::bar(std::string const& %s) ... done\n", val.c_str());
	return "X::bar(std::string const&) -> result";
}

static X baz(X& x)
{
	std::printf("  ~~~ baz(X& x) ... done\n");
	return x;
};

double Y::operator()(double val)
{
	std::printf("  ~~~ Y::operator()(double %f) ... done\n", val);
	return val + 100.0;
}
