const
  VERSION_STR1* = "0.5.0" ## Idetools shifts this one column.
  VERSION_STR2 = "0.5.0" ## This one is ok.
  VERSION_STR3* = "0.5.0" ## Bad.
  VERSION_STR4 = "0.5.0" ## Ok.

proc forward1*(): string = result = ""
proc forward2(): string = result = ""
