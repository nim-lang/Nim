# Test to ensure TEventHandler is '.closure'

# bug #1187

type
  TEventArgs* = object
    skip*: bool
  TEventHandler[T] = proc (e: var TEventArgs, data: T) {.closure.}
  TEvent*[T] = object
    #handlers: seq[TEventHandler[T]] # Does not work
    handlers: seq[proc (e: var TEventArgs, data: T) {.closure.}] # works

  TData = object
    x: int

  TSomething = object
    s: TEvent[TData]

proc init*[T](e: var TEvent[T]) =
  e.handlers.newSeq(0)

#proc add*[T](e: var TEvent[T], h: proc (e: var TEventArgs, data: T) {.closure.}) =
# this line works
proc add*[T](e: var TEvent[T], h: TEventHandler[T]) =
  # this line does not work
  e.handlers.add(h)

proc main () =
  var something: TSomething
  something.s.init()
  var fromOutside = 4711

  something.s.add() do (e: var TEventArgs, data: TData):
    var x = data.x
    x = fromOutside

main()
