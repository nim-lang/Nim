discard """
  output: "pie"
"""

import tables, lists

type
  TEventArgs = object of TObject
  TEventEmitter = object of TObject
    events*: TTable[string, TDoublyLinkedList[proc(e: TEventArgs) {.nimcall.}]]

proc emit*(emitter: TEventEmitter, event: string, args: TEventArgs) =
  for func in nodes(emitter.events[event]):
    func.value(args) #call function with args.

proc on*(emitter: var TEventEmitter, event: string, 
         func: proc(e: TEventArgs) {.nimcall.}) =
  if not hasKey(emitter.events, event):
    var list: TDoublyLinkedList[proc(e: TEventArgs) {.nimcall.}]
    add(emitter.events, event, list) #if not, add it.
  append(emitter.events.mget(event), func)

proc initEmitter(emitter: var TEventEmitter) =
  emitter.events = initTable[string, 
    TDoublyLinkedList[proc(e: TEventArgs) {.nimcall.}]]()

var 
  ee: TEventEmitter
  args: TEventArgs
initEmitter(ee)
ee.on("print", proc(e: TEventArgs) = echo("pie"))
ee.emit("print", args)

