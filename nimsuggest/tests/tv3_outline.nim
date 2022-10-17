# tests v3 outline

type
  Foo* = ref object of RootObj
    bar*: string
  FooEnum = enum value1, value2
  FooPrivate = ref object of RootObj
    barPrivate: string

macro m(arg: untyped): untyped = discard
template t(arg: untyped): untyped = discard
proc p(): void = discard
iterator i(): int = discard
converter c(s: string): int = discard
method m(f: Foo): void = discard
func f(): void = discard

let a = 1
var b = 2
const con = 2

proc outer(): void =
  proc inner() = discard

proc procWithLocal(): void =
  let local = 10

discard """
$nimsuggest --v3 --tester $file
>outline $file
outline	skType	tv3.Foo	Foo	$file	4	2	""	100	5	16
outline	skType	tv3.FooEnum	FooEnum	$file	6	2	""	100	6	31
outline	skEnumField	tv3.FooEnum.value1	FooEnum	$file	6	17	""	100	6	23
outline	skEnumField	tv3.FooEnum.value2	FooEnum	$file	6	25	""	100	6	31
outline	skType	tv3.FooPrivate	FooPrivate	$file	7	2	""	100	8	22
outline	skMacro	tv3.m	macro (arg: untyped): untyped{.noSideEffect, gcsafe, locks: 0.}	$file	10	6	""	100	10	40
outline	skTemplate	tv3.t	template (arg: untyped): untyped	$file	11	9	""	100	11	43
outline	skProc	tv3.p	proc (){.noSideEffect, gcsafe, locks: 0.}	$file	12	5	""	100	12	24
outline	skConverter	tv3.c	converter (s: string): int{.noSideEffect, gcsafe, locks: 0.}	$file	14	10	""	100	14	37
outline	skFunc	tv3.f	proc (){.noSideEffect, gcsafe, locks: 0.}	$file	16	5	""	100	16	24
outline	skConst	tv3.con	int literal(2)	$file	20	6	""	100	20	13
outline	skProc	tv3.outer	proc (){.noSideEffect, gcsafe, locks: 0.}	$file	22	5	""	100	23	24
outline	skProc	tv3.outer.inner	proc (){.noSideEffect, gcsafe, locks: 0.}	$file	23	7	""	100	23	24
outline	skProc	tv3.procWithLocal	proc (){.noSideEffect, gcsafe, locks: 0.}	$file	25	5	""	100	26	16
"""
