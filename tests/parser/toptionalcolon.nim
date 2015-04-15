#! optionalColon

if 1 + 1 + # some comment
   1 > 2
   echo "1+1+1>2"
else
   echo "1+1+1<=2"

if 1 + 1 > 2: echo "1+1>2"
else # else? what else?
  echo "1+1<=2"

if 1 + 1 + 1 > 2
  echo "1+1+1>2" # this seem to be true
else: echo "1+1+1<=2"

let v = 3
case v
  of 1
    echo "one"
  of 2
    echo "two"
  else
    echo "other"

try
  let m = 1+1
except
  echo "what happened!?"
finally
  echo "finally!"
