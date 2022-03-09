## - `FormData` for the JavaScript target: https://developer.mozilla.org/en-US/docs/Web/API/FormData
when not defined(js):
  {.fatal: "Module jsformdata is designed to be used with the JavaScript backend.".}

type FormData* = ref object of JsRoot ## FormData API.

func newFormData*(): FormData {.importjs: "new FormData()".}

func add*(self: FormData; name: cstring; value: SomeNumber | bool | cstring) {.importjs: "#.append(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/append
  ## Duplicate keys are allowed and order is preserved.

func add*(self: FormData; name: cstring; value: SomeNumber | bool | cstring, filename: cstring) {.importjs: "#.append(#, #, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/append
  ## Duplicate keys are allowed and order is preserved.

func delete*(self: FormData; name: cstring) {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/delete
  ##
  ## .. warning:: Deletes *all items* with the same key name.

func getAll*(self: FormData; name: cstring): seq[cstring] {.importjs: "#.$1(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/getAll

func hasKey*(self: FormData; name: cstring): bool {.importjs: "#.has(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/has

func keys*(self: FormData): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/keys

func values*(self: FormData): seq[cstring] {.importjs: "Array.from(#.$1())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/values

func pairs*(self: FormData): seq[tuple[key, val: cstring]] {.importjs: "Array.from(#.entries())".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/entries

func put*(self: FormData; name, value, filename: cstring) {.importjs: "#.set(#, #, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/set

func `[]=`*(self: FormData; name, value: cstring) {.importjs: "#.set(#, #)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/set

func `[]`*(self: FormData; name: cstring): cstring {.importjs: "#.get(#)".}
  ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/get

func clear*(self: FormData) {.importjs:
  "(() => { const frmdt = #; Array.from(frmdt.keys()).forEach((key) => frmdt.delete(key)) })()".}
  ## Convenience func to delete all items from `FormData`.

func toCstring*(self: FormData): cstring {.importjs: "JSON.stringify(#)".}

func `$`*(self: FormData): string = $toCstring(self)

func len*(self: FormData): int {.importjs: "Array.from(#.entries()).length".}


runnableExamples("-r:off"):
  let data: FormData = newFormData()
  data["key0"] = "value0".cstring
  data.add("key1".cstring, "value1".cstring)
  data.delete("key1")
  assert data.hasKey("key0")
  assert data["key0"] == "value0".cstring
  data.clear()
  assert data.len == 0
