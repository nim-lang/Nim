discard """
  matrix: "-d:ssl"
"""

import std/net
from std/strutils import `%`

# bug #15215
proc test() =
  let ctx = newContext()

  proc fn(url: string) =
    echo (url,)
    let socket = newSocket()
    defer: close(socket)
    if url == "www.nim-lang.org":
      connect(socket, url, Port(443), 4) # typically 20 could be enough
    else:
      connect(socket, url, Port(443), 5000) # typically 20 could be enough
    send(socket, "GET / HTTP/1.0\nHost: $#\nConnection: close\n\n" % [url])
    wrapSocket(ctx, socket)

  try:
    fn("www.nim-lang.org")
  except TimeoutError:
    # refs #17458 this can give:
    # Error: unhandled exception: Call to 'connect' timed out. [TimeoutError]
    fn("www.google.com")

test()
