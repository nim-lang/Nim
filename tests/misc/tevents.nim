discard """
output: '''
HandlePrintEvent: Output -> Handled print event
HandlePrintEvent2: Output -> printing for ME
HandlePrintEvent2: Output -> printing for ME
'''
"""

import events

type
  PrintEventArgs = object of EventArgs
    user*: string

proc handleprintevent*(e: EventArgs) =
    write(stdout, "HandlePrintEvent: Output -> Handled print event\n")

proc handleprintevent2*(e: EventArgs) =
    var args: PrintEventArgs = PrintEventArgs(e)
    write(stdout, "HandlePrintEvent2: Output -> printing for " & args.user)

var ee = initEventEmitter()

var eventargs: PrintEventArgs
eventargs.user = "ME\n"

##method one test

ee.on("print", handleprintevent)
ee.on("print", handleprintevent2)

ee.emit("print", eventargs)

##method two test

type
  SomeObject = object of RootObj
    printEvent: EventHandler

var obj: SomeObject
obj.printEvent = initEventHandler("print")
obj.printEvent.addHandler(handleprintevent2)

ee.emit(obj.printEvent, eventargs)

obj.printEvent.removeHandler(handleprintevent2)

ee.emit(obj.printEvent, eventargs)
