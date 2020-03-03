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
#include <base/lock.h>

namespace Nim {
	struct SysLock;
	struct SysCond;
}

struct Nim::SysLock
{
	Genode::Lock _lock_a, _lock_b;
	bool         _locked;

	void acquireSys()
	{
		_lock_a.lock();
		_locked = true;
		_lock_a.unlock();
		_lock_b.lock();
	}

	bool tryAcquireSys()
	{
		if (_locked)
			return false;

		_lock_a.lock();
		if (_locked) {
			_lock_a.unlock();
			return false;
		} else {
			_locked = true;
			_lock_b.lock();
			_lock_a.unlock();
			return true;
		}
	}

	void releaseSys()
	{
		_locked = false;
		_lock_a.unlock();
		_lock_b.unlock();
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
};

#endif
