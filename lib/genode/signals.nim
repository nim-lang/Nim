#
#
#            Nim's Runtime Library
#        (c) Copyright 2022 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## See `Genode Foundations - Asynchronous notifications <https://genode.org/documentation/genode-foundations/21.05/architecture/Inter-component_communication.html#Asynchronous_notifications>`
## for a description of Genode signals.

when not defined(genode) or defined(nimdoc):
  {.error: "Genode only module".}

import ./entrypoints, ./constructibles

export ep # Entrypoint accessor on GenodeEnv

type
  SignalContextCapability* {.
    importcpp: "Genode::Signal_context_capability",
    header: "<base/signal.h>", pure.} = object
    ## Capability to an asynchronous signal context.

proc isValid*(cap: SignalContextCapability): bool {.importcpp: "#.valid()".}
  ## Call the Genode core to check if this `SignalContextCapability` is valid.
  # TODO: RpcEffect

type
  HandlerProc = proc () {.closure, gcsafe.}

  SignalHandlerBase {.
    importcpp: "Nim::SignalHandler",
    header: "genode_cpp/signals.h",
    pure.} = object

  SignalHandlerCpp = Constructible[SignalHandlerBase]

  SignalHandlerObj = object
    cpp: SignalHandlerCpp
    cb: HandlerProc
      ## Signal handling procedure called during dispatch.

  SignalHandler* = ref SignalHandlerObj
    ## Nim object enclosing a Genode signal handler.

proc construct(cpp: SignalHandlerCpp; ep: Entrypoint; sh: SignalHandler) {.importcpp.}

proc cap(cpp: SignalHandlerCpp): SignalContextCapability {.importcpp: "#->cap()".}

proc newSignalHandler*(ep: Entrypoint; cb: HandlerProc): SignalHandler =
  ## Create a new signal handler. A label is recommended for
  ## debugging purposes. A signal handler will not be garbage
  ## collected until after it has been dissolved.
  result = SignalHandler(cb: cb)
  result.cpp.construct(ep, result)
  GCref result

proc dissolve*(sig: SignalHandler) =
  ## Dissolve signal dispatcher from entrypoint.
  # TODO: =destroy?
  destruct sig.cpp
  sig.cb = nil # lose the callback
  GCunref sig

proc cap*(sig: SignalHandler): SignalContextCapability =
  ## Signal context capability. Can be delegated to external components.
  sig.cpp.cap

proc submit*(cap: SignalContextCapability) {.
    importcpp: "Genode::Signal_transmitter(#).submit()".}
  ## Submit a signal to a context capability.

proc nimHandleSignal(p: pointer) {.exportc.} =
  ## C symbol invoked by entrypoint during signal dispatch.
  cast[SignalHandler](p).cb()
