discard """
  file: "tambsym2.nim"
  output: "7"
"""
# Test overloading of procs with locals

type
  TMyType = object
    len: int
    data: string
    
proc len(x: TMyType): int {.inline.} = return x.len

proc x(s: TMyType, len: int) = 
  writeln(stdout, len(s))
  
var
  m: TMyType
m.len = 7
m.data = "1234"

x(m, 5) #OUT 7


