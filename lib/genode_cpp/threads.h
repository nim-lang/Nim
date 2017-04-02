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

		Thread(Genode::Env &env, Genode::size_t stack_size, Entry func, void *arg)
		: Genode::Thread(env, "nim-thread", stack_size), _func(func), _arg(arg)
		{
			Genode::Thread::start();
		}
	};

	Genode::Constructible<Thread> _thread;

	void initThread(Genode::Env *env, Genode::size_t stack_size, Entry func, void *arg) {
		_thread.construct(*env, stack_size, func, arg); }

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
