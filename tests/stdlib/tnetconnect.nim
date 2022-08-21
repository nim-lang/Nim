discard """
  matrix: "-d:ssl"
"""

import std/net
from std/strutils import `%`

# bug #15215
proc test() =
  let ctx = newContext()

  proc fn(url: string) =
    let socket = newSocket()
    defer: close(socket)
    connect(socket, url, Port(443), 5000) # typically 20 could be enough
    send(socket, "GET / HTTP/1.0\nHost: $#\nConnection: close\n\n" % [url])
    wrapSocket(ctx, socket)

  # trying 2 sites makes it more resilent: refs #17458 this could give:
  # * Call to 'connect' timed out. [TimeoutError]
  # * No route to host [OSError]
  try:
    fn("www.nim-lang.org")
  except TimeoutError, OSError:
    fn("www.google.com")

test()
