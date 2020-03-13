discard """
  errormsg: "recursion is not supported in iterators: 'myrec'"
  file: "treciter.nim"
  line: 9
"""
# Test that an error message occurs for a recursive iterator

iterator myrec(n: int): int =
  for x in myrec(n-1): #ERROR_MSG recursive dependency: 'myrec'
    yield x

for x in myrec(10): echo x
