## Test Invocation `con`text in various situations

## various of this proc are used as the basis for these tests
proc test(s: string; a: int) = discard

## This overload should be used to ensure the lower airity `test` doesn't match
proc test(s: string; a: string, b: int) = discard

## similar signature but different name to ensure `con` doesn't get greedy
proc testB(a, b: string) = discard

# with a param already specified
test("hello here", #[!]#)

# as first param
testB(#[!]#

# dot expressions
"from behind".test(#[!]#

# two params matched, so disqualify the lower airity `test`
# TODO: this doesn't work, because dot exprs, overloads, etc aren't currently
#       handled by suggest.suggestCall. sigmatch.partialMatch by way of
#       sigmatch.matchesAux. Doesn't use the operand before the dot as part of
#       the formal parameters. Changing this is tricky because it's used by
#       the proper compilation sem pass and that's a big change all in one go.
"and again".test("more", #[!]#


discard """
$nimsuggest --tester $file
>con $1
con;;skProc;;tcon1.test;;proc (s: string, a: int);;$file;;4;;5;;"";;100
con;;skProc;;tcon1.test;;proc (s: string, a: string, b: int);;$file;;7;;5;;"";;100
>con $2
con;;skProc;;tcon1.testB;;proc (a: string, b: string);;$file;;10;;5;;"";;100
>con $3
con;;skProc;;tcon1.test;;proc (s: string, a: string, b: int);;$file;;7;;5;;"";;100
con;;skProc;;tcon1.test;;proc (s: string, a: int);;$file;;4;;5;;"";;100
>con $4
con;;skProc;;tcon1.test;;proc (s: string, a: int);;$file;;4;;5;;"";;100
con;;skProc;;tcon1.test;;proc (s: string, a: string, b: int);;$file;;7;;5;;"";;100
"""
