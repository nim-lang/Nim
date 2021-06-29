template foo() =
  {.warning: "foo".}
  
foo()

#[!]#
discard """
$nimsuggest --tester $file
>chk $1
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import(dirty): tests/ttempl_inst.nim [Processing]";;0
chk;;skUnknown;;;;Hint;;$file;;4;;3;;"template/generic instantiation from here";;0
chk;;skUnknown;;;;Warning;;$file;;2;;11;;"foo [User]";;0
"""
