## Synchronous `HttpClient <httpclient.html>`_ for JavaScript implemented on top of `jsxmlhttprequest <jsxmlhttprequest.html>`_
when not defined(js):
  {.fatal: "Module jssynchttpclient is designed to be used with the JavaScript backend.".}

import std/uri, std/js/jsxmlhttprequest
from std/uri import Uri

type JsHttpClient* = ref object of XMLHttpRequest

func newJsHttpClient*(): JsHttpClient = discard

proc xmlHttpRequestImpl(self: JsHttpClient; url: Uri | string; body: string; metod: static[cstring]): cstring =
  self.open(metod = metod, url = cstring($url), false)
  self.send(body = body.cstring)
  self.responseText

proc getContent*(self: JsHttpClient; url: Uri | string): cstring =
  xmlHttpRequestImpl(self, url, "", "GET".cstring)

proc deleteContent*(self: JsHttpClient; url: Uri | string): cstring =
  xmlHttpRequestImpl(self, url, "", "DELETE".cstring)

proc postContent*(self: JsHttpClient; url: Uri | string; body = ""): cstring =
  xmlHttpRequestImpl(self, url, body, "POST".cstring)

proc putContent*(self: JsHttpClient; url: Uri | string; body = ""): cstring =
  xmlHttpRequestImpl(self, url, body, "PUT".cstring)

proc patchContent*(self: JsHttpClient; url: Uri | string; body = ""): cstring =
  xmlHttpRequestImpl(self, url, body, "PATCH".cstring)

proc head*(self: JsHttpClient; url: Uri | string): cstring =
  xmlHttpRequestImpl(self, url, "", "HEAD".cstring)


runnableExamples("-r:off"):
  from std/uri import parseUri, Uri

  let client: JsHttpClient = newJsHttpClient()
  const data: string = """{"key": "value"}"""

  block:
    let url: Uri = parseUri("http://nim-lang.org")
    let content: cstring = client.getContent(url)

  block:
    let url: Uri = parseUri("http://httpbin.org/delete")
    let content: cstring = client.deleteContent(url)

  block:
    let url: Uri = parseUri("http://httpbin.org/post")
    let content: cstring = client.postContent(url, data)

  block:
    let url: Uri = parseUri("http://httpbin.org/put")
    let content: cstring = client.putContent(url, data)

  block:
    let url: Uri = parseUri("http://httpbin.org/patch")
    let content: cstring = client.patchContent(url, data)
