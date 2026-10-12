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

type
  Gen*[T] = object
    val: T
  Variant = object
    case kind: bool
    of true: x: int
    of false: y: string
  Valued = enum
    v1 = (1, "one"), v2 = "two", v3

proc exportedPragma*() {.inline.} = discard
proc `$`*(x: Gen[int]): string = discard
proc `[]`(x: Gen[int]; i: int): int = discard
proc `[]=`(x: var Gen[int]; i, v: int) = discard
proc `addr`(x: int) = discard
proc `foo bar`() = discard
template `!!`(x: untyped): untyped = x

proc lvl1() =
  proc lvl2() =
    proc lvl3() = discard

proc localKinds() =
  iterator localIter(): int = discard
  template localTmpl() = discard
  macro localMacro() = discard
  converter localConv(x: float): int = discard
  method localMethod(x: int) = discard
  type LocalEnum = enum le1, le2

let lam = proc () =
  proc inLambda() = discard

const
  c1 = 1
  c2* = 2

block:
  proc inBlock() = discard

static:
  proc inStatic() = discard

proc fwd()
proc fwd() = discard

proc semError(): int = undefinedIdent

import fixtures/minclude_import

proc unclosed(x: int =
  discard

proc afterSyntaxError() = discard

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
outline	skType	tv3_outline2.Gen		$file	45	2	""	100	46	10
outline	skType	tv3_outline2.Variant		$file	47	2	""	100	50	23
outline	skType	tv3_outline2.Valued		$file	51	2	""	100	52	35
outline	skEnumField	tv3_outline2.Valued.v1		$file	52	4	""	100	52	6
outline	skEnumField	tv3_outline2.Valued.v2		$file	52	21	""	100	52	23
outline	skEnumField	tv3_outline2.Valued.v3		$file	52	33	""	100	52	35
outline	skProc	tv3_outline2.exportedPragma		$file	54	5	""	100	54	43
outline	skProc	tv3_outline2.`$$`		$file	55	5	""	100	55	40
outline	skProc	tv3_outline2.`[]`		$file	56	5	""	100	56	45
outline	skProc	tv3_outline2.`[]=`		$file	57	5	""	100	57	48
outline	skProc	tv3_outline2.`addr`		$file	58	5	""	100	58	29
outline	skProc	tv3_outline2.foobar		$file	59	5	""	100	59	26
outline	skTemplate	tv3_outline2.`!!`		$file	60	9	""	100	60	38
outline	skProc	tv3_outline2.lvl1		$file	62	5	""	100	64	25
outline	skProc	tv3_outline2.lvl1.lvl2		$file	63	7	""	100	64	25
outline	skProc	lvl1.lvl2.lvl3		$file	64	9	""	100	64	25
outline	skProc	tv3_outline2.localKinds		$file	66	5	""	100	72	32
outline	skIterator	tv3_outline2.localKinds.localIter		$file	67	11	""	100	67	37
outline	skTemplate	tv3_outline2.localKinds.localTmpl		$file	68	11	""	100	68	32
outline	skMethod	tv3_outline2.localKinds.localMethod		$file	71	9	""	100	71	38
outline	skType	tv3_outline2.localKinds.LocalEnum		$file	72	7	""	100	72	32
outline	skEnumField	localKinds.LocalEnum.le1		$file	72	24	""	100	72	27
outline	skEnumField	localKinds.LocalEnum.le2		$file	72	29	""	100	72	32
outline	skProc	tv3_outline2.inLambda		$file	75	7	""	100	75	27
outline	skConst	tv3_outline2.c1		$file	78	2	""	100	78	8
outline	skConst	tv3_outline2.c2		$file	79	2	""	100	79	9
outline	skProc	tv3_outline2.inBlock		$file	82	7	""	100	82	26
outline	skProc	tv3_outline2.inStatic		$file	85	7	""	100	85	27
outline	skProc	tv3_outline2.fwd		$file	87	5	""	100	87	10
outline	skProc	tv3_outline2.fwd		$file	88	5	""	100	88	20
outline	skProc	tv3_outline2.semError		$file	90	5	""	100	90	37
outline	skProc	tv3_outline2.unclosed		$file	94	5	""	100	95	9
outline	skProc	tv3_outline2.afterSyntaxError		$file	97	5	""	100	97	33
>outline2 $path/fixtures/mnonexistent.nim
>outline2 $path/fixtures/minclude_include.nim
outline	skProc	minclude_import.create		*fixtures/minclude_include.nim	3	5	""	100	4	45
>outline2 $path/fixtures/minclude_types.nim;$path/fixtures/mdep_v2.nim
outline	skType	minclude_types.Foo		*fixtures/minclude_types.nim	7	2	""	100	9	14
"""
