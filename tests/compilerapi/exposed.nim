const overrideMsg = "implementation overridden by tcompilerapi.nim"

proc addFloats*(x, y, z: float): float =
  discard overrideMsg

proc suspend*() =
  discard overrideMsg
