{.experimental: "sumTypes".}
type
  Res* = object
    case
    of None: discard     # also a branch of `msumtypes.Opt`
    of Ok: code*: int
