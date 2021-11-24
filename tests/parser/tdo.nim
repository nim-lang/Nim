discard """
  output: '''
true
true
true
true inner B
running with pragma
ran with pragma
'''
"""

template withValue(a, b, c, d, e: untyped) =
  if c:
    d
  else:
    e

template withValue(a, b, c, d: untyped) =
  if c:
    d

const
  EVENT_READ = 1
  EVENT_WRITE = 2
  FLAG_HANDLE = 3
  EVENT_MASK = 3

var s: string

proc main =
  var value = false
  var fd = 8888
  var event = 0
  s.withValue(fd, value) do:
    if value:
      var oe = (EVENT_MASK)
      if (oe xor event) != 0:
        if (oe and EVENT_READ) != 0 and (event and EVENT_READ) == 0:
          discard
        if (oe and EVENT_WRITE) != 0 and (event and EVENT_WRITE) == 0:
          discard
        if (oe and EVENT_READ) == 0 and (event and EVENT_READ) != 0:
          discard
        if (oe and EVENT_WRITE) == 0 and (event and EVENT_WRITE) != 0:
          discard
    else:
      raise newException(ValueError, "error")
  do:
    raise newException(ValueError, "Descriptor is not registered in queue")

proc main2 =
  var unused = 8
  # test 'then' branch:
  s.withValue(unused, true) do:
    echo "true"
  do:
    echo "false"

  # test overloading:
  s.withValue(unused, false) do:
    echo "cannot come here"

  # test 'else' branch:
  s.withValue(unused, false) do:
    echo "false"
  do:
    echo "true"

  # test proper nesting:
  s.withValue(unused, false) do:
    echo "false"
    s.withValue(unused, false) do:
      echo "false inner A"
    do:
      echo "true inner A"
  do:
    echo "true"
    s.withValue(unused, false) do:
      echo "false inner B"
    do:
      echo "true inner B"

main2()

proc withPragma(foo: int, bar: proc() {.raises: [].}) =
  echo "running with pragma"
  bar()

withPragma(3) do {.raises: [].}:
  echo "ran with pragma"

doAssert not (compiles do:
  withPragma(3) do {.raises: [].}:
    raise newException(Exception))
