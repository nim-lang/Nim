# Helper for texpfield.nim: an object with an exported field, accessed from a
# generic in another module — the nimbus `r.ttl` / protobuf.Register case.

type
  Rec* = object
    ttl*: int

proc makeRec*(t: int): Rec = Rec(ttl: t)
