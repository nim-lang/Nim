#[
helper module to add nodejs support to std/os
Experimental module, unstable API
]#

when false:
  # This could alternatively be turned into an import module; it would require
  # a minor edit in vmops.nim so that `wrap2s(getEnv, osop)` points to this module
  # instead of `os`.
  static: doAssert defined(nodejs) and defined(js)
  from os import ReadEnvEffect, WriteEnvEffect # cyclic but works
else:
  when not declared(os):
    {.error: "This is an include file for os.nim!".}

proc getEnv*(key: string, default = ""): TaintedString {.tags: [ReadEnvEffect].} =
  var ret: cstring
  let key2 = key.cstring
  {.emit: "`ret` = process.env[`key2`];".}
  result = $ret

proc existsEnv*(key: string): bool {.tags: [ReadEnvEffect].} =
  var key2 = key.cstring
  var ret: bool
  {.emit: "`ret` = `key2` in process.env;".}
  result = ret

proc putEnv*(key, val: string) {.tags: [WriteEnvEffect].} =
  var key2 = key.cstring
  var val2 = val.cstring
  {.emit: "process.env[`key2`] = `val2`;".}

proc delEnv*(key: string) {.tags: [WriteEnvEffect].} =
  var key2 = key.cstring
  {.emit: "delete process.env[`key2`];".}

iterator envPairs*(): tuple[key, value: TaintedString] {.tags: [ReadEnvEffect].} =
  var num: int
  var keys: RootObj
  {.emit: "`keys` = Object.keys(process.env); `num` = `keys`.length;".}
  for i in 0..<num:
    var key, value: cstring
    {.emit: "`key` = `keys`[`i`]; `value` = process.env[`key`];".}
    yield ($key, $value)
