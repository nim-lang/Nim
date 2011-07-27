import tables
import lists
type
    TEventArgs = object of TObject
type
    TEventEmitter = object of TObject
        events*: TTable[string, TDoublyLinkedList[proc(e : TEventArgs)]]
proc on*(emitter : var TEventEmitter, event : string, func : proc(e : TEventArgs)) =
    if hasKey(emitter.events, event) == false:
        var list: TDoublyLinkedList[proc(e : TEventArgs)]
        add(emitter.events,event,list) #if not, add it.
    append(emitter.events[event], func) #adds the function to the event's list. I get a error here too.
        
proc emit*(emitter : TEventEmitter, event : string, args : TEventArgs) =
    for func in items(emitter.events[event]):
        func(args) #call function with args.
proc initEmitter(emitter : TEventEmitter) =
     emitter.events = initTable[string, TSinglyLinkedList[TObject]]()

var ee : TEventEmitter
ee.on("print", proc(e : TEventArgs) = echo("pie"))
ee.emit("print")

