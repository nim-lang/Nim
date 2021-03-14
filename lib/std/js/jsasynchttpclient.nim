## `Async <asyncjs.html>`_ `HttpClient <httpclient.html>`_ for JavaScript implemented as sugar on top of `jsfetch <jsfetch.html>`_
##
## .. Note:: jsasynchttpclient module requires `-d:nimExperimentalJsfetch`
when not defined(js):
  {.fatal: "Module jsasynchttpclient is designed to be used with the JavaScript backend.".}
when not defined(nimExperimentalJsfetch):
  {.fatal: "Module jsasynchttpclient requires -d:nimExperimentalJsfetch".}

import std/[jsfetch, asyncjs]
from std/uri import Uri

type JsAsyncHttpClient* = ref object of JsRoot

func newJsAsyncHttpClient*(): JsAsyncHttpClient = discard

func fetchOptionsImpl(body: cstring; metod: static[cstring]): FetchOptions =
  unsafeNewFetchOptions(metod = metod, body = body, mode = "cors".cstring, credentials = "include".cstring,
    cache = "default".cstring, referrerPolicy = "unsafe-url".cstring, keepalive = false)

proc getContent*(self: JsAsyncHttpClient; url: Uri | string): Future[cstring] {.async.} =
  text(await fetch(cstring($url)))

proc deleteContent*(self: JsAsyncHttpClient; url: Uri | string): Future[cstring] {.async.} =
  text(await fetch(cstring($url), fetchOptionsImpl("".cstring, "DELETE".cstring)))

proc postContent*(self: JsAsyncHttpClient; url: Uri | string; body = ""): Future[cstring] {.async.} =
  text(await fetch(cstring($url), fetchOptionsImpl(body.cstring, "POST".cstring)))

proc putContent*(self: JsAsyncHttpClient; url: Uri | string; body = ""): Future[cstring] {.async.} =
  text(await fetch(cstring($url), fetchOptionsImpl(body.cstring, "PUT".cstring)))

proc patchContent*(self: JsAsyncHttpClient; url: Uri | string; body = ""): Future[cstring] {.async.} =
  text(await fetch(cstring($url), fetchOptionsImpl(body.cstring, "PATCH".cstring)))

proc get*(self: JsAsyncHttpClient; url: Uri | string): Future[Response] {.async.} =
  fetch(cstring($url))

proc delete*(self: JsAsyncHttpClient; url: Uri | string): Future[Response] {.async.} =
  fetch(cstring($url), fetchOptionsImpl("".cstring, "DELETE".cstring))

proc post*(self: JsAsyncHttpClient; url: Uri | string; body = ""): Future[Response] {.async.} =
  fetch(cstring($url), fetchOptionsImpl(body.cstring, "POST".cstring))

proc put*(self: JsAsyncHttpClient; url: Uri | string; body = ""): Future[Response] {.async.} =
  fetch(cstring($url), fetchOptionsImpl(body.cstring, "PUT".cstring))

proc patch*(self: JsAsyncHttpClient; url: Uri | string; body = ""): Future[Response] {.async.} =
  fetch(cstring($url), fetchOptionsImpl(body.cstring, "PATCH".cstring))

proc head*(self: JsAsyncHttpClient; url: Uri | string): Future[Response] {.async.} =
  fetch(cstring($url), fetchOptionsImpl("".cstring, "HEAD".cstring))


runnableExamples("-d:nimExperimentalJsfetch -r:off"):
  import std/asyncjs
  from std/jsfetch import Response
  from std/uri import parseUri, Uri

  let client: JsAsyncHttpClient = newJsAsyncHttpClient()
  const data: string = """{"key": "value"}"""

  block:
    proc example() {.async.} =
      let url: Uri = parseUri("http://nim-lang.org")
      let content: cstring = await client.getContent(url)
      let response: Response = await client.get(url)
    discard example()

  block:
    proc example() {.async.} =
      let url: Uri = parseUri("http://httpbin.org/delete")
      let content: cstring = await client.deleteContent(url)
      let response: Response = await client.delete(url)
    discard example()

  block:
    proc example() {.async.} =
      let url: Uri = parseUri("http://httpbin.org/post")
      let content: cstring = await client.postContent(url, data)
      let response: Response = await client.post(url, data)
    discard example()

  block:
    proc example() {.async.} =
      let url: Uri = parseUri("http://httpbin.org/put")
      let content: cstring = await client.putContent(url, data)
      let response: Response = await client.put(url, data)
    discard example()

  block:
    proc example() {.async.} =
      let url: Uri = parseUri("http://httpbin.org/patch")
      let content: cstring = await client.patchContent(url, data)
      let response: Response = await client.patch(url, data)
    discard example()
