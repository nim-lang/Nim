
# propagation to case of
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

# propagation to block
for i in 0..<1:
  let x =
    case false
    of true:
      42
    of false:
      block:
        if true:
          continue
        else:
          raiseAssert "Won't get here"
