discard """
  targets: "cpp"
  cmd: "nim cpp $file"
  output: '''
2
false
destructing
destructing
'''
"""

type
  Foo  {.exportc.} = object
    test: int

proc memberProc(f: Foo) {.exportc, member.} = 
  echo $f.test

proc destructor(f: Foo) {.member: "~'1()".} = 
  echo "destructing"

proc `==`(self, other: Foo): bool {.member:"operator==('2 const & #2) const -> '0"} = 
  self.test == other.test

let foo = Foo(test: 2)
foo.memberProc()
echo foo == Foo(test: 1)
