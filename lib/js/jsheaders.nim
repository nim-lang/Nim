## - HTTP Headers for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/Headers
when not defined(js):
  {.fatal: "Module jsheaders is designed to be used with the JavaScript backend.".}

type Headers* = ref object of JsRoot ## HTTP Headers for the JavaScript target.

func newHeaders*(): Headers {.importjs: "new Headers()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers

func add*(this: Headers; key: cstring; value: cstring) {.importjs: "#.append(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/append

func delete*(this: Headers; key: cstring) {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/delete

func hasKey*(this: Headers; key: cstring): bool {.importjs: "#.has(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/has

func keys*(this: Headers): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/keys

func values*(this: Headers): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/values

func entries*(this: Headers): seq[array[2, cstring]] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/entries

func `[]`*(this: Headers; key: cstring): cstring {.importjs: "#.get(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/get

func `[]=`*(this: Headers; key: cstring; value: cstring) {.importjs: "#.set(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/set

func clear*(this: Headers) {.importjs:
  "(() => { const header = #; Array.from(header.keys()).forEach((key) => header.delete(key)) })()".}
  ## Convenience func to delete all items from `Headers`.


runnableExamples:
  if defined(nimJsHeadersTests):
    let header = newHeaders()
    header.add("key", "value")
    doAssert header.hasKey("key")
    doAssert header.keys() == @["key".cstring]
    doAssert header.values() == @["value".cstring]
    doAssert header["key"] == "value".cstring
    header["other"] = "another".cstring
    doAssert header["other"] == "another".cstring
    doAssert header.entries() == @[["key".cstring, "value"], ["other".cstring, "another"]]
    header.delete("other")
    doAssert header.entries() == @[]
