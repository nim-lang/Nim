proc `%%%`(a: int) = discard
proc `cast`() = discard
proc `gook1`(a: int) = discard
proc gook2(a: int) = discard
tsug_accquote.#[!]#

# ## foo # this would remove the bug
# nonexistant # this would remove the bug
# var bam = 123 # this would not remove the bug

discard """
$nimsuggest --tester $file
>sug $1
sug;;skProc;;tsug_accquote.`%%%`;;proc (a: int);;$file;;1;;5;;"";;100;;None
sug;;skProc;;tsug_accquote.`cast`;;proc ();;$file;;2;;5;;"";;100;;None
sug;;skProc;;tsug_accquote.gook1;;proc (a: int);;$file;;3;;5;;"";;100;;None
sug;;skProc;;tsug_accquote.gook2;;proc (a: int);;$file;;4;;5;;"";;100;;None
"""

#[
D20210427T164219:here un-commenting `foo` doc comment (or `nonexistant`) would
make this test pass even without the linked hack with `result = semIndirectOp(c, n, flags)`.

What happens is that after removing `cursorMarker`, the code nim sees is:
`tsug_accquote.discard """ ... """`
which then gets (without the hack) transformed into `result = errorNode(c, n)`

What's not clear is why `gook1`, `gook2` get listed in suggestions but not the other ones.
]#
