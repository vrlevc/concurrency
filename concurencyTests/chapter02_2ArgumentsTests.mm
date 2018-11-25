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
static void process_ref_data(std::string& some_data);
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
    /// - thread is going be datached to
    /// - simulate possible data dangling
    /// - use arguments copy threads's ability
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

-(void)testRefArgument
{
    /// use ste::ref to wrap data for thread
    
    // data for use in thread function
    std::string some_data = "some_data";
    std::cout << "  >>> data before processing : " << some_data << std::endl;
    // spawn thread with data for processing
    std::thread t(process_ref_data, std::ref(some_data));
    // ... doing something usefull ...
    // get processed data
    t.join();
    std::cout << "  >>> data after processing  : " << some_data << std::endl;
}

-(void)testClassMember
{
    /// use oblect's function in thread
    
    // class for use in spawned threads
    class X
    {
    public:
        void do_lengthy_work()
        {
            std::cout << "  >>> do_lengthy_work" << std::endl;
        }
        void do_lengthy_work_ref(std::string& some_data)
        {
            std::cout << "  >>> do_lengthy_work with data ref  : " << some_data << std::endl;
        }
        void do_lengthy_work_copy(std::string const& some_data)
        {
            std::cout << "  >>> do_lengthy_work with data copy : " << some_data << std::endl;
        }
    };
    
    // data for thread's functions
    std::string some_data{"some_data"};
    X processor;
    
    // spawn threads with functions of processor
    std::thread t1(&X::do_lengthy_work, &processor);
    std::thread t2(&X::do_lengthy_work_ref, &processor, std::ref(some_data));
    std::thread t3(&X::do_lengthy_work_copy, &processor, some_data);
    
    // gether all process
    t1.join();
    t2.join();
    t3.join();
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

static void process_ref_data(std::string& some_data)
{
    std::cout << "  >>> thread : presess data ..." << std::endl;
    some_data.append(" <- processed");
}




















