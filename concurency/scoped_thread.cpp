//
//  scoped_thread.cpp
//  concurency
//
//  Created by Viktor Levchenko on 12/10/18.
//  Copyright © 2018 LVA. All rights reserved.
//

#include "scoped_thread.hpp"

scoped_thread::scoped_thread(std::thread t_)
	: t(std::move(t_))  /// transfer ownership
{
	if (!t.joinable())  /// can be cheked here
		throw std::logic_error("No thread");
}

scoped_thread::~scoped_thread()
{
	t.join(); /// fase done thread
}

