discard """
  targets: "c"
  cmd: "nim $target --compileOnly --os:freertos --gc:arc $options $file"
  disabled: "bsd"
  disabled: "windows"
  action: compile
"""

# Note:
#   This file tests FreeRTOS/LwIP cross-compilation on UNIX platforms
#   Windows should run when compiled with esp-idf, however I'm not
#   sure how to test for only compilation on Windows without running 
#   a test exe
# 
# Note:
#   disabling *BSDs since they're not playing well with `gcc`

import net
import asynchttpserver, asyncdispatch

proc cb*(req: Request) {.async.} =
  await req.respond(Http200, "Hello World")

proc run_http_server*() {.exportc.} =
  echo "starting http server"
  var server = newAsyncHttpServer()

  waitFor server.serve(Port(8181), cb)

echo("ok")
