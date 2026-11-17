discard """
  output: '''
123
123
'''
"""

# bug #12875: a parenthesis-free template call inside a nested template
template foo*(): untyped = 123
proc main()=
  template fun2()=
    echo foo()
    echo foo
    doAssert foo == 123
  fun2()
main()
