#
#
#            Nim's Runtime Library
#        (c) Copyright 2011 Alexander Mitchell-Robinson
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Alexander Mitchell-Robinson
##
## Unstable API.
##
## This module implements an event system that is not dependent on external
## graphical toolkits. It was originally called `NimEE` because
## it was inspired by Python's PyEE module. There are two ways you can use
## events: one is a python-inspired way; the other is more of a C-style way.
##
## .. code-block:: Nim
##    var ee = initEventEmitter()
##    var genericargs: EventArgs
##    proc handleevent(e: EventArgs) =
##        echo("Handled!")
##
##    # Python way
##    ee.on("EventName", handleevent)
##    ee.emit("EventName", genericargs)
##
##    # C/Java way
##    # Declare a type
##    type
##        SomeObject = object of RootObj
##            SomeEvent: EventHandler
##    var myobj: SomeObject
##    myobj.SomeEvent = initEventHandler("SomeEvent")
##    myobj.SomeEvent.addHandler(handleevent)
##    ee.emit(myobj.SomeEvent, genericargs)

type
  EventArgs* = object of RootObj ## Base object for event arguments that are passed to callback functions.
  EventHandler* = tuple[name: string, handlers: seq[proc(e: EventArgs) {.closure.}]] ## An eventhandler for an event.

type
  EventEmitter* = object ## An object that fires events and holds event handlers for an object.
    s: seq[EventHandler]
  EventError* = object of ValueError

proc initEventHandler*(name: string): EventHandler =
  ## Initializes an EventHandler with the specified name and returns it.
  result.handlers = @[]
  result.name = name

proc addHandler*(handler: var EventHandler, fn: proc(e: EventArgs) {.closure.}) =
  ## Adds the callback to the specified event handler.
  handler.handlers.add(fn)

proc removeHandler*(handler: var EventHandler, fn: proc(e: EventArgs) {.closure.}) =
  ## Removes the callback from the specified event handler.
  for i in countup(0, len(handler.handlers)-1):
    if fn == handler.handlers[i]:
      handler.handlers.del(i)
      break

proc containsHandler*(handler: var EventHandler, fn: proc(e: EventArgs) {.closure.}): bool =
  ## Checks if a callback is registered to this event handler.
  return handler.handlers.contains(fn)


proc clearHandlers*(handler: var EventHandler) =
  ## Clears all of the callbacks from the event handler.
  setLen(handler.handlers, 0)

proc getEventHandler(emitter: var EventEmitter, event: string): int =
  for k in 0..high(emitter.s):
    if emitter.s[k].name == event: return k
  return -1

proc on*(emitter: var EventEmitter, event: string, fn: proc(e: EventArgs) {.closure.}) =
  ## Assigns a event handler with the specified callback. If the event
  ## doesn't exist, it will be created.
  var i = getEventHandler(emitter, event)
  if i < 0:
    var eh = initEventHandler(event)
    addHandler(eh, fn)
    emitter.s.add(eh)
  else:
    addHandler(emitter.s[i], fn)

proc emit*(emitter: var EventEmitter, eventhandler: var EventHandler,
           args: EventArgs) =
  ## Fires an event handler with specified event arguments.
  for fn in items(eventhandler.handlers): fn(args)

proc emit*(emitter: var EventEmitter, event: string, args: EventArgs) =
  ## Fires an event handler with specified event arguments.
  var i = getEventHandler(emitter, event)
  if i >= 0:
    emit(emitter, emitter.s[i], args)

proc initEventEmitter*(): EventEmitter =
  ## Creates and returns a new EventEmitter.
  result.s = @[]
