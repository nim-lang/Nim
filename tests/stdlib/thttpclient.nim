discard """
  cmd: "nim c --threads:on -d:ssl $file"
  exitcode: 0
  output: "OK"
  disabled: "travis"
  disabled: "appveyor"
"""

import strutils
from net import TimeoutError

import nativesockets, os, httpclient, asyncdispatch, md5

const enableManualTests = defined(manualTests)

proc test(client: HttpClient | AsyncHttpClient) {.multisync.} =
  var resp = await client.request("http://example.com/")
  doAssert(resp.code.is2xx)
  var body = await resp.body
  body = await resp.body # Test caching
  doAssert("<title>Example Domain</title>" in body)

  resp = await client.request("http://example.com/404")
  doAssert(resp.code.is4xx)
  doAssert(resp.code == Http404)
  doAssert(resp.status == Http404)
  discard await resp.body # Read body. TODO: this may prove too much of PITA.

  resp = await client.request("https://google.com/")
  doAssert(resp.code.is2xx or resp.code.is3xx)
  discard await resp.body # Make sure body is read.

  # Tests redirection
  resp = await client.request("https://github.com/StevenBlack/hosts/blob/master/hosts?raw=true")
  doAssert(resp.code.is2xx)
  discard await resp.body # Make sure body is read.

  # getContent
  try:
    discard await client.getContent("https://google.com/404")
    doAssert(false, "HttpRequestError should have been raised")
  except HttpRequestError:
    discard
  except:
    doAssert(false, "HttpRequestError should have been raised")

  when enableManualTests:
    # w3.org now blocks travis, so disabled:
    # Multipart test.
    var data = newMultipartData()
    data["output"] = "soap12"
    data["uploaded_file"] = ("test.html", "text/html",
      "<html><head></head><body><p>test</p></body></html>")
    resp = await client.post("http://validator.w3.org/check", multipart=data)
    doAssert(resp.code.is2xx)

  # onProgressChanged
  when enableManualTests:
    when client is HttpClient:
      proc onProgressChanged(total, progress, speed: BiggestInt) =
        echo("Downloaded ", progress, " of ", total)
        echo("Current rate: ", speed div 1000, "kb/s")
    else:
      proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
        echo("Downloaded ", progress, " of ", total)
        echo("Current rate: ", speed div 1000, "kb/s")
    client.onProgressChanged = onProgressChanged
    await client.downloadFile("http://speedtest-ams2.digitalocean.com/100mb.test",
                              "100mb.test")

    doAssert getMD5(readFile("100mb.test")) == "121aca26d3e239628204aad290e34e3e"

  client.close()

  # Proxy test
  #when enableManualTests:
  #  client = newAsyncHttpClient(proxy = newProxy("http://51.254.106.76:80/"))
  #  var resp = await client.request("https://github.com")
  #  echo resp

proc makeIPv6HttpServer(hostname: string, port: Port): AsyncFD =
  let fd = newNativeSocket(AF_INET6)
  setSockOptInt(fd, SOL_SOCKET, SO_REUSEADDR, 1)
  var aiList = getAddrInfo(hostname, port, AF_INET6)
  if bindAddr(fd, aiList.ai_addr, aiList.ai_addrlen.Socklen) < 0'i32:
    freeAddrInfo(aiList)
    raiseOSError(osLastError())
  freeAddrInfo(aiList)
  if listen(fd) != 0:
    raiseOSError(osLastError())
  setBlocking(fd, false)

  var serverFd = fd.AsyncFD
  register(serverFd)
  result = serverFd

  proc onAccept(fut: Future[AsyncFD]) {.gcsafe.} =
    if not fut.failed:
      let clientFd = fut.read()
      clientFd.send("HTTP/1.1 200 OK\r\LContent-Length: 0\r\LConnection: Closed\r\L\r\L").callback = proc() =
        clientFd.closeSocket()
      serverFd.accept().callback = onAccept
  serverFd.accept().callback = onAccept

proc ipv6Test() =
  var client = newAsyncHttpClient()
  let serverFd = makeIPv6HttpServer("::1", Port(18473))
  var resp = waitFor client.request("http://[::1]:18473/")
  doAssert(resp.status == "200 OK")
  serverFd.closeSocket()
  client.close()

when isMainModule:
  echo("Synchronous tests")
  var syncClient = newHttpClient()
  syncClient.test()
  echo("Async tests")
  var asyncClient = newAsyncHttpClient()
  waitFor(asyncClient.test())

  ipv6Test()

echo "OK"
