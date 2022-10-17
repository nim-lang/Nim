import std/macros
import asyncdispatch

macro replyMacro(arg: untyped): untyped =
  result = quote do:
    `arg`

macro helloMacro*(prc: untyped): untyped =
  result = quote do:
    proc helloProc(): string = replyMacro("Hello")

#[!]#proc helloProc(): void {.helloMacro.}=
  discard

proc call(i: int): void =
  discard

#[!]#replyMacro(replyMacro(call(2)))

#[!]#replyMacro call 10

discard """
$nimsuggest --v3 --tester $file
>expand $2  1
expand	skUnknown				18	0	"replyMacro(call(2))"	0	18	31
>expand $2  2
expand	skUnknown				18	0	"call(2)"	0	18	31
>expand $2  all
expand	skUnknown				18	0	"call(2)"	0	18	31
>expand $2  0
expand	skUnknown				18	0	"replyMacro(replyMacro(call(2)))"	0	18	31
>expand $1
expand	skUnknown				12	0	"proc helloProc(): string =\x0A  result = \"Hello\"\x0A"	0	13	9
>expand $1  0
expand	skUnknown				12	0	"proc helloProc(): void {.helloMacro.} =\x0A  discard\x0A"	0	13	9
>expand $3  1
expand	skUnknown				20	0	"call 10"	0	20	18
"""
