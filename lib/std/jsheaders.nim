## - HTTP Headers for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/Headers
when not defined(js):
  {.fatal: "Module jsheaders is designed to be used with the JavaScript backend.".}

type Headers* = ref object of JsRoot ## HTTP Headers for the JavaScript target.

func newHeaders*(): Headers {.importjs: "new Headers()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers

func add*(this: Headers; key: cstring; value: cstring) {.importjs: "#.append(#, #)".}
  ## Allows duplicated keys.
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/append

func delete*(this: Headers; key: cstring) {.importjs: "#.$1(#)".}
  ## Delete *all* items with `key` from the headers, including duplicated keys.
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/delete

func hasKey*(this: Headers; key: cstring): bool {.importjs: "#.has(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/has

func keys*(this: Headers): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/keys

func values*(this: Headers): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/values

func entries*(this: Headers): seq[tuple[key, value: cstring]] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/entries

func `[]`*(this: Headers; key: cstring): cstring {.importjs: "#.get(#)".}
  ## Get *all* items with `key` from the headers, including duplicated values.
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/get

func `[]=`*(this: Headers; key: cstring; value: cstring) {.importjs: "#.set(#, #)".}
  ## Do *not* allow duplicated keys, overwrites duplicated keys.
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/set

func clear*(this: Headers) {.importjs:
  "(() => { const header = #; Array.from(header.keys()).forEach((key) => header.delete(key)) })()".}
  ## Convenience func to delete all items from `Headers`.

func toCstring*(this: Headers): cstring {.importjs: "JSON.stringify(Array.from(#.entries()))".}
  ## Returns a `cstring` representation of `Headers`.

func `$`*(this: Headers): string = $toCstring(this)


runnableExamples:
  if defined(nimJsHeadersTests):
    block:
      let header = newHeaders()
      header.add("key", "value")
      doAssert header.hasKey("key")
      doAssert header.keys() == @["key".cstring]
      doAssert header.values() == @["value".cstring]
      doAssert header["key"] == "value".cstring
      header["other"] = "another".cstring
      doAssert header["other"] == "another".cstring
      doAssert header.entries() == @[("key".cstring, "value".cstring), ("other".cstring, "another".cstring)]
      doAssert header.toCstring() == """[["key","value"],["other","another"]]""".cstring
      header.delete("other")
      doAssert header.entries() == @[("key".cstring, "value".cstring)]
      header.clear()
      doAssert header.entries() == @[]
    block:
      let header = newHeaders()
      header.add("key", "a")
      header.add("key", "b")  ## Duplicated.
      header.add("key", "c")  ## Duplicated.
      doAssert header["key"] == "a, b, c".cstring
      header["key"] = "value".cstring
      doAssert header["key"] == "value".cstring
    block:
      let header = newHeaders()
      header["key"] = "a"
      header["key"] = "b"  ## Duplicated.
      header["key"] = "c"  ## Duplicated.
      doAssert header["key"] == "c".cstring

