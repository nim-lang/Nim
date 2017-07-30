discard """
  line: 8
  errormsg: "public implementation 'tmismatchedvisibility.foo(a: int)[declared in tmismatchedvisibility.nim(6, 5)]' has non-public forward declaration in "
"""

proc foo(a: int): int

proc foo*(a: int): int =
  result = a + a
