# Hello world program

import macros, strutils

{. noforward: on .}

proc hola(x: int) =
  echo "HOLA"
  comuEsta(x)

proc comuEsta(x: int) =
  echo "COMU ESTA"
  echo x

hola(10)

