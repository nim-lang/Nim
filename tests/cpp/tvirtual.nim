discard """
  targets: "cpp"
  cmd: "nim cpp $file"
  output: '''
hello foo
hello boo
hello boo
Const Message: hello world
NimPrinter: hello world
NimPrinterConstRef: hello world
NimPrinterConstRefByRef: hello world
'''
"""

{.emit:"""/*TYPESECTION*/
#include <iostream>
  class CppPrinter {
  public:
    
    virtual void printConst(char* message) const {
        std::cout << "Const Message: " << message << std::endl;
    }
    virtual void printConstRef(char* message, const int& flag) const {
        std::cout << "Const Ref Message: " << message << std::endl;
    }  
    virtual void printConstRef2(char* message, const int& flag) const {
        std::cout << "Const Ref2 Message: " << message << std::endl;
    }  
    
};
""".}

proc newCpp*[T](): ptr T {.importcpp:"new '*0()".}
type 
  Foo = object of RootObj
  FooPtr = ptr Foo
  Boo = object of Foo
  BooPtr = ptr Boo
  CppPrinter {.importcpp, inheritable.} = object
  NimPrinter {.exportc.} = object of CppPrinter

proc salute(self: FooPtr) {.virtual.} = 
  echo "hello foo"

proc salute(self: BooPtr) {.virtual.} =
  echo "hello boo"

let foo = newCpp[Foo]()
let boo = newCpp[Boo]()
let booAsFoo = cast[FooPtr](newCpp[Boo]())

#polymorphism works
foo.salute()
boo.salute()
booAsFoo.salute()
let message = "hello world".cstring

proc printConst(self: CppPrinter, message: cstring) {.importcpp.}
CppPrinter().printConst(message)

#notice override is optional. 
#Will make the cpp compiler to fail if not virtual function with the same signature if found in the base type
proc printConst(self: NimPrinter, message: cstring) {.virtual:"$1('2 #2) const override".} =
  echo "NimPrinter: " & $message

proc printConstRef(self: NimPrinter, message: cstring, flag: int32) {.virtual:"$1('2 #2, const '3& #3 ) const override".} =
  echo "NimPrinterConstRef: " & $message

proc printConstRef2(self: NimPrinter, message: cstring, flag {.byref.}: int32) {.virtual:"$1('2 #2, const '3 #3 ) const override".} =
  echo "NimPrinterConstRefByRef: " & $message

NimPrinter().printConst(message)
var val : int32 = 10
NimPrinter().printConstRef(message, val)
NimPrinter().printConstRef2(message, val)

#bug 22269
type Doo = object
proc naiveMember(x: Doo): int {. virtual .} = 2
discard naiveMember(Doo())

