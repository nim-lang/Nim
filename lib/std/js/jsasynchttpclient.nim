## `Async <asyncjs.html>`_ `HttpClient <httpclient.html>`_ for JavaScript implemented on top of `jsfetch <jsfetch.html>`_
when not defined(js):
  {.fatal: "Module jsasynchttpclient is designed to be used with the JavaScript backend.".}

import std/[jsfetch, asyncjs]
from std/uri import Uri

type JsAsyncHttpClient* = ref object of JsRoot

func newJsAsyncHttpClient*(): JsAsyncHttpClient = discard

func fetchOptionsImpl(body: cstring; `method`: static[cstring]): FetchOptions =
  unsafeNewFetchOptions(metod = `method`, body = body, mode = "cors".cstring, credentials = "include".cstring,
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


runnableExamples("-d:nimExperimentalJsfetch -d:nimExperimentalAsyncjsThen -r:off"):
  import std/[asyncjs, jsfetch, uri]

  proc example(): Future[void] {.async.} =
    let client = newJsAsyncHttpClient()
    const data = """{"key": "value"}"""

    block:
      let url = parseUri("http://nim-lang.org")
      let content = await client.getContent(url)
      let response = await client.get(url)

    block:
      let url = parseUri("http://httpbin.org/delete")
      let content = await client.deleteContent(url)
      let response = await client.delete(url)

    block:
      let url = parseUri("http://httpbin.org/post")
      let content = await client.postContent(url, data)
      let response = await client.post(url, data)

    block:
      let url = parseUri("http://httpbin.org/put")
      let content = await client.putContent(url, data)
      let response = await client.put(url, data)

    block:
      let url = parseUri("http://httpbin.org/patch")
      let content = await client.patchContent(url, data)
      let response = await client.patch(url, data)

  discard example()
