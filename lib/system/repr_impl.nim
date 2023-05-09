#[
other APIs common to system/repr and system/reprjs could be refactored here, eg:
* reprChar
* reprBool
* reprStr

Another possibility in future work would be to have a single include file instead
of system/repr and system/reprjs, and use `when defined(js)` inside it.
]#

proc reprDiscriminant*(e: int, typ: PNimType): string {.compilerRtl.} =
  case typ.kind
  of tyEnum: reprEnum(e, typ)
  of tyBool: $(e != 0)
  else: $e
