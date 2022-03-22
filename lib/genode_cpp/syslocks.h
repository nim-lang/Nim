/*
 *
 *           Nim's Runtime Library
 *       (c) Copyright 2017 Emery Hemingway
 *
 *   See the file "copying.txt", included in this
 *   distribution, for details about the copyright.
 *
 */

#ifndef _GENODE_CPP__SYSLOCKS_H_
#define _GENODE_CPP__SYSLOCKS_H_

/* Genode includes */
#include <base/semaphore.h>
#include <base/mutex.h>

namespace Nim {
	struct SysLock;
	struct SysCond;
}

struct Nim::SysLock
{
	Genode::Mutex _mutex_a, _mutex_b;
	bool         _locked;

	void acquireSys()
	{
		Genode::Mutex::Guard guard(_mutex_a);
		_locked = true;
		_mutex_b.acquire();
	}

	bool tryAcquireSys()
	{
		if (_locked)
			return false;

		Genode::Mutex::Guard guard(_mutex_a);

		if (_locked) {
			return false;
		} else {
			_locked = true;
			_mutex_b.acquire();
			return true;
		}
	}

	void releaseSys()
	{
		Genode::Mutex::Guard guard(_mutex_a);
		_locked = false;
		_mutex_b.release();
	}
};

struct Nim::SysCond
{
	Genode::Semaphore _semaphore;

	void waitSysCond(SysLock &syslock)
	{
		syslock.releaseSys();
		_semaphore.down();
		syslock.acquireSys();
	}

	void signalSysCond()
	{
		_semaphore.up();
	}

	void broadcastSysCond()
	{
		_semaphore.up();
	}
};

#endif
