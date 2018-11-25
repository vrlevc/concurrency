//
//  Created by lva on 11/24/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <iostream>
#include <string>
#include <thread>

/// Thread function with string arg by reference
static void f(int i, std::string const& s);
static void process_copy_data(std::string const& some_data);

// MARK: -

@interface chapter02_2ArgumentsTests : XCTestCase

@end

@implementation chapter02_2ArgumentsTests

// MARK: -

- (void)testCopyArgumentDetach
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

-(void)testCopyArgument
{
    /// thread is going be datached to simulate possible
    /// data dangling
    {
        // prepare local data
        std::string some_data = "some_data";
        // thread ctor copies data
        std::thread t(process_copy_data, some_data);
        // thread processes copy of data so
        // can be safaty detached
        t.detach();
    }
}

@end

// MARK: -

static void f(int i, std::string const& s)
{
    // access to s paramentr which is ref
}

static void process_copy_data(std::string const& some_data)
{
    // data shoul be copied to been safe usage of it
    std::cout << "  >>> process_copy_data wit : \"" << some_data << "\"" << std::endl;
}





















