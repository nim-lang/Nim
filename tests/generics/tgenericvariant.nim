type  
  TMaybe[T] = object
    case empty: Bool
    of False: value: T
    else: nil

proc Just*[T](val: T): TMaybe[T] =
  result.empty = False
  result.value = val

proc Nothing[T](): TMaybe[T] =
  result.empty = True

proc safeReadLine(): TMaybe[string] =
  var r = stdin.readLine()
  if r == "": return Nothing[string]()
  else: return Just(r)

when isMainModule:
  var Test = Just("Test")
  echo(Test.value)
  var mSomething = safeReadLine()
  echo(mSomething.value)
