discard """
  joinable: false
"""

import httpClient

proc test() =
  var client = newHttpClient()
  discard client.getContent("http://localhost:8000")

for i in 0..<10000:
  try:
    test()
  except:
    let e = getCurrentException()
    echo e.name, ": ", e.msg
    if e.msg != "Connection refused":
      echo "break=", i
      break
