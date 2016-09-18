import strutils

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

syncTest()

waitFor(asyncTest())

#[

  else:
    #downloadFile("http://force7.de/nim/index.html", "nimindex.html")
    #downloadFile("http://www.httpwatch.com/", "ChunkTest.html")
    #downloadFile("http://validator.w3.org/check?uri=http%3A%2F%2Fgoogle.com",
    # "validator.html")

    #var r = get("http://validator.w3.org/check?uri=http%3A%2F%2Fgoogle.com&
    #  charset=%28detect+automatically%29&doctype=Inline&group=0")

    var data = newMultipartData()
    data["output"] = "soap12"
    data["uploaded_file"] = ("test.html", "text/html",
      "<html><head></head><body><p>test</p></body></html>")

    echo postContent("http://validator.w3.org/check", multipart=data)]#
