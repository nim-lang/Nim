#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Alex Mitchell
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Alex Mitchell
##
## This module implements an event system that is not dependant on external
## graphical toolkits. It was originally called ``NimEE`` because 
## it was inspired by Python's PyEE module. There are two ways you can use
## events: one is a python-inspired way; the other is more of a C-style way.
##
## .. code-block:: Nimrod
##    var ee = initEventEmitter()
##    var genericargs: TEventArgs
##    proc handleevent(e: TEventArgs) =
##        echo("Handled!")
##
##    # Python way
##    ee.on("EventName", handleevent)
##    ee.emit("EventName", genericargs)
## 
##    # C/Java way
##    # Declare a type
##    type
##        TSomeObject = object of TObject
##            SomeEvent: TEventHandler
##    var myobj: TSomeObject
##    myobj.SomeEvent = initEventHandler("SomeEvent")
##    myobj.SomeEvent.addHandler(handleevent)
##    ee.emit(myobj.SomeEvent, genericargs)

type
  TEventArgs* = object of TObject ## Base object for event arguments that are passed to callback functions.
  TEventHandler* = tuple[name: string, handlers: seq[proc(e:TEventArgs) {.closure.}]] ## An eventhandler for an event.

type
  TEventEmitter* = object {.pure, final.} ## An object that fires events and holds event handlers for an object.
    s: seq[TEventHandler]
  EInvalidEvent* = object of EInvalidValue
    
proc initEventHandler*(name: string): TEventHandler =
  ## Initializes an EventHandler with the specified name and returns it.
  result.handlers = @[]
  result.name = name

proc addHandler*(handler: var TEventHandler, func: proc(e: TEventArgs) {.closure.}) =
  ## Adds the callback to the specified event handler.
  handler.handlers.add(func)

proc removeHandler*(handler: var TEventHandler, func: proc(e: TEventArgs) {.closure.}) =
  ## Removes the callback from the specified event handler.
  for i in countup(0, len(handler.handlers) -1):
    if func == handler.handlers[i]:
      handler.handlers.del(i)
      break
    
proc containsHandler*(handler: var TEventHandler, func: proc(e: TEventArgs) {.closure.}): bool =
  ## Checks if a callback is registered to this event handler.
  return handler.handlers.contains(func)


proc clearHandlers*(handler: var TEventHandler) =
  ## Clears all of the callbacks from the event handler.
  setLen(handler.handlers, 0)

proc getEventHandler(emitter: var TEventEmitter, event: string): int =
  for k in 0..high(emitter.s):
    if emitter.s[k].name == event: return k
  return -1

proc on*(emitter: var TEventEmitter, event: string, func: proc(e: TEventArgs) {.closure.}) =
  ## Assigns a event handler with the specified callback. If the event
  ## doesn't exist, it will be created.
  var i = getEventHandler(emitter, event)
  if i < 0:
    var eh = initEventHandler(event)
    addHandler(eh, func)
    emitter.s.add(eh)
  else:
    addHandler(emitter.s[i], func)
  
proc emit*(emitter: var TEventEmitter, eventhandler: var TEventHandler, 
           args: TEventArgs) =
  ## Fires an event handler with specified event arguments.
  for func in items(eventhandler.handlers): func(args)

proc emit*(emitter: var TEventEmitter, event: string, args: TEventArgs) =
  ## Fires an event handler with specified event arguments.
  var i = getEventHandler(emitter, event)
  if i >= 0:
    emit(emitter, emitter.s[i], args)

proc initEventEmitter*(): TEventEmitter =
  ## Creates and returns a new EventEmitter.
  result.s = @[]
