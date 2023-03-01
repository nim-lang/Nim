discard """
  action: "compile"
"""

proc test(a: openArray[string]): proc =
  result = proc =
    for i in a:
      discard i


const a = ["t1", "t2"]

discard test(a)

