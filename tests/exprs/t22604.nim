# if
for i in 0..<1:
  let x =
    case false
    of true:
      42
    of false:
      if true:
        continue
      else:
        raiseAssert "Won't get here"

# nested case
for i in 0..<1:
  let x =
    case false
    of true:
      42
    of false:
      case true
      of true:
        continue
      of false:
        raiseAssert "Won't get here"

# try except
for i in 0..<1:
  let x =
    case false
    of true:
      42
    of false:
      try:
        continue
      except:
        raiseAssert "Won't get here"