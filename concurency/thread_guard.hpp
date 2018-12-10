//
//  Created by lva on 11/25/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#ifndef thread_guard_h
#define thread_guard_h

#include <thread>

/// Guard for thread
/// make it to be safe for executing if throw
class thread_guard
{
    std::thread& t;
public:
	explicit thread_guard(std::thread& t_);
	~thread_guard();
	
    thread_guard(thread_guard const&)=delete;       /// 3. Copying or assigning such an object would be dangerous
    thread_guard& oprator(thread_guard&)=delete;    /// it might then outlive the scope of the thread it was joining.
};

#endif /* thread_guard_h */
