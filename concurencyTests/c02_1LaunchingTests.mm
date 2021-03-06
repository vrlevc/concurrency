//
//  Created by Viktor Levchenko on 11/23/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "thread_guard.hpp"

#include <iostream>
#include <string>
#include <thread>

/// Thread via function
void do_some_work()
{
	std::cout<<"  >>> do some work from function \n";
}

/// Thread task as callable object
class background_task
{
public:
	void operator()() const
	{
		std::cout<<"  >>> backgroud task";
		do_some_work();
	}
};

/// Thread task as callable object
/// with external data refernece
struct func
{
	int& i;
	func(int& i_):i(i_){}
	void operator()()
	{
		for (unsigned j=0;j<10;++j)
			std::cout<<"  >>> do some work: " << j << "\n";
	}
};

/// Listing 2.4 Detaching a thread to handle other documents
static void open_document_and_disply_gui(std::string const&);
static std::string get_file_name_from_user();
enum class command { open_new_document };
struct user_command { command type; };
static user_command get_user_input();
static bool done_editing();
static void process_user_input(user_command const&);
// thread spawn function - new thred for each document
void edit_document(std::string const& filename)
{
    open_document_and_disply_gui(filename);
    while (!done_editing())
    {
        user_command cmd = get_user_input();
        if (command::open_new_document == cmd.type)
        {
            std::string const new_name = get_file_name_from_user();
            std::thread t(edit_document, new_name);
            t.detach();
        }
        else
        {
            process_user_input(cmd);
        }
    }
}

// MARK: -

@interface c02_1LaunchingTests : XCTestCase

@end

@implementation c02_1LaunchingTests

// MARK: - 2.1.1 Launching a thread

- (void)testThreadFunction
{
	/// Use function to launch thread:
	std::thread function_thread(do_some_work);
	
	// --- DONE --- //
	function_thread.join();
}

- (void)testThreadCallableObjec
{
	/// Regular way of using callable objects:
	background_task f;
	std::thread thread_task(f);
	
	/// Threads without named objects:
	std::thread thread_taskA( ( background_task() ) );
	std::thread thread_taskB{ background_task() };
	
	// --- DONE --- //
	thread_task.join();
	thread_taskA.join();
	thread_taskB.join();
}

- (void)testThreadLambda
{
	/// Thread by lambda
	std::thread thread_lambda([]{
		std::cout<<"  >>> lambda: do some work from function \n";
	});
	
	// --- DONE --- //
	thread_lambda.join();
}

/// MARK: - 2.1.2 Waiting for a thread to complete
/// MARK:   2.1.3 Waiting in exceptional circumstances

// Listing 2.2 : Waiting for a thread to finish
- (void)testWaitingThread
{
    static bool rizeException = true;
    
    try
    {
        int local_state = 0;
        func task(local_state);
        std::thread executor(task);
        try
        {
            // do thomethig - can throw exception ...
            if (rizeException)
                throw 0;
        }
        catch(...)
        {
            executor.join();
            throw;
        }
        executor.join();
    }
    catch (...)
    {
        
    }
}

// Listing 2.3 : Using RAII to wait for a thread to complete
- (void)testWaitingThreadRAII
{
    try
    {
        int local_state = 0;
        func task(local_state);
        std::thread executor(task);
        thread_guard saferuard(executor);
        
        // do thomethig - can throw exception ...
        throw 0;
    }
    catch (...)
    {
		std::cout << "  >>> cought exception ...\n";
    }
}

@end

// MARK: -

// fix warnings:
static void open_document_and_disply_gui(std::string const&) {}
static std::string get_file_name_from_user() { return ""; }
static user_command get_user_input() { return user_command(); }
static bool done_editing() { return false; }
static void process_user_input(user_command const&) {}

