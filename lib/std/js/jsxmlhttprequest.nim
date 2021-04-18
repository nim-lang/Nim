## `XMLHttpRequest` for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest
when not defined(js):
  {.fatal: "Module jsxmlhttprequest is designed to be used with the JavaScript backend.".}

from std/dom import Node

type XMLHttpRequest* = ref object of JsRoot  ## https://xhr.spec.whatwg.org
  responseXML*: Node
  withCredentials*: bool
  status*, timeout*, readyState*: cint
  responseText*, responseURL*, statusText*: cstring

func newXMLHttpRequest*(): XMLHttpRequest {.importjs: "new XMLHttpRequest()".}
  ## Constructor for `XMLHttpRequest`.

func open*(this: XMLHttpRequest; `method`, url: cstring; async = true; user = cstring.default; password = cstring.default) {.importjs: "#.$1(#, #, #, #, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/open

func send*(this: XMLHttpRequest; body: cstring | Node = cstring.default) {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/send

func abort*(this: XMLHttpRequest) {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/abort

func getAllResponseHeaders*(this: XMLHttpRequest): cstring {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/getAllResponseHeaders

func overrideMimeType*(this: XMLHttpRequest; mimeType: cstring) {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/overrideMimeType

func setRequestHeader*(this: XMLHttpRequest; key, value: cstring) {.importjs: "#.$1(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest/setRequestHeader

func setRequestHeader*(this: XMLHttpRequest; keyValuePairs: openArray[tuple[key, val: cstring]]) {.importjs:
  "(() => { const rqst = #; #.forEach((item) => rqst.$1(item[0], item[1])) })()".}
  ## Same as `setRequestHeader` but takes `openArray[tuple[key, val: cstring]]`.


runnableExamples("-r:off"):
  from std/dom import Node
  let request = newXMLHttpRequest()
  request.open("GET".cstring, "http://localhost:8000/".cstring, false)
  request.setRequestHeader("mode".cstring, "no-cors".cstring)
  request.setRequestHeader([(key: "mode".cstring, val: "no-cors".cstring)])
  request.overrideMimeType("text/plain".cstring)
  request.send()
  echo request.getAllResponseHeaders()
  echo "responseText\t", request.responseText
  echo "responseURL\t", request.responseURL
  echo "statusText\t", request.statusText
  echo "responseXML\t", request.responseXML is Node
  echo "status\t", request.status
  echo "timeout\t", request.timeout
  echo "withCredentials\t", request.withCredentials
  echo "readyState\t", request.readyState
  request.abort()
