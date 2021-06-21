## suggestions for enums

type
  LogLevel {.pure.} = enum
    debug, log, warn, error
  
  FooBar = enum
    fbFoo, fbBar

echo fbFoo, fbBar

echo LogLevel.deb#[!]#

discard """
$nimsuggest --tester $file
>sug $1
sug;;skEnumField;;debug;;LogLevel;;*nimsuggest/tests/tsug_enum.nim;;5;;4;;"";;100;;Prefix
"""