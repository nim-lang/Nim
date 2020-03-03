discard """
  cmd: "nim $target --threads:on $options $file"
  errormsg: "illegal recursion in type 'TIRC'"
  line: 16
"""

import events
import net
import strutils
import os

type
    TMessageReceivedEventArgs = object of EventArgs
        Nick*: string
        Message*: string
    TIRC = object
        EventEmitter: EventEmitter
        MessageReceivedHandler*: EventHandler
        Socket: Socket
        Thread: Thread[TIRC]

proc initIRC*(): TIRC =
    result.Socket = socket()
    result.EventEmitter = initEventEmitter()
    result.MessageReceivedHandler = initEventHandler("MessageReceived")

proc IsConnected*(irc: var TIRC): bool =
    return running(irc.Thread)


proc sendRaw*(irc: var TIRC, message: string) =
    irc.Socket.send(message & "\r\L")
proc handleData(irc: TIRC) {.thread.} =
    var connected = False
    while connected:
        var tup = @[irc.Socket]
        var o = select(tup, 200)
        echo($o)
        echo($len(tup))
        if len(tup) == 1:
            #Connected
            connected = True

            #Parse data here

        else:
            #Disconnected
            connected = False
            return

proc Connect*(irc: var TIRC, nick: string, host: string, port: int = 6667) =
    connect(irc.Socket, host, TPort(port), TDomain.AF_INET)
    send(irc.Socket,"USER " & nick & " " & nick & " " & nick & " " & nick & "\r\L")
    send(irc.Socket,"NICK " & nick & "\r\L")
    var thread: Thread[TIRC]
    createThread(thread, handleData, irc)
    irc.Thread = thread




when true:
    var irc = initIRC()
    irc.Connect("AmryBot[Nim]","irc.freenode.net",6667)
    irc.sendRaw("JOIN #nim")
    os.Sleep(4000)
