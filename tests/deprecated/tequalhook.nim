discard """
  errormsg: "Overriding `=` hook is deprecated; Override `=copy` hook instead"
  matrix: "--warningAsError[Deprecated]:on"
"""

type
  SharedString = object
    data: string

proc `=`(x: var SharedString, y: SharedString) =
  discard