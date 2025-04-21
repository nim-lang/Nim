discard """
  errormsg: "illegal recursion in type 'Test"
  line: 9
"""

# issue #18855

type
  TestProc = proc(a: Test)
  Test = Test
