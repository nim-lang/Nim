discard """
  output: '''
tlenvarargs.nim:35:9 (1, 2)
tlenvarargs.nim:36:9 12
tlenvarargs.nim:37:9 1
tlenvarargs.nim:38:8 
done
'''
"""
## line 10

template myecho*(a: varargs[untyped]) =
  ## shows a useful debugging echo-like proc that is dependency-free (no dependency
  ## on macros.nim) so can be used in more contexts
  const info = instantiationInfo(-1, false)
  const loc = info.filename & ":" & $info.line & ":" & $info.column & " "
  when lenVarargs(a) > 0:
    echo(loc, a)
  else:
    echo(loc)

template fun*(a: varargs[untyped]): untyped =
  lenVarargs(a)

template fun2*(a: varargs[typed]): untyped =
  a.lenVarargs

template fun3*(a: varargs[int]): untyped =
  a.lenVarargs

template fun4*(a: varargs[untyped]): untyped =
  len(a)

proc main()=
  myecho (1, 2)
  myecho 1, 2
  myecho 1
  myecho()

  doAssert fun() == 0
  doAssert fun('a') == 1
  doAssert fun("asdf", 1) == 2

  doAssert fun2() == 0
  doAssert fun2('a') == 1
  doAssert fun2("asdf", 1) == 2

  doAssert fun3() == 0
  doAssert fun3(10) == 1
  doAssert fun3(10, 11) == 2

  ## shows why `lenVarargs` can't be named `len`
  doAssert fun4("abcdef") == len("abcdef")

  ## workaround for BUG:D20191218T171447 whereby if testament expected output ends
  ## in space, testament strips it from expected output but not actual output,
  ## which leads to a mismatch when running test via megatest
  echo "done"
main()
