//
//  chapter02_4ThreadsNumberTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 11/27/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "parallel_accumulate.hpp"

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
