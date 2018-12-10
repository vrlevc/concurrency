//
//  hierarchical_mutex.hpp
//  concurency
//
//  Created by Viktor Levchenko on 12/10/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#ifndef hierarchical_mutex_h
#define hierarchical_mutex_h

#include <mutex>

class thread_hierarchy_value
{
	// extention - mutex hierarchy value
	unsigned long const value;
	
	// itegration with other mutexes - for restoring hierarchy value
	unsigned long previous_value = 0;
	
	// mutex thread state - current locked hierarchy value
	static thread_local unsigned long this_thread_value;
	
public:
	explicit thread_hierarchy_value(unsigned long value);

	void check_for_violation();
	void update();
	void restor();
};

/// Listing 3.8 A simple hierarchical mutex

class hierarchical_mutex
{
	// basic - wrapped std mutex
	std::mutex internal_mutex;
	
	// extention - thread hierarchy value for mutex
	thread_hierarchy_value hierarchy_value;
	
public:
	explicit hierarchical_mutex(unsigned long value);
	
	void lock();
	void unlock();
	bool try_lock();
};

#endif /* hierarchical_mutex_h */
