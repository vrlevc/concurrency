//
//  c04_2_3MakingPromisesTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 1/28/19.
//  Copyright © 2019 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <future>
#include <string>
#include <list>

///-----------------------------------------------------------------
/// API declaration

using  payload_type = std::string;
using  packet_id = std::size_t;
struct data_packet;
struct outgoing_packet;
class  Connection;
using  connection_set = std::list<Connection>;
using  connection_iterator = connection_set::iterator;

bool done(connection_set const&);
void process_connections(connection_set&);

///-----------------------------------------------------------------
/// API definition

struct data_packet
{
	packet_id id;
	payload_type payload;
};

struct outgoing_packet
{
	std::promise<bool> promise;
	payload_type payload;
};

class  Connection
{
public:
	// imcomming
	bool has_incoming_data() const;
	data_packet&& incoming();
	std::promise<payload_type>& get_promise(const packet_id) const;
	// outgoing
	bool has_outgoing_data() const;
	outgoing_packet&& top_of_outgoing_queue();
	void send(payload_type);
};

///-----------------------------------------------------------------
/// API Implementation

/// Threaded function for process all connctions in one thread
void process_connections(connection_set& connections)
{
	while ( !done(connections) ) /// 1. process until done returns true
	{
		/// 2. Every time through the loop, it checks each connection in turn
		for (connection_iterator connection  = connections.begin();
			 					 connection != connections.end();
							   ++connection	)
		{
			/// 3. Retriving incomming data if there is any
			if (connection->has_incoming_data())
			{
				data_packet data = connection->incoming();
				std::promise<payload_type>& p = connection->get_promise(data.id);
				p.set_value(data.payload);
			}
			/// 5. Sending any queued outgong data
			if (connection->has_outgoing_data())
			{
				outgoing_packet data = connection->top_of_outgoing_queue();
				connection->send(data.payload);
				data.promise.set_value(true);
			}
		}
	}
}

// MARK: -

@interface c04_2_3MakingPromisesTests : XCTestCase
@end

@implementation c04_2_3MakingPromisesTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

// MARK: -

- (void)testExample
{
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

@end
