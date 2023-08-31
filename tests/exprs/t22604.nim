
for i in 0..<1:
  # propagation to case of
  let x =
    case false
    of true:
      42
    of false:
      if true:
        continue
      else:
        raiseAssert "Won't get here"

for i in 0..<1:
  # propagation to block
  let y =
    case false
    of true:
      42
    of false:
      block:
        if true:
          continue
        else:
          raiseAssert "Won't get here"
