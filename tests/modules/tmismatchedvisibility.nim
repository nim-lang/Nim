discard """
  errormsg: "public implementation 'tmismatchedvisibility.foo(a: int)' has non-public forward declaration at "
  line: 8
"""

proc foo(a: int): int

proc foo*(a: int): int =
  result = a + a
