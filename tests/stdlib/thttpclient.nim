discard """
  cmd: "nim c -d:ssl $file"
"""

import strutils
from net import TimeoutError

import httpclient, asyncdispatch

proc asyncTest() {.async.} =
  var client = newAsyncHttpClient()
  var resp = await client.request("http://example.com/")
  doAssert(resp.code.is2xx)
  doAssert("<title>Example Domain</title>" in resp.body)

  resp = await client.request("http://example.com/404")
  doAssert(resp.code.is4xx)
  doAssert(resp.code == Http404)
  doAssert(resp.status == Http404)

  resp = await client.request("https://google.com/")
  doAssert(resp.code.is2xx or resp.code.is3xx)

  # Multipart test.
  var data = newMultipartData()
  data["output"] = "soap12"
  data["uploaded_file"] = ("test.html", "text/html",
    "<html><head></head><body><p>test</p></body></html>")
  resp = await client.post("http://validator.w3.org/check", multipart=data)
  doAssert(resp.code.is2xx)

  client.close()

  # Proxy test
  #client = newAsyncHttpClient(proxy = newProxy("http://51.254.106.76:80/"))
  #var resp = await client.request("https://github.com")
  #echo resp

proc syncTest() =
  var client = newHttpClient()
  var resp = client.request("http://example.com/")
  doAssert(resp.code.is2xx)
  doAssert("<title>Example Domain</title>" in resp.body)

  resp = client.request("http://example.com/404")
  doAssert(resp.code.is4xx)
  doAssert(resp.code == Http404)
  doAssert(resp.status == Http404)

  resp = client.request("https://google.com/")
  doAssert(resp.code.is2xx or resp.code.is3xx)

  # Multipart test.
  var data = newMultipartData()
  data["output"] = "soap12"
  data["uploaded_file"] = ("test.html", "text/html",
    "<html><head></head><body><p>test</p></body></html>")
  resp = client.post("http://validator.w3.org/check", multipart=data)
  doAssert(resp.code.is2xx)

  client.close()

  # Timeout test.
  client = newHttpClient(timeout = 1)
  try:
    resp = client.request("http://example.com/")
    doAssert false, "TimeoutError should have been raised."
  except TimeoutError:
    discard
  except:
    doAssert false, "TimeoutError should have been raised."

syncTest()

waitFor(asyncTest())
