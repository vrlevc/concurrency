//
//  c04_2_2PackagedTaskTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 1/15/19.
//  Copyright © 2019 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>
#include <iostream>
#include <future>
#include <mutex>
#include <deque>
#include <thread>

static std::mutex m;
static std::deque<std::packaged_task<void()>> tasks;

template<typename Func>
std::future<void> post_task_for_thread(Func f)
{
	/// 7. Created a new packaged task from the supplied function
	std::packaged_task<void()> task(f);
	/// 8. Obtain future from task
	std::future<void> res = task.get_future();
	/// 9. Put the task into the list
	std::lock_guard<std::mutex> lk(m);
	tasks.push_back(std::move(task));
	/// 10. Return future after put task into list
	return res;
}

// MARK: -

@interface c04_2_2PackagedTaskTests : XCTestCase
@end

@implementation c04_2_2PackagedTaskTests

// MARK: -

- (void)testPackagedTask
{
	int ui_events_number = 100;
	auto gui_shutdown_message_received = [&ui_events_number](){
		return --ui_events_number == 0;
	};
	auto get_and_process_gui_message = [&ui_events_number](){
		std::printf("  ~~~ GUI:BG get_and_process_gui_message %d ... done\n", ui_events_number);
	};
	
	/// 1. GUI thread loop
	auto gui_thread = [&gui_shutdown_message_received,
					   &get_and_process_gui_message]()
	{
		/// 2. Loops shutdown message has been received
		while ( !gui_shutdown_message_received() )
		{
			/// 3. Repeatedly polling for GUI messages to handle
			get_and_process_gui_message();
			std::packaged_task<void()> task;
			{
				std::lock_guard<std::mutex> lk(m);
				/// 4. If there are no tasks on the queue - loops again
				if (tasks.empty())
					continue;
				/// 5. Extracts the task from the queue
				task = std::move(tasks.front());
				tasks.pop_front();
			}
			/// 6. - Releases the lock on the queue,
			///    - Runs the task
			task();
		}
	};
	
	// Background thread for posting tasks
	auto task_thread = [&ui_events_number]()
	{
		auto task = []()
		{
			std::printf("  ~~~ TASK:BG processed_task ... done\n");
		};
		
		while ( 0 < ui_events_number )
		{
			if (ui_events_number < 50) {
				for ( int i=0; i<10; ++i)
					post_task_for_thread(task);
				break;
			}
		}
	};
	
	// Background threads
	std::thread task_bg_thread(task_thread);
	std::thread gui_bg_thread(gui_thread);
	
	// Corret finish test:
	gui_bg_thread.join();
	task_bg_thread.join();
}

@end
