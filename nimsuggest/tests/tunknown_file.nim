discard """
$nimsuggest --tester $file
>def $path/fixtures/munknown_file.nim:4:6
def;;skProc;;munknown_file.greet;;*;;*fixtures/munknown_file.nim;;1;;5;;"";;100
>outline $path/fixtures/munknown_file.nim
outline;;skProc;;munknown_file.greet;;*;;*fixtures/munknown_file.nim;;1;;5;;"";;100
"""

proc unrelated(): int =
  42

echo unrelated()
