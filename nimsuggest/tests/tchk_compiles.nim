discard compiles(2 + "hello")

#[!]#
discard """
$nimsuggest --tester $file
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;"tchk_compiles [Processing]";;0
"""
