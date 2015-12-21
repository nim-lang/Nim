discard """
  output: '''asdas
processClient end
false
'''
"""

type
  PAsyncHttpServer = ref object
    value: string
  PFutureBase = ref object
    callback: proc () {.closure.}
    value: string
    failed: bool

proc accept(server: PAsyncHttpServer): PFutureBase =
  new(result)
  result.callback = proc () =
    discard
  server.value = "hahaha"

proc processClient(): PFutureBase =
  new(result)

proc serve(server: PAsyncHttpServer): PFutureBase =
  iterator serveIter(): PFutureBase {.closure.} =
    echo server.value
    while true:
      var acceptAddrFut = server.accept()
      yield acceptAddrFut
      var fut = acceptAddrFut.value

      var f = processClient()
      f.callback =
        proc () =
          echo("processClient end")
          echo(f.failed)
      yield f
  var x = serveIter
  for i in 0 .. 1:
    result = x()
    result.callback()

discard serve(PAsyncHttpServer(value: "asdas"))
