discard """
  action: "compile"
"""
import sugar


block:
  let y = @[@[1, 2], @[2, 4, 6]]
  let x = collect(newSeq):
    for i in y:
      if i.len > 2:
        for j in i:
          j
  echo(x)

block:
  let y = @[@[1, 2], @[2, 4, 6]]
  let x = collect(newSeq):
    for i in y:
      for j in i:
        if i.len > 2:
          j
  echo(x)
