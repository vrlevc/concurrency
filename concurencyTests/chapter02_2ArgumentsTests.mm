//
//  Created by lva on 11/24/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <string>
#include <thread>

/// Thread function with string arg by reference
static void f(int i, std::string const& s);

// MARK: -

@interface chapter02_2ArgumentsTests : XCTestCase

@end

@implementation chapter02_2ArgumentsTests

// MARK: -

- (void)testRefArgument
{
    int some_param = 256;
    
    char buffer[256]{0};
    sprintf(buffer, "%i", some_param);

    /// thread make a copy of arguments
    /// thus buffer is a copy of pointer
    /// to the local buffer
//  std::thread t(f, 3, buffer);
    
    /// Using std::string avoids dangling pointer
    std::thread t(f, 3, std::string(buffer));
    
    // t has a copy of buffer in std::string
    t.detach();
}

@end

// MARK: -

static void f(int i, std::string const& s)
{
    // access to s paramentr which is ref
}
