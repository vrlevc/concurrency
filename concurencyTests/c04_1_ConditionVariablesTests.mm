//
//  c04_1_ConditionVariablesTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 12/20/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>
#include <string>
#include <list>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <thread>

struct raw_data_t
{
    std::string data;
    int index;
};
using data_storage_t = std::list<raw_data_t>;
static data_storage_t storage;
static bool more_data_to_prepare();
using data_chunk = std::string;
static data_chunk prepare_data();
static void process(data_chunk& chunk);
static bool is_last_chunk(data_chunk& chunk);

// MARK: -

@interface c04_1_ConditionVariablesTests : XCTestCase
@end

@implementation c04_1_ConditionVariablesTests

- (void)setUp
{
    [super setUp];
    
    // Prepare regular data chuncks for processing ...
    for (int i=0;i<100;i++)
        storage.emplace_front( raw_data_t{"data", i} );
}

- (void)tearDown
{
    XCTAssertTrue(storage.empty());
    [super tearDown];
}

// MARK: -

/// Listing 4.1 Waiting for data to process with a std::condition_variable
- (void)testConditionalVariableWaiting
{
	std::mutex mut;
	std::queue<data_chunk> data_queue;	// 1: pass data between threads
	std::condition_variable data_cond;
	
    auto data_preparation_thread = [&](const std::size_t processors_num)
	{
		while ( more_data_to_prepare() )
		{
			data_chunk const data = prepare_data();
			std::lock_guard<std::mutex> lk(mut); // 2.1: protect queue
			data_queue.push(data);	// 2.2: push data into queue
			data_cond.notify_one(); //   3: notify waiting threads
		}
        // put last blocks
        std::lock_guard<std::mutex> lk(mut);
        for (int i=0;i<processors_num;++i)
            data_queue.push("eof");
        data_cond.notify_all();
	};
	
	auto data_processing_thread = [&]()
	{
		while ( true )
		{
			std::unique_lock<std::mutex> lk(mut);
            data_cond.wait(lk, [&]
            {
            //    NSLog(@"  >>> T:%@ -> check condition", NSThread.currentThread);
                return !data_queue.empty();
            });
			data_chunk data = data_queue.front();
			data_queue.pop();
			lk.unlock();
			process(data);
			if (is_last_chunk(data))
				break;
		}
	};
	
    std::vector<std::thread> data_processors;
    constexpr std::size_t processors_num = 5;
    for (int i=0; i<processors_num; ++i)
        data_processors.emplace_back( data_processing_thread );
    
    std::thread data_preparator( data_preparation_thread, processors_num );
    
    data_preparator.join();
    std::for_each(data_processors.begin(), data_processors.end(), std::mem_fn(&std::thread::join));
}

@end

// MARK:-

static bool more_data_to_prepare()
{
//    NSLog(@"  >>> T:%@ -> more_data_to_prepare", NSThread.currentThread);
    
    return !storage.empty();
}

static data_chunk prepare_data()
{
    NSLog(@"  >>> T:%@ -> prepare > data", NSThread.currentThread);
    
    raw_data_t& data = storage.front();
    
    constexpr std::size_t buff_len = 128;
    char buffer[buff_len] = {0};
    
    std::snprintf(buffer, buff_len, "<< %s : %d >>", data.data.c_str(), data.index);
    
    data_chunk ready_data_chunk(buffer);
    storage.pop_front();
    return ready_data_chunk;
}

static void process(data_chunk& chunk)
{
    NSLog(@"  >>> T:%@ -> process < data", NSThread.currentThread);
}

static bool is_last_chunk(data_chunk& chunk)
{
    bool lastChunk = (chunk == "eof");
    if (lastChunk)
        NSLog(@"  >>> T:%@ -> last chunk : END", NSThread.currentThread);
    return lastChunk;
}
