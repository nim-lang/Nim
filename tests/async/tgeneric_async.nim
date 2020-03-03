discard """
output: "1\nmessa"
"""

import async

# bug #2377
proc test[T](v: T) {.async.} =
  echo $v

asyncCheck test[int](1)

# More complex case involving typedesc and static params
type
  SomeMsg = object
    data: string

template msgId(M: type SomeMsg): int = 1

proc recvMsg(): Future[tuple[msgId: int, msgData: string]] {.async.} =
  return (1, "message")

proc read(data: string, T: type SomeMsg, maxBytes: int): T =
  result.data = data[0 ..< min(data.len, maxBytes)]

proc nextMsg*(MsgType: typedesc,
              maxBytes: static[int]): Future[MsgType] {.async.} =
  const wantedId = MsgType.msgId

  while true:
    var (nextMsgId, nextMsgData) = await recvMsg()
    if nextMsgId == wantedId:
      return nextMsgData.read(MsgType, maxBytes)

proc main {.async.} =
  let msg = await nextMsg(SomeMsg, 5)
  echo msg.data

asyncCheck main()

