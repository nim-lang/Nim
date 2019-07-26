discard """
output: '''
123
'''
"""

# issue #11812

proc run(a: proc()) = a()

proc main() =
  var test: int
  run(proc() = test = 0)
  run do:
    test = 0

main()


# issue #10899

proc foo(x: proc {.closure.}) =
  x()

proc bar =
  var x = 123
  # foo proc = echo x     #[ ok ]#
  foo: echo x             #[ SIGSEGV: Illegal storage access. (Attempt to read from nil?) ]#

bar()
