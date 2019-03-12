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
#include <queue>
#include <vector>

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

class data_packet
{
	data_packet(packet_id _id, payload_type&& data)
		: id(_id)
		, payload(data)
	{}
private:
	packet_id id;
	payload_type payload;
};

class outgoing_packet
{
public:
	outgoing_packet() {};
	outgoing_packet(outgoing_packet&& other)
	: promise( std::move(other.promise) )
	, payload( std::move(other.payload) )
	{}
	outgoing_packet& operator=(outgoing_packet&& other)
	{
		promise = std::move(other.promise);
		payload = std::move(other.payload);
		return *this;
	}
	
	std::promise<bool> promise;
	payload_type payload;
};

class  Connection
{
public:
	// Initialization and preparation:
	Connection() {}
	
	bool isOpen() const { return state == State::open; }
	bool isClosed() const { return state == State::closed; }
	void open() { if (!isClosed()) state = State::open; }
	void close() { state = State::closed; }
	
	//-------------------------------------------------------------
	// imcomming
	bool has_incoming_data() const;
	data_packet&& incoming();
	std::promise<payload_type>& get_promise(const packet_id) const;
	
	// outgoing
	bool has_outgoing_data() const { return isOpen() && !outgoing_queue.empty(); };
	outgoing_packet& top_of_outgoing_queue() { return outgoing_queue.front(); }
	void send(payload_type data) { std::printf("   >>> Send data < %s >\n", data.c_str()); }
	void pop_outgoing_queue() { std::lock_guard<std::mutex> lk(outq_m); outgoing_queue.pop(); }
	
	//-------------------------------------------------------------
	// for client
	void post_packet(outgoing_packet&& packet) { std::lock_guard<std::mutex> lk(outq_m); outgoing_queue.push( std::move(packet) ); }
	
private:
	std::mutex outq_m;
	std::queue<outgoing_packet> outgoing_queue;
	enum class State { ready, open, closed } state = State::ready;
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
//			if (connection->has_incoming_data())
			{
//				data_packet data = connection->incoming();
//				std::promise<payload_type>& p = connection->get_promise(data.id);
//				p.set_value(data.payload);
			}
			/// 5. Sending any queued outgong data
			if (connection->has_outgoing_data())
			{
				outgoing_packet& data = connection->top_of_outgoing_queue();
				connection->send(data.payload);
				data.promise.set_value(true);
				connection->pop_outgoing_queue();
			}
		}
	}
}

// MARK: -

@interface c04_2_3MakingPromisesTests : XCTestCase
@end

@implementation c04_2_3MakingPromisesTests

// MARK: -

- (void)testConnectionHandling
{
	std::mutex cm;
	connection_set connections;
	
	auto fnClientProcessor = [&cm, &connections](int clientID)
	{
		// Emplace connecting to server into process set:
		Connection* connect = nullptr;
		{
			std::lock_guard<std::mutex> lock(cm);
			connect = &connections.emplace_back();
			std::printf("   >>> Thread[ %.3d ] - has opened connection\n", clientID);
		}
		
		// Open connection
		connect->open();
		
		std::vector<std::future<bool>> posted_set;
		for (int i=0; i<5; ++i) // post 100 packets ...
		{
			// prepare data for posting
			std::string data;
			data.append("POST DATA : Client ");
			data.append( std::to_string(clientID) );
			data.append(" : Packet ");
			data.append( std::to_string(i) );
			
			// Prepare some data packets ...
			outgoing_packet packet;
			packet.payload = data;
			posted_set.emplace_back( packet.promise.get_future() );
			
			// Post
			connect->post_packet( std::move(packet) );
		}
		
		// Wait for data has been posted
		std::for_each(posted_set.begin(), posted_set.end(), std::mem_fn( &std::future<bool>::get ));
		
		// close connection
		connect->close();
	};

	
	// Launch several clients:
	std::vector< std::thread > clients;
	for (int i=0; i<5; ++i)
		clients.emplace_back(fnClientProcessor, i*10);
	
	// prcess connections:
	std::thread  connections_processor(	process_connections, std::ref(connections) );
	
	// wait for client to finish work...
	std::for_each(clients.begin(), clients.end(), std::mem_fn(&std::thread::join));
	
	connections_processor.join();
}

// MARK: - Helper tests

- (void)testConnectionOpenClose
{
	Connection connection;
	XCTAssertFalse(connection.isOpen());
	XCTAssertFalse(connection.isClosed());
	
	connection.open();
	XCTAssertTrue(connection.isOpen());
	XCTAssertFalse(connection.isClosed());
	
	connection.close();
	XCTAssertFalse(connection.isOpen());
	XCTAssertTrue(connection.isClosed());

	connection.open();
	XCTAssertFalse(connection.isOpen());
	XCTAssertTrue(connection.isClosed());
}

- (void)testDoneFn
{
	connection_set connections;
	
	// empty connections set is not a reason for done
	XCTAssertFalse( done(connections) );
	
	// Add couple connetions to process set
	connections.emplace_back();
	connections.emplace_back();
	connections.emplace_back();
	
	// Still not done: each connection was not set to closed yet
	XCTAssertFalse( done(connections) );
	
	// Open connetion
	connections.front().open();
	XCTAssertFalse( done(connections) );
	
	connections.back().open();
	XCTAssertFalse( done(connections) );
	
	// Open all connections:
	std::for_each(connections.begin(), connections.end(), std::mem_fn( &Connection::open ));
	XCTAssertFalse( done(connections) );
	
	// Close connection
	connections.front().close();
	XCTAssertFalse( done(connections) );
	
	connections.back().close();
	XCTAssertFalse( done(connections) );
	
	// Close all connections:
	std::for_each(connections.begin(), connections.end(), std::mem_fn( &Connection::close ));
	XCTAssertTrue( done(connections) ); // DONE! All connections were closed.
	
	// Still done even if one wre tried to open:
	connections.front().open();
	XCTAssertTrue( done(connections) );
}

-(void)testConnection_has_outgoing_data
{
	Connection connection;
	
	XCTAssertFalse(connection.has_outgoing_data());
	connection.open();
	XCTAssertFalse(connection.has_outgoing_data());
	connection.close();
	XCTAssertFalse(connection.has_outgoing_data());
}

-(void)testConnection_post_packet
{
	Connection connection;
	
	XCTAssertFalse(connection.has_outgoing_data());
	
	outgoing_packet packetA;
	connection.post_packet( std::move(packetA) );
	XCTAssertFalse(connection.has_outgoing_data());
	connection.open();
	XCTAssertTrue(connection.has_outgoing_data());
	connection.close();
	XCTAssertFalse(connection.has_outgoing_data());
}

-(void)testConnection_send
{
	Connection connection;
	
	payload_type data = "test data to send";
	connection.send(data);
}

-(void)testConnection_top_of_outgoing_queue
{
	Connection connection;
	
	connection.open();
	outgoing_packet packetA;
	packetA.payload = "AAA";
	connection.post_packet( std::move(packetA) );
	outgoing_packet packetB;
	packetB.payload = "BBB";
	connection.post_packet( std::move(packetA) );
	
	outgoing_packet& top_packet = connection.top_of_outgoing_queue();
	XCTAssertTrue( top_packet.payload == "AAA" );
}

-(void)testConnection_pop_outgoing_queue
{
	Connection connection;
	
	connection.open();
	outgoing_packet packetA, packetB, packetC;
	packetA.payload = "AAA";
	packetB.payload = "BBB";
	packetC.payload = "CCC";
	
	XCTAssertFalse(connection.has_outgoing_data());
	connection.post_packet( std::move(packetA) );
	connection.post_packet( std::move(packetB) );
	connection.post_packet( std::move(packetC) );
	XCTAssertTrue(connection.has_outgoing_data());
	
	XCTAssertTrue( connection.top_of_outgoing_queue().payload == "AAA" );
	connection.pop_outgoing_queue();
	XCTAssertTrue(connection.has_outgoing_data());
	XCTAssertTrue( connection.top_of_outgoing_queue().payload == "BBB" );
	connection.pop_outgoing_queue();
	XCTAssertTrue(connection.has_outgoing_data());
	XCTAssertTrue( connection.top_of_outgoing_queue().payload == "CCC" );
	connection.pop_outgoing_queue();
	XCTAssertFalse(connection.has_outgoing_data());
}

@end

// MARK: - Implementation

bool done(connection_set const& connections)
{
	bool _done = false;

	if (!connections.empty())
		_done = std::all_of(connections.begin(), connections.end(), std::mem_fn( &Connection::isClosed ));

	return _done;
}
