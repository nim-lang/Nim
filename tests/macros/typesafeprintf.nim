discard """
  output: '''test 10'''
"""

# bug #1152

import macros, typetraits
proc printfImpl(formatstr: cstring) {.importc: "printf", varargs.}

iterator tokenize(format: string): char =
  var i = 0
  while i < format.len:
    case format[i]
    of '%':
      case format[i+1]
      of '\0': break
      else: yield format[i+1]
      i.inc
    of '\0': break
    else: discard
    i.inc

macro printf(formatString: string{lit}, args: varargs[typed]): untyped =
  var i = 0
  let err = getType(bindSym"ValueError")
  for c in tokenize(formatString.strVal):
    var expectedType = case c
      of 'c': getType(bindSym"char")
      of 'd', 'i', 'x', 'X': getType(bindSym"int")
      of 'f', 'e', 'E', 'g', 'G': getType(bindSym"float")
      of 's': getType(bindSym"string")
      of 'p': getType(bindSym"pointer")
      else: err

    var actualType = getType(args[i])
    inc i

    if sameType(expectedType, err):
      error c & " is not a valid format character"
    elif not sameType(expectedType, actualType):
      error "type mismatch for argument " & $i & ". expected type: " &
            $expectedType & ", actual type: " & $actualType

  # keep the original callsite, but use cprintf instead
  result = newCall(bindSym"printfImpl")
  result.add formatString
  for a in args: result.add a

printf("test %d\n", 10)
