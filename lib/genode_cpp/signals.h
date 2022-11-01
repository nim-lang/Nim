/*
 *
 *           Nim's Runtime Library
 *       (c) Copyright 2022 Emery Hemingway
 *
 *   See the file "copying.txt", included in this
 *   distribution, for details about the copyright.
 *
 */

#ifndef _NIM_SIGNALS_H_
#define _NIM_SIGNALS_H_

#include <libc/component.h>
#include <base/signal.h>
#include <util/reconstructible.h>

// Symbol for calling back into Nim
extern "C" void nimHandleSignal(void *arg);

namespace Nim { struct SignalHandler; }

struct Nim::SignalHandler
{
	// Pointer to the Nim handler object.
	void *arg;

	void handle_signal() {
		Libc::with_libc([this] () { nimHandleSignal(arg); }); }

	Genode::Signal_handler<SignalHandler> handler;

	SignalHandler(Genode::Entrypoint *ep, void *arg)
	: arg(arg), handler(*ep, *this, &SignalHandler::handle_signal) { }

	Genode::Signal_context_capability cap() { return handler; }
};

#endif
