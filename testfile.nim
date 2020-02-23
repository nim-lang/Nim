import macros, jsffi
{.emit: "/*HEADERSECTION*/import { x as x$$  } from './aba'".}

var
  x {.importjs: "$ID = x$$".}: JsObject
