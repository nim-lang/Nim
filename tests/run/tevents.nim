discard """
file: "tevents.nim"
output: '''HandlePrintEvent: Output -> Handled print event
HandlePrintEvent2: Output -> printing for ME
HandlePrintEvent2: Output -> printing for ME'''
"""

import events

type
  TPrintEventArgs = object of TEventArgs
    user*: string

proc handleprintevent*(e: TEventArgs) =
    write(stdout, "HandlePrintEvent: Output -> Handled print event\n")
        
proc handleprintevent2*(e: TEventArgs) =
    var args: TPrintEventArgs = TPrintEventArgs(e)
    write(stdout, "HandlePrintEvent2: Output -> printing for " & args.user)
    
var ee = initEventEmitter()

var eventargs: TPrintEventArgs
eventargs.user = "ME\n"

##method one test

ee.on("print", handleprintevent)
ee.on("print", handleprintevent2)

ee.emit("print", eventargs)

##method two test

type
  TSomeObject = object of TObject
    PrintEvent: TEventHandler

var obj: TSomeObject
obj.PrintEvent = initEventHandler("print")
obj.PrintEvent.addHandler(handleprintevent2)

ee.emit(obj.PrintEvent, eventargs)

obj.PrintEvent.removeHandler(handleprintevent2)

ee.emit(obj.PrintEvent, eventargs)

