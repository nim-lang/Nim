import tables
import lists
type
  TEventArgs = object of TObject
type
  TEventEmitter = object of TObject
    events*: TTable[string, TDoublyLinkedList[proc(e: TEventArgs)]]
        
proc emit*(emitter: TEventEmitter, event: string, args: TEventArgs) =
  for func in nodes(emitter.events[event]):
    func.value(args) #call function with args.

proc on*(emitter: var TEventEmitter, event: string, func: proc(e: TEventArgs)) =
  if not hasKey(emitter.events, event):
    var list: TDoublyLinkedList[proc(e: TEventArgs)]
    add(emitter.events,event,list) #if not, add it.
  #append(emitter.events[event], func)
  #adds the function to the event's list. I get a error here too.

proc initEmitter(emitter: TEventEmitter) =
  emitter.events = initTable[string, TDoublyLinkedList[proc(e: TEventArgs)]]()

var ee: TEventEmitter
ee.on("print", proc(e: TEventArgs) = echo("pie"))
ee.emit("print")

