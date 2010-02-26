# All and any

template all(container, cond: expr): expr =
  block:
    var result = true
    for item in items(container):
      if not cond(item):
        result = false
        break
    result

if all("mystring", {'a'..'z'}.contains): 
  echo "works"
else: 
  echo "does not work"


