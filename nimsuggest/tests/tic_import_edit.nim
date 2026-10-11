# An import edited after nimsuggest wrote its NIF is compiled from source again
# by the next nimsuggest instead of being loaded from the stale NIF.

import micdep

discard foo()

discard """
!copy fixtures/micdep_v1.nim micdep.nim
$nimsuggest --v3 --tester $file
>def $file:6:9
def;;skProc;;micdep.foo;;*;;*micdep.nim;;1;;5;;"";;100
!copy fixtures/micdep_v2.nim micdep.nim
!restart
>def $file:6:9
def;;skProc;;micdep.foo;;*;;*micdep.nim;;2;;5;;"";;100
!del micdep.nim
"""
