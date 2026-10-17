# nimsuggest2 runs `nim ns` from any query once a file its last run read was
# saved after that run (a branch switch, an edit outside the editor), without a
# `changed`: `known` must then see the module that only the new `ns2dep` imports.

import ns2dep

discard depValue()

discard """
$nimsuggest2 $file
!copy fixtures/mns2dep_v1.nim ns2dep.nim
>changed $file
>known $path/ns2extra.nim
false
!copy fixtures/mns2extra.nim ns2extra.nim
!copy fixtures/mns2dep_v2.nim ns2dep.nim
>known $path/ns2extra.nim
true
!del ns2dep.nim
!del ns2extra.nim
"""
