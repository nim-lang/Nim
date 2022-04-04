# test we get some suggestion at the end of the file







type


template foo() =

proc main =

#[!]#
discard """
$nimsuggest --tester $file
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import(dirty): tests/tchk1.nim [Processing]";;0
chk;;skUnknown;;;;Error;;$file;;12;;0;;"identifier expected, but got \'keyword template\'";;0
chk;;skUnknown;;;;Error;;$file;;14;;0;;"nestable statement requires indentation";;0
chk;;skUnknown;;;;Error;;$file;;12;;0;;"implementation of \'foo\' expected";;0
chk;;skUnknown;;;;Error;;$file;;17;;0;;"invalid indentation";;0
chk;;skUnknown;;;;Hint;;$file;;12;;9;;"\'foo\' is declared but not used [XDeclaredButNotUsed]";;0
chk;;skUnknown;;;;Hint;;$file;;14;;5;;"\'main\' is declared but not used [XDeclaredButNotUsed]";;0
"""
