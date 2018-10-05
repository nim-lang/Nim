discard """
  output: '''
true
true
true
'''
"""

when true:
  # Error: undeclared identifier: '|'
  proc bar[T](t:T): bool =
    runnableExamples:
      type Foo = int | float
    true
  echo bar(0)

when true:
  # ok
  proc bar(t:int): bool =
    runnableExamples:
      type Foo = int | float
    true
  echo bar(0)

when true:
  # Error: undeclared identifier: '|'
  proc bar(t:typedesc): bool =
    runnableExamples:
      type Foo = int | float
    true
  echo bar(int)
