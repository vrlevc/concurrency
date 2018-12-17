//
//  c03_3_AlternativeLocksTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 12/14/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include "scoped_thread.hpp"

#include <mutex>
#include <shared_mutex>
#include <thread>
#include <memory>
#include <vector>
#include <string>
#include <map>

struct some_resource_t
{
	void do_something() {}
};

// MARK: -

@interface c03_3_AlternativeLocksTests : XCTestCase
@end

@implementation c03_3_AlternativeLocksTests

// MARK: -


/// Listing 3.11 Thread-safe lazy initialization using a mutex
// Note: This solution causes unnecessary serialization of threads using the resource.
- (void)testLazyInitialization_notOptimal
{
	std::shared_ptr<some_resource_t> resource_ptr;
	std::mutex resource_mutex;
	auto foo = [&]()
	{
		/// All threads are serialized here:
		std::unique_lock<std::mutex> lk(resource_mutex);
		if (!resource_ptr)
		{
			/// Only the initialization need protection:
			resource_ptr.reset(new some_resource_t);
		}
		lk.unlock();
		resource_ptr->do_something();
	};
	
	std::vector<std::thread> threads;
	for (int i=0;i<10;++i)
		threads.emplace_back(foo);
	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
}

// MARK: - std::call_once
/// ------------------------------- ///
/// std::once_flag & std::call_once ///
/// ------------------------------- ///

- (void)testLazyInitialization_GOOD
{
	std::shared_ptr<some_resource_t> resource_ptr;
	std::once_flag resource_flag;
	auto init_resource = [&]()
	{
		resource_ptr.reset(new some_resource_t);
	};
	auto foo = [&]()
	{
		/// Initialization is called exactly once
		std::call_once(resource_flag, init_resource);
		resource_ptr->do_something();
	};
	
	std::vector<std::thread> threads;
	for (int i=0;i<10;++i)
		threads.emplace_back(foo);
	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
}

/// Listing 3.12 Thread-safe lazy initialization of a class member using std::call_once

- (void)testLazyInitialization_class
{
	/// 1: External non thread safe function to init connection:
	using data_packet = std::string;
	class Connection
	{
	private:
		std::string trafic;
	public:
		Connection() = default;
		Connection(Connection const &) = default;
		Connection(std::string const & connection_data) : trafic(connection_data) {}
		void send_data(data_packet const & data)
		{
			// non thread safe - need one ...
		}
		data_packet recieve_data()
		{
			return "Some data package";
		}
	};
	class ConnectionLogger
	{
	public:
		Connection connect(std::string const & info)
		{
			std::string connectionLog = "Connected to : ";
			connectionLog.append( info );
			Connection connection(connectionLog);
			return connection;
		};
	};
	// 2: Test class - used thread safe lazy init
	class X
	{
	private:
		using connection_info = std::string;
		using connection_handle = Connection;
		using data_packet = std::string;
		
		ConnectionLogger connection_manager;
		connection_info connection_details;
		connection_handle connection;
		std::once_flag connection_init_flag;	// data guard
		
		/// 3: non thread safe!!!
		void open_connection()
		{
			connection=connection_manager.connect(connection_details);
		}
	public: /// 4: thread safe public interface:
		X(connection_info const & connection_detatils_)	: connection_details(connection_detatils_) {}
		void send_data(data_packet const & data)
		{
			std::call_once(connection_init_flag, &X::open_connection, this);	// guard class function
			connection.send_data(data);
		}
		data_packet recieve_data()
		{
			std::call_once(connection_init_flag, &X::open_connection, this);
			return connection.recieve_data();
		}
	};
	
	// 3: Using class X for send and receive data:
	auto server_handler = []()
	{
		X server("mail.server.com");
		for (int i=0;i<10;++i)
		{
			server.send_data("send e-mails");
			server.recieve_data();
		}
	};
	
	// 4: create multy threaded server with one connection:
	X sender("sender.server.com");
	X receiver("receiver.server.com");
	std::vector<std::thread> users;
	for (int i=0;i<50;++i)
	{
		users.emplace_back(server_handler);
		users.emplace_back(&X::send_data, &sender, "send by sender");
		users.emplace_back(&X::recieve_data, &receiver);
	}
	std::for_each(users.begin(), users.end(), std::mem_fn(&std::thread::join));
}

// MARK: - std::shared_mutex
/// ------------------------------- ///
/// std::shared_mutex			    ///
/// ------------------------------- ///

/// Listing 3.13 Protecting a data structure with a std::shared_mutex

-(void) testSharedDataProtection
{
	using dns_entry = std::string;
	
	class dns_cache
	{
		std::map<std::string, dns_entry> entries;
		mutable std::shared_mutex entry_mutex;
	public:
		dns_entry find_entry(std::string const & domain) const
		{
			// support mutilock from other threads
			std::shared_lock<std::shared_mutex> lk(entry_mutex);
			std::printf("  >>> read - shared protected");
			std::map<std::string,dns_entry>::const_iterator const it = entries.find(domain);
			return (it==entries.end())?dns_entry():it->second;
		}
		void update_or_add_entry(std::string const & domain,
								 dns_entry const & dns_details)
		{
			std::lock_guard<std::shared_mutex> lk(entry_mutex);
			std::printf("\n  >>> update/add - unique protected\n");
			entries[domain]=dns_details;
		}
	};
	
	// Test data
	dns_cache DNS_Server;
	DNS_Server.update_or_add_entry("aaa.com", "10.20");
	DNS_Server.update_or_add_entry("bbb.com", "10.30");
	DNS_Server.update_or_add_entry("ccc.com", "20.20");
	DNS_Server.update_or_add_entry("ddd.com", "30.20");
	
	std::vector<std::thread> threads;
	for (int i=0;i<50;++i)
		threads.emplace_back([&DNS_Server]() {
			DNS_Server.find_entry("aaa.com");
			DNS_Server.find_entry("bbb.com");
			DNS_Server.find_entry("ccc.com");
			DNS_Server.find_entry("xxx.com");
		});
	
	DNS_Server.update_or_add_entry("ccc.com", "25.20");
	DNS_Server.update_or_add_entry("eee.com", "10.70");
	
	for (int i=0;i<50;++i)
		threads.emplace_back([&DNS_Server]() {
			DNS_Server.find_entry("aaa.com");
			DNS_Server.find_entry("bbb.com");
			DNS_Server.find_entry("ccc.com");
			DNS_Server.find_entry("xxx.com");
		});

	std::for_each(threads.begin(), threads.end(), std::mem_fn(&std::thread::join));
}

@end
