//
//  Created by Viktor Levchenko on 11/23/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <iostream>
#include <thread>		/// 1: c++ threads

void hello() /// 2: thread has to have an initial function
{
	std::cout << "  >>> Hello Concurent World\n";
}

// MARK: -

@interface chapter01_HelloTests : XCTestCase

@end

@implementation chapter01_HelloTests

// MARK: -

- (void)testSingleThreadMain
{
	std::cout << "  >>> Hello World\n";
}

- (void)testMultiThreadedMain
{
	std::thread t(hello); /// 3: Thread has the new function hello() as its initial function
	t.join();	/// 4: wait for the thread t
}

@end
