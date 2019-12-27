/*
 *
 *           Nim's Runtime Library
 *       (c) Copyright 2017 Emery Hemingway
 *
 *   See the file "copying.txt", included in this
 *   distribution, for details about the copyright.
 *
 */


#ifndef _GENODE_CPP__THREAD_H_
#define _GENODE_CPP__THREAD_H_

#include <base/thread.h>
#include <base/env.h>
#include <util/reconstructible.h>

namespace Nim { struct SysThread; }

struct Nim::SysThread
{
	typedef void (Entry)(void*);

	struct Thread : Genode::Thread
	{
		void *_tls;

		Entry *_func;
		void  *_arg;

		void entry() override {
			(_func)(_arg); }

		Thread(Genode::Env &env, Genode::size_t stack_size, Entry func, void *arg, int affinity)
		: Genode::Thread(env, "nim-thread", stack_size,
		                 env.cpu().affinity_space().location_of_index(affinity),
		                 Genode::Cpu_session::Weight(Genode::Cpu_session::Weight::DEFAULT_WEIGHT-1),
		                 env.cpu()),
		  _func(func), _arg(arg)
		{
			Genode::Thread::start();
		}
	};

	Genode::Constructible<Thread> _thread;

	void initThread(Genode::Env *env, Genode::size_t stack_size, Entry func, void *arg, int aff) {
		_thread.construct(*env, stack_size, func, arg, aff); }

	void joinThread() {
		_thread->join(); }

	static bool offMainThread() {
		return dynamic_cast<SysThread::Thread*>(Genode::Thread::myself()); }

	static void *threadVarGetValue()
	{
		SysThread::Thread *thr =
			static_cast<SysThread::Thread*>(Genode::Thread::myself());
		return thr->_tls;
	}

	static void threadVarSetValue(void *value)
	{
		SysThread::Thread *thr =
			static_cast<SysThread::Thread*>(Genode::Thread::myself());
		thr->_tls = value;
	}

};

#endif
