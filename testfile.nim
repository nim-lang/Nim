import macros, jsffi
{.emit: "/*HEADERSECTION*/import { x as x$$  } from './xaba'".}

var
  x: seq[int]

{.emit: "%ID% = x$$".}