//
//  chapter03_2_4DeadlockTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 12/5/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <mutex>
#include <thread>
#include <vector>

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

/// Listing 3.6 Using std::lock() and std::lock_guard in a swap operation

using some_big_object = int;
void swap(some_big_object& lhs, some_big_object& rhs) { std::swap(lhs, rhs); }

class X
{
private:
	some_big_object	some_detail;
	std::mutex m;
public:
	X(const some_big_object& sd) : some_detail(sd) {};
	some_big_object v() { return some_detail; }	// NON Thread safe - for testing only!!!
	
	friend void swap(X& lhs, X& rhs)
	{
		if (&lhs==&rhs)
			return;
		
		/// Loack two mutexes together:
		std::lock(lhs.m, rhs.m);
		std::lock_guard<std::mutex> lock_a(lhs.m, std::adopt_lock); // Just get ownership
		std::lock_guard<std::mutex> lock_b(rhs.m, std::adopt_lock); // Just get ownership
		swap(lhs.some_detail, rhs.some_detail);
	}
};

// MARK: -

@interface chapter03_2_4DeadlockTests : XCTestCase
@end

@implementation chapter03_2_4DeadlockTests

// MARK: -

- (void)testDeadlock
{
	constexpr int N = 1000;
	
	X a(10);
	X b(20);
	
	std::vector<std::thread> swapers;
	for (int i=0;i<N;++i)
	{
		swapers.emplace_back([lhs=std::ref(a), rhs=std::ref(b)](){
			for (int n=0;n<N;++n)
				swap(lhs.get(), rhs.get());
		});
	}
	
	std::for_each(swapers.begin(), swapers.end(), std::mem_fn(&std::thread::join));
	
	XCTAssertTrue( a.v() + b.v() == 10 + 20 );
}

/// Listing 3.7 Using a lock hierarchy to prevent deadlock

- (void)testHierarchical_mutex
{
	constexpr bool siletnt = true;
	auto log = [](char const * msg)
	{
		if (!siletnt)
			std::printf("  >>> %s\n", msg);
	};
	
	constexpr unsigned long logic_level = 100;
	constexpr unsigned long core_level = 50;
	constexpr unsigned long data_level = 10;
	
	/// DATA ---------------------------------------------------

	// protected data
	using binary_data_t = int;
	binary_data_t data = 10;
	
	// protector/guarg = security
	hierarchical_mutex data_level_mutex(data_level);
	
	// data level functionality:
	auto get_data = [&](){
		std::lock_guard<hierarchical_mutex> data_lockG(data_level_mutex);
		log("get_data");
		return data;
	};
	auto set_data = [&](binary_data_t new_value){
		std::lock_guard<hierarchical_mutex> data_lockG(data_level_mutex);
		log("set_data");
		data = new_value;
	};
	
	// test data level:
	XCTAssertEqual(10, get_data());
	set_data(20);
	XCTAssertEqual(20, get_data());
	
	/// CORE ---------------------------------------------------
	
	// core data
	using data_chunk_t = long;
	using core_data_t = std::vector<data_chunk_t>;
	constexpr core_data_t::size_type core_chunks_count = 5;
	core_data_t core_data(core_chunks_count, static_cast<data_chunk_t>(0));
	
	// protector/guarg = security
	hierarchical_mutex core_level_mutex(core_level);
	
	// core level functionality:
	auto update_chunk = [&](core_data_t::size_type index){
		if ( index>=core_data.size() )
			throw std::out_of_range("core data chank does not exist");
		
		std::lock_guard<hierarchical_mutex> core_lockG(core_level_mutex);
		log("update_chunk");
		core_data[index] = get_data();
	};
	auto get_core_chunk = [&](core_data_t::size_type index){
		if ( index>=core_data.size() )
			throw std::out_of_range("core data chank does not exist");
		
		std::lock_guard<hierarchical_mutex> core_lockG(core_level_mutex);
		log("get_core_chunk");
		return (index + 1) * core_data[index];
	};
	
	// test core level:
	for (int i=0;i<core_data.size();++i) {
		XCTAssertEqual(0, get_core_chunk(i));
		update_chunk(i);
	}
	for (int i=0;i<core_data.size();++i)
		XCTAssertEqual((i+1)*get_data(), get_core_chunk(i));
	XCTAssertThrows(get_core_chunk(core_data.size()));

	/// LOGIC --------------------------------------------------
	
	// data
	data_chunk_t sum = 0;
	
	// protector/guarg = security
	hierarchical_mutex logic_level_mutex(logic_level);
	
	// logic level functionality
	auto sum_chunks = [&](){
		std::lock_guard<hierarchical_mutex> logic_lockG(logic_level_mutex);
		log("sum_chunks");
		sum = 0;
		for (int i=0;i<core_chunks_count;++i)
			sum += get_core_chunk(i);
		return sum;
	};
	
	// test logic
	data_chunk_t sum_test = 0;
	for (int i=0;i<core_data.size();++i)
		sum_test += get_core_chunk(i);
	XCTAssertEqual(sum_chunks(), sum_test );
	
	/// TEST ---------------------------------------------------
	
	std::vector<std::thread> threads;
	
	for (int t=0;t<10;++t)
	{
		// logic processors
		threads.emplace_back([&](){
			for (int i=0;i<10;++i)
				sum_chunks();
		});
		
		// core processors
		threads.emplace_back([&](){
			for (int i=0;i<10;++i)
				for (core_data_t::size_type c=0;c<core_chunks_count;++c)
					update_chunk(c);
		});

		// data processors
		threads.emplace_back([&](){
			for (int i=0;i<10;++i)
				set_data(i);
		});
	}
	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
	
	hierarchical_mutex base_logic_level_mutex( 25 );
	auto ignore_hiererchy = [&](){
		std::lock_guard<hierarchical_mutex> base_logic_lockG(base_logic_level_mutex);
		sum_chunks();
	};
	XCTAssertThrows( ignore_hiererchy() );
	
}

@end
