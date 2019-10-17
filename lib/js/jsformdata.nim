#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
## Wrapper for the `FormData` object for the `JavaScript backend
## <backends.html#the-javascript-target>`_.
when not defined(js) and not defined(Nimdoc): {.error: "This module only works on the JavaScript platform".}


type FormData* {.importcpp: "FormData".} = ref object ## https://developer.mozilla.org/en-US/docs/Web/API/FormData

proc newFormData*(): FormData {.importcpp: "(new FormData())".} ## Constructor for a new FormData.

proc append*(formData: FormData, name: cstring, value: cstring|bool|SomeNumber, filename = "".cstring) {.importcpp: "append".} ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/append

proc delete*(formData: FormData, name: cstring) {.importcpp: "delete".} ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/delete

proc get*(formData: FormData, name: cstring): cstring {.importcpp: "get".} ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/get

proc getAll*(formData: FormData, name: cstring): seq[cstring] {.importcpp: "getAll".} ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/getAll

proc has*(formData: FormData, name: cstring): bool {.importcpp: "has".} ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/has

proc set*(formData: FormData, name: cstring, value: cstring, filename = "".cstring) {.importcpp: "set".} ## https://developer.mozilla.org/en-US/docs/Web/API/FormData/set


runnableExamples:
  let data = newFormData()
  data.set("key", "value".cstring)
  data.append("key2", "value2".cstring)
  data.delete("key2")
  discard data.has("key")
  discard data.get("key")
  assert data.has("key") == true
  assert data.get("key") == "value"
