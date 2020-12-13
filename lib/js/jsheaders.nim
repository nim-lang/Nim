## - HTTP Headers for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/Headers
when not defined(js) and not defined(nimdoc):
  {.fatal: "Module jsheaders is designed to be used with the JavaScript backend.".}

type Headers* = ref object ## HTTP Headers

func newHeaders*(): Headers {.importjs: "new Headers()".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers

func newHeaders*(keyValuePairs: openArray[array[2, cstring]]): Headers {.importjs: """
(() => {
  const header = new Headers();
  #.forEach((item) => header.append(item[0], item[1]));
  return header;
})();""".}
  ## Same as `newHeaders` but initializes `Headers` with `keyValuePairs`.

func append*(this: Headers; key: cstring; value: cstring) {.importjs: "#.append(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/append

func delete*(this: Headers; key: cstring) {.importjs: "#.delete(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/delete

func get*(this: Headers; key: cstring): cstring {.importjs: "#.get(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/get

func has*(this: Headers; key: cstring): bool {.importjs: "#.has(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/has

func set*(this: Headers; key: cstring; value: cstring) {.importjs: "#.set(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/set

func keys*(this: Headers): seq[cstring] {.importjs: "Array.from(#.keys())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/keys

func values*(this: Headers): seq[cstring] {.importjs: "Array.from(#.values())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/values

func entries*(this: Headers): seq[array[2, cstring]] {.importjs: "Array.from(#.entries())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/Headers/entries


runnableExamples:
  if defined(nimJsHeadersTests):

    block:
      var header = newHeaders()
      header.append(r"key", r"value")
      doAssert header.has(r"key")
      doAssert header.keys() == @["key".cstring]
      doAssert header.values() == @["value".cstring]
      doAssert header.get(r"key") == "value".cstring
      header.set(r"other", r"another")
      doAssert header.get(r"other") == "another".cstring
      doAssert header.entries() == @[["key".cstring, "value"], ["other".cstring, "another"]]
      header.delete(r"other")
