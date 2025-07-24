proc fn(a: static float) = discard
proc fn(a: int) = discard

let x = 1
fn(x)

discard """
$nimsuggest --tester --v3 $file
>chk $file
chk;;skUnknown;;;;Hint;;*
"""
