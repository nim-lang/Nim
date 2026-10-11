discard """
  output: '''
true
false
'''
"""

# bug #10609: an injected local with the name of a param of a second routine
template foo =
  proc bar1(x: bool) =
    var x {.inject.} = x
    echo x

  proc bar2(x: bool) =
    var x {.inject.} = x
    echo x

foo()
bar1(true)
bar2(false)
