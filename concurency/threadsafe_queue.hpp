//
//  threadsafe_queue.h
//  concurency
//
//  Created by lva on 12/24/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#ifndef threadsafe_queue_h
#define threadsafe_queue_h

#include <mutex>
#include <queue>
#include <condition_variable>
#include <memory>

// Consider std::queue interafce for our thread safe queue
// There are three groups of operations:
//   1: those that query the state of the whole queue (empty() and size()),
//   2: those that query the elements of the queue (front() and back()),
//   3: those that modify the queue (push(), pop() and emplace())
//
// 1. We need to combine front() and pop() into a single function call.
// 2. Provide two variants on pop():
//    -  try_pop(), which tries to pop the value from the queue but always returns immediately
//                  (with an indication of failure) even if there wasn’t a value to retrieve
//    - wait_and_pop(), which will wait until there’s a value to retrieve.
//
// Interface:
/**
template<typename T> class threadsafe_queue
{
public:
	threadsafe_queue();
	threadsafe_queue(const threadsafe_queue&);
	threadsafe_queue& operator=(const threadsafe_queue&)=delete; // Dissallow assignment fot simplicity
	
	void push(T new_value);
 
 	// Stores the retrieved value in the referenced variable,
 	// so it can use the return value for status.
 	// Returns true if it retrieved a value and false otherwise.
 	bool try_pop(T& value);
 
 	// Returns the retrieved value directly.
 	// Returned pointer can be set to NULL if there’s no value to retrieve.
 	std::shared_ptr<T> try_pop();
 
 	void wait_and_pop(T& value);
 	std::shared_ptr<T> wait_and_pop();
 
 	bool empty() const;
};
**/

template<typename T>
class threadsafe_queue
{
private:
	mutable std::mutex mut;		/// The mutex must be mutable
	std::queue<T> data_queue;
	std::condition_variable data_cond;
public:
	threadsafe_queue()
	{}
	threadsafe_queue(threadsafe_queue const& other)
	{
		std::lock_guard<std::mutex> lk(other.mut);
		data_queue = other.data_queue;
	}
	void push(T new_value)
	{
		std::lock_guard<std::mutex> lk(mut); // 2.1: protect queue
		data_queue.push(new_value);	// 2.2: push data into queue
		data_cond.notify_one(); //   3: notify waiting threads
	}
	void wait_and_pop(T& value)
	{
		std::unique_lock<std::mutex> lk(mut);
		data_cond.wait(lk, [this]{ return !data_queue.empty(); });
		value=data_queue.front();
		data_queue.pop();
	}
	std::shared_ptr<T> wait_and_pop()
	{
		std::unique_lock<std::mutex> lk(mut);
		data_cond.wait(lk, [this]{ return !data_queue.empty(); });
		std::shared_ptr<T> res( std::make_shared<T>(data_queue.front()) );
		data_queue.pop();
		return res;
	}
	bool try_pop(T& value)
	{
		std::lock_guard<std::mutex> lk(mut);
		if (data_queue.empty())
			return false;
		value=data_queue.front();
		data_queue.pop();
		return true;
	}
	std::shared_ptr<T> try_pop()
	{
		std::lock_guard<std::mutex> lk(mut);
		if (data_queue.empty())
			return std::shared_ptr<T>();
		std::shared_ptr<T> res( std::make_shared<T>(data_queue.front()) );
		data_queue.pop();
		return res;
	}
	bool empty() const
	{
		std::lock_guard<std::mutex> lk(mut);
		return data_queue.empty();
	}
};

#endif /* threadsafe_queue_h */
