//
//  concurencyTests.m
//  concurencyTests
//
//  Created by Viktor Levchenko on 11/22/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#import <XCTest/XCTest.h>

#include <thread>
#include <vector>
#include <iostream>

/// Thread task as callable object
/// with external data refernece
struct func
{
    int& i;
    func(int& i_):i(i_){}
    void operator()()
    {
        for (unsigned j=0;j<10;++j)
            std::cout<<"  >>> func : do task #" << j << "\n";
    }
};

static void do_work(unsigned id)
{
    std::cout << "  >>> thread #" << id << " done work" << std::endl;
}

/// Listing 2.6 : transfer thread ownership
class scoped_thread
{
    std::thread t;
public:
    explicit scoped_thread(std::thread t_)
    : t(std::move(t_))  /// transfer ownership
    {
        if (!t.joinable())  /// can be cheked here
            throw std::logic_error("No thread");
    }
    ~scoped_thread()
    {
        t.join(); /// fase done thread
    }
    scoped_thread(scoped_thread const&)=delete; /// only move
    scoped_thread& operator=(scoped_thread const&)=delete; /// only move
};

// MARK: -

@interface chapter02_3Ownership : XCTestCase

@end

@implementation chapter02_3Ownership

// MARK: -

- (void)testScopedThread
{
    int some_local_state = 0;
    scoped_thread t( std::thread{ func( some_local_state ) } );
    // do thomethig in current thread ...
}

-(void)testVectorThread
{
    /// Listing 2.7 Spawn some threads and wait for them to finish
    
    std::vector<std::thread> threads;
    for (int i=0;i<10;++i)
        threads.push_back(std::thread(do_work, i));
    
    std::for_each(threads.begin(), threads.end(),
                  std::mem_fn(&std::thread::join));
}

@end
