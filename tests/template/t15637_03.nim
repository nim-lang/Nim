discard """
  action: reject
"""

# issue #15637

proc newString(data: int): int = 
  result = data

template addObject(s: int): untyped =
  discard s
  s

proc slice() =
  let obj = addObject(newString((var intval = 5; intval)))

slice()
