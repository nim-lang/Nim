# `nimsuggest` is defined both for the NIFs `nim ns` builds and for the modules
# a query compiles from source: a dirty buffer using a field `mns2nsdef` (loaded
# from its NIF) declares under `when defined(nimsuggest)` compiles.

import mns2nsdef

proc get*(o: Obj): int =
  when defined(nimsuggest):
    o.b
  else:
    o.a

discard """
$nimsuggest2 $file
>changed $file
>chkFile $file;$file:0:0
>quit
"""
