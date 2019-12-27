# test we get some suggestion at the end of the file







type


template foo() =

proc main =

#[!]#
discard """
disabled:true
$nimsuggest --tester $file
>chk $1
chk;;skUnknown;;;;Hint;;???;;-1;;-1;;"tchk1 [Processing]";;0
chk;;skUnknown;;;;Error;;$file;;12;;0;;"identifier expected, but found \'keyword template\'";;0
chk;;skUnknown;;;;Error;;$file;;14;;0;;"complex statement requires indentation";;0
chk;;skUnknown;;;;Error;;$file;;12;;0;;"implementation of \'foo\' expected";;0
chk;;skUnknown;;;;Error;;$file;;17;;0;;"invalid indentation";;0
chk;;skUnknown;;;;Hint;;$file;;12;;9;;"\'foo\' is declared but not used [XDeclaredButNotUsed]";;0
chk;;skUnknown;;;;Hint;;$file;;14;;5;;"\'tchk1.main()[declared in tchk1.nim(14, 5)]\' is declared but not used [XDeclaredButNotUsed]";;0
"""
