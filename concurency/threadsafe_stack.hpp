//
//  threadsafe_stack.hpp
//  concurency
//
//  Created by Viktor Levchenko on 12/5/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#ifndef threadsafe_stack_h
#define threadsafe_stack_h

#include <exception>
#include <memory>		// for std::shared_ptr
#include <stack>
#include <mutex>

/// Listing 3.4 An outline class definition for a thread-safe stack

struct empty_stack : std::exception
{
	virtual const char* what() const noexcept override { return "empty_stack"; }
};

template<typename T>
class threadsafe_stack
{
private:
	std::stack<T> data;
	mutable std::mutex m;
public:
	threadsafe_stack() {}
	threadsafe_stack(const threadsafe_stack& other)
	{
		// copy preformed in constructor body
		std::lock_guard<std::mutex> lock(other.m);
		data = other.data;
	}
	threadsafe_stack& operator=(const threadsafe_stack&) = delete; // assignment operator is deleted
	
	void push(T new_value)
	{
		std::lock_guard<std::mutex> lock(m);
		data.push(new_value);
	}
	std::shared_ptr<T> pop()	// return top as a pointer, throws exception if empty
	{
		std::lock_guard<std::mutex> lock(m);
		
		/// Check for empty before trying to pop value:
		if (data.empty()) throw empty_stack();
		
		/// Allocate return value before modify stack:
		std::shared_ptr<T> const res( std::make_shared<T>(data.top()) );
		data.pop();
		
		return res;
	}
	void pop(T& value)			// put top into referenced value, throws exception if empty
	{
		std::lock_guard<std::mutex> lock(m);
		if (data.empty()) throw empty_stack();
		value = data.top();
		data.pop();
	}
	bool empty() const
	{
		std::lock_guard<std::mutex> lock(m);
		return data.empty();
	}
};

#endif /* threadsafe_stack_h */
