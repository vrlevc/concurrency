//
//  hierarchical_mutex.cpp
//  concurency
//
//  Created by Viktor Levchenko on 12/10/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#include "hierarchical_mutex.hpp"

// MARK: -
// MARK: thread_hierarchy_value

thread_hierarchy_value::thread_hierarchy_value(unsigned long value)
	: value(value)
{
}
	
void thread_hierarchy_value::check_for_violation()
{
	if (this_thread_value <= value)
		throw std::logic_error("mutex hierarchy violated");
}
void thread_hierarchy_value::update()
{
	previous_value = this_thread_value;
	this_thread_value = value;
}
void thread_hierarchy_value::restor()
{
	this_thread_value = previous_value;
}

thread_local unsigned long thread_hierarchy_value::this_thread_value(ULONG_MAX);

// MARK: -
// MARK: hierarchical_mutex

hierarchical_mutex::hierarchical_mutex(unsigned long value)
	: hierarchy_value(value)
{
}
void hierarchical_mutex::lock()
{
	hierarchy_value.check_for_violation();
	internal_mutex.lock();
	hierarchy_value.update();
}
void hierarchical_mutex::unlock()
{
	hierarchy_value.restor();
	internal_mutex.unlock();
}
bool hierarchical_mutex::try_lock()
{
	hierarchy_value.check_for_violation();
	if (!internal_mutex.try_lock())
		return false;
	hierarchy_value.update();
	return true;
}


