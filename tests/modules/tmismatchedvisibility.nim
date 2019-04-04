discard """
  errormsg: "public implementation 'tmismatchedvisibility.foo(a: int) [declared in tmismatchedvisibility.nim(6, 6)]' has non-public forward declaration in "
  line: 8
"""

proc foo(a: int): int

proc foo*(a: int): int =
  result = a + a
