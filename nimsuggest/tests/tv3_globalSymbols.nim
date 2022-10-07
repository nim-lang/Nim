# Tests the order of the matches
proc Btoken(): int = 5
proc tokenA(): int = 5
proc token(): int = 5
proc BBtokenA(): int = 5

discard """
$nimsuggest --v3 --tester $file
>globalSymbols token
def	skProc	tv3_globalSymbols.token	proc (): int{.noSideEffect, gcsafe, locks: 0.}	$file	4	5	""	100
def	skProc	tv3_globalSymbols.tokenA	proc (): int{.noSideEffect, gcsafe, locks: 0.}	$file	3	5	""	100
def	skProc	tv3_globalSymbols.Btoken	proc (): int{.noSideEffect, gcsafe, locks: 0.}	$file	2	5	""	100
def	skProc	tv3_globalSymbols.BBtokenA	proc (): int{.noSideEffect, gcsafe, locks: 0.}	$file	5	5	""	100
"""
