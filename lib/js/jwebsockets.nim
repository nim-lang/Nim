#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Websockets support for the `JavaScript backend
## <backends.html#the-javascript-target>`_.

when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

type
  MessageEvent* {.importc.} = ref object
    data*: cstring

  WebSocket* {.importc.} = ref object
    onmessage*: proc (e: MessageEvent)
    onopen*: proc (e: MessageEvent)

proc newWebSocket*(url, key: cstring): WebSocket
  {.importcpp: "new WebSocket(@)".}

proc send*(w: WebSocket; data: cstring) {.importcpp.}
