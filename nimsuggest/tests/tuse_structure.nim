# tests for use and structures

type
  Foo* = ref object of RootObj
    bar*: string

proc test(f: Foo) =
  echo f.#[!]#bar

discard """
$nimsuggest --tester $file
>use $1
def	skField	tuse_structure.Foo.bar	string	$file	5	4	""	100
use	skField	tuse_structure.Foo.bar	string	$file	8	9	""	100
"""
