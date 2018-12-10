//
//  Created by lva on 11/28/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#ifndef scoped_thread_h
#define scoped_thread_h

#include <thread>

/// Listing 2.6 : transfer thread ownership
class scoped_thread
{
    std::thread t;
public:
	template<typename... Args>
	explicit scoped_thread(Args&&... args);
	explicit scoped_thread(std::thread t_);
	~scoped_thread();
	
    scoped_thread(scoped_thread const&)=delete; /// only move
    scoped_thread& operator=(scoped_thread const&)=delete; /// only move
};

template<typename... Args>
scoped_thread::scoped_thread(Args&&... args)
{
	t = std::thread( std::forward<Args>(args)... );
}

#endif /* scoped_thread_h */
