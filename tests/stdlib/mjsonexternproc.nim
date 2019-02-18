# Test case for https://github.com/nim-lang/Nim/issues/6385
# extended for test case https://github.com/nim-lang/Nim/issues/10700

import json
# export json

proc foo*[T](a: T) =
  let params = %*{
    "data": [ 1 ],
    "someNaN": NaN,
    "someInf": Inf,
    "someNegInf": -Inf,
  }
  echo $params
