discard """
  output: "pie"
"""

import tables, lists

type
  EventArgs = object of RootObj
  EventEmitter = object of RootObj
    events*: Table[string, DoublyLinkedList[proc(e: EventArgs) {.nimcall.}]]

proc emit*(emitter: EventEmitter, event: string, args: EventArgs) =
  for fn in nodes(emitter.events[event]):
    fn.value(args) #call function with args.

proc on*(emitter: var EventEmitter, event: string,
         fn: proc(e: EventArgs) {.nimcall.}) =
  if not hasKey(emitter.events, event):
    var list: DoublyLinkedList[proc(e: EventArgs) {.nimcall.}]
    add(emitter.events, event, list) #if not, add it.
  append(emitter.events[event], fn)

proc initEmitter(emitter: var EventEmitter) =
  emitter.events = initTable[string,
    DoublyLinkedList[proc(e: EventArgs) {.nimcall.}]]()

var
  ee: EventEmitter
  args: EventArgs
initEmitter(ee)
ee.on("print", proc(e: EventArgs) = echo("pie"))
ee.emit("print", args)
