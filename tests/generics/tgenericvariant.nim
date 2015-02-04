type
  TMaybe[T] = object
    case empty: bool
    of false: value: T
    else: nil

proc Just*[T](val: T): TMaybe[T] =
  result.empty = false
  result.value = val

proc Nothing[T](): TMaybe[T] =
  result.empty = true

proc safeReadLine(): TMaybe[string] =
  var r = stdin.readLine()
  if r == "": return Nothing[string]()
  else: return Just(r)

when isMainModule:
  var Test = Just("Test")
  echo(Test.value)
  var mSomething = safeReadLine()
  echo(mSomething.value)
