//
//  threadsafe_queue.h
//  concurency
//
//  Created by lva on 12/24/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#ifndef threadsafe_queue_h
#define threadsafe_queue_h

#include <mutex>
#include <queue>
#include <condition_variable>
#include <memory>

template<typename T>
class threadsafe_queue
{
private:
    mutable std::mutex mut; // The mutex must be mutable
    std::queue<T> data_queue;
    std::condition_variable data_cond;
public:
    threadsafe_queue()
    {}
    threadsafe_queue(const threadsafe_queue& other)
    {
        std::lock_guard<std::mutex> lg(other.mut);
        data_queue = other.data_queue;
    }
    
};

#endif /* threadsafe_queue_h */
