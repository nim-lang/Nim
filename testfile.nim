import macros, jsffi
{.emit: "/*HEADERSECTION*/import { x as x$$  } from './xaba'".}

# {.importjs: "%ID% = x$$"}

var
  x: seq[int]

{.emit: "%ID% = x$$".}