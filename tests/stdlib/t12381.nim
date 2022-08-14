discard """
  joinable: false
"""

import httpClient

proc test() =
  var client: HttpClient
  try:
    client = newHttpClient()
    discard client.getContent("http://localhost:8000")
  finally:
    # If the connection fails, client.getSocket() is nil here.
    client.close()

for i in 0..<100000:
  try:
    test()
  except:
    let e = getCurrentException()
    echo e.name, ": ", e.msg
    if e.msg != "Connection refused":
      doAssert false
      echo "break=", i
      break