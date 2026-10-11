# An import whose included file was edited after nimsuggest wrote its NIF is
# compiled from source again by the next nimsuggest instead of being loaded
# from the stale NIF.

import micinc

discard foo()

discard """
!copy fixtures/micinc_body_v1.nim micinc_body.nim
$nimsuggest --v3 --tester $file
>def $file:7:9
def;;skProc;;micinc.foo;;*;;*micinc_body.nim;;1;;5;;"";;100
!copy fixtures/micinc_body_v2.nim micinc_body.nim
!restart
>def $file:7:9
def;;skProc;;micinc.foo;;*;;*micinc_body.nim;;2;;5;;"";;100
!del micinc_body.nim
"""
