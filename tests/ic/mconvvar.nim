type
  Box* = object
    val*: int

converter toVarInt*(b: var Box): var int = b.val
