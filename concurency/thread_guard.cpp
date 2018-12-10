//
//  thread_guard.cpp
//  concurency
//
//  Created by Viktor Levchenko on 12/10/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#include "thread_guard.hpp"

thread_guard::thread_guard(std::thread& t_)
	: t(t_)
{
	
}

thread_guard::~thread_guard()
{
	if (t.joinable())  /// 1. test joinable before
		t.join();      /// 2. call join
}
