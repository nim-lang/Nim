import asyncnet, asyncdispatch, strtabs

type
  WebSocketCallback = proc (client: WebSocket, message: WebSocketMessage) {.closure, gcsafe.}
  WebSocketRecvClosure = proc (ws: WebSocket): Future[string] {.gcsafe.}

  WebSocketMessage = ref object
    msg: string

  WebSocket = ref object
    socket:     AsyncSocket
    header:     StringTableRef
    onOpen:     WebSocketCallback
    onMessage:  WebSocketCallback
    onClose:    WebSocketCallback

proc recv(ws: WebSocket, p: WebSocketRecvClosure): Future[string] {.async.}=
  if not ws.socket.isClosed():
    result = await ws.p()
    if result == "":
      ws.socket.close()
      if ws.onClose != nil:
        ws.onClose(ws, nil)
  return result

proc reсvSize(ws: WebSocket, size: int): Future[string] {.async.} =
  proc recvSizeClosure(ws: WebSocket): Future[string] {.async.} =
    return await ws.socket.recv(size)
  return await ws.recv(recvSizeClosure)
