#[
other APIs common to system/repr and system/reprjs could be refactored here, eg:
* reprChar
* reprBool
* reprStr
]#

proc reprDiscriminant*(e: int, typ: PNimType): string {.compilerRtl.} =
  case typ.kind
  of tyEnum: reprEnum(e, typ)
  of tyBool: (if e == 0: "false" else: "true")
  else: $e
