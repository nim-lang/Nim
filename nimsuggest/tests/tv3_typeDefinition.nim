# tests v3

type
  Foo* = ref object of RootObj
    bar*: string

proc test(ff: Foo) =
  echo f#[!]#f.bar

type
  Fo#[!]#o2* = ref object of RootObj

type
  FooGeneric[T] = ref object of RootObj
    bar*: T

let fooGeneric = FooGeneric[string]()
echo fo#[!]#oGeneric.bar

# bad type
echo unde#[!]#fined

discard """
$nimsuggest --v3 --tester $file
>type $1
type	skType	tv3_typeDefinition.Foo	Foo	$file	4	2	""	100
>type $2
type	skType	tv3_typeDefinition.Foo2	Foo2	$file	11	2	""	100
>type $3
type	skType	tv3_typeDefinition.FooGeneric	FooGeneric	$file	14	2	""	100
>type $4
"""
