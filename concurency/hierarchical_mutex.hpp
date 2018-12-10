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

/// Listing 3.8 A simple hierarchical mutex

class hierarchical_mutex
{
	// basic - wrapped std mutex
	std::mutex internal_mutex;
	// extention - mutex hierarchy value
	unsigned long const hierarchical_value;
	
	// itegration with other mutexes - for restoring hierarchy value
	unsigned long previous_hierarchical_value = 0;
	// mutex thread state - current locked hierarchy value
	static thread_local unsigned long this_thread_hierarchy_value;
	
	void check_for_heirarchy_violation()
	{
		if (this_thread_hierarchy_value <= hierarchical_value)
			throw std::logic_error("mutex hierarchy violated");
	}
	void update_hierarchy_value()
	{
		previous_hierarchical_value = this_thread_hierarchy_value;
		this_thread_hierarchy_value = hierarchical_value;
	}
	
public:
	explicit hierarchical_mutex(unsigned long value)
	: hierarchical_value(value)
	{}
	void lock()
	{
		check_for_heirarchy_violation();
		internal_mutex.lock();
		update_hierarchy_value();
	}
	void unlock()
	{
		this_thread_hierarchy_value = previous_hierarchical_value;
		internal_mutex.unlock();
	}
	bool try_lock()
	{
		check_for_heirarchy_violation();
		if (!internal_mutex.try_lock())
			return false;
		update_hierarchy_value();
		return true;
	}
};
thread_local unsigned long hierarchical_mutex::this_thread_hierarchy_value(ULONG_MAX);

#endif /* hierarchical_mutex_h */
