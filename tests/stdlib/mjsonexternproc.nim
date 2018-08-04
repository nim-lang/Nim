# Test case for https://github.com/nim-lang/Nim/issues/6385

import json
# export json

proc foo*[T](a: T) =
  let params = %*{
    "data": [ 1 ]
  }
  echo $params