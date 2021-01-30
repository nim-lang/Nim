## `Set` for the JavaScript target.
## * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set
when not defined(js):
  {.fatal: "Module jssets is designed to be used with the JavaScript backend.".}

import std/jsffi

type JsSet* {.importjs: "Set".} = ref object of JsRoot ## Set API.
  size: cint

func newJsSet*(): JsSet {.importjs: "new Set()".} ## Constructor for `JsSet`.

func newJsSet*(items: openArray[JsObject]): JsSet {.importjs: "new Set(#)".} ## Constructor for `JsSet`.

func add*(this: JsSet; value: JsObject) {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set/add

func delete*(this: JsSet; value: JsObject) {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set/delete

func clear*(this: JsSet) {.importjs: "#.$1()".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set/clear

func contains*(this: JsSet; value: JsObject): bool {.importjs: "#.has(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set/has

func toString*(this: JsSet): seq[cstring] {.importjs: """
  (() => {const result = []; #.forEach(item => result.push(JSON.stringify(item))); return result})()""".}
  ## Convert `JsSet` to `seq[cstring]`, all items will be converted to `cstring`.

func len*(this: JsSet): int = this.size.int

func `$`*(this: JsSet): string = $this.toString()


runnableExamples:
  import std/jsffi
  if defined(nimJsSetTests):
    let a: JsSet = newJsSet([1.toJs, 2.toJs, 3.toJs, 4.toJs])
    let b: JsSet = newJsSet([1.0.toJs, 2.0.toJs, 3.0.toJs])
    doAssert a.len == 4
    doAssert b.len == 3
    doAssert a.toString() == @["1".cstring, "2", "3", "4"]
    doAssert b.toString() == @["1".cstring, "2", "3"]
    a.clear()
    b.clear()
    let d: JsSet = newJsSet([1.toJs, 2.toJs, 3.toJs])
    doAssert d.len == 3
    d.add(4.toJs)
    d.delete(2.toJs)
    doAssert 3.toJs in d
    doAssert "3".cstring.toJs notin d
    doAssert d.contains 1.toJs
    doAssert $d == """@["1", "3", "4"]"""
