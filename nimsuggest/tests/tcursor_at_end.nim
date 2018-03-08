# test we get some suggestion at the end of the file

discard """
$nimsuggest --tester $file
>sug $1
sug;;skProc;;tcursor_at_end.main;;proc ();;$file;;10;;5;;"";;*
"""


proc main = discard

#[!]#
