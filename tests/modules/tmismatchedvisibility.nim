discard """
  line: 8
  errormsg: "public implementation 'tmismatchedvisibility.foo(a: int): int' has non-public forward declaration in tmismatchedvisibility.nim(6,5)"
"""

proc foo(a: int): int

proc foo*(a: int): int =
  result = a + a