discard """
  line: 8
  errormsg: "public implementation 'tmismatchedvisibility.foo(a: int)' has non-public forward declaration in "
"""

proc foo(a: int): int

proc foo*(a: int): int =
  result = a + a
