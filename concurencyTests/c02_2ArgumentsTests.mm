//
//  Created by lva on 11/24/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <iostream>
#include <string>
#include <thread>

/// Thread function with string arg by copy, reference, move
static void f(int i, std::string const& s);
static void process_copy_data(std::string const& some_data);
static void process_ref_data(std::string& some_data);

class big_object {};
static void process_big_object(std::unique_ptr<big_object>);

// MARK: -

@interface c02_2ArgumentsTests : XCTestCase

@end

@implementation c02_2ArgumentsTests

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

-(void)testMoveArgument
{
    /// use std::unique_ptr for transfer object ownership
    std::unique_ptr<big_object> p(new big_object());
    std::thread t1(process_big_object, std::move(p));
    std::thread t2(process_big_object, std::make_unique<big_object>());
    
    // get threads done
    t1.join();
    t2.join();
}

-(void)testClassMember
{
    /// use oblect's function in thread
    
    // class for use in spawned threads
    class X
    {
	private:
		int id;
    public:
		explicit X(int id_) : id(id_) {}
        void do_lengthy_work()
        {
			std::printf("  >>> X:%d - do_lengthy_work\n", id);
        }
        void do_lengthy_work(std::string& some_data)
        {
            std::printf("  >>> X:%d - do_lengthy_work with data ref  : %s\n", id, some_data.c_str());
        }
        void do_lengthy_work(std::string const& some_data)
        {
            std::printf("  >>> X:%d - do_lengthy_work with data copy : %s\n", id, some_data.c_str());
        }
    };
	
    // data for thread's functions
    std::string some_data{"some_data"};
    X processor1(1);
	X processor2(2);
	X processor3(3);
    
    // spawn threads with functions of processor
	std::thread t1(static_cast<void(X::*)(void)>(&X::do_lengthy_work), &processor1);
    std::thread t2(static_cast<void(X::*)(std::string&)>(&X::do_lengthy_work), &processor2, std::ref(some_data));
    std::thread t3(static_cast<void(X::*)(std::string const&)>(&X::do_lengthy_work), &processor3, some_data);
    
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
    std::printf("  >>> process_copy_data wit : \"%s\"\n", some_data.c_str());
}

static void process_ref_data(std::string& some_data)
{
    std::printf("  >>> thread : presess data ...\n");
    some_data.append(" <- processed");
}

static void process_big_object(std::unique_ptr<big_object> big_object)
{
    
}



















