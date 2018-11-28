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

#endif /* scoped_thread_h */
