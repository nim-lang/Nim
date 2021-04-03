## - HTTP Headers for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/Headers
when not defined(js):
  {.fatal: "Module jsheaders is designed to be used with the JavaScript backend.".}

type Headers* = ref object of JsRoot ## HTTP Headers API.

func newHeaders*(): Headers {.importjs: "new Headers()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers

func add*(self: Headers; key: cstring; value: cstring) {.importjs: "#.append(#, #)".}
  ## Allows duplicated keys.
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/append

func delete*(self: Headers; key: cstring) {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/delete
  ##
  ## .. warning:: Delete *all* items with `key` from the headers, including duplicated keys.

func hasKey*(self: Headers; key: cstring): bool {.importjs: "#.has(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/has

func keys*(self: Headers): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/keys

func values*(self: Headers): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/values

func entries*(self: Headers): seq[tuple[key, value: cstring]] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/entries

func `[]`*(self: Headers; key: cstring): cstring {.importjs: "#.get(#)".}
  ## Get *all* items with `key` from the headers, including duplicated values.
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/get

func `[]=`*(self: Headers; key: cstring; value: cstring) {.importjs: "#.set(#, #)".}
  ## Do *not* allow duplicated keys, overwrites duplicated keys.
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/set

func clear*(self: Headers) {.importjs:
  "(() => { const header = #; Array.from(header.keys()).forEach((key) => header.delete(key)) })()".}
  ## Convenience func to delete all items from `Headers`.

func toCstring*(self: Headers): cstring {.importjs: "JSON.stringify(Array.from(#.entries()))".}
  ## Returns a `cstring` representation of `Headers`.

func `$`*(self: Headers): string = $toCstring(self)

func len*(self: Headers): int {.importjs: "Array.from(#.entries()).length".}


runnableExamples("-r:off"):

  block:
    let header: Headers = newHeaders()
    header.add("key", "value")
    assert header.hasKey("key")
    assert header.keys() == @["key".cstring]
    assert header.values() == @["value".cstring]
    assert header["key"] == "value".cstring
    header["other"] = "another".cstring
    assert header["other"] == "another".cstring
    assert header.entries() == @[("key".cstring, "value".cstring), ("other".cstring, "another".cstring)]
    assert header.toCstring() == """[["key","value"],["other","another"]]""".cstring
    header.delete("other")
    assert header.entries() == @[("key".cstring, "value".cstring)]
    header.clear()
    assert header.entries() == @[]
    assert header.len == 0

  block:
    let header: Headers = newHeaders()
    header.add("key", "a")
    header.add("key", "b")  ## Duplicated.
    header.add("key", "c")  ## Duplicated.
    assert header["key"] == "a, b, c".cstring
    header["key"] = "value".cstring
    assert header["key"] == "value".cstring

  block:
    let header: Headers = newHeaders()
    header["key"] = "a"
    header["key"] = "b"  ## Overwrites.
    assert header["key"] == "b".cstring
