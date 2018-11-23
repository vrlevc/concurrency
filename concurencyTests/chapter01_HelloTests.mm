//
//  chapter01_HelloTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 11/23/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <iostream>
#include <thread>

void hello()
{
	std::cout << "Hello Concurent World\n";
}

// MARK: -

@interface chapter01_HelloTests : XCTestCase

@end

@implementation chapter01_HelloTests

// MARK: -

- (void)testSingleThreadMain
{
	std::cout << "Hello World\n";
}

- (void)testMultiThreadedMain
{
	std::thread t(hello);
	t.join();
}

@end
