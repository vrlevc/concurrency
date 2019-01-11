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

#endif /* threadsafe_queue_h */
