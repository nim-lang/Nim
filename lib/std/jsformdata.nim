## - `FormData` for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/FormData
when not defined(js):
  {.fatal: "Module jsformdata is designed to be used with the JavaScript backend.".}

type FormData* = ref object of JsRoot ## FormData API.

func newFormData*(): FormData {.importjs: "new FormData()".}

func add*(this: FormData; name: cstring; value: SomeNumber | bool | cstring) {.importjs: "#.append(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/append
  ## Duplicate keys are allowed and order is preserved.

func add*(this: FormData; name: cstring; value: SomeNumber | bool | cstring, filename: cstring) {.importjs: "#.append(#, #, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/append
  ## Duplicate keys are allowed and order is preserved.

func delete*(this: FormData; name: cstring) {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/delete
  ## Deletes *all items* with the same key name.

func getAll*(this: FormData; name: cstring): seq[cstring] {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/getAll

func hasKey*(this: FormData; name: cstring): bool {.importjs: "#.has(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/has

func keys*(this: FormData): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/keys

func values*(this: FormData): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/values

func pairs*(this: FormData): seq[tuple[key, val: cstring]] {.importjs: "Array.from(#.entries())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/entries

func put*(this: FormData; name, value, filename: cstring) {.importjs: "#.set(#, #, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/set

func `[]=`*(this: FormData; name, value: cstring) {.importjs: "#.set(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/set

func `[]`*(this: FormData; name: cstring): cstring {.importjs: "#.get(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/get

func clear*(this: FormData) {.importjs:
  "(() => { const frmdt = #; Array.from(frmdt.keys()).forEach((key) => frmdt.delete(key)) })()".}
  ## Convenience func to delete all items from `FormData`.


runnableExamples:
  if defined(fusionJsFormdataTests):
    let data: FormData = newFormData()
    data["key0"] = "value0".cstring
    data.add("key1".cstring, "value1".cstring)
    data.delete("key1")
    doAssert data.hasKey("key0")
    doAssert data["key0"] == "value0".cstring
    data.clear()
