discard """
  targets: "c cpp"
"""

# bug #19094
type
  X = object
    filler: array[2048, int]
    innerAddress: uint

proc initX(): X =
  result.innerAddress = cast[uint](result.addr)

proc initXInPlace(x: var X) =
  x.innerAddress = cast[uint](x.addr)

block: # NRVO1
  var x = initX()
  let innerAddress = x.innerAddress
  let outerAddress = cast[uint](x.addr)
  doAssert(innerAddress == outerAddress) # [OK]

block: # NRVO2
  var x: X
  initXInPlace(x)
  let innerAddress = x.innerAddress
  let outerAddress = cast[uint](x.addr)
  doAssert(innerAddress == outerAddress) # [OK]
