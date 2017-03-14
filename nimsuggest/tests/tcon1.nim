proc test(s: string; a: int) = discard
proc testB(a, b: string) = discard
test("hello here", #[!]#)
testB(#[!]#


discard """
$nimsuggest --tester $file
>con $1
con;;skProc;;tcon1.test;;proc (s: string, a: int);;$file;;1;;5;;"";;100
>con $2
con;;skProc;;tcon1.testB;;proc (a: string, b: string);;$file;;2;;5;;"";;100
"""
