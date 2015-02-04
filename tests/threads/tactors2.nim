discard """
  output: "1"
"""

import actors

type
  some_type {.pure, final.} = object
    bla: int

proc thread_proc(input: some_type): some_type {.thread.} =
  result.bla = 1

proc main() =
  var actorPool: TActorPool[some_type, some_type]
  createActorPool(actorPool, 1)

  var some_data: some_type

  var inchannel = spawn(actorPool, some_data, thread_proc)
  var recv_data = ^inchannel
  close(inchannel[])
  echo recv_data.bla

main()
