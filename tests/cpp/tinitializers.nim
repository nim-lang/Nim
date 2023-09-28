discard """
  cmd: "nim cpp $file"
"""

{.emit:"""/*TYPESECTION*/
struct CppStruct {
  CppStruct(int x, char* y): x(x), y(y){}
  void doSomething() {}
  int x;
  char* y;
};
""".}
type
  CppStruct {.importcpp, inheritable.} = object
  ChildStruct = object of CppStruct
  HasCppStruct = object
    cppstruct: CppStruct 

proc constructCppStruct(a:cint = 5, b:cstring = "hello"): CppStruct {.importcpp: "CppStruct(@)", constructor.}
proc doSomething(this: CppStruct) {.importcpp.}
proc returnCppStruct(): CppStruct = discard
proc initChildStruct: ChildStruct = ChildStruct() 
proc makeChildStruct(): ChildStruct {.constructor:"""ChildStruct(): CppStruct(5, "10")""".} = discard
proc initHasCppStruct(x: cint): HasCppStruct =
  HasCppStruct(cppstruct: constructCppStruct(x))

proc main =
  var hasCppStruct = initHasCppStruct(2) #generates cppstruct = { 10 } inside the struct
  hasCppStruct.cppstruct.doSomething() 
  discard returnCppStruct() #generates result = { 10 } 
  discard initChildStruct() #generates ChildStruct temp ({}) bypassed with makeChildStruct
  (proc (s:CppStruct) = discard)(CppStruct()) #CppStruct temp ({10})
main()


#Should handle ObjectCalls
{.emit:"""/*TYPESECTION*/
struct Foo {
};
struct Boo {
  Boo(int x, char* y, Foo f): x(x), y(y), foo(f){}
  int x;
  char* y;
  Foo foo;
};
""".}
type
  Foo {.importcpp, inheritable, bycopy.} = object
  Boo {.importcpp, inheritable.} = object
    x: int32
    y: cstring
    foo: Foo

proc makeBoo(a:cint = 10, b:cstring = "hello", foo: Foo = Foo()): Boo {.importcpp, constructor.}

proc main2() = 
  let cppStruct = makeBoo()
  (proc (s:Boo) = discard)(Boo()) 

main2()