# tests v3 outline2: outline from the parse tree, without compiling

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

type Pure* {.pure.} = enum
  first = 1, second

proc `==`(x, y: Pure): bool = discard

proc withLocals() =
  const localConst = 1
  type LocalType = int
  func localFunc() = discard
  proc localProc() = discard

when defined(windows):
  proc onWindows() = discard
else:
  proc elsewhere() = discard

discard """
$nimsuggest --v3 --tester $file
>outline2 $file
outline	skType	tv3_outline2.Foo		$file	4	2	""	100	5	16
outline	skType	tv3_outline2.FooEnum		$file	6	2	""	100	6	31
outline	skEnumField	tv3_outline2.FooEnum.value1		$file	6	17	""	100	6	23
outline	skEnumField	tv3_outline2.FooEnum.value2		$file	6	25	""	100	6	31
outline	skType	tv3_outline2.FooPrivate		$file	7	2	""	100	8	22
outline	skMacro	tv3_outline2.m		$file	10	6	""	100	10	40
outline	skTemplate	tv3_outline2.t		$file	11	9	""	100	11	43
outline	skProc	tv3_outline2.p		$file	12	5	""	100	12	24
outline	skIterator	tv3_outline2.i		$file	13	9	""	100	13	27
outline	skConverter	tv3_outline2.c		$file	14	10	""	100	14	37
outline	skMethod	tv3_outline2.m		$file	15	7	""	100	15	32
outline	skFunc	tv3_outline2.f		$file	16	5	""	100	16	24
outline	skConst	tv3_outline2.con		$file	20	6	""	100	20	13
outline	skProc	tv3_outline2.outer		$file	22	5	""	100	23	24
outline	skProc	tv3_outline2.outer.inner		$file	23	7	""	100	23	24
outline	skProc	tv3_outline2.procWithLocal		$file	25	5	""	100	26	16
outline	skType	tv3_outline2.Pure		$file	28	5	""	100	29	19
outline	skEnumField	tv3_outline2.Pure.first		$file	29	2	""	100	29	7
outline	skEnumField	tv3_outline2.Pure.second		$file	29	13	""	100	29	19
outline	skProc	tv3_outline2.`==`		$file	31	5	""	100	31	37
outline	skProc	tv3_outline2.withLocals		$file	33	5	""	100	37	28
outline	skType	tv3_outline2.withLocals.LocalType		$file	35	7	""	100	35	22
outline	skProc	tv3_outline2.withLocals.localProc		$file	37	7	""	100	37	28
outline	skProc	tv3_outline2.onWindows		$file	40	7	""	100	40	28
outline	skProc	tv3_outline2.elsewhere		$file	42	7	""	100	42	28
"""
