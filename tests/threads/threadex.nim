discard """
  output: ""
"""

type
  TMsgKind = enum
    mLine, mEof
  TMsg = object {.pure, final.}
    case k: TMsgKind
    of mEof: backTo: TThreadId[int]
    of mLine: data: string

var
  consumer: TThread[TMsg]
  printedLines = 0

proc consume() {.thread.} =
  while true:
    var x = recv[TMsg]()
    if x.k == mEof: 
      x.backTo.send(printedLines)
      break
    echo x.data
    atomicInc(printedLines)

proc produce() =
  var m: TMsg
  var input = open("readme.txt")
  while not endOfFile(input):
    if consumer.ready:
      m.data = input.readLine()
      consumer.send(m)
  close(input)
  m.k = mEof
  m.backTo = mainThreadId[int]()
  consumer.send(m)
  var result = recv[int]()
  echo result
  
createThread(consumer, consume)
produce()
joinThread(consumer)

echo printedLines

