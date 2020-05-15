# #14350
var cstr: cstring
doAssert cstr == cstring(nil)
doAssert cstr.isNil
doAssert cstr != cstring("")
