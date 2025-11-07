discard """
  action: reject
  nimout: '''
tforwardraises.nim(15, 14) Hint: n is a forward declaration without explicit .raises, assuming it can raise anything [UnknownRaises]
tforwardraises.nim(14, 26) template/generic instantiation from here
tforwardraises.nim(15, 14) Error: n(0) can raise an unlisted exception: Exception
'''
"""

# issue #24766

proc n(_: int)

proc s(_: int) {.raises: [CatchableError].} =
  if false: n(0)

proc n(_: int) = s(0)
